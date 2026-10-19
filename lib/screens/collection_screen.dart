import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  int selectedNav = 3;
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> books = [
    {
      'title': 'Keajaiban Toko Kelontong Namiya',
      'author': 'Keigo Higashino',
      'status': 'Dipinjam',
      'dueDate': '17 Juni 1997',
      'asset': 'assets/images/namiya.jpeg',
      'color': const Color(0xFF3F4C9B),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'title': 'Namalaku Alam',
      'author': 'Leila S. Chudori',
      'status': 'Dipinjam',
      'dueDate': '17 Juni 1997',
      'asset': 'assets/images/namakualam.jpeg',
      'color': const Color(0xFF9D3028),
      'icon': Icons.waves_rounded,
    },
    {
      'title': 'Dompet Ayah Sepatu Ibu',
      'author': 'J.S. Khairen',
      'status': 'Dipinjam',
      'dueDate': '17 Juni 1997',
      'asset': 'assets/images/dompetayah.jpeg',
      'color': const Color(0xFF58AEB4),
      'icon': Icons.menu_book_rounded,
    },
  ];

  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return books;

    return books.where((book) {
      return book['title'].toString().toLowerCase().contains(query) ||
          book['author'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600 ? 32.0 : 16.0;

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          20,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildSearchField(),
                            const SizedBox(height: 20),
                          ]),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _buildBookCard(filteredBooks[index]),
                            ),
                            childCount: filteredBooks.length,
                          ),
                        ),
                      ),
                      if (filteredBooks.isEmpty)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _buildEmptyState(),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                    ],
                  ),
                ),
                _buildBottomNavigation(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Koleksi Saya',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() => searchQuery = value);
        },
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
        ),
        decoration: InputDecoration(
          hintText: 'Cari di koleksi kamu...',
          hintStyle: TextStyle(
            color: AppColors.grey.withOpacity(0.9),
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.navy,
            size: 21,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = '');
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 16),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth = (constraints.maxWidth * 0.27).clamp(70.0, 100.0);

        return Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: coverWidth,
                  height: 106,
                  child: Image.asset(
                    book['asset'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: book['color'] as Color,
                        child: Icon(
                          book['icon'] as IconData,
                          color: AppColors.yellow,
                          size: 31,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book['title'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.navy,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book['author'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C8C92),
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          book['status'] as String,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'Jatuh Tempo: ${book['dueDate']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.grey, size: 30),
          SizedBox(height: 8),
          Text(
            'Koleksi tidak ditemukan',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba judul atau nama penulis lain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const items = [
      {'icon': Icons.home_outlined, 'label': 'Beranda'},
      {'icon': Icons.search_rounded, 'label': 'Cari'},
      {'icon': Icons.menu_book_outlined, 'label': 'Peminjaman'},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Koleksi'},
      {'icon': Icons.person_outline_rounded, 'label': 'Akun'},
    ];

    return Container(
      color: AppColors.cream,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
          child: Row(
            children: List.generate(items.length, (index) {
              final active = selectedNav == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (index == 3) {
                      return;
                    }

                    if (index == 0) {
                      Navigator.pop(context);
                    } else {
                      final label = item['label'] as String;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Halaman $label akan dibuat berikutnya.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 17,
                          color: active ? AppColors.navy : const Color(0xFF655F51),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? AppColors.navy : const Color(0xFF655F51),
                            fontSize: 7.5,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
