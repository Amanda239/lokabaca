import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/book_repository.dart';
import '../../widgets/book_cover.dart';
import 'all_books_screen.dart';
import 'category_books_screen.dart';
import 'collection_screen.dart';
import 'dashboard_screen.dart';
import 'detail_buku_screen.dart';
import 'peminjaman_screen.dart';
import 'profile_screen.dart';
import 'user_bottom_navigation.dart';

class SearchPageScreen extends StatefulWidget {
  const SearchPageScreen({super.key});

  @override
  State<SearchPageScreen> createState() => _SearchPageScreenState();
}

class _SearchPageScreenState extends State<SearchPageScreen> {
  final TextEditingController searchController = TextEditingController();

  final PageController recommendationController =
      PageController(viewportFraction: 0.94);

  List<Map<String, dynamic>> books = [];
  List<String> categories = [];

  String searchQuery = '';
  String selectedSort = 'Rekomendasi';

  int selectedNav = 1;
  int currentRecommendation = 0;
  int _loadToken = 0;

  bool isLoadingBooks = true;
  String? errorMessage;

  static const sortOptions = [
    'Rekomendasi',
    'Judul A-Z',
    'Penulis A-Z',
    'Rating Tertinggi',
  ];

  String get repositorySort => switch (selectedSort) {
        'Judul A-Z' => 'Judul A-Z',
        'Penulis A-Z' => 'Judul A-Z',
        'Rating Tertinggi' => 'Rating tertinggi',
        _ => BookRepository.sortOptions.first,
      };

  IconData _categoryIcon(String name) {
    final key = name.toLowerCase();
    if (key.contains('fiksi') && !key.contains('non')) {
      return Icons.menu_book_rounded;
    }
    if (key.contains('non')) return Icons.auto_stories_rounded;
    if (key.contains('komik')) return Icons.draw_rounded;
    if (key.contains('teknolog')) return Icons.memory_rounded;
    if (key.contains('pendidikan')) return Icons.school_rounded;
    if (key.contains('agama')) return Icons.bookmark_rounded;
    return Icons.book_outlined;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    loadBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    recommendationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final result = await BookRepository.categories();
    if (mounted) setState(() => categories = result);
  }

