
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'collection_screen.dart';
import 'searchpage_screen.dart';
import 'peminjaman_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedNav = 0;

  final List<Map<String, dynamic>> books = [
    {
      'title': 'Hujan',
      'author': 'Tere Liye',
      'category': 'Novel',
      'rating': '4.8',
      'cover': 'assets/images/hujan.jpeg',
      'color': const Color(0xFF75C9E0),
      'icon': Icons.water_drop_rounded,
    },
    {
      'title': 'Cake Shop',
      'author': 'Nana S.',
      'category': 'Romansa',
      'rating': '4.7',
      'cover': 'assets/images/cakeshop.jpeg',
      'color': const Color(0xFFE9D0D0),
      'icon': Icons.cake_rounded,
    },
    {
      'title': 'Bumi',
      'author': 'Tere Liye',
      'category': 'Fantasi',
      'rating': '4.7',
      'cover': 'assets/images/bumi.jpeg',
      'color': const Color(0xFF244C38),
      'icon': Icons.public_rounded,
    },
    {
      'title': 'Laut Bercerita',
      'author': 'Leila S. Chudori',
      'category': 'Fiksi',
      'rating': '4.9',
      'cover': 'assets/images/lautbercerita.jpeg',
      'color': const Color(0xFF356B82),
      'icon': Icons.waves_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 600 ? 28.0 : 18.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
                        onTap: _openSearch,
                      ),
                      const SizedBox(height: 15),
                      _buildPopularBooks(width),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
                Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.navy,
                  size: 28,
                ),
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
        IconButton(
          onPressed: () =>
              _showMessage('Halaman notifikasi akan dibuat berikutnya.'),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.navy,
            size: 23,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () =>
              _showMessage('Halaman akun akan dibuat berikutnya.'),
          icon: const Icon(
            Icons.account_circle_rounded,
            color: AppColors.navy,
            size: 23,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  // SEARCH BAR
  Widget _buildSearchBar() {
    return Material(
      color: const Color(0xFFF8F4EC),
      elevation: 2,
      shadowColor: const Color(0xFF2F4156).withOpacity(0.12),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: _openSearch,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE3DED4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.navy,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cari buku, penulis, atau kategori',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey.withOpacity(0.95),
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
    final bannerHeight = (availableWidth * 0.47).clamp(105.0, 190.0);

    return Container(
      width: double.infinity,
      height: bannerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD0D0D0),
          width: 0.5,
        ),
      ),
    );
  }

  // SHORTCUTS
  Widget _buildShortcuts() {
    final shortcuts = [
      {'label': 'Pinjam Buku', 'icon': Icons.menu_book_rounded},
      {'label': 'Wishlist', 'icon': Icons.favorite_border_rounded},
      {'label': 'Riwayat', 'icon': Icons.history_rounded},
      {'label': 'Profil', 'icon': Icons.person_outline_rounded},
    ];

    return Row(
      children: shortcuts.map((shortcut) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              final label = shortcut['label'] as String;

              if (label == 'Wishlist') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollectionScreen(),
                  ),
                );
              } else if (label == 'Pinjam Buku') {
                _openSearch();
              } else if (label == 'Riwayat') {
                _openBorrowing();
              } else {
                _showMessage('Halaman $label akan dibuat berikutnya.');
              }
            },
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF5EB),
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

    return SizedBox(
      height: 205,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];

          return SizedBox(
            width: cardWidth,
            child: Material(
              color: AppColors.white,
              elevation: 5,
              shadowColor: const Color(0xFF2F4156).withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showMessage(
                  'Detail "${book['title']}" akan dibuat berikutnya.',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: double.infinity,
                            child: Image.asset(
                              book['cover'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: book['color'] as Color,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    book['icon'] as IconData,
                                    color: AppColors.yellow,
                                    size: 34,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        book['title'] as String,
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
                        book['author'] as String,
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
                            color: Color(0xFFFFC83D),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            book['rating'] as String,
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

  // BOTTOM NAVIGATION
  Widget _buildBottomNavigation() {
    const items = [
      {'icon': Icons.home_outlined, 'label': 'Beranda'},
      {'icon': Icons.search_rounded, 'label': 'Cari'},
      {'icon': Icons.menu_book_outlined, 'label': 'Peminjaman'},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Koleksi'},
      {'icon': Icons.person_outline_rounded, 'label': 'Akun'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EC),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.8),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 7, 3, 5),
          child: Row(
            children: List.generate(items.length, (index) {
              final active = selectedNav == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () {
                    if (index == 0) {
                      setState(() => selectedNav = 0);
                    } else if (index == 1) {
                      _openSearch();
                    } else if (index == 2) {
                      _openBorrowing();
                    } else if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollectionScreen(),
                        ),
                      );
                    } else {
                      _showMessage(
                        'Halaman akun akan dibuat berikutnya.',
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 19,
                          color: active
                              ? AppColors.navy
                              : const Color(0xFF514B3E),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? AppColors.navy
                                : const Color(0xFF514B3E),
                            fontSize: 8,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // NAVIGATION HELPERS
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchPageScreen(),
      ),
    );
  }

  void _openBorrowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PeminjamanScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }
}
