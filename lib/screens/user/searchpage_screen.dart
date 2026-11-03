
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'collection_screen.dart';
import 'peminjaman_screen.dart';
import 'profile_screen.dart';

class SearchPageScreen extends StatefulWidget {
  const SearchPageScreen({super.key});

  @override
  State<SearchPageScreen> createState() => _SearchPageScreenState();
}

class _SearchPageScreenState extends State<SearchPageScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'Semua';
  String selectedSort = 'Rekomendasi';
  int selectedNav = 1;

  final List<String> categories = [
    'Semua',
    'Fiksi',
    'Non Fiksi',
    'Romance',
  ];

  final List<Map<String, dynamic>> books = [
    {
      'title': 'Laut Bercerita',
      'author': 'Leila S. Chudori',
      'category': 'Fiksi',
      'cover': 'assets/images/lautbercerita.jpeg',
      'color': const Color(0xFF355C70),
      'icon': Icons.waves_rounded,
      'rating': '4.9',
      'status': 'Tersedia',
      'description':
          'Sebuah novel tentang persahabatan, keluarga, perjuangan, '
          'dan kehilangan dalam perjalanan mencari keadilan.',
    },
    {
      'title': 'Bumi',
      'author': 'Tere Liye',
      'category': 'Fiksi',
      'cover': 'assets/images/bumi.jpeg',
      'color': const Color(0xFF65836A),
      'icon': Icons.public_rounded,
      'rating': '4.8',
      'status': 'Tersedia',
      'description':
          'Petualangan fantasi yang membawa pembaca ke dunia '
          'penuh rahasia dan kejutan.',
    },
    {
      'title': 'Filosofi Teras',
      'author': 'Henry Manampiring',
      'category': 'Non Fiksi',
      'cover': 'assets/images/filosofiteras.jpeg',
      'color': const Color(0xFFB47A45),
      'icon': Icons.spa_rounded,
      'rating': '4.9',
      'status': 'Dipinjam',
      'description':
          'Buku pengantar filsafat Stoisisme untuk membantu '
          'memahami hal-hal yang dapat kita kendalikan.',
    },
    {
      'title': 'Pulang',
      'author': 'Tere Liye',
      'category': 'Fiksi',
      'cover': 'assets/images/pulang.jpeg',
      'color': const Color(0xFF66547D),
      'icon': Icons.nights_stay_rounded,
      'rating': '4.7',
      'status': 'Tersedia',
      'description':
          'Kisah perjalanan hidup, keluarga, dan makna pulang '
          'dalam sebuah perjalanan panjang.',
    },
    {
      'title': 'Atomic Habits',
      'author': 'James Clear',
      'category': 'Non Fiksi',
      'cover': 'assets/images/habits.jpeg',
      'color': const Color(0xFF8C9A6B),
      'icon': Icons.auto_awesome_rounded,
      'rating': '4.9',
      'status': 'Tersedia',
      'description':
          'Panduan membangun kebiasaan baik melalui perubahan '
          'kecil yang dilakukan secara konsisten.',
    },
    {
      'title': 'Bumi Manusia',
      'author': 'Pramoedya Ananta Toer',
      'category': 'Fiksi',
      'cover': 'assets/images/bumimanusia.jpeg',
      'color': const Color(0xFF477B8D),
      'icon': Icons.memory_rounded,
      'rating': '4.43',
      'status': 'Tersedia',
      'description':
          'Kisah perjuangan pemikiran pemuda pribumi Minke dan '
          'cinta tragisnya dengan gadis Indo-Belanda, di tengah '
          'diskriminasi hukum serta penindasan kolonial abad ke-19.',
    },
    {
      'title': 'Cantik Itu Luka',
      'author': 'Eka Kurniawan',
      'category': 'Fiksi',
      'cover': 'assets/images/cantikituluka.jpeg',
      'color': const Color(0xFFB77882),
      'icon': Icons.favorite_rounded,
      'rating': '4.5',
      'status': 'Tersedia',
      'description':
          'Kisah keluarga yang dibalut unsur mistis, berlatar '
          'sejarah kelam dan kekerasan politik di Indonesia.',
    },
  ];

  final List<Map<String, dynamic>> categoryItems = [
    {'name': 'Fiksi', 'icon': Icons.menu_book_rounded},
    {'name': 'Non Fiksi', 'icon': Icons.auto_stories_rounded},
    {'name': 'Komik', 'icon': Icons.draw_rounded},
    {'name': 'Teknologi', 'icon': Icons.memory_rounded},
    {'name': 'Pendidikan', 'icon': Icons.school_rounded},
    {'name': 'Agama', 'icon': Icons.bookmark_rounded},
  ];

  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    final result = books.where((book) {
      final title = book['title'].toString().toLowerCase();
      final author = book['author'].toString().toLowerCase();
      final category = book['category'].toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          title.contains(query) ||
          author.contains(query) ||
          category.contains(query);

      final matchesCategory = selectedCategory == 'Semua' ||
          book['category'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (selectedSort == 'Judul A-Z') {
      result.sort(
        (a, b) => a['title']
            .toString()
            .compareTo(b['title'].toString()),
      );
    } else if (selectedSort == 'Penulis A-Z') {
      result.sort(
        (a, b) => a['author']
            .toString()
            .compareTo(b['author'].toString()),
      );
    }

    return result;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // SEARCH FIELD - LANGSUNG DI BAGIAN ATAS
                  _buildSearchField(),

                  const SizedBox(height: 14),

                  // CATEGORY FILTER
                  _buildCategories(),

                  const SizedBox(height: 23),

                  // RECOMMENDATION HEADER
                  _buildSectionHeader(
                    'Rekomendasi untukmu',
                    '',
                    trailing: 'Lihat Semua',
                    onTrailingTap: () {
                      setState(() {
                        selectedCategory = 'Semua';
                        searchQuery = '';
                        searchController.clear();
                        selectedSort = 'Rekomendasi';
                      });
                    },
                  ),

                  const SizedBox(height: 13),

                  // RECOMMENDED BOOKS
                  _buildRecommendedBooks(),

                  const SizedBox(height: 25),

                  // CATEGORY SECTION
                  _buildSectionHeader('Kategori', ''),

                  const SizedBox(height: 13),

                  _buildCategoryGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
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
          setState(() => searchQuery = value);
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
                    setState(() => searchQuery = '');
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

  // CATEGORIES
  Widget _buildCategories() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => selectedCategory = category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.navy
                    : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.navy
                      : AppColors.border,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected
                      ? AppColors.white
                      : AppColors.text,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
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
                const SizedBox(height: 3),
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

  // RECOMMENDED BOOKS
  Widget _buildRecommendedBooks() {
    final result = filteredBooks;

    if (result.isEmpty) return _emptyState();

    return SizedBox(
      height: 207,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: result.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final book = result[index];

          return SizedBox(
            width: 112,
            child: _buildBookCard(
              book,
              compact: true,
            ),
          );
        },
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
                  final name = item['name'].toString();

                  setState(() {
                    selectedCategory =
                        name == 'Fiksi' || name == 'Non Fiksi'
                            ? name
                            : 'Semua';

                    searchQuery = '';
                    searchController.clear();
                  });
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(
        child: Image.asset(
          book['cover'] as String,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: book['color'] as Color,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    book['icon'] as IconData,
                    color: AppColors.yellow,
                    size: compact ? 32 : 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book['title'].toString().toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // BOOK CARD
  Widget _buildBookCard(
    Map<String, dynamic> book, {
    bool compact = false,
  }) {
    final available = book['status'] == 'Tersedia';

    return GestureDetector(
      onTap: () => _showBookDetail(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBookCover(
                  book,
                  compact: compact,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            book['title'].toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            book['author'].toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFE5AA35),
                size: 13,
              ),
              const SizedBox(width: 2),
              Text(
                book['rating'].toString(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
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
            ],
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
        color: AppColors.white,
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
            'Coba kata kunci atau kategori lainnya.',
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

  // BOOK DETAIL
  void _showBookDetail(Map<String, dynamic> book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        final available = book['status'] == 'Tersedia';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 175,
                    child: _buildBookCover(book),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  book['title'].toString(),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Penulis: ${book['author']}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      color: AppColors.navy,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      book['category'].toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE5AA35),
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      book['rating'].toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  book['description'].toString(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Status: ${book['status']}',
                    style: TextStyle(
                      color: available
                          ? const Color(0xFF4D9469)
                          : const Color(0xFFD49B38),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      if (available) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PeminjamanScreen(
                              selectedBook: book,
                            ),
                          ),
                        );
                      } else {
                        _showMessage('Buku sedang dipinjam.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      available
                          ? 'Ajukan Peminjaman'
                          : 'Buku Sedang Dipinjam',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // SORT OPTIONS
  void _showSortOptions() {
    const options = [
      'Rekomendasi',
      'Judul A-Z',
      'Penulis A-Z',
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

                    setState(() => selectedSort = value);
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

  // SNACKBAR
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
