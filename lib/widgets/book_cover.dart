import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Penampil cover buku yang sama di seluruh aplikasi.
/// Mendukung path aset (`assets/images/...`) maupun URL Storage Supabase.
class BookCover extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  const BookCover({
    super.key,
    this.imageUrl,
    required this.width,
    required this.height,
    this.radius = 8,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final source = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.input,
        child: source.isEmpty
            ? const Icon(Icons.menu_book_rounded,
                color: AppColors.navy, size: 30)
            : source.startsWith('http')
                ? Image.network(
                    source,
                    width: width,
                    height: height,
                    fit: fit,
                    errorBuilder: (_, __, ___) => const _Fallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    source,
                    width: width,
                    height: height,
                    fit: fit,
                    errorBuilder: (_, __, ___) => const _Fallback(),
                  ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_not_supported_outlined,
          color: AppColors.grey, size: 26),
    );
  }
}
