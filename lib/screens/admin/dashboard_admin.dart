
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';
import 'admin_bottom_navigation.dart';

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

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  // =========================
  // LOAD DASHBOARD DATA
  // =========================

  Future<void> loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final booksCount = await supabase
          .from('books')
          .count(CountOption.exact);

      final membersCount = await supabase
          .from('profiles')
          .count(CountOption.exact)
          .eq('role', 'anggota');

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

      final borrowings =
          List<Map<String, dynamic>>.from(borrowingResponse);

      final bookIds = borrowings
          .map((item) => item['book_id'])
          .whereType<int>()
          .toSet()
          .toList();

      final userIds = borrowings
          .map((item) => item['user_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

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

      final List<Map<String, dynamic>> combinedLoans = [];

      for (final borrowing in borrowings) {
        final bookId = borrowing['book_id'];
        final userId = borrowing['user_id']?.toString();

        final book = bookId is int ? booksMap[bookId] : null;
        final profile =
            userId != null ? profilesMap[userId] : null;

        combinedLoans.add({
          ...borrowing,
          'books': book,
          'profiles': profile,
        });
      }

      final active = combinedLoans.where((borrowing) {
        return _isActiveStatus(borrowing['status']);
      }).toList();

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

  // =========================
  // MESSAGE
  // =========================

  void showMessage(String message) {
    if (!mounted) return;

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

  // =========================
  // NAVIGATION
  // =========================

  Future<void> navigateToPage(
    int index,
    Widget page,
  ) async {
    setState(() {
      selectedIndex = index;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;

    setState(() {
      selectedIndex = 0;
    });

    await loadDashboardData();
  }

  void _handleBottomNavigation(int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        setState(() => selectedIndex = 0);
        break;

      case 1:
        navigateToPage(
          1,
          const KelolaBukuScreen(),
        );
        break;

      case 2:
        navigateToPage(
          2,
          const KelolaAnggotaPage(),
        );
        break;

      case 3:
        navigateToPage(
          3,
          const PeminjamanAdminScreen(),
        );
        break;

      case 4:
        navigateToPage(
          4,
          const AdminProfileScreen(),
        );
        break;
    }
  }

  void _openProfile() {
    navigateToPage(
      4,
      const AdminProfileScreen(),
    );
  }

  void _openReport() {
    navigateToPage(
      0,
      const AdminReportScreen(),
    );
  }

  // =========================
  // BUILD
  // =========================

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
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: selectedIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  // =========================
  // HEADER
  // =========================

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
            errorBuilder: (_, __, ___) {
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

          const SizedBox(width: 5),

          // PROFIL ADMIN
          _buildHeaderButton(
            Icons.account_circle_rounded,
            _openProfile,
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

  // =========================
  // LOADING
  // =========================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: cream,
        strokeWidth: 2.5,
      ),
    );
  }

  // =========================
  // ERROR
  // =========================

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

  // =========================
  // DASHBOARD CONTENT
  // =========================

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

  // =========================
  // STATISTICS
  // =========================

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
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = statistics[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: navy,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${item['value']}',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 30,
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

  // =========================
  // LOAN HEADER
  // =========================

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

  // =========================
  // LOAN CARD
  // =========================

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
      (loan['borrowed_at'] ?? loan['created_at'])?.toString() ?? '',
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
              errorBuilder: (_, __, ___) {
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

  // =========================
  // REPORT BUTTON
  // =========================

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: _openReport,
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
}

// =====================================================
// HALAMAN PROFIL ADMIN
// =====================================================

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() =>
      _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const navy = Color(0xFF2E4057);
  static const cream = Color(0xFFF8F4EA);

  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Admin belum login.');
      }

      final response = await supabase
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = response;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal keluar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    final name = profile?['full_name']?.toString() ?? 'Admin';
    final email = user?.email ?? '-';
    final role = profile?['role']?.toString() ?? 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Admin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: navy),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: navy,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadProfile,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 25),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: cream,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_circle_rounded,
                            size: 85,
                            color: navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      _profileItem(
                        Icons.person_outline_rounded,
                        'Nama Lengkap',
                        name,
                      ),
                      _profileItem(
                        Icons.email_outlined,
                        'Email',
                        email,
                      ),
                      _profileItem(
                        Icons.admin_panel_settings_outlined,
                        'Role',
                        role,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _profileItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy, size: 23),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HALAMAN LAPORAN ADMIN
// =====================================================

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() =>
      _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  static const navy = Color(0xFF2E4057);
  static const cream = Color(0xFFF8F4EA);
  static const muted = Color(0xFF8792A1);

  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;

  int totalBorrowings = 0;
  int activeBorrowings = 0;
  int returnedBorrowings = 0;
  int overdueBorrowings = 0;

  List<Map<String, dynamic>> borrowings = [];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await supabase
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

      final data = List<Map<String, dynamic>>.from(response);

      int active = 0;
      int returned = 0;
      int overdue = 0;

      for (final item in data) {
        final status =
            item['status']?.toString().toLowerCase().trim() ?? '';

        final isActive = [
          'dipinjam',
          'borrowed',
          'aktif',
          'active',
        ].contains(status);

        if (isActive) {
          active++;

          final dueDate = DateTime.tryParse(
            item['due_date']?.toString() ?? '',
          );

          if (dueDate != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final deadline = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
            );

            if (deadline.isBefore(today)) {
              overdue++;
            }
          }
        }

        if ([
          'dikembalikan',
          'returned',
          'selesai',
        ].contains(status)) {
          returned++;
        }
      }

      if (!mounted) return;

      setState(() {
        borrowings = data;
        totalBorrowings = data.length;
        activeBorrowings = active;
        returnedBorrowings = returned;
        overdueBorrowings = overdue;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Laporan Perpustakaan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: navy),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                          'Laporan gagal dimuat',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: loadReport,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadReport,
                  color: navy,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: navy,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan LokaBaca',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Ringkasan aktivitas peminjaman perpustakaan.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Ringkasan Peminjaman',
                        style: TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          _reportCard(
                            'Total Peminjaman',
                            totalBorrowings,
                            Icons.library_books_outlined,
                          ),
                          _reportCard(
                            'Sedang Dipinjam',
                            activeBorrowings,
                            Icons.menu_book_rounded,
                          ),
                          _reportCard(
                            'Dikembalikan',
                            returnedBorrowings,
                            Icons.assignment_turned_in_outlined,
                          ),
                          _reportCard(
                            'Terlambat',
                            overdueBorrowings,
                            Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Riwayat Peminjaman',
                        style: TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (borrowings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada data laporan.',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      else
                        ...borrowings.map(_reportLoanItem),
                      const SizedBox(height: 25),
                      SizedBox(
                        height: 45,
                        child: OutlinedButton.icon(
                          onPressed: loadReport,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Perbarui Laporan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: navy,
                            side: const BorderSide(color: navy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _reportCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E4DB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: navy, size: 27),
          const SizedBox(height: 9),
          Text(
            '$value',
            style: const TextStyle(
              color: navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportLoanItem(Map<String, dynamic> item) {
    final status =
        item['status']?.toString().toUpperCase() ?? '-';

    final date = DateTime.tryParse(
      (item['borrowed_at'] ?? item['created_at'])?.toString() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: navy,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peminjaman #${item['id']}',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null
                      ? '-'
                      : '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: navy,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
