import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/book_repository.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/catalog_controls.dart';
import 'detail_buku_screen.dart';

class AllBooksScreen extends StatefulWidget {
  /// Filter awal opsional agar halaman pencarian bisa meneruskan query/kategori.
  final String? search;
  final String? category;

  const AllBooksScreen({
    super.key,
    this.search,
    this.category,
  });

  @override
  State<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends State<AllBooksScreen> {
  List<String> categories = [];
  List<Map<String, dynamic>> books = [];

  String? selectedCategory;
  String selectedSort = BookRepository.sortOptions.first;

  int currentPage = 0;
  int totalItems = 0;
  int _loadToken = 0;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
    _loadCategories();
    loadBooks();
  }

  Future<void> _loadCategories() async {
    final result = await BookRepository.categories();
    final category = widget.category;
    if (category != null &&
        category.isNotEmpty &&
        !result.contains(category)) {
      result.add(category);
    }
    if (mounted) setState(() => categories = result);
  }

  // AMBIL DATA BUKU DARI REPOSITORY (MAKS. 10 PER HALAMAN)
  Future<void> loadBooks() async {
    final token = ++_loadToken;

    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        BookRepository.fetchPage(
          page: currentPage,
          search: widget.search,
          category: selectedCategory,
          sort: selectedSort,
        ),
        BookRepository.count(
          search: widget.search,
          category: selectedCategory,
        ),
      ]);

      if (!mounted || token != _loadToken) return;

      setState(() {
        books = results[0] as List<Map<String, dynamic>>;
        totalItems = results[1] as int;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat daftar buku.';
      });
    }
  }

  void _changeCategory(String? category) {
    if (category == selectedCategory) return;
    setState(() {
      selectedCategory = category;
      currentPage = 0;
    });
    loadBooks();
  }

  void _changeSort(String sort) {
    if (sort == selectedSort) return;
    setState(() {
      selectedSort = sort;
      currentPage = 0;
    });
    loadBooks();
  }

  void _goToPage(int page) {
    if (page < 0 || page * BookRepository.pageSize >= totalItems) return;
    setState(() => currentPage = page);
    loadBooks();
  }

  // MENYESUAIKAN DATA UNTUK HALAMAN DETAIL
  Map<String, dynamic> prepareBookForDetail(Map<String, dynamic> book) {
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

  void openBook(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailBukuScreen(
          book: prepareBookForDetail(book),
        ),
      ),
    );
  }

  String formatRating(dynamic rating) {
    final value = double.tryParse(rating?.toString() ?? '');
    return value == null ? '-' : value.toStringAsFixed(1);
  }

  bool isAvailable(Map<String, dynamic> book) {
    return (int.tryParse(book['stock']?.toString() ?? '0') ?? 0) > 0;
  }

  // CARD BUKU — GRID BERSIH, COVER BESAR, INFO RINGKAS
  Widget buildBookCard(Map<String, dynamic> book) {
    final available = isAvailable(book);
    final title = book['title']?.toString().trim() ?? '';
    final author = book['author']?.toString().trim() ?? '';

    return Material(
      color: AppColors.white,
      elevation: 3,
      shadowColor: AppColors.navy.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () => openBook(book),
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final coverWidth = constraints.maxWidth;
              final coverHeight = coverWidth * 1.24;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      BookCover(
                        imageUrl: book['cover_url'] ?? book['cover'],
                        width: coverWidth,
                        height: coverHeight,
                        radius: 9,
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.yellow,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                formatRating(book['rating']),
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.isNotEmpty ? title : 'Tanpa Judul',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    author.isNotEmpty ? author : 'Penulis tidak diketahui',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: available ? AppColors.navy : AppColors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        available ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          color: available ? AppColors.navy : AppColors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.navy,
        strokeWidth: 2,
      ),
    );
  }

  Widget buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loadBooks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 45, color: AppColors.grey),
          SizedBox(height: 10),
          Text(
            'Buku tidak ditemukan',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Coba ubah kata kunci atau kategori pencarian.',
            style: TextStyle(color: AppColors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navy,
                      size: 19,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.search != null && widget.search!.isNotEmpty
                          ? 'Hasil Pencarian'
                          : 'Semua Buku',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: loadBooks,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$totalItems buku ditemukan',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              CatalogFilterBar(
                categories: categories,
                selectedCategory: selectedCategory,
                selectedSort: selectedSort,
                onCategoryChanged: _changeCategory,
                onSortChanged: _changeSort,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? buildLoading()
                    : errorMessage != null
                        ? buildError()
                        : books.isEmpty
                            ? buildEmpty()
                            : GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: books.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 13,
                                  mainAxisSpacing: 13,
                                  childAspectRatio: 0.55,
                                ),
                                itemBuilder: (context, index) =>
                                    buildBookCard(books[index]),
                              ),
              ),
              if (!isLoading && errorMessage == null && totalItems > 0)
                CatalogPagination(
                  page: currentPage,
                  totalItems: totalItems,
                  onPrevious: () => _goToPage(currentPage - 1),
                  onNext: () => _goToPage(currentPage + 1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