  // AMBIL DATA BUKU DARI REPOSITORY (MAKS. 10 REKOMENDASI)
  Future<void> loadBooks() async {
    final token = ++_loadToken;

    if (!mounted) return;
    setState(() {
      isLoadingBooks = true;
      errorMessage = null;
    });

    try {
      final query = searchQuery.trim().isEmpty ? null : searchQuery.trim();
      final result = await BookRepository.fetchPage(
        page: 0,
        search: query,
        sort: repositorySort,
      );

      if (!mounted || token != _loadToken) return;

      setState(() {
        books = result;
        isLoadingBooks = false;
        currentRecommendation = 0;
      });

      if (recommendationController.hasClients) {
        recommendationController.jumpToPage(0);
      }
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        isLoadingBooks = false;
        errorMessage = 'Gagal memuat data buku.';
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      currentRecommendation = 0;
    });
    loadBooks();
    if (recommendationController.hasClients) {
      recommendationController.jumpToPage(0);
    }
  }

  Map<String, dynamic> _prepareBookForDetail(Map<String, dynamic> book) {
    return {
      ...book,
      'cover': book['cover_url'] ?? book['cover'] ?? '',
      'synopsis': book['description'] ?? book['synopsis'] ?? '',
      'year': book['published_year']?.toString() ??
          book['year']?.toString() ??
          '-',
      'pages': book['pages']?.toString() ?? '-',
    };
  }

  void _openBookDetail(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailBukuScreen(
          book: _prepareBookForDetail(book),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.navy,
          onRefresh: loadBooks,
          child: CustomScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSearchField(),
                    const SizedBox(height: 25),
                    _buildSectionHeader(
                      searchQuery.trim().isEmpty
                          ? 'Rekomendasi untukmu'
                          : 'Hasil pencarian',
                      'Temukan bacaan yang menarik untukmu.',
                      trailing: 'Lihat Semua',
                      onTrailingTap: _openAllBooks,
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendationControls(),
                    const SizedBox(height: 10),
                    _buildRecommendedBooks(),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'Kategori',
                      'Jelajahi buku berdasarkan kategori.',
                    ),
                    const SizedBox(height: 14),
                    _buildCategoryGrid(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: selectedNav,
        onTap: _navigateTo,
      ),
    );
  }

  // SEARCH FIELD
  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AppColors.text, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Cari buku, penulis, atau kategori',
          hintStyle: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.navy,
            size: 21,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // SECTION HEADER
  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.grey, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
              child: Row(
                children: [
                  Text(
                    trailing,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // SORTING CONTROL
  Widget _buildRecommendationControls() {
    return Row(
      children: [
        const Icon(Icons.swipe_rounded, color: AppColors.grey, size: 14),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            'Geser untuk melihat buku lainnya',
            style: TextStyle(color: AppColors.grey, fontSize: 9),
          ),
        ),
        InkWell(
          onTap: _showSortOptions,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_vert_rounded,
                  color: AppColors.navy,
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  selectedSort,
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
      ],
    );
  }

  // RECOMMENDATION SLIDER
  Widget _buildRecommendedBooks() {
    if (isLoadingBooks) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
      );
    }

    if (errorMessage != null) return _buildLoadError();
    if (books.isEmpty) return _emptyState();

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: recommendationController,
            itemCount: books.length,
            onPageChanged: (index) {
              setState(() => currentRecommendation = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildRecommendationCard(books[index]),
              );
            },
          ),
        ),
        if (books.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(books.length, (index) {
              final isSelected = currentRecommendation == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 19 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navy : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // RECOMMENDATION CARD (KOMPAK)
  Widget _buildRecommendationCard(Map<String, dynamic> book) {
    final stock = int.tryParse('${book['stock'] ?? 0}') ?? 0;
    final rating = double.tryParse('${book['rating'] ?? 0}') ?? 0;
    final available = stock > 0;
    final description = (book['description'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () => _openBookDetail(book),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -35,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PILIHAN BACAAN',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book['title']?.toString() ?? 'Tanpa Judul',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book['author']?.toString() ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          description.isNotEmpty
                              ? description
                              : 'Temukan cerita dan pengetahuan baru dari buku ini.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 9,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.yellow,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: available
                                    ? AppColors.navy
                                    : AppColors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                available ? 'Tersedia' : 'Tidak tersedia',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: available
                                      ? AppColors.navy
                                      : AppColors.grey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  BookCover(
                    imageUrl: book['cover_url'] ?? book['cover'],
                    width: 100,
                    height: 150,
                    radius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CATEGORY GRID (KATEGORI ASLI DARI DATABASE)
  Widget _buildCategoryGrid() {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Kategori belum tersedia.',
          style: TextStyle(color: AppColors.grey, fontSize: 11),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 260 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return Material(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryBooksScreen(category: category),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: AppColors.navy,
                      size: 23,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // EMPTY STATE
  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book_rounded, color: AppColors.grey, size: 38),
          SizedBox(height: 10),
          Text(
            'Buku tidak ditemukan',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Coba kata kunci lainnya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ERROR STATE
  Widget _buildLoadError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.grey, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat buku',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: loadBooks,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // OPEN ALL BOOKS
  void _openAllBooks() {
    final query = searchQuery.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllBooksScreen(search: query.isEmpty ? null : query),
      ),
    );
  }

  // SORT OPTIONS
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urutkan buku',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...sortOptions.map(
                (option) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: option,
                  groupValue: selectedSort,
                  activeColor: AppColors.navy,
                  title: Text(option, style: const TextStyle(fontSize: 12)),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedSort = value;
                      currentRecommendation = 0;
                    });
                    if (recommendationController.hasClients) {
                      recommendationController.jumpToPage(0);
                    }
                    Navigator.pop(sheetContext);
                    loadBooks();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // NAVIGATION
  void _navigateTo(int index) {
    if (index == selectedNav) return;

    Widget? destination;

    switch (index) {
      case 0:
        destination = const DashboardScreen();
        break;
      case 1:
        return;
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
}
