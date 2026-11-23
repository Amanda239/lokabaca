
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/book_cover.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'peminjaman_screen.dart';
import 'profile_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController searchController =
      TextEditingController();

  int selectedNav = 3;
  int currentPage = 0;

  static const int booksPerPage = 10;

  String searchQuery = '';
  String selectedStatus = 'Semua';

  static const statusFilters = ['Semua', 'Dipinjam', 'Terlambat', 'Selesai'];

  List<Map<String, dynamic>> books = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadCollection();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // LOAD DATA KOLEKSI DARI SUPABASE
  Future<void> loadCollection() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna belum login.');
      }

      // Mengambil data peminjaman milik pengguna
      final borrowingResponse = await supabase
          .from('borrowings')
          .select()
          .eq('user_id', user.id)
          .order('borrowed_at', ascending: false);

      final borrowings =
          List<Map<String, dynamic>>.from(borrowingResponse);

      if (borrowings.isEmpty) {
        if (!mounted) return;

        setState(() {
          books = [];
          isLoading = false;
          currentPage = 0;
        });

        return;
      }

      // Mengambil ID buku dari data peminjaman
      final bookIds = borrowings
          .map((item) => item['book_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      if (bookIds.isEmpty) {
        if (!mounted) return;

        setState(() {
          books = [];
          isLoading = false;
          currentPage = 0;
        });

        return;
      }

      // Mengambil informasi buku
      final bookResponse = await supabase
          .from('books')
          .select()
          .inFilter('id', bookIds);

      final bookList =
          List<Map<String, dynamic>>.from(bookResponse);

      // Membuat map agar data buku mudah dicari berdasarkan ID
      final Map<dynamic, Map<String, dynamic>> bookMap = {
        for (final book in bookList) book['id']: book,
      };

      // Menggabungkan data peminjaman dengan data buku
      final List<Map<String, dynamic>> collection = [];

      for (final borrowing in borrowings) {
        final book = bookMap[borrowing['book_id']];

        if (book == null) continue;

        collection.add({
          'borrowing_id': borrowing['id'],
          'book_id': borrowing['book_id'],
          'title': book['title'] ?? 'Tanpa Judul',
          'author': book['author'] ?? 'Penulis tidak diketahui',
          'cover_url': book['cover_url'],
          'status': borrowing['status'] ?? 'Menunggu',
          'due_date': borrowing['due_date'],
          'borrowed_at': borrowing['borrowed_at'],
          'returned_at': borrowing['returned_at'],
        });
      }

      if (!mounted) return;

      setState(() {
        books = collection;
        isLoading = false;
        currentPage = 0;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // FILTER PENCARIAN + STATUS
  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    return books.where((book) {
      final matchesSearch = query.isEmpty ||
          book['title'].toString().toLowerCase().contains(query) ||
          book['author'].toString().toLowerCase().contains(query);
      return matchesSearch && _matchesStatus(book);
    }).toList();
  }

  bool _matchesStatus(Map<String, dynamic> book) {
    if (selectedStatus == 'Semua') return true;

    final status = book['status']?.toString().toLowerCase() ?? '';
    final returned = book['returned_at'] != null &&
        book['returned_at'].toString().isNotEmpty;

    switch (selectedStatus) {
      case 'Dipinjam':
        return status == 'dipinjam' || status == 'menunggu';
      case 'Terlambat':
        if (status == 'terlambat') return true;
        if (returned) return false;
        final due = DateTime.tryParse(book['due_date']?.toString() ?? '');
        return due != null && due.isBefore(DateTime.now());
      case 'Selesai':
        return returned ||
            status == 'selesai' ||
            status == 'dikembalikan';
      default:
        return true;
    }
  }

  // TOTAL HALAMAN
  int get totalPages {
    final total = filteredBooks.length;

    return total == 0 ? 0 : (total / booksPerPage).ceil();
  }

  // BUKU DI HALAMAN AKTIF
  List<Map<String, dynamic>> get currentBooks {
    final result = filteredBooks;

    final startIndex = currentPage * booksPerPage;

    if (startIndex >= result.length) return [];

    final endIndex =
        (startIndex + booksPerPage).clamp(0, result.length);

    return result.sublist(startIndex, endIndex);
  }

  // GANTI HALAMAN
  void _changePage(int page) {
    if (page < 0 || page >= totalPages) return;

    setState(() {
      currentPage = page;
    });
  }

  // FORMAT TANGGAL
  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) {
      return '-';
    }

    try {
      final parsedDate = DateTime.parse(date.toString()).toLocal();

      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      return '${parsedDate.day} '
          '${months[parsedDate.month - 1]} '
          '${parsedDate.year}';
    } catch (_) {
      return '-';
    }
  }

  // WARNA STATUS
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dipinjam':
        return const Color(0xFFE8B94F);

      case 'menunggu':
        return const Color(0xFF7895C1);

      case 'menunggu pengembalian':
        return const Color(0xFFB58BCE);

      case 'dikembalikan':
        return const Color(0xFF65A77A);

      case 'ditolak':
        return const Color(0xFFD77B70);

      default:
        return AppColors.grey;
    }
  }

  // NAVIGASI ANTAR HALAMAN
  void _navigateTo(int index) {
    if (index == selectedNav) return;

    Widget? destination;

    switch (index) {
      case 0:
        destination = const DashboardScreen();
        break;

      case 1:
        destination = const SearchPageScreen();
        break;

      case 2:
        destination = const PeminjamanScreen();
        break;

      case 3:
        return;

      case 4:
        destination = const ProfileScreen();
        break;
    }

    if (destination == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedBooks = currentBooks;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 600 ? 32.0 : 16.0;

            return RefreshIndicator(
              color: AppColors.navy,
              onRefresh: loadCollection,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // HEADER DAN SEARCH
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
                        const SizedBox(height: 24),
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildStatusFilter(),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),

                  // LOADING
                  if (isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                        ),
                      ),
                    )

                  // ERROR
                  else if (errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(),
                    )

                  // DAFTAR BUKU
                  else if (displayedBooks.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 18,
                              ),
                              child: _buildBookCard(
                                displayedBooks[index],
                              ),
                            );
                          },
                          childCount: displayedBooks.length,
                        ),
                      ),
                    )

                  // EMPTY STATE
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      ),
                    ),

                  // PAGINATION
                  if (!isLoading &&
                      errorMessage == null &&
                      totalPages > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 4,
                          bottom: 24,
                        ),
                        child: _buildPagination(),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: selectedNav,
        onTap: _navigateTo,
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                ),
              );
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 34,
          ),
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
        IconButton(
          onPressed: loadCollection,
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.white,
            size: 21,
          ),
        ),
      ],
    );
  }

  // SEARCH FIELD
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
          setState(() {
            searchQuery = value;
            currentPage = 0;
          });
        },
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
        ),
        decoration: InputDecoration(
          hintText: 'Cari di koleksi kamu...',
          hintStyle: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.9),
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

                    setState(() {
                      searchQuery = '';
                      currentPage = 0;
                    });
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // FILTER STATUS PEMINJAMAN
  Widget _buildStatusFilter() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = statusFilters[index];
          final active = selectedStatus == label;

          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: active ? AppColors.white : AppColors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: active,
            selectedColor: AppColors.navy,
            backgroundColor: AppColors.white,
            side: BorderSide(color: AppColors.border),
            showCheckmark: false,
            onSelected: (_) {
              setState(() {
                selectedStatus = label;
                currentPage = 0;
              });
            },
          );
        },
      ),
    );
  }

  // BOOK CARD
  Widget _buildBookCard(Map<String, dynamic> book) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth =
            (constraints.maxWidth * 0.27).clamp(70.0, 100.0);

        final status = book['status']?.toString() ?? 'Menunggu';

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
                  child: BookCover(
                    imageUrl: book['cover_url'] ?? book['cover'],
                    width: coverWidth,
                    height: 106,
                    radius: 9,
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
                            book['title']?.toString() ?? 'Tanpa Judul',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10.5,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
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
                      book['author']?.toString() ??
                          'Penulis tidak diketahui',
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
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status)
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'Jatuh Tempo: ${_formatDate(book['due_date'])}',
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

  // PAGINATION
  Widget _buildPagination() {
    return Column(
      children: [
        Text(
          'Halaman ${currentPage + 1} dari $totalPages',
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: currentPage > 0
                  ? () => _changePage(currentPage - 1)
                  : null,
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 25,
              ),
              color: AppColors.white,
              disabledColor: AppColors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            ...List.generate(totalPages, (index) {
              final isSelected = currentPage == index;

              return GestureDetector(
                onTap: () => _changePage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 29,
                  height: 29,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.white,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.navy
                          : AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            IconButton(
              onPressed: currentPage < totalPages - 1
                  ? () => _changePage(currentPage + 1)
                  : null,
              icon: const Icon(
                Icons.chevron_right_rounded,
                size: 25,
              ),
              color: AppColors.white,
              disabledColor: AppColors.grey.withValues(alpha: 0.4),
            ),
          ],
        ),
      ],
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Koleksi tidak ditemukan'
                : 'Belum ada koleksi',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            searchQuery.isNotEmpty
                ? 'Coba judul atau nama penulis lain.'
                : 'Buku yang kamu pinjam akan muncul di sini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ERROR STATE
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.white,
              size: 35,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat koleksi',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.75),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: loadCollection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.navy,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
