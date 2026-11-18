
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AllBooksScreen extends StatefulWidget {
  final List<Map<String, dynamic>> books;

  const AllBooksScreen({
    super.key,
    required this.books,
  });

  @override
  State<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends State<AllBooksScreen> {
  String selectedCategory = 'Semua';

  final List<String> categories = [
    'Semua',
    'Fiksi',
    'Non Fiksi',
    'Romance',
  ];

  final PageController pageController = PageController();

  int currentPage = 0;

  // FILTER BUKU BERDASARKAN KATEGORI
  List<Map<String, dynamic>> get filteredBooks {
    if (selectedCategory == 'Semua') {
      return widget.books;
    }

    return widget.books.where((book) {
      return book['category'] == selectedCategory;
    }).toList();
  }

  // BAGI BUKU MENJADI 4 BUKU PER HALAMAN
  List<List<Map<String, dynamic>>> get bookPages {
    final result = filteredBooks;
    final pages = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < result.length; i += 4) {
      final end = (i + 4 < result.length)
          ? i + 4
          : result.length;

      pages.add(result.sublist(i, end));
    }

    return pages;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // GANTI KATEGORI
  void changeCategory(String category) {
    setState(() {
      selectedCategory = category;
      currentPage = 0;
    });

    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
  }

  // PINDAH HALAMAN
  void goToPage(int index) {
    if (!pageController.hasClients) return;

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = bookPages;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Semua Buku',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 45),
                ],
              ),

              const SizedBox(height: 18),

              // JUMLAH BUKU
              Text(
                '${filteredBooks.length} buku ditemukan',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              // FILTER KATEGORI
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected =
                        selectedCategory == category;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => changeCategory(category),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.navy
                              : AppColors.white,
                          borderRadius:
                              BorderRadius.circular(10),
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
                                : AppColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // HALAMAN BUKU
              Expanded(
                child: pages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 45,
                              color: AppColors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Buku tidak ditemukan',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : PageView.builder(
                        controller: pageController,
                        itemCount: pages.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, pageIndex) {
                          final pageBooks = pages[pageIndex];

                          return SingleChildScrollView(
                            physics:
                                const BouncingScrollPhysics(),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 950,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    bottom: 15,
                                  ),
                                  itemCount: pageBooks.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemBuilder: (context, index) {
                                    return _buildBookCard(
                                      pageBooks[index],
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // INDIKATOR HALAMAN
              if (pages.length > 1) ...[
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 0
                          ? () => goToPage(currentPage - 1)
                          : null,
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                      ),
                      color: AppColors.navy,
                      disabledColor: AppColors.border,
                    ),

                    Text(
                      '${currentPage + 1} / ${pages.length}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    IconButton(
                      onPressed:
                          currentPage < pages.length - 1
                              ? () => goToPage(currentPage + 1)
                              : null,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                      ),
                      color: AppColors.navy,
                      disabledColor: AppColors.border,
                    ),
                  ],
                ),

                const Center(
                  child: Text(
                    'Geser ke samping untuk melihat buku lainnya',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // KARTU BUKU
  Widget _buildBookCard(Map<String, dynamic> book) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COVER BUKU
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: AspectRatio(
                  aspectRatio: 0.68,
                  child: Image.asset(
                    book['cover'].toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: book['color'] as Color,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          book['title'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 9),

          // JUDUL
          Text(
            book['title'].toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          // PENULIS
          Text(
            book['author'].toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 7),

          // RATING DAN STATUS
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFE5AA35),
                size: 15,
              ),

              const SizedBox(width: 3),

              Text(
                book['rating'].toString(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: book['status'] == 'Tersedia'
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
}
