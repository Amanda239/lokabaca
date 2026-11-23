import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/book_repository.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/catalog_controls.dart';
import 'detail_buku_screen.dart';

class CategoryBooksScreen extends StatefulWidget {
  final String category;

  const CategoryBooksScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> books = [];

  String searchQuery = '';
  String selectedSort = BookRepository.sortOptions.first;

  int currentPage = 0;
  int totalItems = 0;
  int _loadToken = 0;

  bool isLoading = true;
  String? errorMessage;

  String? get effectiveCategory =>
      widget.category.trim().toLowerCase() == 'semua'
          ? null
          : widget.category.trim();

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // LOAD BOOKS DARI REPOSITORY (MAKS. 10 PER HALAMAN)
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
          search: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
          category: effectiveCategory,
          sort: selectedSort,
        ),
        BookRepository.count(
          search: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
          category: effectiveCategory,
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
        errorMessage = 'Gagal mengambil data buku. Periksa koneksi.';
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
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

  void _changePage(int page) {
    if (page < 0 || page * BookRepository.pageSize >= totalItems) return;
    setState(() => currentPage = page);
    loadBooks();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchField(),
            _buildFilterBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.navy,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Jelajahi buku berdasarkan kategori',
                  style: TextStyle(color: AppColors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.navy,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH FIELD
  Widget _buildSearchField() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.input,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Cari judul atau nama penulis...',
            hintStyle: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 11,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.navy,
              size: 20,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded, size: 17),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  // FILTER + SORT (BERSAMA)
  Widget _buildFilterBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$totalItems buku ditemukan',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CatalogFilterBar(
            categories: effectiveCategory == null
                ? const []
                : [widget.category],
            selectedCategory: effectiveCategory == null
                ? null
                : widget.category,
            selectedSort: selectedSort,
            onCategoryChanged: (_) {},
            onSortChanged: _changeSort,
          ),
        ],
      ),
    );
  }

  // CONTENT
  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }

    if (errorMessage != null) {
      return _buildMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Tidak dapat memuat buku',
        subtitle: errorMessage!,
        showRetry: true,
      );
    }

    if (books.isEmpty) {
      return _buildMessage(
        icon: Icons.menu_book_rounded,
        title: 'Belum ada buku',
        subtitle: searchQuery.isNotEmpty
            ? 'Buku yang kamu cari tidak ditemukan.'
            : 'Belum ada koleksi buku dalam kategori ini.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.navy,
            onRefresh: loadBooks,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 13, 18, 18),
              itemCount: books.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 15,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) => _buildBookCard(books[index]),
            ),
          ),
        ),
        CatalogPagination(
          page: currentPage,
          totalItems: totalItems,
          onPrevious: () => _changePage(currentPage - 1),
          onNext: () => _changePage(currentPage + 1),
        ),
      ],
    );
  }

  // BOOK CARD (KOMPAK)
  Widget _buildBookCard(Map<String, dynamic> book) {
    final stock = int.tryParse('${book['stock'] ?? 0}') ?? 0;
    final available = stock > 0;
    final rating = double.tryParse('${book['rating'] ?? 0}') ?? 0;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      shadowColor: AppColors.navy.withValues(alpha: 0.10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBookDetail(book),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: BookCover(
                        imageUrl: book['cover_url'] ?? book['cover'],
                        width: double.infinity,
                        height: double.infinity,
                        radius: 9,
                      ),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? AppColors.input
                              : AppColors.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          available ? 'Tersedia' : 'Habis',
                          style: TextStyle(
                            color: available
                                ? AppColors.navy
                                : AppColors.grey,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                book['title']?.toString() ?? 'Tanpa Judul',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book['author']?.toString() ?? 'Penulis tidak diketahui',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 9),
              ),
              const SizedBox(height: 7),
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
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.grey,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EMPTY / ERROR MESSAGE
  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: loadBooks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // BOOK DETAIL
  void _showBookDetail(Map<String, dynamic> book) {
    final stock = int.tryParse('${book['stock'] ?? 0}') ?? 0;
    final available = stock > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: BookCover(
                    imageUrl: book['cover_url'] ?? book['cover'],
                    width: 125,
                    height: 170,
                    radius: 12,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  book['title']?.toString() ?? 'Tanpa Judul',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Penulis: ${book['author'] ?? '-'}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 11),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      color: AppColors.navy,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      book['category']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.yellow,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${book['rating'] ?? 0}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  book['description']?.toString().isNotEmpty == true
                      ? book['description'].toString()
                      : 'Belum ada deskripsi untuk buku ini.',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    available
                        ? 'Tersedia • Stok: $stock'
                        : 'Stok buku sedang habis',
                    style: TextStyle(
                      color: available ? AppColors.navy : AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: available
                        ? () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailBukuScreen(
                                  book: _prepareBookForDetail(book),
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      disabledBackgroundColor: AppColors.grey,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      available
                          ? 'Ajukan Peminjaman'
                          : 'Buku Tidak Tersedia',
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
}
