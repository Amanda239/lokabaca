
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_bottom_navigation.dart';

class DetailPeminjamanScreen extends StatefulWidget {
  final dynamic borrowingId;

  const DetailPeminjamanScreen({
    super.key,
    required this.borrowingId,
  });

  @override
  State<DetailPeminjamanScreen> createState() =>
      _DetailPeminjamanScreenState();
}

class _DetailPeminjamanScreenState
    extends State<DetailPeminjamanScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color muted = Color(0xFF8993A1);

  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? borrowing;
  Map<String, dynamic>? book;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    loadBorrowingDetail();
  }

  // =====================================================
  // LOAD DETAIL TRANSAKSI DARI SUPABASE
  // =====================================================

  Future<void> loadBorrowingDetail() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Ambil transaksi peminjaman.
      final response = await supabase
          .from('borrowings')
          .select()
          .eq('id', widget.borrowingId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Data peminjaman tidak ditemukan.');
      }

      final transaction =
          Map<String, dynamic>.from(response);

      // 2. Ambil data buku berdasarkan book_id.
      Map<String, dynamic>? bookData;

      if (transaction['book_id'] != null) {
        final result = await supabase
            .from('books')
            .select()
            .eq('id', transaction['book_id'])
            .maybeSingle();

        if (result != null) {
          bookData = Map<String, dynamic>.from(result);
        }
      }

      // 3. Ambil data anggota berdasarkan user_id/member_id.
      final userId = transaction['user_id'] ??
          transaction['member_id'];

      Map<String, dynamic>? profileData;

      if (userId != null) {
        final result = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (result != null) {
          profileData = Map<String, dynamic>.from(result);
        }
      }

      if (!mounted) return;

      setState(() {
        borrowing = transaction;
        book = bookData;
        profile = profileData;
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

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    const months = [
      'Januari', 'Februari', 'Maret', 'April',
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // =====================================================
  // STATUS
  // =====================================================

  String get statusText {
    if (borrowing == null) return '-';

    final status = (borrowing!['status'] ?? '')
        .toString()
        .toLowerCase();

    if (['dipinjam', 'borrowed', 'aktif'].contains(status)) {
      final dueDate = DateTime.tryParse(
        (borrowing!['due_date'] ??
                borrowing!['tanggal_jatuh_tempo'] ??
                '')
            .toString(),
      );

      if (dueDate != null) {
        final today = DateTime.now();

        final due = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
        );

        final now = DateTime(
          today.year,
          today.month,
          today.day,
        );

        if (due.isBefore(now)) {
          return 'Terlambat';
        }
      }

      return 'Dipinjam';
    }

    if (['dikembalikan', 'returned', 'selesai'].contains(status)) {
      return 'Dikembalikan';
    }

    if (status == 'terlambat') return 'Terlambat';

    return status.isEmpty ? 'Tidak diketahui' : status;
  }

  Color get statusColor {
    switch (statusText) {
      case 'Terlambat':
        return const Color(0xFFFFD6D6);
      case 'Dikembalikan':
        return const Color(0xFFB9E4CD);
      default:
        return const Color(0xFFFFD36A);
    }
  }

  Color get statusTextColor {
    switch (statusText) {
      case 'Terlambat':
        return const Color(0xFFB83232);
      case 'Dikembalikan':
        return const Color(0xFF315F46);
      default:
        return const Color(0xFF76551A);
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      : borrowing == null
                          ? _buildEmpty()
                          : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: 3,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: navy,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Detail Peminjaman',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: loadBorrowingDetail,
            icon: const Icon(
              Icons.refresh_rounded,
              color: navy,
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
    final title = valueOf(
      book,
      ['title', 'judul'],
      fallback: 'Buku tidak ditemukan',
    );

    final author = valueOf(
      book,
      ['author', 'penulis'],
    );

    final category = valueOf(
      book,
      ['category', 'kategori'],
    );

    final year = valueOf(
      book,
      ['published_year', 'year', 'tahun_terbit'],
    );

    final pages = valueOf(
      book,
      ['pages', 'page_count', 'jumlah_halaman'],
    );

    final stock = valueOf(
      book,
      ['stock', 'stok'],
    );

    final cover = valueOf(
      book,
      ['cover_url', 'cover', 'image_url'],
      fallback: '',
    );

    final memberName = valueOf(
      profile,
      ['full_name', 'name', 'nama_lengkap', 'username'],
      fallback: 'Anggota tidak ditemukan',
    );

    final nis = valueOf(
      profile,
      ['nisn', 'nis', 'student_id', 'nomor_induk'],
    );

    final kelas = valueOf(
      profile,
      ['kelas', 'class_name'],
    );

    final borrowedDate = borrowing!['borrowed_at'] ??
        borrowing!['borrow_date'] ??
        borrowing!['tanggal_pinjam'] ??
        borrowing!['created_at'];

    final dueDate = borrowing!['due_date'] ??
        borrowing!['tanggal_jatuh_tempo'];

    final returnedDate = borrowing!['returned_at'] ??
        borrowing!['return_date'] ??
        borrowing!['tanggal_kembali'];

    return RefreshIndicator(
      color: navy,
      onRefresh: loadBorrowingDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(17, 9, 17, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFORMASI BUKU
            _buildBookCard(
              cover: cover,
              title: title,
              author: author,
              category: category,
              year: year,
              pages: pages,
              stock: stock,
            ),

            const SizedBox(height: 27),

            // INFORMASI ANGGOTA
            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: Text(
                'Informasi anggota',
                style: TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildMemberCard(
              name: memberName,
              nis: nis,
              kelas: kelas,
            ),

            const SizedBox(height: 19),

            // INFORMASI PEMINJAMAN
            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: Text(
                'Informasi peminjaman',
                style: TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildBorrowingInfo(
              borrowedDate: borrowedDate,
              dueDate: dueDate,
              returnedDate: returnedDate,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BOOK CARD
  // =====================================================

  Widget _buildBookCard({
    required String cover,
    required String title,
    required String author,
    required String category,
    required String year,
    required String pages,
    required String stock,
  }) {
    final additionalInfo = [
      category,
      if (year != '-') year,
      if (pages != '-') '$pages hlm',
    ].where((e) => e != '-').join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: navy.withOpacity(0.7),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBookCover(cover),
          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                if (additionalInfo.isNotEmpty)
                  Text(
                    additionalInfo,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 9,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Stok: $stock',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.more_vert_rounded,
            color: navy,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover(String url) {
    return Container(
      width: 68,
      height: 102,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverPlaceholder(),
            )
          : _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return const Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: navy,
        size: 30,
      ),
    );
  }

  // =====================================================
  // MEMBER CARD
  // =====================================================

  Widget _buildMemberCard({
    required String name,
    required String nis,
    required String kelas,
  }) {
    final avatarUrl = valueOf(
      profile,
      ['avatar_url', 'photo_url', 'profile_image'],
      fallback: '',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: navy.withOpacity(0.7),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _memberPlaceholder(),
                  )
                : _memberPlaceholder(),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'NISN: $nis',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KELAS: $kelas',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberPlaceholder() {
    return const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 48,
    );
  }

  // =====================================================
  // BORROWING INFORMATION
  // =====================================================

  Widget _buildBorrowingInfo({
    required dynamic borrowedDate,
    required dynamic dueDate,
    required dynamic returnedDate,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: cream,
        border: Border.all(
          color: const Color(0xFFB8B9B7),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            icon: Icons.calendar_today_rounded,
            title: 'Tanggal pinjaman',
            value: formatDate(borrowedDate),
          ),

          const SizedBox(height: 19),

          _infoRow(
            icon: Icons.event_note_rounded,
            title: 'Tanggal jatuh tempo',
            value: formatDate(dueDate),
          ),

          const SizedBox(height: 19),

          _infoRow(
            icon: Icons.assignment_return_rounded,
            title: 'Tanggal kembali',
            value: formatDate(returnedDate),
          ),

          const SizedBox(height: 19),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 45,
                child: Icon(
                  Icons.alarm_rounded,
                  color: navy,
                  size: 31,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        color: navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 45,
          child: Icon(
            icon,
            color: navy,
            size: 30,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // LOADING / ERROR / EMPTY
  // =====================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: navy,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal Memuat Detail',
              style: TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: loadBorrowingDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Data peminjaman tidak ditemukan',
        style: TextStyle(
          color: muted,
          fontSize: 13,
        ),
      ),
    );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  void _handleBottomNavigation(int index) {
    if (index == 3) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Silakan pilih menu melalui navigasi utama.',
        ),
      ),
    );
  }
}
