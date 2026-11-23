
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/book_cover.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'collection_screen.dart';
import 'profile_screen.dart';
import 'denda_screen.dart';
import 'form_peminjaman.dart';

class PeminjamanScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedBook;

  const PeminjamanScreen({
    super.key,
    this.selectedBook,
  });

  @override
  State<PeminjamanScreen> createState() =>
      _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.cream;
  static const Color muted = AppColors.grey;
  static const Color dividerColor = AppColors.border;

  final supabase = Supabase.instance.client;

  int selectedNav = 2;
  int selectedFilter = 0;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> borrowings = [];

  final List<String> filters = [
    'Dipinjam',
    'Denda',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    loadBorrowings();

    // Buka formulir peminjaman bila halaman dipanggil dengan buku pilihan.
    final selectedBook = widget.selectedBook;
    if (selectedBook != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FormPeminjamanScreen(book: selectedBook),
          ),
        );
      });
    }
  }

  // =====================================================
  // LOAD DATA PEMINJAMAN USER
  // =====================================================

  Future<void> loadBorrowings() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = AuthService.currentUserId;

      if (userId == null) {
        throw Exception('Silakan login terlebih dahulu.');
      }

      final response = await supabase
          .from('borrowings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final transactions =
          List<Map<String, dynamic>>.from(response);

      final bookIds = transactions
          .map((item) => item['book_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      List<Map<String, dynamic>> books = [];

      if (bookIds.isNotEmpty) {
        final bookResponse = await supabase
            .from('books')
            .select()
            .inFilter('id', bookIds);

        books = List<Map<String, dynamic>>.from(
          bookResponse,
        );
      }

      final bookMap = {
        for (final book in books)
          book['id'].toString(): book,
      };

      final combined = transactions.map((item) {
        final bookId = item['book_id']?.toString();

        return {
          ...item,
          '_book': bookMap[bookId],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        borrowings = combined;
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

  String valueOf(
    Map<String, dynamic>? data,
    List<String> keys, {
    String fallback = '-',
  }) {
    if (data == null) return fallback;

    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String formatDate(dynamic value) {
    final date = parseDate(value);

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

  String formatRupiah(dynamic value) {
    final amount = num.tryParse(value?.toString() ?? '') ?? 0;

    final digits = amount.toInt().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp${buffer.toString()}';
  }

  String normalizeStatus(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  // =====================================================
  // STATUS DAN KATEGORI
  // =====================================================

  bool isReturned(Map<String, dynamic> item) {
    final status = normalizeStatus(item['status']);

    return [
      'dikembalikan',
      'returned',
      'selesai',
    ].contains(status);
  }

  bool isRejected(Map<String, dynamic> item) {
    return normalizeStatus(item['status']) == 'ditolak';
  }

  bool isActive(Map<String, dynamic> item) {
    final status = normalizeStatus(item['status']);

    return [
      'menunggu',
      'dipinjam',
      'borrowed',
      'aktif',
      'menunggu pengembalian',
    ].contains(status);
  }

  bool isOverdue(Map<String, dynamic> item) {
    if (isReturned(item) || isRejected(item)) {
      return false;
    }

    final status = normalizeStatus(item['status']);

    if (![
      'dipinjam',
      'borrowed',
      'aktif',
      'menunggu pengembalian',
    ].contains(status)) {
      return false;
    }

    final dueDate = parseDate(item['due_date']);

    if (dueDate == null) return false;

    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(dueDate);

    return due.isBefore(today);
  }

  bool hasFine(Map<String, dynamic> item) {
    final fineAmount =
        num.tryParse(item['fine_amount']?.toString() ?? '') ?? 0;

    return fineAmount > 0;
  }

  bool isUnpaidFine(Map<String, dynamic> item) {
    return hasFine(item) && item['fine_paid'] != true;
  }

  String getStatus(Map<String, dynamic> item) {
    final status = normalizeStatus(item['status']);

    if (status == 'menunggu') return 'Menunggu';

    if (status == 'ditolak') return 'Ditolak';

    if (status == 'menunggu pengembalian') {
      return 'Menunggu Pengembalian';
    }

    if (isReturned(item)) return 'Selesai';

    if (isOverdue(item)) return 'Terlambat';

    if ([
      'dipinjam',
      'borrowed',
      'aktif',
    ].contains(status)) {
      return 'Dipinjam';
    }

    return status.isEmpty ? 'Tidak diketahui' : status;
  }

  // =====================================================
  // FILTER DATA
  // =====================================================

  List<Map<String, dynamic>> get visibleBorrowings {
    switch (selectedFilter) {
      case 0:
        return borrowings.where((item) {
          return isActive(item);
        }).toList();

      case 1:
        return borrowings.where((item) {
          return isUnpaidFine(item);
        }).toList();

      case 2:
        return borrowings.where((item) {
          return isReturned(item);
        }).toList();

      default:
        return borrowings;
    }
  }

  int getFilterCount(int index) {
    switch (index) {
      case 0:
        return borrowings.where(isActive).length;

      case 1:
        return borrowings.where(isUnpaidFine).length;

      case 2:
        return borrowings.where(isReturned).length;

      default:
        return 0;
    }
  }

  // =====================================================
  // WARNA STATUS
  // =====================================================

  Color statusBackground(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFFFE9B9);

      case 'Ditolak':
      case 'Terlambat':
        return const Color(0xFFFFE0E0);

      case 'Dipinjam':
        return const Color(0xFFDDE8F6);

      case 'Menunggu Pengembalian':
        return const Color(0xFFECE3F7);

      case 'Selesai':
        return const Color(0xFFDCEFE3);

      default:
        return cream;
    }
  }

  Color statusForeground(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFF85601D);

      case 'Ditolak':
      case 'Terlambat':
        return const Color(0xFF9B3636);

      case 'Dipinjam':
        return const Color(0xFF355D8C);

      case 'Menunggu Pengembalian':
        return const Color(0xFF715393);

      case 'Selesai':
        return const Color(0xFF356A4D);

      default:
        return navy;
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
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
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: selectedNav,
        onTap: _navigateTo,
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _goBack,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.chevron_left_rounded,
                color: navy,
                size: 29,
              ),
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Riwayat Peminjaman',
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),

          IconButton(
            onPressed: _openDenda,
            tooltip: 'Denda Saya',
            icon: const Icon(
              Icons.receipt_long_outlined,
              color: navy,
              size: 21,
            ),
          ),
          IconButton(
            onPressed: loadBorrowings,
            tooltip: 'Muat ulang',
            icon: const Icon(
              Icons.refresh_rounded,
              color: navy,
              size: 21,
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
    final data = visibleBorrowings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        _buildFilterButtons(),

        const SizedBox(height: 23),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Text(
                selectedFilter == 0
                    ? 'Buku yang sedang dipinjam'
                    : selectedFilter == 1
                        ? 'Riwayat denda'
                        : 'Buku yang telah dikembalikan',
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Spacer(),

              Text(
                '${data.length} buku',
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: RefreshIndicator(
            color: navy,
            onRefresh: loadBorrowings,
            child: data.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      7,
                      22,
                      25,
                    ),
                    itemCount: data.length,
                    separatorBuilder: (_, __) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 0.7,
                          color: dividerColor,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      return _buildLoanItem(data[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // FILTER BUTTONS
  // =====================================================

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: List.generate(filters.length, (index) {
          final active = selectedFilter == index;
          final count = getFilterCount(index);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == filters.length - 1 ? 0 : 10,
              ),
              child: _buildFilterButton(
                label: filters[index],
                count: count,
                active: active,
                onTap: () {
                  if (index == 1) {
                    _openDenda();
                  } else {
                    setState(() {
                      selectedFilter = index;
                    });
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? AppColors.yellow : navy,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: active ? navy : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 5),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? navy.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: active ? navy : Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ITEM PEMINJAMAN
  // =====================================================

  Widget _buildLoanItem(Map<String, dynamic> item) {
    final book = item['_book'] as Map<String, dynamic>?;

    final title = valueOf(
      book,
      ['title', 'judul'],
      fallback: 'Judul tidak tersedia',
    );

    final author = valueOf(
      book,
      ['author', 'penulis'],
    );

    final cover = valueOf(
      book,
      ['cover_url', 'cover', 'image_url'],
      fallback: '',
    );

    final status = getStatus(item);

    final borrowedDate = item['borrowed_at'] ??
        item['created_at'];

    final dueDate = item['due_date'];

    final fineAmount =
        num.tryParse(item['fine_amount']?.toString() ?? '') ?? 0;

    final returnedAt = item['returned_at'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // COVER BUKU
        _buildBookCover(cover),

        const SizedBox(width: 12),

        // INFORMASI BUKU
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
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(width: 7),

                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              _buildDateInfo(
                icon: Icons.calendar_today_outlined,
                label: 'Tanggal pinjam',
                value: formatDate(borrowedDate),
              ),

              const SizedBox(height: 5),

              if (isReturned(item))
                _buildDateInfo(
                  icon: Icons.event_available_outlined,
                  label: 'Dikembalikan',
                  value: formatDate(returnedAt),
                )
              else
                _buildDateInfo(
                  icon: Icons.event_outlined,
                  label: 'Batas pengembalian',
                  value: formatDate(dueDate),
                ),

              if (fineAmount > 0) ...[
                const SizedBox(height: 9),

                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 13,
                      color: isUnpaidFine(item)
                          ? const Color(0xFFB64B4B)
                          : const Color(0xFF43805B),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Denda: ${formatRupiah(fineAmount)}',
                      style: TextStyle(
                        color: isUnpaidFine(item)
                            ? const Color(0xFFB64B4B)
                            : const Color(0xFF43805B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      item['fine_paid'] == true
                          ? '(Lunas)'
                          : '(Belum dibayar)',
                      style: TextStyle(
                        color: isUnpaidFine(item)
                            ? const Color(0xFFB64B4B)
                            : const Color(0xFF43805B),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // COVER BUKU
  // =====================================================

  Widget _buildBookCover(String url) {
    return BookCover(
      imageUrl: url,
      width: 62,
      height: 88,
      radius: 6,
    );
  }

  // =====================================================
  // STATUS BADGE
  // =====================================================

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusBackground(status),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusForeground(status),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =====================================================
  // DATE INFO
  // =====================================================

  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: muted,
        ),

        const SizedBox(width: 5),

        Text(
          '$label: ',
          style: const TextStyle(
            color: muted,
            fontSize: 9.5,
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
    String title;
    String description;
    IconData icon;

    switch (selectedFilter) {
      case 0:
        title = 'Tidak Ada Peminjaman';
        description =
            'Buku yang sedang kamu pinjam akan muncul di sini.';
        icon = Icons.menu_book_outlined;
        break;

      case 1:
        title = 'Tidak Ada Denda';
        description =
            'Kamu tidak memiliki tagihan denda yang belum dibayar.';
        icon = Icons.receipt_long_outlined;
        break;

      case 2:
        title = 'Belum Ada Buku Selesai';
        description =
            'Buku yang sudah dikembalikan akan muncul di sini.';
        icon = Icons.library_books_outlined;
        break;

      default:
        title = 'Belum Ada Riwayat';
        description = 'Riwayat peminjamanmu akan muncul di sini.';
        icon = Icons.menu_book_outlined;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 105),

        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: navy,
              size: 38,
            ),
          ),
        ),

        const SizedBox(height: 17),

        Center(
          child: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 7),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // ERROR STATE
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
              size: 43,
            ),

            const SizedBox(height: 14),

            const Text(
              'Gagal Memuat Riwayat',
              style: TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 17),

            ElevatedButton.icon(
              onPressed: loadBorrowings,
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

  // =====================================================
  // NAVIGASI
  // =====================================================

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  void _openDenda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DendaScreen(),
      ),
    );
  }

  void _navigateTo(int index) {
    if (index == selectedNav) return;

    Widget? destination;

    switch (index) {
      case 0:
        destination = const DashboardScreen();
        break;

      case 1:
        destination = const SearchPageScreen();
        break;

      case 2:
        return;

      case 3:
        destination = const CollectionScreen();
        break;

      case 4:
        destination = const ProfileScreen();
        break;
    }

    if (destination == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
    );
  }
}
