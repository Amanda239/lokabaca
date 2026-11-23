import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Avatar user yang dipakai bersama dashboard dan halaman profil.
/// Menggunakan `avatar_url` dari tabel `profiles` bila tersedia.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.size = 36,
    this.iconSize = 22,
    this.backgroundColor = AppColors.yellow,
    this.foregroundColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              key: ValueKey<String>(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: foregroundColor,
        size: iconSize,
      ),
    );
  }
}
