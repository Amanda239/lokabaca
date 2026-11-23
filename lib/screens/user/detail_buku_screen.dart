
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/wishlist_service.dart';
import '../../widgets/book_cover.dart';
import 'ulasan_buku.dart';
import 'form_peminjaman.dart';

class DetailBukuScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const DetailBukuScreen({
    super.key,
    required this.book,
  });

  @override
  State<DetailBukuScreen> createState() => _DetailBukuScreenState();
}

class _DetailBukuScreenState extends State<DetailBukuScreen> {
  @override
  void initState() {
    super.initState();
    WishlistService.load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
  }

  // ==========================================
  // WISHLIST (HATI) DAN KOLEKSI (PEMINJAMAN)
  // ==========================================

  Future<void> _toggleFavorite() async {
    await WishlistService.toggle(widget.book);
    if (!mounted) return;

    _showMessage(
      WishlistService.isFavorite(widget.book)
          ? 'Buku ditambahkan ke wishlist.'
          : 'Buku dihapus dari wishlist.',
    );
  }

  /// Koleksi berasal dari peminjaman yang disetujui, bukan wishlist.
  void _openKoleksi() {
    final stock =
        int.tryParse(widget.book['stock']?.toString() ?? '0') ?? 0;

    if (stock <= 0) {
      _showMessage(
        'Stok buku habis. Ajukan peminjaman saat buku tersedia '
        'untuk menambahkannya ke koleksi.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPeminjamanScreen(book: widget.book),
      ),
    );
  }

  String _resolvePublisher(Map<String, dynamic> book) {
    final direct = book['publisher']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final description =
        (book['description'] ?? book['synopsis'])?.toString() ?? '';
    final match = RegExp(
      r'Penerbit\s*:\s*([^\n,.]+)',
      caseSensitive: false,
    ).firstMatch(description);
    final parsed = match?.group(1)?.trim();

    return (parsed != null && parsed.isNotEmpty) ? parsed : '-';
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    final title = book['title']?.toString() ?? '—';
    final author = book['author']?.toString() ?? '—';
    final cover =
        (book['cover_url'] ?? book['cover'])?.toString() ?? '';
    final rating = book['rating']?.toString() ?? '—';
    final category = book['category']?.toString() ?? '—';

    final synopsis = (book['description'] ?? book['synopsis'])?.toString() ??
        'Informasi sinopsis buku ini belum tersedia.';

    final publisher = _resolvePublisher(book);

    final year = (book['published_year'] ?? book['year'])?.toString() ?? '—';
    final pages = book['pages'] == null ? '—' : '${book['pages']} halaman';
    final reviews = book['reviews']?.toString() ?? '—';

    final rawTags = book['tags'];
    final tags = rawTags is List
        ? rawTags
        : <String>[if (category != '—') category];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // =================================
                    // HEADER
                    // =================================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.navy,
                              size: 21,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _showMessage(
                                  'Fitur berbagi buku akan segera tersedia.',
                                ),
                                icon: const Icon(
                                  Icons.share_rounded,
                                  color: AppColors.navy,
                                  size: 23,
                                ),
                              ),

                              // TOMBOL FAVORITE
                              ValueListenableBuilder<List<String>>(
                                valueListenable: WishlistService.ids,
                                builder: (context, ids, child) {
                                  final isFavorite =
                                      WishlistService.isFavorite(book);

                                  return IconButton(
                                    onPressed: _toggleFavorite,
                                    tooltip: 'Wishlist',
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isFavorite
                                          ? Colors.red
                                          : AppColors.navy,
                                      size: 25,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =================================
                    // COVER BUKU
                    // =================================

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFECE4D5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.08),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 148,
                        height: 218,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(5, 9),
                            ),
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.10),
                              blurRadius: 5,
                              offset: const Offset(-2, 2),
                            ),
                          ],
                        ),
                        child: BookCover(
                          imageUrl: cover,
                          width: 148,
                          height: 218,
                          radius: 7,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =================================
                    // JUDUL DAN PENULIS
                    // =================================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 21,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            author,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================
                    // RATING
                    // =================================

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFFE6DDCC),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.yellow,
                            size: 23,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '($reviews)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================
                    // KATEGORI
                    // =================================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 9,
                        children: List.generate(
                          tags.length,
                          (index) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3D27D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD6B45E),
                              ),
                            ),
                            child: Text(
                              tags[index].toString(),
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =================================
                    // SINOPSIS
                    // =================================

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: const Color(0xFFECE4D5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sinopsis Buku',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showMessage(
                                  'Informasi sinopsis buku.',
                                ),
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  color: AppColors.navy,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            synopsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================
                    // INFORMASI BUKU
                    // =================================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Buku',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Penerbit', publisher),
                          const SizedBox(height: 16),
                          _buildInfoRow('Tahun Terbit', year),
                          const SizedBox(height: 16),
                          _buildInfoRow('Jumlah Halaman', pages),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // =================================
            // TOMBOL BAWAH
            // =================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FormPeminjamanScreen(
                                book: widget.book,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Ajukan Peminjaman',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TOMBOL KOLEKSI: mengarah ke pengajuan peminjaman,
                  // bukan toggle wishlist.
                  _buildBottomIcon(
                    Icons.bookmark_add_outlined,
                    _openKoleksi,
                    tooltip: 'Koleksi',
                  ),

                  const SizedBox(width: 10),

                  // TOMBOL ULASAN
                  _buildBottomIcon(
                    Icons.comment_rounded,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UlasanBukuScreen(
                            book: widget.book,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // INFO ROW
  // ==========================================

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 7,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM ICON
  // ==========================================

  Widget _buildBottomIcon(
    IconData icon,
    VoidCallback onTap, {
    bool isActive = false,
    String? tooltip,
  }) {
    return SizedBox(
      width: 48,
      height: 46,
      child: Material(
        color: AppColors.input,
        elevation: 1,
        borderRadius: BorderRadius.circular(11),
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF4D9469) : AppColors.navy,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
