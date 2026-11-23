import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color navy = AppColors.navy;
  static const Color inactiveColor = Color(0xFF5B5344);
  static const Color backgroundColor = AppColors.input;

  final List<NavigationItem> _items = const [
    NavigationItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    NavigationItem(
      label: 'Buku',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
    ),
    NavigationItem(
      label: 'Anggota',
      icon: Icons.person_add_alt_1_outlined,
      activeIcon: Icons.person_add_alt_1,
    ),
    NavigationItem(
      label: 'Peminjaman',
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
    ),
    NavigationItem(
      label: 'Denda',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
    ),
    NavigationItem(
      label: 'Akun',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 22,
                        color: isSelected ? navy : inactiveColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? navy : inactiveColor,
                        ),
                      ),
                    ],
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

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
