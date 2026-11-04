import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'detail_peminjaman.dart';

class PeminjamanAdminScreen extends StatefulWidget {
  const PeminjamanAdminScreen({super.key});

  @override
  State<PeminjamanAdminScreen> createState() =>
      _PeminjamanAdminScreenState();
}

class _PeminjamanAdminScreenState
    extends State<PeminjamanAdminScreen> {
  static const Color navy = Color.fromARGB(255, 17, 18, 20);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFFCBD0D7);

  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  int selectedFilter = 0;

  final List<String> filters = [
    'Semua',
    'Dipinjam',
    'Dikembalikan',
    'Terlambat',
  ];

  List<Map<String, dynamic>> borrowings = [];

  @override
  void initState() {
    super.initState();
    loadBorrowings();
  }

  // =====================================================
  // LOAD DATA SUPABASE
  // =====================================================

  Future<void> loadBorrowings() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Mengambil semua data peminjaman.
      final borrowingResponse =
          await supabase.from('borrowings').select();

      final List<Map<String, dynamic>> borrowingData =
          List<Map<String, dynamic>>.from(borrowingResponse);

      // Mengambil ID buku dan anggota.
      final bookIds = borrowingData
          .map((item) => item['book_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      final userIds = borrowingData
          .map((item) =>
              item['user_id'] ?? item['member_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      // Mengambil data buku.
      List<Map<String, dynamic>> bookData = [];

      if (bookIds.isNotEmpty) {
        final response = await supabase
            .from('books')
            .select()
            .inFilter('id', bookIds);

        bookData = List<Map<String, dynamic>>.from(response);
      }

      // Mengambil data anggota.
      List<Map<String, dynamic>> profileData = [];

      if (userIds.isNotEmpty) {
        final response = await supabase
            .from('profiles')
            .select()
            .inFilter('id', userIds);

        profileData = List<Map<String, dynamic>>.from(response);
      }

      // Menggabungkan data.
      final Map<String, Map<String, dynamic>> booksMap = {
        for (final book in bookData)
          book['id'].toString(): book,
      };

      final Map<String, Map<String, dynamic>> profilesMap = {
        for (final profile in profileData)
          profile['id'].toString(): profile,
      };

      final List<Map<String, dynamic>> combined = [];

      for (final borrowing in borrowingData) {
        final bookId = borrowing['book_id']?.toString();

        final userId = (
          borrowing['user_id'] ?? borrowing['member_id']
        )?.toString();

        combined.add({
          ...borrowing,
          '_book': booksMap[bookId],
          '_profile': profilesMap[userId],
        });
      }

      // Urutkan berdasarkan tanggal terbaru.
      combined.sort((a, b) {
        final dateA = _parseDate(a['created_at']);
        final dateB = _parseDate(b['created_at']);

        return dateB.compareTo(dateA);
      });

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
  // HELPER DATA
  // =====================================================

  dynamic getValue(
    Map<String, dynamic>? data,
    List<String> keys, {
    dynamic fallback,
  }) {
    if (data == null) return fallback;

    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime(2000);

    return DateTime.tryParse(value.toString()) ??
        DateTime(2000);
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

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

  bool isOverdue(Map<String, dynamic> borrowing) {
    final status = getValue(
      borrowing,
      ['status'],
      fallback: '',
    ).toString().toLowerCase();

    final isBorrowed = [
      'dipinjam',
      'borrowed',
      'aktif',
    ].contains(status);

    if (!isBorrowed) return false;

    final dueDate = getValue(
      borrowing,
      ['due_date', 'tanggal_jatuh_tempo'],
    );

    if (dueDate == null) return false;

    final date = DateTime.tryParse(dueDate.toString());

    if (date == null) return false;

    return date.isBefore(DateTime.now());
  }

  String getStatus(Map<String, dynamic> borrowing) {
    if (isOverdue(borrowing)) return 'Terlambat';

    final status = getValue(
      borrowing,
      ['status'],
      fallback: 'Dipinjam',
    ).toString().toLowerCase();

    if ([
      'dipinjam',
      'borrowed',
      'aktif',
    ].contains(status)) {
      return 'Dipinjam';
    }

    if ([
      'dikembalikan',
      'returned',
      'selesai',
    ].contains(status)) {
      return 'Dikembalikan';
    }

    return status.isEmpty
        ? 'Dipinjam'
        : status[0].toUpperCase() + status.substring(1);
  }

  List<Map<String, dynamic>> get filteredBorrowings {
    if (selectedFilter == 0) return borrowings;

    return borrowings.where((item) {
      return getStatus(item).toLowerCase() ==
          filters[selectedFilter].toLowerCase();
    }).toList();
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
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
              'Peminjaman',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          IconButton(
            onPressed: loadBorrowings,
            icon: const Icon(
              Icons.refresh_rounded,
              color: navy,
              size: 22,
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
              Icons.cloud_off_rounded,
              color: navy,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat peminjaman',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: loadBorrowings,
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

  // =====================================================
  // CONTENT
  // =====================================================

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 12),

        _buildFilters(),

        const SizedBox(height: 17),

        Expanded(
          child: RefreshIndicator(
            color: navy,
            onRefresh: loadBorrowings,
            child: filteredBorrowings.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 150),
                      Icon(
                        Icons.menu_book_outlined,
                        color: mutedText,
                        size: 45,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Belum ada peminjaman',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      13,
                      0,
                      13,
                      18,
                    ),
                    itemCount: filteredBorrowings.length,
                    itemBuilder: (context, index) {
                      return _buildBorrowingCard(
                        filteredBorrowings[index],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // FILTERS
  // =====================================================

  Widget _buildFilters() {
    return SizedBox(
      height: 37,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final selected = selectedFilter == index;

          return InkWell(
            onTap: () {
              setState(() {
                selectedFilter = index;
              });
            },
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected ? navy : Colors.white,
                border: Border.all(
                  color: navy.withOpacity(0.7),
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: navy.withOpacity(0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: selected ? Colors.white : navy,
                  fontSize: 10,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // BORROWING CARD
  // =====================================================

  Widget _buildBorrowingCard(
    Map<String, dynamic> borrowing,
  ) {
    final book = borrowing['_book']
        as Map<String, dynamic>?;

    final profile = borrowing['_profile']
        as Map<String, dynamic>?;

    final title = getValue(
      book,
      ['title', 'judul'],
      fallback: 'Judul Buku',
    ).toString();

    final author = getValue(
      book,
      ['author', 'penulis'],
      fallback: 'Penulis',
    ).toString();

    final borrower = getValue(
      profile,
      ['full_name', 'name', 'nama_lengkap', 'username'],
      fallback: 'Nama Anggota',
    ).toString();

    final cover = getValue(
      book,
      ['cover_url', 'cover', 'image_url'],
    )?.toString();

    final createdAt = getValue(
      borrowing,
      ['created_at', 'borrow_date', 'tanggal_pinjam'],
    );

    final status = getStatus(borrowing);

    final bool overdue = status == 'Terlambat';

    final statusColor = overdue
        ? const Color(0xFFFF858C)
        : status == 'Dikembalikan'
            ? const Color(0xFFB9E4CD)
            : const Color(0xFFFFD15C);

    final statusTextColor = overdue
        ? const Color(0xFF8F1F29)
        : status == 'Dikembalikan'
            ? const Color(0xFF315F46)
            : navy;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPeminjamanScreen(
              borrowing: borrowing,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: navy,
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.12),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _bookCover(cover, title),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 9,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle_rounded,
                        color: navy,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          borrower,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    formatDate(createdAt),
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 8,
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
  // BOOK COVER
  // =====================================================

  Widget _bookCover(String? url, String title) {
    return Container(
      width: 50,
      height: 72,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _coverPlaceholder(),
            )
          : _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return const Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: navy,
        size: 27,
      ),
    );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  Widget _buildBottomNavigation() {
    final items = [
      Icons.home_outlined,
      Icons.menu_book_rounded,
      Icons.person_add_alt_1_outlined,
      Icons.menu_book_outlined,
      Icons.person_outline_rounded,
    ];

    final labels = [
      'Beranda',
      'Buku',
      'Anggota',
      'Peminjaman',
      'Akun',
    ];

    return Container(
      height: 57,
      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E0D5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(5, (index) {
            final selected = index == 3;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (index != 3) {
                    showMessage(
                      'Menu ${labels[index]} dipilih',
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[index],
                      size: 19,
                      color: selected
                          ? navy
                          : const Color(0xFF69624F),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 8,
                        color: selected
                            ? navy
                            : const Color(0xFF69624F),
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ======================================================
// DETAIL PEMINJAMAN
// ======================================================

class DetailPeminjamanScreen extends StatelessWidget {
  final Map<String, dynamic> borrowing;

  const DetailPeminjamanScreen({
    super.key,
    required this.borrowing,
  });

  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFFCBD0D7);

  dynamic getValue(
    Map<String, dynamic>? data,
    List<String> keys, {
    dynamic fallback,
  }) {
    if (data == null) return fallback;

    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }


  bool get overdue {
    final status = getValue(
      borrowing,
      ['status'],
      fallback: '',
    ).toString().toLowerCase();

    if (![
      'dipinjam',
      'borrowed',
      'aktif',
    ].contains(status)) {
      return false;
    }

    final dueDate = getValue(
      borrowing,
      ['due_date', 'tanggal_jatuh_tempo'],
    );

    if (dueDate == null) return false;

    final date = DateTime.tryParse(dueDate.toString());

    return date != null && date.isBefore(DateTime.now());
  }

  String get statusText {
    if (overdue) return 'Terlambat';

    final status = getValue(
      borrowing,
      ['status'],
      fallback: 'Dipinjam',
    ).toString().toLowerCase();

    if ([
      'dikembalikan',
      'returned',
      'selesai',
    ].contains(status)) {
      return 'Dikembalikan';
    }

    return 'Dipinjam';
  }

  @override
  Widget build(BuildContext context) {
    final book = borrowing['_book']
        as Map<String, dynamic>?;

    final profile = borrowing['_profile']
        as Map<String, dynamic>?;

    final title = getValue(
      book,
      ['title', 'judul'],
      fallback: 'Judul Buku',
    ).toString();

    final author = getValue(
      book,
      ['author', 'penulis'],
      fallback: '-',
    ).toString();

    final category = getValue(
      book,
      ['category', 'kategori'],
      fallback: '-',
    ).toString();

    final year = getValue(
      book,
      ['year', 'published_year', 'tahun_terbit'],
      fallback: '-',
    ).toString();

    final pages = getValue(
      book,
      ['pages', 'page_count', 'jumlah_halaman'],
      fallback: '-',
    ).toString();

    final stock = getValue(
      book,
      ['stock', 'stok'],
      fallback: '-',
    ).toString();

    final cover = getValue(
      book,
      ['cover_url', 'cover', 'image_url'],
    )?.toString();

    final memberName = getValue(
      profile,
      ['full_name', 'name', 'nama_lengkap', 'username'],
      fallback: 'Nama Anggota',
    ).toString();

    final nis = getValue(
      profile,
      ['nis', 'student_id', 'nomor_induk'],
      fallback: '-',
    ).toString();

    final memberClass = getValue(
      profile,
      ['class', 'kelas', 'class_name'],
      fallback: '-',
    ).toString();

    final phone = getValue(
      profile,
      ['phone', 'phone_number', 'no_hp', 'nomor_telepon'],
      fallback: '-',
    ).toString();

    final address = getValue(
      profile,
      ['address', 'alamat'],
      fallback: '-',
    ).toString();

    final borrowDate = getValue(
      borrowing,
      ['created_at', 'borrow_date', 'tanggal_pinjam'],
    );

    final dueDate = getValue(
      borrowing,
      ['due_date', 'tanggal_jatuh_tempo'],
    );

    final returnDate = getValue(
      borrowing,
      ['returned_at', 'return_date', 'tanggal_kembali'],
    );

    final statusColor = overdue
        ? const Color(0xFFFF858C)
        : statusText == 'Dikembalikan'
            ? const Color(0xFFB9E4CD)
            : const Color(0xFFFFD15C);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // INFORMASI BUKU
                    _buildBookCard(
                      title: title,
                      author: author,
                      category: category,
                      year: year,
                      pages: pages,
                      stock: stock,
                      cover: cover,
                    ),

                    const SizedBox(height: 28),

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

                    const SizedBox(height: 7),

                    _buildMemberCard(
                      memberName: memberName,
                      nis: nis,
                      memberClass: memberClass,
                    ),

                    const SizedBox(height: 17),

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

                    const SizedBox(height: 7),

                    _buildLoanInformation(
                      borrowDate: borrowDate,
                      dueDate: dueDate,
                      returnDate: returnDate,
                      phone: phone,
                      address: address,
                      statusColor: statusColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // =====================================================
  // DETAIL HEADER
  // =====================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // =====================================================
  // BOOK INFORMATION
  // =====================================================

  Widget _buildBookCard({
    required String title,
    required String author,
    required String category,
    required String year,
    required String pages,
    required String stock,
    required String? cover,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navy, width: 0.8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 95,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(7),
            ),
            clipBehavior: Clip.antiAlias,
            child: cover != null && cover.isNotEmpty
                ? Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  author,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$category · $year · $pages hlm',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  'Stok: $stock',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: navy,
              size: 20,
            ),
            color: Colors.white,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Text(
                  'Tutup menu',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
  // MEMBER INFORMATION
  // =====================================================

  Widget _buildMemberCard({
    required String memberName,
    required String nis,
    required String memberClass,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navy, width: 0.8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 65,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'NISN: $nis',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'KELAS: $memberClass',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LOAN INFORMATION
  // =====================================================

  Widget _buildLoanInformation({
    required dynamic borrowDate,
    required dynamic dueDate,
    required dynamic returnDate,
    required String phone,
    required String address,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: cream,
        border: Border.all(
          color: const Color(0xFFB9B9B9),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          _informationItem(
            icon: Icons.calendar_today_outlined,
            title: 'tanggal pinjaman',
            value: formatDate(borrowDate),
          ),

          const SizedBox(height: 18),

          _informationItem(
            icon: Icons.event_outlined,
            title: 'tanggal jatuh tempo',
            value: formatDate(dueDate),
          ),

          const SizedBox(height: 18),

          _informationItem(
            icon: Icons.assignment_return_outlined,
            title: 'tanggal kembali',
            value: returnDate == null
                ? 'Belum dikembalikan'
                : formatDate(returnDate),
          ),

          const SizedBox(height: 18),

          _informationItem(
            icon: Icons.history_rounded,
            title: 'status',
            value: statusText,
            statusColor: statusColor,
          ),

          const SizedBox(height: 18),

          _informationItem(
            icon: Icons.phone_outlined,
            title: 'nomor telepon',
            value: phone,
          ),

          const SizedBox(height: 18),

          _informationItem(
            icon: Icons.location_on_outlined,
            title: 'alamat',
            value: address,
          ),
        ],
      ),
    );
  }

  Widget _informationItem({
    required IconData icon,
    required String title,
    required String value,
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 43,
          child: Icon(
            icon,
            color: navy,
            size: 27,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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

              if (title == 'status')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
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
  // DATE FORMAT
  // =====================================================

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

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

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  Widget _buildBottomNavigation() {
    final icons = [
      Icons.home_outlined,
      Icons.menu_book_rounded,
      Icons.person_add_alt_1_outlined,
      Icons.menu_book_outlined,
      Icons.person_outline_rounded,
    ];

    final labels = [
      'Beranda',
      'Buku',
      'Anggota',
      'Peminjaman',
      'Akun',
    ];

    return Container(
      height: 57,
      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E0D5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(5, (index) {
            final selected = index == 3;

            return Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 19,
                    color: selected
                        ? navy
                        : const Color(0xFF69624F),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 8,
                      color: selected
                          ? navy
                          : const Color(0xFF69624F),
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}