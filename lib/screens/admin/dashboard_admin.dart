
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8792A1);
  static const Color borderColor = Color(0xFFE8E4DB);

  final SupabaseClient supabase = Supabase.instance.client;

  int selectedIndex = 0;

  bool isLoading = true;
  String? errorMessage;

  int totalBooks = 0;
  int totalMembers = 0;
  int activeLoans = 0;
  int overdueLoans = 0;

  List<Map<String, dynamic>> recentLoans = [];

  // BOTTOM NAVIGATION: HANYA 4 MENU
  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.home_outlined, 'label': 'Beranda'},
    {'icon': Icons.menu_book_outlined, 'label': 'Buku'},
    {'icon': Icons.people_outline_rounded, 'label': 'Anggota'},
    {'icon': Icons.assignment_outlined, 'label': 'Peminjaman'},
  ];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  // ==========================================
  // LOAD DASHBOARD DATA
  // ==========================================

  Future<void> loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. TOTAL BUKU
      final booksCount = await supabase
          .from('books')
          .count(CountOption.exact);

      // 2. TOTAL ANGGOTA
      final membersCount = await supabase
          .from('profiles')
          .count(CountOption.exact)
          .eq('role', 'anggota');

      // 3. AMBIL DATA PEMINJAMAN
      // Tidak menggunakan JOIN otomatis.
      final borrowingResponse = await supabase
          .from('borrowings')
          .select('''
            id,
            user_id,
            book_id,
            borrowed_at,
            due_date,
            returned_at,
            status,
            created_at
          ''')
          .order('created_at', ascending: false);

      final borrowings = List<Map<String, dynamic>>.from(
        borrowingResponse,
      );

      // 4. AMBIL ID BUKU
      final bookIds = borrowings
          .map((item) => item['book_id'])
          .whereType<int>()
          .toSet()
          .toList();

      // 5. AMBIL ID ANGGOTA
      final userIds = borrowings
          .map((item) => item['user_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      // 6. AMBIL DATA BUKU SECARA TERPISAH
      final Map<int, Map<String, dynamic>> booksMap = {};

      if (bookIds.isNotEmpty) {
        final booksResponse = await supabase
            .from('books')
            .select('id, title, author, cover_url')
            .inFilter('id', bookIds);

        for (final item in booksResponse) {
          final book = Map<String, dynamic>.from(item);
          final id = book['id'];

          if (id is int) {
            booksMap[id] = book;
          }
        }
      }

      // 7. AMBIL PROFIL ANGGOTA SECARA TERPISAH
      // Tabel profiles tetap dipakai untuk nama peminjam.
      final Map<String, Map<String, dynamic>> profilesMap = {};

      if (userIds.isNotEmpty) {
        final profilesResponse = await supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', userIds);

        for (final item in profilesResponse) {
          final profile = Map<String, dynamic>.from(item);
          final id = profile['id']?.toString();

          if (id != null) {
            profilesMap[id] = profile;
          }
        }
      }

      // 8. GABUNGKAN DATA BERDASARKAN ID
      final List<Map<String, dynamic>> combinedLoans = [];

      for (final borrowing in borrowings) {
        final bookId = borrowing['book_id'];
        final userId = borrowing['user_id']?.toString();

        final book = bookId is int ? booksMap[bookId] : null;
        final profile = userId != null
            ? profilesMap[userId]
            : null;

        combinedLoans.add({
          ...borrowing,
          'books': book,
          'profiles': profile,
        });
      }

      // 9. PEMINJAMAN AKTIF
      final active = combinedLoans.where((borrowing) {
        return _isActiveStatus(borrowing['status']);
      }).toList();

      // 10. PEMINJAMAN TERLAMBAT
      final overdue = active.where((borrowing) {
        return _isOverdue(borrowing);
      }).toList();

      if (!mounted) return;

      setState(() {
        totalBooks = booksCount;
        totalMembers = membersCount;
        activeLoans = active.length;
        overdueLoans = overdue.length;
        recentLoans = combinedLoans.take(5).toList();
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

  // ==========================================
  // STATUS PEMINJAMAN
  // ==========================================

  bool _isActiveStatus(dynamic value) {
    final status = value?.toString().toLowerCase().trim() ?? '';

    return [
      'dipinjam',
      'borrowed',
      'aktif',
      'active',
    ].contains(status);
  }

  bool _isOverdue(Map<String, dynamic> borrowing) {
    if (!_isActiveStatus(borrowing['status'])) {
      return false;
    }

    final dueDate = DateTime.tryParse(
      borrowing['due_date']?.toString() ?? '',
    );

    if (dueDate == null) return false;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final deadline = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );

    return deadline.isBefore(today);
  }

  // ==========================================
  // MESSAGE
  // ==========================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==========================================
  // NAVIGASI HALAMAN
  // ==========================================

  Future<void> navigateToPage(
    int index,
    Widget page,
  ) async {
    setState(() {
      selectedIndex = index;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedIndex = 0;
    });

    await loadDashboardData();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(38),
                    topRight: Radius.circular(38),
                  ),
                ),
                child: isLoading
                    ? _buildLoading()
                    : errorMessage != null
                        ? _buildError()
                        : _buildContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 5, 14, 8),
      child: Row(
        children: [
          Image.asset(
            'assets/images/lokabaca.png',
            width: 78,
            height: 78,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 78,
                height: 78,
                child: Icon(
                  Icons.menu_book_rounded,
                  color: navy,
                  size: 42,
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, Admin',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selamat datang di panel admin\nLokaBaca',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // NOTIFIKASI
          _buildHeaderButton(
            Icons.notifications_none_rounded,
            () => showMessage('Belum ada notifikasi baru'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          color: navy,
          size: 25,
        ),
      ),
    );
  }

  // ==========================================
  // LOADING
  // ==========================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: cream,
        strokeWidth: 2.5,
      ),
    );
  }

  // ==========================================
  // ERROR
  // ==========================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: cream,
              size: 48,
            ),

            const SizedBox(height: 16),

            const Text(
              'Data gagal dimuat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD7DFE8),
                fontSize: 11,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cream,
                foregroundColor: navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTENT
  // ==========================================

  Widget _buildContent() {
    return RefreshIndicator(
      color: navy,
      backgroundColor: cream,
      onRefresh: loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 35, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatistics(),

            const SizedBox(height: 28),

            _buildLoanHeader(),

            const SizedBox(height: 16),

            if (recentLoans.isEmpty)
              _buildEmptyLoans()
            else
              ...recentLoans.map(
                (loan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLoanCard(loan),
                ),
              ),

            const SizedBox(height: 12),

            _buildReportButton(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATISTICS
  // ==========================================

  Widget _buildStatistics() {
    final statistics = [
      {
        'title': 'Total Buku',
        'value': totalBooks,
        'icon': Icons.auto_stories_outlined,
      },
      {
        'title': 'Total Anggota',
        'value': totalMembers,
        'icon': Icons.people_outline_rounded,
      },
      {
        'title': 'Peminjam Aktif',
        'value': activeLoans,
        'icon': Icons.bookmark_border_rounded,
      },
      {
        'title': 'Terlambat',
        'value': overdueLoans,
        'icon': Icons.schedule_rounded,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statistics.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = statistics[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 0.7,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: navy,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${item['value']}',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // PEMINJAMAN TERBARU
  // ==========================================

  Widget _buildLoanHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Peminjaman Terbaru',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        InkWell(
          onTap: () => navigateToPage(
            3,
            const PeminjamanAdminScreen(),
          ),
          borderRadius: BorderRadius.circular(8),
          child: const Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // EMPTY
  // ==========================================

  Widget _buildEmptyLoans() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: navy,
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada peminjaman',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Data peminjaman akan muncul di sini.',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOAN CARD
  // ==========================================

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final book = loan['books'] as Map<String, dynamic>?;
    final profile = loan['profiles'] as Map<String, dynamic>?;

    final title = book?['title']?.toString() ?? 'Buku';
    final author = book?['author']?.toString() ?? '-';
    final coverUrl = book?['cover_url']?.toString();

    final borrower =
        profile?['full_name']?.toString() ?? 'Anggota';

    final status =
        loan['status']?.toString().toLowerCase().trim() ?? '';

    final isOverdue = _isOverdue(loan);

    final statusText = isOverdue
        ? 'TERLAMBAT'
        : _isActiveStatus(status)
            ? 'DIPINJAM'
            : status.isEmpty
                ? '-'
                : status.toUpperCase();

    final statusBackground = isOverdue
        ? const Color(0xFFF9E5E0)
        : const Color(0xFFE5F2EA);

    final statusForeground = isOverdue
        ? const Color(0xFF9D3D30)
        : const Color(0xFF315F46);

    final borrowedAt = DateTime.tryParse(
      (loan['borrowed_at'] ?? loan['created_at'])
              ?.toString() ??
          '',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _buildBookCover(coverUrl),

          const SizedBox(width: 12),

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
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  borrower,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  borrowedAt == null
                      ? '-'
                      : _formatDate(borrowedAt),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusForeground,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOOK COVER
  // ==========================================

  Widget _buildBookCover(String? coverUrl) {
    return Container(
      width: 52,
      height: 76,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl != null && coverUrl.isNotEmpty
          ? Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildCoverPlaceholder();
              },
            )
          : _buildCoverPlaceholder(),
    );
  }

  Widget _buildCoverPlaceholder() {
    return const Center(
      child: Icon(
        Icons.auto_stories_outlined,
        color: navy,
        size: 27,
      ),
    );
  }

  // ==========================================
  // DATE
  // ==========================================

  String _formatDate(DateTime date) {
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

  // ==========================================
  // REPORT BUTTON
  // ==========================================

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: () {
          showMessage('Halaman laporan akan dibuka');
        },
        icon: const Icon(
          Icons.insert_chart_outlined_rounded,
          size: 18,
        ),
        label: const Text(
          'Cek Laporan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: cream,
          foregroundColor: navy,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE4DFD4),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(
            menuItems.length,
            (index) {
              final item = menuItems[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (index == 0) {
                      setState(() {
                        selectedIndex = 0;
                      });
                    } else if (index == 1) {
                      navigateToPage(
                        1,
                        const KelolaBukuScreen(),
                      );
                    } else if (index == 2) {
                      navigateToPage(
                        2,
                        const KelolaAnggotaPage(),
                      );
                    } else if (index == 3) {
                      navigateToPage(
                        3,
                        const PeminjamanAdminScreen(),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 21,
                        color: isSelected
                            ? navy
                            : const Color(0xFF69624F),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        item['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? navy
                              : const Color(0xFF69624F),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
