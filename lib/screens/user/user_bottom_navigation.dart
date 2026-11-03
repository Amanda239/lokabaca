
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UserBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const UserBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<Map<String, dynamic>> items = [
    {'icon': Icons.home_outlined, 'label': 'Beranda'},
    {'icon': Icons.search_rounded, 'label': 'Cari'},
    {'icon': Icons.menu_book_outlined, 'label': 'Peminjaman'},
    {'icon': Icons.bookmark_border_rounded, 'label': 'Koleksi'},
    {'icon': Icons.person_outline_rounded, 'label': 'Akun'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EC),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.8),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 7, 3, 5),
          child: Row(
            children: List.generate(items.length, (index) {
              final active = selectedIndex == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => onTap(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 19,
                          color: active
                              ? AppColors.navy
                              : const Color(0xFF514B3E),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? AppColors.navy
                                : const Color(0xFF514B3E),
                            fontSize: 8,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
