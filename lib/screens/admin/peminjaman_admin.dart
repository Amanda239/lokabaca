import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_bottom_navigation.dart';
import 'detail_peminjaman.dart';

// Halaman untuk navigasi bottom navigation
import 'dashboard_admin.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'profile_admin.dart';

class PeminjamanAdminScreen extends StatefulWidget {
  const PeminjamanAdminScreen({super.key});

  @override
  State<PeminjamanAdminScreen> createState() =>
      _PeminjamanAdminScreenState();
}

class _PeminjamanAdminScreenState
    extends State<PeminjamanAdminScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color muted = Color(0xFF8993A1);

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> borrowings = [];

  bool isLoading = true;
  String? errorMessage;
  int selectedFilter = 0;

  final List<String> filters = [
    'Semua',
    'Dipinjam',
    'Dikembalikan',
    'Terlambat',
  ];

  @override
  void initState() {
    super.initState();
    loadBorrowings();
  }

  // =====================================================
  // LOAD DATA PEMINJAMAN
  // =====================================================

  Future<void> loadBorrowings() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await supabase
          .from('borrowings')
          .select()
          .order('created_at', ascending: false);

      final transactions =
          List<Map<String, dynamic>>.from(response);

      final bookIds = transactions
          .map((e) => e['book_id'])
          .where((e) => e != null)
          .toSet()
          .toList();

      final userIds = transactions
          .map((e) => e['user_id'] ?? e['member_id'])
          .where((e) => e != null)
          .toSet()
          .toList();

      List<Map<String, dynamic>> books = [];
      List<Map<String, dynamic>> profiles = [];

      if (bookIds.isNotEmpty) {
        final result = await supabase
            .from('books')
            .select()
            .inFilter('id', bookIds);

        books = List<Map<String, dynamic>>.from(result);
      }

      if (userIds.isNotEmpty) {
        final result = await supabase
            .from('profiles')
            .select()
            .inFilter('id', userIds);

        profiles = List<Map<String, dynamic>>.from(result);
      }

      final bookMap = {
        for (final book in books)
          book['id'].toString(): book,
      };

      final profileMap = {
        for (final profile in profiles)
          profile['id'].toString(): profile,
      };

      final combined = transactions.map((transaction) {
        final bookId = transaction['book_id']?.toString();

        final userId = (transaction['user_id'] ??
                transaction['member_id'])
            ?.toString();

        return {
          ...transaction,
          '_book': bookMap[bookId],
          '_profile': profileMap[userId],
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
    return DateTime.tryParse(value.toString());
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

  bool isOverdue(Map<String, dynamic> item) {
    final status = (item['status'] ?? '')
        .toString()
        .toLowerCase();

    if (!['dipinjam', 'borrowed', 'aktif'].contains(status)) {
      return false;
    }

    final dueDate = parseDate(
      item['due_date'] ?? item['tanggal_jatuh_tempo'],
    );

    if (dueDate == null) return false;

    final today = DateTime.now();

    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).isBefore(
      DateTime(today.year, today.month, today.day),
    );
  }

  String getStatus(Map<String, dynamic> item) {
    if (isOverdue(item)) return 'Terlambat';

    final status = (item['status'] ?? '')
        .toString()
        .toLowerCase();

    if ([
      'dikembalikan',
      'returned',
      'selesai',
    ].contains(status)) {
      return 'Dikembalikan';
    }

    if ([
      'dipinjam',
      'borrowed',
      'aktif',
    ].contains(status)) {
      return 'Dipinjam';
    }

    return status.isEmpty ? 'Tidak diketahui' : status;
  }

  List<Map<String, dynamic>> get filteredBorrowings {
    if (selectedFilter == 0) return borrowings;

    return borrowings.where((item) {
      return getStatus(item) == filters[selectedFilter];
    }).toList();
  }

  // =====================================================
  // JUMLAH DATA PER FILTER
  // =====================================================

  int getFilterCount(int index) {
    if (index == 0) return borrowings.length;

    return borrowings
        .where((item) => getStatus(item) == filters[index])
        .length;
  }

  // =====================================================
  // SNACKBAR
  // =====================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
      ),
    );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  void handleBottomNavigation(int index) {
    // Sudah berada di halaman Peminjaman
    if (index == 3) return;

    late final Widget page;

    switch (index) {
      case 0:
        page = const DashboardAdmin();
        break;

      case 1:
        page = const KelolaBukuScreen();
        break;

      case 2:
        page = const KelolaAnggotaPage();
        break;

      case 4:
        page = const AdminProfileScreen();
        break;

      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => page,
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
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: 3,
        onTap: handleBottomNavigation,
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
    final data = filteredBorrowings;

    return Column(
      children: [
        const SizedBox(height: 10),

        _buildFilters(),

        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(
                Icons.library_books_outlined,
                color: navy,
                size: 19,
              ),

              const SizedBox(width: 7),

              Text(
                'Total peminjaman: ${borrowings.length}',
                style: const TextStyle(
                  color: navy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            color: navy,
            onRefresh: loadBorrowings,
            child: data.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),

                      Icon(
                        Icons.menu_book_outlined,
                        size: 55,
                        color: muted.withOpacity(0.6),
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                          borrowings.isEmpty
                              ? 'Belum ada peminjaman'
                              : 'Tidak ada peminjaman ${filters[selectedFilter].toLowerCase()}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      0,
                      14,
                      20,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return _buildBorrowingCard(data[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // FILTER PEMINJAMAN
  // =====================================================

  Widget _buildFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = selectedFilter == index;
          final count = getFilterCount(index);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                setState(() {
                  selectedFilter = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? navy : cream,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: selected
                        ? navy
                        : const Color(0xFFEAE5D9),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filters[index],
                      style: TextStyle(
                        color: selected ? Colors.white : navy,
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 7),

                    AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(0.18)
                            : const Color(0xFFE8E1D2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : navy,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // CARD PEMINJAMAN
  // =====================================================

  Widget _buildBorrowingCard(
    Map<String, dynamic> item,
  ) {
    final book = item['_book'] as Map<String, dynamic>?;
    final profile =
        item['_profile'] as Map<String, dynamic>?;

    final title = valueOf(
      book,
      ['title', 'judul'],
      fallback: 'Judul tidak tersedia',
    );

    final author = valueOf(
      book,
      ['author', 'penulis'],
    );

    final borrower = valueOf(
      profile,
      ['full_name', 'name', 'nama_lengkap', 'username'],
      fallback: 'Anggota tidak tersedia',
    );

    final cover = valueOf(
      book,
      ['cover_url', 'cover', 'image_url'],
      fallback: '',
    );

    final borrowedDate = item['borrowed_at'] ??
        item['borrow_date'] ??
        item['tanggal_pinjam'] ??
        item['created_at'];

    final status = getStatus(item);

    final Color statusColor;
    final Color statusTextColor;

    if (status == 'Terlambat') {
      statusColor = const Color(0xFFFF858C);
      statusTextColor = const Color(0xFF8F1F29);
    } else if (status == 'Dikembalikan') {
      statusColor = const Color(0xFFB9E4CD);
      statusTextColor = const Color(0xFF315F46);
    } else {
      statusColor = const Color(0xFFFFD15C);
      statusTextColor = navy;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPeminjamanScreen(
              borrowingId: item['id'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE2E5E9),
            width: 0.9,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildBookCover(cover),

            const SizedBox(width: 11),

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
                      color: muted,
                      fontSize: 9,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle_rounded,
                        color: navy,
                        size: 13,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          borrower,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: muted,
                        size: 10,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        formatDate(borrowedDate),
                        style: const TextStyle(
                          color: muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
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
  // COVER BUKU
  // =====================================================

  Widget _buildBookCover(String url) {
    return Container(
      width: 51,
      height: 75,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(7),
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _coverFallback(),
            )
          : _coverFallback(),
    );
  }

  Widget _coverFallback() {
    return const Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: navy,
        size: 27,
      ),
    );
  }

  // =====================================================
  // ERROR
  // =====================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                color: muted,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: loadBorrowings,
              icon: const Icon(Icons.refresh),
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