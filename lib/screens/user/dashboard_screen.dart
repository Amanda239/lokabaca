import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/book_repository.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/user_avatar.dart';
import 'all_books_screen.dart';
import 'collection_screen.dart';
import 'denda_screen.dart';
import 'detail_buku_screen.dart';
import 'notifikasi_screen.dart';
import 'peminjaman_screen.dart';
import 'profile_screen.dart';
import 'searchpage_screen.dart';
import 'user_bottom_navigation.dart';
import 'wishlist_screen.dart';
import 'ai_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int selectedNav = 0;

  List<Map<String, dynamic>> popularBooks = [];
  int unreadCount = 0;
  String? avatarUrl;
  bool isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotifications();
      _loadProfileAvatar();
    }
  }

  Future<void> _refreshNotifications() async {
    await NotificationService.runChecks();
    await _loadUnreadCount();
  }

  // DATA ASLI SUPABASE
  Future<void> _loadDashboard() async {
    if (mounted) setState(() => isLoadingBooks = true);

    try {
      final rows = await BookRepository.fetchPage(page: 0);
      if (mounted) {
        setState(() {
          popularBooks = rows;
          isLoadingBooks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          popularBooks = const [];
          isLoadingBooks = false;
        });
      }
    }

    await _loadProfileAvatar();
    await _refreshNotifications();
  }

  /// Foto profil di dashboard memakai data yang sama dengan halaman profil.
  Future<void> _loadProfileAvatar() async {
    final profile = await AuthService.currentProfile();
    final url = profile?['avatar_url']?.toString().trim();
    if (!mounted) return;
    setState(() {
      avatarUrl = (url == null || url.isEmpty) ? null : url;
    });
  }

  Future<void> _loadUnreadCount() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => unreadCount = 0);
      return;
    }

    try {
      final rows = await SupabaseConfig.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      if (mounted) setState(() => unreadCount = rows.length);
    } catch (_) {
      // Biarkan angka terakhir bila gagal memuat.
    }
  }

  Map<String, dynamic> _prepareBookForDetail(Map<String, dynamic> book) {
    return {
      ...book,
      'cover': book['cover_url'] ?? book['cover'] ?? '',
      'synopsis': book['description'] ?? book['synopsis'] ?? '',
      'year':
          book['published_year']?.toString() ?? book['year']?.toString() ?? '-',
      'pages': book['pages']?.toString() ?? '-',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 600 ? 28.0 : 18.0;

            return RefreshIndicator(
              color: AppColors.navy,
              onRefresh: _loadDashboard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      20,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 17),
                        _buildSearchBar(),
                        const SizedBox(height: 25),
                        _buildBanner(width),
                        const SizedBox(height: 17),
                        _buildShortcuts(),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          'Buku Populer',
                          'Lihat Semua',
                          onTap: _openAllBooks,
                        ),
                        const SizedBox(height: 15),
                        _buildPopularBooks(width),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.yellow,
        elevation: 4,
        tooltip: 'AI Assistant',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.navy,
          size: 25,
        ),
      ),

      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: selectedNav,
        onTap: _navigateTo,
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(
          width: 76,
          height: 54,
          child: Image.asset(
            'assets/images/lokabaca.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded, color: AppColors.navy, size: 28),
                Text(
                  'LokaBaca',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotifikasiUserScreen(),
                  ),
                );
                await _refreshNotifications();
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.navy,
                size: 23,
              ),
              visualDensity: VisualDensity.compact,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.white, width: 1),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Tooltip(
          message: 'Profil',
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              await _loadProfileAvatar();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: UserAvatar(imageUrl: avatarUrl, size: 31, iconSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  // SEARCH BAR

  Widget _buildSearchBar() {
    return Material(
      color: AppColors.input,
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: _openSearch,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.navy, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cari buku, penulis, atau kategori',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.95),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BANNER

  Widget _buildBanner(double availableWidth) {
    final bannerHeight = (availableWidth * 0.47).clamp(112.0, 180.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: bannerHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navy, AppColors.navy.withValues(alpha: 0.78)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              bottom: -48,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SELAMAT DATANG DI LOKABACA',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Perpustakaan digital untuk semua.',
                          maxLines: 2,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Temukan, pinjam, dan baca buku favoritmu kapan saja.',
                          maxLines: 2,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.82),
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: 0.92,
                    child: Image.asset(
                      'assets/images/lokabaca.png',
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.yellow,
                        size: 52,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SHORTCUTS

  Widget _buildShortcuts() {
    final shortcuts = [
      {'label': 'Denda', 'icon': Icons.receipt_long_rounded},
      {'label': 'Wishlist', 'icon': Icons.favorite_border_rounded},
      {'label': 'Koleksi', 'icon': Icons.collections_bookmark_rounded},
      {'label': 'Profil', 'icon': Icons.person_outline_rounded},
    ];

    return Row(
      children: shortcuts.map((shortcut) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              switch (shortcut['label'] as String) {
                case 'Denda':
                  _openFine();
                  break;
                case 'Wishlist':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                  break;
                case 'Koleksi':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CollectionScreen()),
                  );
                  break;
                case 'Profil':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.input,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      shortcut['icon'] as IconData,
                      color: AppColors.navy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    shortcut['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // SECTION HEADER

  Widget _buildSectionHeader(
    String title,
    String action, {
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // POPULAR BOOKS

  Widget _buildPopularBooks(double availableWidth) {
    final cardWidth = availableWidth < 370 ? 100.0 : 112.0;

    if (isLoadingBooks) {
      return const SizedBox(
        height: 182,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.navy,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (popularBooks.isEmpty) {
      return const SizedBox(
        height: 182,
        child: Center(
          child: Text(
            'Belum ada buku tersedia.',
            style: TextStyle(color: AppColors.grey, fontSize: 11),
          ),
        ),
      );
    }

    return SizedBox(
      height: 182,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: popularBooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = popularBooks[index];
          final rating = double.tryParse('${book['rating'] ?? 0}') ?? 0;

          return SizedBox(
            width: cardWidth,
            child: Material(
              color: AppColors.white,
              elevation: 4,
              shadowColor: AppColors.navy.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailBukuScreen(book: _prepareBookForDetail(book)),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(
                        imageUrl: book['cover_url'] ?? book['cover'],
                        width: cardWidth - 14,
                        height: 108,
                        radius: 8,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        book['title']?.toString() ?? 'Tanpa Judul',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book['author']?.toString() ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.yellow,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // BOTTOM NAVIGATION HANDLER

  void _navigateTo(int index) {
    if (index == selectedNav) return;

    Widget? destination;

    switch (index) {
      case 0:
        return;
      case 1:
        destination = const SearchPageScreen();
        break;
      case 2:
        destination = const PeminjamanScreen();
        break;
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
      MaterialPageRoute(builder: (_) => destination!),
    );
  }

  // NAVIGATION HELPERS

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPageScreen()),
    );
  }

  void _openAllBooks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllBooksScreen()),
    );
  }

  void _openFine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DendaScreen()),
    );
  }
}
