
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
  bool isFavorite = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    final title = book['title'] ?? 'Judul Buku';
    final author = book['author'] ?? 'Penulis';
    final cover = book['cover'] ?? '';
    final rating = book['rating'] ?? '4.9';
    final category = book['category'] ?? 'Fiksi';

    final synopsis = book['synopsis'] ??
        'Informasi sinopsis buku ini belum tersedia.';

    final publisher = book['publisher'] ??
        'Kepustakaan Populer Gramedia';

    final year = book['year'] ?? '2017';
    final pages = book['pages'] ?? '379 halaman';
    final reviews = book['reviews'] ?? '12.4k ulasan';

    final tags = book['tags'] ??
        [category, 'Sastra', 'Rekomendasi'];

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
                    // HEADER
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
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    isFavorite = !isFavorite;
                                  });
                                  _showMessage(
                                    isFavorite
                                        ? 'Buku ditambahkan ke wishlist.'
                                        : 'Buku dihapus dari wishlist.',
                                  );
                                },
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite
                                      ? Colors.red
                                      : AppColors.navy,
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // COVER BUKU
                    Container(
                      width: 148,
                      height: 218,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 8,
                            offset: const Offset(4, 7),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: book['color'] ??
                                  const Color(0xFF356B82),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 55,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 45),

                    // JUDUL DAN PENULIS
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
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

                    const SizedBox(height: 12),

                    // RATING
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFFD0C9BB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC83D),
                            size: 25,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$rating',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
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

                    const SizedBox(height: 18),

                    // KATEGORI
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: List.generate(
                        (tags as List).length,
                        (index) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3D27D),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: const Color(0xFFD6B45E),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
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

                    const SizedBox(height: 23),

                    // SINOPSIS
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(17),
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
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
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
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // INFORMASI BUKU
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Penerbit',
                            publisher,
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            'Tahun Terbit',
                            '$year',
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            'Jumlah Halaman',
                            '$pages',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // TOMBOL BAWAH
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14, 8, 14, 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child:ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormPeminjamanScreen(
                                book: widget.book,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Ajukan Peminjaman',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildBottomIcon(
                    Icons.bookmark_add_outlined,
                    () => _showMessage(
                      'Buku ditambahkan ke koleksi.',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildBottomIcon(
  Icons.comment_rounded,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UlasanBukuScreen(
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

  Widget _buildBottomIcon(
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 52,
      height: 44,
      child: Material(
        color: const Color(0xFFFAF5EB),
        elevation: 2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            icon,
            color: AppColors.navy,
            size: 22,
          ),
        ),
      ),
    );
  }
}
