import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/book_repository.dart';

/// Bar filter bersama: kategori + urutan. Dipakai semua daftar buku.
class CatalogFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final String selectedSort;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSortChanged;

  const CatalogFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedSort,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded,
              size: 17, color: AppColors.navy),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: (selectedCategory == null ||
                        !categories.contains(selectedCategory))
                    ? null
                    : selectedCategory,
                isExpanded: true,
                hint: const Text('Semua kategori',
                    style: TextStyle(fontSize: 12, color: AppColors.text)),
                style: const TextStyle(fontSize: 12, color: AppColors.text),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Semua kategori'),
                  ),
                  ...categories.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
          ),
          Container(width: 1, height: 20, color: AppColors.border),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: BookRepository.sortOptions.contains(selectedSort)
                  ? selectedSort
                  : BookRepository.sortOptions.first,
              style: const TextStyle(fontSize: 12, color: AppColors.text),
              items: BookRepository.sortOptions
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigasi halaman dengan batas tetap 10 buku per halaman.
class CatalogPagination extends StatelessWidget {
  final int page;
  final int totalItems;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const CatalogPagination({
    super.key,
    required this.page,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : page * BookRepository.pageSize + 1;
    final end = (page + 1) * BookRepository.pageSize > totalItems
        ? totalItems
        : (page + 1) * BookRepository.pageSize;
    final pages = (totalItems / BookRepository.pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan $start–$end dari $totalItems',
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          Row(
            children: [
              Text('${page + 1}/$pages',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _NavButton(
                icon: Icons.chevron_left_rounded,
                enabled: page > 0,
                onTap: onPrevious,
              ),
              const SizedBox(width: 4),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                enabled: (page + 1) * BookRepository.pageSize < totalItems,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.navy : AppColors.input,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.white : AppColors.grey),
      ),
    );
  }
}
