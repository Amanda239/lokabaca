
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'peminjaman_screen.dart';
import 'profile_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int selectedNav = 3;
  int currentPage = 0;

  static const int booksPerPage = 3;

  String searchQuery = '';

  final TextEditingController searchController =
      TextEditingController();

  final List<Map<String, dynamic>> books = [
    {
      'title': 'Keajaiban Toko Kelontong Namiya',
      'author': 'Keigo Higashino',
      'status': 'Dipinjam',
      'dueDate': '17 Juni 1997',
      'asset': 'assets/images/namiya.jpeg',
      'color': const Color(0xFF3F4C9B),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'title': 'Namakua Alam',
      'author': 'Leila S. Chudori',
      'status': 'Dipinjam',
      'dueDate': '17 Juni 1997',
      'asset': 'assets/images/namakualam.jpeg',
      'color': const Color(0xFF9D3028),
      'icon': Icons.waves_rounded,
    },
    {
      'title': 'Dompet Ayah Sepatu Ibu',
      'author': 'J.S. Khairen',
      'status': 'Dipinjam',
      'dueDate': '17 Juni 1997',
      'asset': 'assets/images/dompetayah.jpeg',
      'color': const Color(0xFF58AEB4),
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Laut Bercerita',
      'author': 'Leila S. Chudori',
      'status': 'Dipinjam',
      'dueDate': '20 Juni 1997',
      'asset': 'assets/images/lautbercerita.jpeg',
      'color': const Color(0xFF355C70),
      'icon': Icons.waves_rounded,
    },
    {
      'title': 'Bumi',
      'author': 'Tere Liye',
      'status': 'Dipinjam',
      'dueDate': '22 Juni 1997',
      'asset': 'assets/images/bumi.jpeg',
      'color': const Color(0xFF65836A),
      'icon': Icons.public_rounded,
    },
  ];

  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return books;

    return books.where((book) {
      return book['title']
              .toString()
              .toLowerCase()
              .contains(query) ||
          book['author']
              .toString()
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  int get totalPages {
    return (filteredBooks.length / booksPerPage).ceil();
  }

  List<Map<String, dynamic>> get currentBooks {
    final startIndex = currentPage * booksPerPage;

    final endIndex = (startIndex + booksPerPage)
        .clamp(0, filteredBooks.length);

    return filteredBooks.sublist(startIndex, endIndex);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _changePage(int page) {
    if (page < 0 || page >= totalPages) return;

    setState(() {
      currentPage = page;
    });
  }

  // NAVIGASI ANTAR HALAMAN
  void _navigateTo(int index) {
    if (index == selectedNav) return;

    Widget? destination;

    switch (index) {
      case 0:
        destination = const DashboardScreen();
        break;

      case 1:
        destination = const SearchPageScreen();
        break;

      case 2:
        destination = const PeminjamanScreen();
        break;

      case 3:
        return;

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

  @override
  Widget build(BuildContext context) {
    final displayedBooks = currentBooks;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 600 ? 32.0 : 16.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HEADER DAN SEARCH
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildSearchField(),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),

                // DAFTAR BUKU: 3 BUKU PER HALAMAN
                if (displayedBooks.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 18),
                            child: _buildBookCard(
                              displayedBooks[index],
                            ),
                          );
                        },
                        childCount: displayedBooks.length,
                      ),
                    ),
                  ),

                // EMPTY STATE
                if (filteredBooks.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    ),
                  ),

                // PAGINATION
                if (totalPages > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 24,
                      ),
                      child: _buildPagination(),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            );
          },
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
        IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                ),
              );
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 34,
          ),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Koleksi Saya',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // SEARCH FIELD
  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentPage = 0;
          });
        },
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
        ),
        decoration: InputDecoration(
          hintText: 'Cari di koleksi kamu...',
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
                      currentPage = 0;
                    });
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // BOOK CARD
  Widget _buildBookCard(Map<String, dynamic> book) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth =
            (constraints.maxWidth * 0.27).clamp(70.0, 100.0);

        return Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: coverWidth,
                  height: 106,
                  child: Image.asset(
                    book['asset'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: book['color'] as Color,
                        child: Icon(
                          book['icon'] as IconData,
                          color: AppColors.yellow,
                          size: 31,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book['title'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.navy,
                          size: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      book['author'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C8C92),
                        fontSize: 9.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          book['status'] as String,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 11),

                    Text(
                      'Jatuh Tempo: ${book['dueDate']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // PAGINATION
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 0
              ? () => _changePage(currentPage - 1)
              : null,
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 25,
          ),
          color: AppColors.white,
          disabledColor: AppColors.grey.withOpacity(0.4),
        ),

        const SizedBox(width: 8),

        ...List.generate(totalPages, (index) {
          final isSelected = currentPage == index;

          return GestureDetector(
            onTap: () => _changePage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 29,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.white,
                ),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected
                      ? AppColors.navy
                      : AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),

        const SizedBox(width: 8),

        IconButton(
          onPressed: currentPage < totalPages - 1
              ? () => _changePage(currentPage + 1)
              : null,
          icon: const Icon(
            Icons.chevron_right_rounded,
            size: 25,
          ),
          color: AppColors.white,
          disabledColor: AppColors.grey.withOpacity(0.4),
        ),
      ],
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.grey,
            size: 30,
          ),
          SizedBox(height: 8),
          Text(
            'Koleksi tidak ditemukan',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba judul atau nama penulis lain.',
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
}
