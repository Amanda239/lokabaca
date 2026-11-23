import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/wishlist_service.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/catalog_controls.dart';
import 'detail_buku_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _books = [];
  int currentPage = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WishlistService.ids.addListener(_onIdsChanged);
    WishlistService.load().then((_) => _loadBooks());
  }

  @override
  void dispose() {
    WishlistService.ids.removeListener(_onIdsChanged);
    super.dispose();
  }

  void _onIdsChanged() => _loadBooks();

  Future<void> _loadBooks() async {
    final books = await WishlistService.books();
    if (!mounted) return;
    setState(() {
      _books = books;
      final pages = (books.length / 10).ceil();
      if (pages == 0) {
        currentPage = 0;
      } else if (currentPage >= pages) {
        currentPage = pages - 1;
      }
      isLoading = false;
    });
  }

  void _goToPage(int page) {
    if (page < 0 || page * 10 >= _books.length) return;
    setState(() => currentPage = page);
  }

  // HAPUS DARI WISHLIST (SUPABASE)
  Future<void> _removeBook(Map<String, dynamic> book) async {
    await WishlistService.remove('${book['id']}');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Buku dihapus dari wishlist.'),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<List<String>>(
              valueListenable: WishlistService.ids,
              builder: (context, ids, _) => _buildHeader(ids.length),
            ),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: WishlistService.ids,
                builder: (context, ids, child) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    );
                  }

                  if (_books.isEmpty) return _buildEmptyWishlist();

                  final start = currentPage * 10;
                  final end = (start + 10).clamp(0, _books.length);
                  final pageBooks = _books.sublist(start, end);

                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.66,
                          ),
                          itemCount: pageBooks.length,
                          itemBuilder: (context, index) =>
                              _buildBookCard(pageBooks[index]),
                        ),
                      ),
                      CatalogPagination(
                        page: currentPage,
                        totalItems: _books.length,
                        onPrevious: () => _goToPage(currentPage - 1),
                        onNext: () => _goToPage(currentPage + 1),
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

  // HEADER
  Widget _buildHeader(int count) {
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
          Expanded(
            child: Text(
              'Wishlist ($count)',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

  // CARD BUKU (KOMPAK)
  Widget _buildBookCard(Map<String, dynamic> book) {
    final title = book['title']?.toString() ?? 'Judul Buku';
    final author = book['author']?.toString() ?? 'Penulis';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailBukuScreen(book: book),
            ),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 12, 9, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(
                    imageUrl: book['cover_url'] ?? book['cover'],
                    width: double.infinity,
                    height: 156,
                    radius: 9,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 7,
              left: 7,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _removeBook(book),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE8324A),
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY WISHLIST
  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 65,
            color: AppColors.grey.withValues(alpha: 0.4),
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
            'Tekan ikon love pada buku untuk menyimpannya ke wishlist.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
