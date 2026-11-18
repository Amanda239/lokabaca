
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import 'detail_buku_screen.dart';

class AllBooksScreen extends StatefulWidget {
  const AllBooksScreen({super.key});

  @override
  State<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends State<AllBooksScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  static const int booksPerPage = 1;

  final List<String> categories = [
    'Semua',
    'Fiksi',
    'Non Fiksi',
    'Romance',
    'Komik',
    'Teknologi',
    'Pendidikan',
    'Agama',
  ];

  List<Map<String, dynamic>> books = [];

  String selectedCategory = 'Semua';
  int currentPage = 0;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  // AMBIL DATA BUKU DARI SUPABASE
  Future<void> loadBooks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await supabase
          .from('books')
          .select()
          .order('title', ascending: true);

      if (!mounted) return;

      setState(() {
        books = List<Map<String, dynamic>>.from(response);
        currentPage = 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat daftar buku.';
      });
    }
  }

  // MENYESUAIKAN DATA UNTUK HALAMAN DETAIL
  Map<String, dynamic> prepareBookForDetail(
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

  // FILTER KATEGORI
  List<Map<String, dynamic>> get filteredBooks {
    if (selectedCategory == 'Semua') {
      return books;
    }

    return books.where((book) {
      return book['category']?.toString().toLowerCase() ==
          selectedCategory.toLowerCase();
    }).toList();
  }

  // TOTAL HALAMAN
  int get totalPages {
    if (filteredBooks.isEmpty) return 0;

    return (filteredBooks.length / booksPerPage).ceil();
  }

  // BUKU PADA HALAMAN AKTIF
  List<Map<String, dynamic>> get currentBooks {
    final start = currentPage * booksPerPage;

    if (start >= filteredBooks.length) return [];

    final end = (start + booksPerPage).clamp(
      0,
      filteredBooks.length,
    );

    return filteredBooks.sublist(start, end);
  }

  // GANTI KATEGORI
  void changeCategory(String category) {
    setState(() {
      selectedCategory = category;
      currentPage = 0;
    });
  }

  // PINDAH HALAMAN
  void goToPage(int index) {
    if (index < 0 || index >= totalPages) return;

    setState(() {
      currentPage = index;
    });
  }

  // FORMAT RATING
  String formatRating(dynamic rating) {
    if (rating == null) return '-';

    final value = double.tryParse(rating.toString());

    if (value == null) return '-';

    return value.toStringAsFixed(1);
  }

  // CEK KETERSEDIAAN STOK
  bool isAvailable(Map<String, dynamic> book) {
    final stock = int.tryParse(
          book['stock']?.toString() ?? '0',
        ) ??
        0;

    return stock > 0;
  }

  // COVER BUKU
  Widget buildBookCover(Map<String, dynamic> book) {
    final coverUrl = book['cover_url']?.toString() ?? '';

    if (coverUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF5F5F5),
        alignment: Alignment.center,
        child: const Icon(
          Icons.menu_book_rounded,
          color: AppColors.navy,
          size: 35,
        ),
      );
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF5F5F5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.menu_book_rounded,
            color: AppColors.navy,
            size: 35,
          ),
        );
      },
    );
  }

  // CARD BUKU
  Widget buildBookCard(Map<String, dynamic> book) {
    final available = isAvailable(book);
    final description =
        book['description']?.toString().trim() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => openBook(book),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEAEAEA),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SizedBox(
                  width: 105,
                  height: 150,
                  child: buildBookCover(book),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: SizedBox(
                  height: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title']?.toString() ?? 'Tanpa Judul',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        book['author']?.toString() ??
                            'Penulis tidak diketahui',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: Text(
                          description.isNotEmpty
                              ? description
                              : 'Belum ada deskripsi buku.',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFE5AA35),
                            size: 16,
                          ),

                          const SizedBox(width: 3),

                          Text(
                            formatRating(book['rating']),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            available ? 'Tersedia' : 'Habis',
                            style: TextStyle(
                              color: available
                                  ? const Color(0xFF4D9469)
                                  : const Color(0xFFD49B38),
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

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFAAAAAA),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // LOADING
  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.navy,
        strokeWidth: 2,
      ),
    );
  }

  // ERROR
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

  // EMPTY STATE
  Widget buildEmpty() {
    return const Center(
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
              fontSize: 13,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Belum ada buku dalam kategori ini.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // PAGINATION
  Widget buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 0
              ? () => goToPage(currentPage - 1)
              : null,
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 21,
          ),
          color: AppColors.navy,
          disabledColor: const Color(0xFFDDDDDD),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xFFEAEAEA),
              width: 0.8,
            ),
          ),
          child: Text(
            '${currentPage + 1} / $totalPages',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        IconButton(
          onPressed: currentPage < totalPages - 1
              ? () => goToPage(currentPage + 1)
              : null,
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.chevron_right_rounded,
            size: 21,
          ),
          color: AppColors.navy,
          disabledColor: const Color(0xFFDDDDDD),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      size: 19,
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

              const SizedBox(height: 15),

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
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => changeCategory(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.navy
                              : Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: selected
                                ? AppColors.navy
                                : const Color(0xFFEAEAEA),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // DAFTAR BUKU
              Expanded(
                child: isLoading
                    ? buildLoading()
                    : errorMessage != null
                        ? buildError()
                        : filteredBooks.isEmpty
                            ? buildEmpty()
                            : ListView.separated(
                                key: ValueKey(selectedCategory),
                                physics:
                                    const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                itemCount: currentBooks.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return buildBookCard(
                                    currentBooks[index],
                                  );
                                },
                              ),
              ),

              if (!isLoading &&
                  errorMessage == null &&
                  totalPages > 1) ...[
                const SizedBox(height: 10),
                buildPagination(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
