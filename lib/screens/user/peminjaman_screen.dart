
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'collection_screen.dart';
import 'profile_screen.dart';

class PeminjamanScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedBook;

  const PeminjamanScreen({
    super.key,
    this.selectedBook,
  });

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  int selectedTab = 0;
  int selectedNav = 2;

  // DATA BUKU YANG SEDANG DIPINJAM
  final List<Map<String, dynamic>> borrowingBooks = [
    {
      'title': 'Laut Bercerita',
      'author': 'Leila S. Chudori',
      'cover': 'assets/images/lautbercerita.jpeg',
      'color': const Color(0xFF355C70),
      'icon': Icons.waves_rounded,
      'borrowDate': DateTime(2026, 10, 12),
      'returnDate': DateTime(2026, 10, 26),
    },
    {
      'title': 'Bumi',
      'author': 'Tere Liye',
      'cover': 'assets/images/bumi.jpeg',
      'color': const Color(0xFF65836A),
      'icon': Icons.public_rounded,
      'borrowDate': DateTime(2026, 9, 20),
      'returnDate': DateTime(2026, 10, 4),
    },
  ];

  // DATA BUKU YANG SUDAH SELESAI
  final List<Map<String, dynamic>> completedBooks = [
    {
      'title': 'Filosofi Teras',
      'author': 'Henry Manampiring',
      'cover': 'assets/images/filosofiteras.jpeg',
      'color': const Color(0xFFB47A45),
      'icon': Icons.spa_rounded,
      'borrowDate': DateTime(2026, 9, 20),
      'returnDate': DateTime(2026, 10, 4),
      'actualReturnDate': DateTime(2026, 10, 3),
    },
    {
      'title': 'Pulang',
      'author': 'Tere Liye',
      'cover': 'assets/images/pulang.jpeg',
      'color': const Color(0xFF66547D),
      'icon': Icons.nights_stay_rounded,
      'borrowDate': DateTime(2026, 8, 10),
      'returnDate': DateTime(2026, 8, 24),
      'actualReturnDate': DateTime(2026, 8, 22),
    },
  ];

  @override
  void initState() {
    super.initState();

    final book = widget.selectedBook;

    if (book != null) {
      final today = DateUtils.dateOnly(DateTime.now());

      borrowingBooks.insert(0, {
        'title': book['title'] ?? 'Judul Buku',
        'author': book['author'] ?? 'Penulis',
        'cover': book['cover'] ?? '',
        'color': book['color'] ?? AppColors.navy,
        'icon': book['icon'] ?? Icons.menu_book_rounded,
        'borrowDate': today,
        'returnDate': today.add(const Duration(days: 14)),
      });
    }
  }

  List<Map<String, dynamic>> get currentBooks {
    return selectedTab == 0 ? borrowingBooks : completedBooks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),

                  const SizedBox(height: 7),

                  const Text(
                    'Pantau status buku yang kamu pinjam.',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 23),

                  _buildStatusTabs(),

                  const SizedBox(height: 21),

                  _buildSummary(),

                  const SizedBox(height: 15),

                  if (currentBooks.isEmpty)
                    _buildEmptyState()
                  else
                    ...currentBooks.map(
                      (book) => Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: _buildBorrowingCard(book),
                      ),
                    ),
                ]),
              ),
            ),
          ],
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
        const Expanded(
          child: Text(
            'Riwayat Peminjaman',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: AppColors.navy,
            size: 22,
          ),
        ),
      ],
    );
  }

  // TAB STATUS
  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(
            label: 'Sedang Dipinjam',
            index: 0,
            icon: Icons.menu_book_rounded,
          ),
          _buildTab(
            label: 'Selesai',
            index: 1,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final active = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? AppColors.white : AppColors.grey,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // RINGKASAN
  Widget _buildSummary() {
    final count = currentBooks.length;

    final label = selectedTab == 0
        ? 'buku sedang dipinjam'
        : 'buku telah selesai';

    return Row(
      children: [
        Expanded(
          child: Text(
            '$count $label',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Icon(
          selectedTab == 0
              ? Icons.access_time_rounded
              : Icons.check_circle_outline_rounded,
          size: 15,
          color: AppColors.grey,
        ),
      ],
    );
  }

  // KARTU BUKU
  Widget _buildBorrowingCard(Map<String, dynamic> book) {
    final borrowDate = book['borrowDate'] as DateTime;
    final returnDate = book['returnDate'] as DateTime;
    final actualReturnDate = book['actualReturnDate'] as DateTime?;

    final isCompleted = selectedTab == 1;

    final today = DateUtils.dateOnly(DateTime.now());
    final dueDate = DateUtils.dateOnly(returnDate);

    final isOverdue = !isCompleted && today.isAfter(dueDate);

    final lateDays = isOverdue
        ? today.difference(dueDate).inDays
        : 0;

    final isOnTime = isCompleted &&
        actualReturnDate != null &&
        !DateUtils.dateOnly(actualReturnDate).isAfter(dueDate);

    final isLateReturn = isCompleted &&
        actualReturnDate != null &&
        DateUtils.dateOnly(actualReturnDate).isAfter(dueDate);

    final status = isCompleted
        ? 'Selesai'
        : isOverdue
            ? 'Terlambat'
            : 'Dipinjam';

    final statusColor = _getStatusColor(status);
    final statusBackground = _getStatusBackground(status);

    final timingLabel = isCompleted
        ? actualReturnDate == null
            ? 'Tanggal pengembalian belum tersedia'
            : isOnTime
                ? 'Dikembalikan tepat waktu'
                : 'Dikembalikan terlambat'
        : isOverdue
            ? 'Terlambat $lateDays hari'
            : 'Tepat waktu';

    final timingColor = isLateReturn || isOverdue
        ? const Color(0xFFC54B4B)
        : const Color(0xFF43845B);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEAE6DE),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.07),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COVER BUKU
              SizedBox(
                width: 79,
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    book['cover'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: book['color'] as Color,
                        alignment: Alignment.center,
                        child: Icon(
                          book['icon'] as IconData,
                          color: AppColors.yellow,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 11),

              // INFORMASI BUKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      book['author'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 9,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        Icon(
                          isLateReturn || isOverdue
                              ? Icons.error_rounded
                              : Icons.check_circle_rounded,
                          size: 12,
                          color: timingColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timingLabel,
                            style: TextStyle(
                              color: timingColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    _buildDateInfo(
                      icon: Icons.calendar_today_rounded,
                      label: 'Mulai',
                      date: borrowDate,
                    ),

                    const SizedBox(height: 5),

                    _buildDateInfo(
                      icon: Icons.event_rounded,
                      label: isCompleted ? 'Kembali' : 'Batas',
                      date: isCompleted && actualReturnDate != null
                          ? actualReturnDate
                          : returnDate,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              // STATUS
              Container(
                constraints: const BoxConstraints(maxWidth: 78),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // INFORMASI DENDA
          if (isOverdue || isLateReturn) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFC54B4B),
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isOverdue
                          ? 'Buku terlambat $lateDays hari. Silakan hubungi admin untuk informasi nominal denda.'
                          : 'Buku dikembalikan melewati batas waktu. Silakan periksa informasi denda kepada admin.',
                      style: const TextStyle(
                        color: Color(0xFFC54B4B),
                        fontSize: 9,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // INFORMASI TANGGAL
  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required DateTime date,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 11,
          color: AppColors.grey,
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 8,
          ),
        ),
        Expanded(
          child: Text(
            _formatDate(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              selectedTab == 0
                  ? Icons.menu_book_rounded
                  : Icons.check_circle_outline_rounded,
              color: AppColors.navy,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            selectedTab == 0
                ? 'Belum Ada Peminjaman'
                : 'Belum Ada Riwayat Selesai',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Buku yang kamu pinjam akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // FORMAT TANGGAL
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'Mei', 'Jun', 'Jul', 'Agu',
      'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // WARNA STATUS
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFF287346);
      case 'Terlambat':
        return const Color(0xFFB83232);
      default:
        return const Color(0xFF926700);
    }
  }

  Color _getStatusBackground(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFFDDF3E4);
      case 'Terlambat':
        return const Color(0xFFFCE5E5);
      default:
        return const Color(0xFFFFF0C2);
    }
  }

  // NAVIGASI
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
        return;
      case 3:
        destination = const CollectionScreen();
        break;
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
}
