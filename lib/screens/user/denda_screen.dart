
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';

class DendaScreen extends StatefulWidget {
  const DendaScreen({super.key});

  @override
  State<DendaScreen> createState() => _DendaScreenState();
}

class _DendaScreenState extends State<DendaScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color muted = Color(0xFF8993A1);
  static const Color orange = Color(0xFFE99A43);

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> fines = [];
  Map<String, Map<String, dynamic>> books = {};

  bool isLoading = true;
  String? errorMessage;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    loadFines();
  }

  // =====================================================
  // LOAD DATA DENDA DARI SUPABASE
  // =====================================================

  Future<void> loadFines() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Silakan login terlebih dahulu.');
      }

      final response = await supabase
          .from('borrowings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final borrowingData =
          List<Map<String, dynamic>>.from(response);

      // Ambil hanya transaksi yang memiliki denda.
      final fineData = borrowingData.where((item) {
        final amount = _toInt(item['fine_amount']);
        return amount > 0;
      }).toList();

      // Ambil data buku berdasarkan book_id.
      final bookIds = fineData
          .map((item) => item['book_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> bookMap = {};

      if (bookIds.isNotEmpty) {
        final bookResponse = await supabase
            .from('books')
            .select()
            .inFilter('id', bookIds);

        final bookData =
            List<Map<String, dynamic>>.from(bookResponse);

        bookMap = {
          for (final book in bookData)
            book['id'].toString(): book,
        };
      }

      final combined = fineData.map((item) {
        final bookId = item['book_id']?.toString();

        return {
          ...item,
          '_book': bookMap[bookId],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        fines = combined;
        books = bookMap;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // =====================================================
  // HELPER
  // =====================================================

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool _isPaid(Map<String, dynamic> item) {
    return item['fine_paid'] == true;
  }

  List<Map<String, dynamic>> get unpaidFines {
    return fines.where((item) => !_isPaid(item)).toList();
  }

  List<Map<String, dynamic>> get paidFines {
    return fines.where((item) => _isPaid(item)).toList();
  }

  List<Map<String, dynamic>> get currentFines {
    return selectedTab == 0 ? unpaidFines : paidFines;
  }

  int get totalUnpaid {
    return unpaidFines.fold(
      0,
      (total, item) => total + _toInt(item['fine_amount']),
    );
  }

  int get totalPaid {
    return paidFines.fold(
      0,
      (total, item) => total + _toInt(item['fine_amount']),
    );
  }

  int _lateDays(Map<String, dynamic> item) {
    final dueDate = _parseDate(item['due_date']);

    if (dueDate == null) return 0;

    final returnedAt = _parseDate(item['returned_at']);
    final referenceDate = returnedAt ?? DateTime.now();

    final due = DateUtils.dateOnly(dueDate);
    final actual = DateUtils.dateOnly(referenceDate);

    final difference = actual.difference(due).inDays;

    return difference > 0 ? difference : 0;
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date == null) return '-';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _rupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  String _formatHeaderDate(DateTime date) {
    const days = [
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
      'MINGGU',
    ];

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];

    return '${days[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: navy,
                      ),
                    )
                  : errorMessage != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 23),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => Navigator.maybePop(context),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Denda Saya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: loadFines,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _formatHeaderDate(DateTime.now()),
            style: const TextStyle(
              color: Color(0xFFD9DFE7),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CONTENT
  // =====================================================

  Widget _buildContent() {
    final list = currentFines;

    return RefreshIndicator(
      color: navy,
      onRefresh: loadFines,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(19, 22, 19, 30),
        children: [
          _buildTotalCard(),
          const SizedBox(height: 27),
          _buildTabs(),
          const SizedBox(height: 17),

          if (list.isEmpty)
            _buildEmptyState()
          else
            _buildFineList(list),
        ],
      ),
    );
  }

  // =====================================================
  // TOTAL DENDA
  // =====================================================

  Widget _buildTotalCard() {
    final isClear = totalUnpaid == 0;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3A8),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: navy,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TOTAL DENDA BELUM DIBAYAR',
                style: TextStyle(
                  color: navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            'Rp ${_rupiah(totalUnpaid)}',
            style: const TextStyle(
              color: navy,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isClear
                      ? const Color(0xFFD8F0E1)
                      : const Color(0xFFFFD0D0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isClear ? 'Tidak ada tagihan' : 'Belum lunas',
                  style: TextStyle(
                    color: isClear
                        ? const Color(0xFF267346)
                        : const Color(0xFFAA3434),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${unpaidFines.length} tagihan',
                style: const TextStyle(
                  color: navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: navy.withOpacity(0.12),
          ),
          const SizedBox(height: 11),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: navy,
                size: 15,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Pembayaran denda dapat dilakukan melalui '
                  'kasir perpustakaan. Status pembayaran akan '
                  'diperbarui setelah dikonfirmasi petugas.',
                  style: TextStyle(
                    color: navy,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TAB
  // =====================================================

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildTab(
            'Belum Dibayar',
            unpaidFines.length,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTab(
            'Riwayat Selesai',
            paidFines.length,
            1,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int count, int index) {
    final active = selectedTab == index;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: active ? navy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? navy : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.17)
                    : cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: active ? Colors.white : navy,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // LIST DENDA
  // =====================================================

  Widget _buildFineList(List<Map<String, dynamic>> list) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE9E9E5),
        ),
      ),
      child: Column(
        children: List.generate(list.length, (index) {
          final item = list[index];

          return Column(
            children: [
              _buildFineItem(item),
              if (index != list.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 91),
                  child: Divider(
                    height: 1,
                    thickness: 0.8,
                    color: const Color(0xFFE9E9E5),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // =====================================================
  // ITEM DENDA
  // =====================================================

  Widget _buildFineItem(Map<String, dynamic> item) {
    final book = item['_book'] as Map<String, dynamic>?;

    final title = (book?['title'] ?? 'Judul tidak tersedia').toString();
    final author = (book?['author'] ?? 'Penulis tidak tersedia').toString();
    final cover = (book?['cover_url'] ?? '').toString();

    final amount = _toInt(item['fine_amount']);
    final paid = _isPaid(item);
    final lateDays = _lateDays(item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(cover),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildStatus(paid),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Jatuh tempo',
                  _formatDate(item['due_date']),
                ),
                const SizedBox(height: 5),
                _buildDetailRow(
                  'Keterlambatan',
                  '$lateDays hari',
                ),
                const SizedBox(height: 5),
                _buildDetailRow(
                  'Total denda',
                  'Rp ${_rupiah(amount)}',
                  bold: true,
                ),
                if (paid && item['fine_paid_at'] != null) ...[
                  const SizedBox(height: 5),
                  _buildDetailRow(
                    'Dibayar pada',
                    _formatDate(item['fine_paid_at']),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(String url) {
    return Container(
      width: 69,
      height: 99,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(7),
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(),
            )
          : _coverFallback(),
    );
  }

  Widget _coverFallback() {
    return const Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: navy,
        size: 28,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            color: muted,
            fontSize: 10,
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(
            value,
            style: TextStyle(
              color: navy,
              fontSize: 10,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(bool paid) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: paid
            ? const Color(0xFFDDF1E4)
            : const Color(0xFFFFE1E1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        paid ? 'Lunas' : 'Belum Bayar',
        style: TextStyle(
          color: paid
              ? const Color(0xFF267346)
              : const Color(0xFFB33C3C),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: const BoxDecoration(
              color: cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: navy,
              size: 33,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            selectedTab == 0
                ? 'Tidak Ada Denda'
                : 'Belum Ada Riwayat Pembayaran',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            selectedTab == 0
                ? 'Kamu tidak memiliki tagihan denda saat ini.'
                : 'Riwayat pembayaran denda akan muncul di sini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ERROR
  // =====================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: navy,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal Memuat Data Denda',
              style: TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: loadFines,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
