
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'detail_buku_screen.dart';
import 'wishlist_store.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  static const int booksPerPage = 6;

  final PageController pageController = PageController();

  int currentPage = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // ==========================================
  // REMOVE BOOK FROM WISHLIST
  // ==========================================

  void _removeBook(Map<String, dynamic> book) {
    WishlistStore.toggle(book);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Buku dihapus dari wishlist.'),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
        ),
      );

    final totalBooks = WishlistStore.books.value.length;
    final totalPages = (totalBooks / booksPerPage).ceil();

    if (totalPages == 0) {
      setState(() {
        currentPage = 0;
      });
    } else if (currentPage >= totalPages) {
      final newPage = totalPages - 1;

      setState(() {
        currentPage = newPage;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pageController.hasClients) {
          pageController.jumpToPage(newPage);
        }
      });
    } else {
      setState(() {});
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: ValueListenableBuilder<
                  List<Map<String, dynamic>>>(
                valueListenable: WishlistStore.books,
                builder: (context, books, child) {
                  if (books.isEmpty) {
                    return _buildEmptyWishlist();
                  }

                  final totalPages =
                      (books.length / booksPerPage).ceil();

                  return Column(
                    children: [
                      // ==================================
                      // PAGE VIEW
                      // ==================================

                      Expanded(
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: totalPages,
                          onPageChanged: (index) {
                            setState(() {
                              currentPage = index;
                            });
                          },
                          itemBuilder: (context, pageIndex) {
                            final startIndex =
                                pageIndex * booksPerPage;

                            final endIndex =
                                (startIndex + booksPerPage)
                                    .clamp(0, books.length);

                            final pageBooks =
                                books.sublist(startIndex, endIndex);

                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    25,
                                  ),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemCount: pageBooks.length,
                                  itemBuilder: (context, index) {
                                    final book = pageBooks[index];

                                    return _buildBookCard(book);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ==================================
                      // PAGE INDICATOR
                      // ==================================

                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 20,
                            top: 8,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: List.generate(
                              totalPages,
                              (index) {
                                final isActive =
                                    currentPage == index;

                                return AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: isActive ? 20 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.navy
                                        : Colors.grey.shade300,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
              size: 21,
            ),
          ),

          const Expanded(
            child: Text(
              'Wishlist',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ==========================================
  // BOOK CARD
  // ==========================================

  Widget _buildBookCard(Map<String, dynamic> book) {
    final title = book['title']?.toString() ?? 'Judul Buku';
    final author = book['author']?.toString() ?? 'Penulis';
    final cover = book['cover']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailBukuScreen(book: book),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E5E5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 12),
              child: Column(
                children: [
                  // BOOK COVER
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 115,
                        constraints: const BoxConstraints(
                          maxHeight: 165,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 4,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: cover.isNotEmpty
                            ? Image.asset(
                                cover,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) {
                                  return _coverPlaceholder();
                                },
                              )
                            : _coverPlaceholder(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BOOK TITLE
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 3),

                  // AUTHOR
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // LOVE BUTTON
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _removeBook(book),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE8324A),
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COVER PLACEHOLDER
  // ==========================================

  Widget _coverPlaceholder() {
    return Container(
      color: const Color(0xFFEEF1F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.navy,
        size: 40,
      ),
    );
  }

  // ==========================================
  // EMPTY WISHLIST
  // ==========================================

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 65,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 12),

          const Text(
            'Wishlist masih kosong',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Tekan ikon love pada buku untuk menyimpannya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
