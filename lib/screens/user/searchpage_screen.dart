
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'collection_screen.dart';
import 'peminjaman_screen.dart';
import 'profile_screen.dart';
import 'category_books_screen.dart';
import 'detail_buku_screen.dart';
import 'all_books_screen.dart';

class SearchPageScreen extends StatefulWidget {
  const SearchPageScreen({super.key});

  @override
  State<SearchPageScreen> createState() => _SearchPageScreenState();
}

class _SearchPageScreenState extends State<SearchPageScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController searchController =
      TextEditingController();

  final PageController recommendationController =
      PageController(viewportFraction: 0.94);

  List<Map<String, dynamic>> books = [];

  String searchQuery = '';
  String selectedSort = 'Rekomendasi';

  int selectedNav = 1;
  int currentRecommendation = 0;

  bool isLoadingBooks = true;
  String? errorMessage;

  final List<Map<String, dynamic>> categoryItems = [
    {
      'name': 'Fiksi',
      'icon': Icons.menu_book_rounded,
    },
    {
      'name': 'Non Fiksi',
      'icon': Icons.auto_stories_rounded,
    },
    {
      'name': 'Komik',
      'icon': Icons.draw_rounded,
    },
    {
      'name': 'Teknologi',
      'icon': Icons.memory_rounded,
    },
    {
      'name': 'Pendidikan',
      'icon': Icons.school_rounded,
    },
    {
      'name': 'Agama',
      'icon': Icons.bookmark_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    recommendationController.dispose();
    super.dispose();
  }

  // AMBIL DATA BUKU DARI SUPABASE
  Future<void> loadBooks() async {
    try {
      setState(() {
        isLoadingBooks = true;
        errorMessage = null;
      });

      final response = await supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        books = List<Map<String, dynamic>>.from(response);
        isLoadingBooks = false;
        currentRecommendation = 0;
      });

      if (recommendationController.hasClients) {
        recommendationController.jumpToPage(0);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBooks = false;
        errorMessage = 'Gagal memuat data buku.';
      });
    }
  }

  // MENYESUAIKAN DATA BUKU UNTUK HALAMAN DETAIL
  Map<String, dynamic> _prepareBookForDetail(
    Map<String, dynamic> book,
  ) {
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

  // MEMBUKA HALAMAN DETAIL BUKU
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

  // FILTER DAN SORTING BUKU
  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    final result = books.where((book) {
      final title =
          (book['title'] ?? '').toString().toLowerCase();

      final author =
          (book['author'] ?? '').toString().toLowerCase();

      final category =
          (book['category'] ?? '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          author.contains(query) ||
          category.contains(query);

      return matchesSearch;
    }).toList();

    if (selectedSort == 'Judul A-Z') {
      result.sort(
        (a, b) => (a['title'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo(
              (b['title'] ?? '').toString().toLowerCase(),
            ),
      );
    } else if (selectedSort == 'Penulis A-Z') {
      result.sort(
        (a, b) => (a['author'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo(
              (b['author'] ?? '').toString().toLowerCase(),
            ),
      );
    } else if (selectedSort == 'Rating Tertinggi') {
      result.sort((a, b) {
        final ratingA =
            double.tryParse('${a['rating'] ?? 0}') ?? 0;

        final ratingB =
            double.tryParse('${b['rating'] ?? 0}') ?? 0;

        return ratingB.compareTo(ratingA);
      });
    }

    return result;
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
                      'Rekomendasi untukmu',
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
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentRecommendation = 0;
          });

          if (recommendationController.hasClients) {
            recommendationController.jumpToPage(0);
          }
        },
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: 'Cari buku, penulis, atau kategori',
          hintStyle: TextStyle(
            color: AppColors.grey.withOpacity(0.9),
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

                    setState(() {
                      searchQuery = '';
                      currentRecommendation = 0;
                    });

                    if (recommendationController.hasClients) {
                      recommendationController.jumpToPage(0);
                    }
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
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
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10,
                  ),
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
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 2,
              ),
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
        const Icon(
          Icons.swipe_rounded,
          color: AppColors.grey,
          size: 14,
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            'Geser untuk melihat buku lainnya',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 9,
            ),
          ),
        ),
        InkWell(
          onTap: _showSortOptions,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
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
        height: 215,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.navy,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return _buildLoadError();
    }

    final result = filteredBooks;

    if (result.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: [
        SizedBox(
          height: 205,
          child: PageView.builder(
            controller: recommendationController,
            itemCount: result.length,
            onPageChanged: (index) {
              setState(() {
                currentRecommendation = index;
              });
            },
            itemBuilder: (context, index) {
              final book = result[index];

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildRecommendationCard(book, index),
              );
            },
          ),
        ),
        if (result.length > 1) ...[
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              result.length,
              (index) {
                final isSelected =
                    currentRecommendation == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 19 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.navy
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // RECOMMENDATION CARD
  Widget _buildRecommendationCard(
    Map<String, dynamic> book,
    int index,
  ) {
    final stock =
        int.tryParse('${book['stock'] ?? 0}') ?? 0;

    final rating =
        double.tryParse('${book['rating'] ?? 0}') ?? 0;

    final available = stock > 0;

    final description =
        (book['description'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () => _openBookDetail(book),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: AppColors.border.withOpacity(0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withOpacity(0.08),
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
                        const SizedBox(height: 11),
                        Text(
                          book['title']?.toString() ?? 'Tanpa Judul',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          book['author']?.toString() ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 9),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 9,
                              height: 1.4,
                            ),
                          )
                        else
                          const Text(
                            'Temukan cerita dan pengetahuan baru dari buku ini.',
                            maxLines: 2,
                            style: TextStyle(
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
                              color: Color(0xFFE5AA35),
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
                            const SizedBox(width: 9),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: available
                                    ? const Color(0xFF4D9469)
                                    : const Color(0xFFD49B38),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                available
                                    ? 'Tersedia'
                                    : 'Tidak tersedia',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: available
                                      ? const Color(0xFF4D9469)
                                      : const Color(0xFFD49B38),
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
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 105,
                    height: 155,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withOpacity(0.17),
                            blurRadius: 10,
                            offset: const Offset(3, 5),
                          ),
                        ],
                      ),
                      child: _buildBookCover(book),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 13,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CATEGORY GRID
  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth < 260 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryItems.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) {
            final item = categoryItems[index];

            return Material(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  final category = item['name'].toString();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryBooksScreen(
                        category: category,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: AppColors.navy,
                      size: 23,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item['name'].toString(),
                      textAlign: TextAlign.center,
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

  // BOOK COVER
  Widget _buildBookCover(
    Map<String, dynamic> book, {
    bool compact = false,
  }) {
    final coverUrl = book['cover_url']?.toString() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.expand(
        child: coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildCoverPlaceholder(book, compact),
              )
            : _buildCoverPlaceholder(book, compact),
      ),
    );
  }

  Widget _buildCoverPlaceholder(
    Map<String, dynamic> book, [
    bool compact = false,
  ]) {
    return Container(
      color: AppColors.cream,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: AppColors.navy,
            size: compact ? 32 : 40,
          ),
          const SizedBox(height: 8),
          Text(
            (book['title'] ?? 'Buku').toString().toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: compact ? 10 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // EMPTY STATE
  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cream.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: AppColors.grey,
            size: 38,
          ),
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
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10,
            ),
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
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.grey,
            size: 32,
          ),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AllBooksScreen(),
      ),
    );
  }

  // SORT OPTIONS
  void _showSortOptions() {
    const options = [
      'Rekomendasi',
      'Judul A-Z',
      'Penulis A-Z',
      'Rating Tertinggi',
    ];

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
              ...options.map(
                (option) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: option,
                  groupValue: selectedSort,
                  activeColor: AppColors.navy,
                  title: Text(
                    option,
                    style: const TextStyle(fontSize: 12),
                  ),
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
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
    );
  }
}
