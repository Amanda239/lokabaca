
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import 'peminjaman_screen.dart';

class CategoryBooksScreen extends StatefulWidget {
  final String category;

  const CategoryBooksScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryBooksScreen> createState() =>
      _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController searchController =
      TextEditingController();

  static const int booksPerPage = 10;

  List<Map<String, dynamic>> books = [];

  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';
  String selectedSort = 'Judul A-Z';

  int currentPage = 1;

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

  // LOAD BOOKS
  Future<void> loadBooks() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = widget.category.toLowerCase() == 'semua'
          ? await supabase
              .from('books')
              .select()
              .order('title', ascending: true)
          : await supabase
              .from('books')
              .select()
              .eq('category', widget.category)
              .order('title', ascending: true);

      if (!mounted) return;

      setState(() {
        books = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal mengambil data buku. Periksa koneksi.';
        isLoading = false;
      });
    }
  }

  // FILTER DAN SORTING
  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.toLowerCase().trim();

    final result = books.where((book) {
      final title =
          (book['title'] ?? '').toString().toLowerCase();

      final author =
          (book['author'] ?? '').toString().toLowerCase();

      return title.contains(query) || author.contains(query);
    }).toList();

    if (selectedSort == 'Judul A-Z') {
      result.sort((a, b) =>
          (a['title'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo(
                (b['title'] ?? '').toString().toLowerCase(),
              ));
    } else if (selectedSort == 'Penulis A-Z') {
      result.sort((a, b) =>
          (a['author'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo(
                (b['author'] ?? '').toString().toLowerCase(),
              ));
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

  // TOTAL HALAMAN
  int get totalPages {
    final total = filteredBooks.length;

    return total == 0 ? 1 : (total / booksPerPage).ceil();
  }

  // BUKU DI HALAMAN AKTIF
  List<Map<String, dynamic>> get paginatedBooks {
    final result = filteredBooks;

    final startIndex = (currentPage - 1) * booksPerPage;

    if (startIndex >= result.length) return [];

    final endIndex =
        (startIndex + booksPerPage).clamp(0, result.length);

    return result.sublist(startIndex, endIndex);
  }

  // GANTI HALAMAN
  void changePage(int page) {
    if (page < 1 || page > totalPages) return;

    setState(() {
      currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = filteredBooks;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchField(),
            _buildSortRow(result.length),
            Expanded(
              child: _buildContent(result),
            ),
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
                  'Jelajahi koleksi buku berdasarkan kategori',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10,
                  ),
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
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 15),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              currentPage = 1;
            });
          },
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: 'Cari judul atau nama penulis...',
            hintStyle: TextStyle(
              color: AppColors.grey.withOpacity(0.8),
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

                      setState(() {
                        searchQuery = '';
                        currentPage = 1;
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 17,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  // SORT ROW
  Widget _buildSortRow(int totalBooks) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
      child: Row(
        children: [
          Text(
            '$totalBooks buku ditemukan',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            color: AppColors.white,
            onSelected: (value) {
              setState(() {
                selectedSort = value;
                currentPage = 1;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'Judul A-Z',
                child: Text('Judul A-Z'),
              ),
              PopupMenuItem(
                value: 'Penulis A-Z',
                child: Text('Penulis A-Z'),
              ),
              PopupMenuItem(
                value: 'Rating Tertinggi',
                child: Text('Rating Tertinggi'),
              ),
            ],
            child: Row(
              children: [
                const Icon(
                  Icons.sort_rounded,
                  size: 17,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 5),
                Text(
                  selectedSort,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.navy,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CONTENT
  Widget _buildContent(List<Map<String, dynamic>> result) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.navy,
        ),
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

    if (result.isEmpty) {
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
              itemCount: paginatedBooks.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 15,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                return _buildBookCard(paginatedBooks[index]);
              },
            ),
          ),
        ),
        _buildPagination(result.length),
      ],
    );
  }

  // BOOK CARD
  Widget _buildBookCard(Map<String, dynamic> book) {
    final stock =
        int.tryParse('${book['stock'] ?? 0}') ?? 0;

    final available = stock > 0;

    final rating =
        double.tryParse('${book['rating'] ?? 0}') ?? 0;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      shadowColor: AppColors.navy.withOpacity(0.10),
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
                      child: _buildCover(book),
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
                              ? const Color(0xFFE7F3EA)
                              : const Color(0xFFFFE9E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          available ? 'Tersedia' : 'Habis',
                          style: TextStyle(
                            color: available
                                ? const Color(0xFF43845A)
                                : const Color(0xFFC65F50),
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
                book['author']?.toString() ??
                    'Penulis tidak diketahui',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFE5AA35),
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

  // COVER
  Widget _buildCover(Map<String, dynamic> book) {
    final coverUrl = book['cover_url']?.toString() ?? '';

    if (coverUrl.isEmpty) {
      return _coverPlaceholder(book);
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _coverPlaceholder(book),
    );
  }

  Widget _coverPlaceholder(Map<String, dynamic> book) {
    return Container(
      color: AppColors.cream,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.navy,
            size: 30,
          ),
          const SizedBox(height: 7),
          Text(
            book['title']?.toString() ?? 'Buku',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // PAGINATION
  Widget _buildPagination(int totalBooks) {
    final startNumber =
        (currentPage - 1) * booksPerPage + 1;

    final endNumber =
        (currentPage * booksPerPage).clamp(0, totalBooks);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.7),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Menampilkan $startNumber–$endNumber dari $totalBooks buku',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageButton(
                icon: Icons.chevron_left_rounded,
                onTap: currentPage > 1
                    ? () => changePage(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                final page = index + 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),
                  child: _pageNumber(page),
                );
              }),
              const SizedBox(width: 8),
              _pageButton(
                icon: Icons.chevron_right_rounded,
                onTap: currentPage < totalPages
                    ? () => changePage(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageNumber(int page) {
    final selected = currentPage == page;

    return InkWell(
      onTap: () => changePage(page),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navy
              : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.navy
                : AppColors.border,
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: selected
                ? AppColors.white
                : AppColors.navy,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.cream
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.navy : AppColors.grey,
          size: 18,
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
            Icon(
              icon,
              size: 42,
              color: AppColors.grey,
            ),
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
    final stock =
        int.tryParse('${book['stock'] ?? 0}') ?? 0;

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
                  child: SizedBox(
                    width: 125,
                    height: 170,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCover(book),
                    ),
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
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
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
                      color: Color(0xFFE5AA35),
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
                      color: available
                          ? const Color(0xFF43845A)
                          : const Color(0xFFC65F50),
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
                                builder: (_) => PeminjamanScreen(
                                  selectedBook: book,
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
