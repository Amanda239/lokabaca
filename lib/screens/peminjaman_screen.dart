
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'collection_screen.dart';

class PeminjamanScreen extends StatefulWidget {
  const PeminjamanScreen({super.key});

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  int selectedTab = 0;
  int selectedNav = 2;

  final List<Map<String, dynamic>> borrowingBooks = [
    {
      'title': 'Laut Bercerita',
      'author': 'Leila S. Chudori',
      'cover': 'assets/images/lautbercerita.jpeg',
      'color': const Color(0xFF355C70),
      'icon': Icons.waves_rounded,
      'borrowDate': DateTime(2026, 10, 12),
      'returnDate': DateTime(2026, 10, 26),
      'status': 'Dipinjam',
    },
    {
      'title': 'Bumi',
      'author': 'Tere Liye',
      'cover': 'assets/images/bumi.jpeg',
      'color': const Color(0xFF65836A),
      'icon': Icons.public_rounded,
      'borrowDate': DateTime(2026, 9, 20),
      'returnDate': DateTime(2026, 10, 4),
      'status': 'Terlambat',
    },
  ];

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
      'status': 'Selesai',
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
      'status': 'Selesai',
    },
  ];

  List<Map<String, dynamic>> get currentBooks {
    if (selectedTab == 0) {
      return borrowingBooks;
    }
    return completedBooks;
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Peminjaman',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 23,
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

  // STATUS TABS
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
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.13),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
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

  // SUMMARY
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

  // BORROWING CARD
  Widget _buildBorrowingCard(Map<String, dynamic> book) {
    final status = book['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusBackground = _getStatusBackground(status);

    final borrowDate = book['borrowDate'] as DateTime;
    final returnDate = book['returnDate'] as DateTime;
    final actualReturnDate = book['actualReturnDate'] as DateTime?;

    final isCompleted = status == 'Selesai';
    final isLate = status == 'Terlambat';

    final isOverdue = !isCompleted &&
        DateTime.now().isAfter(
          DateTime(
            returnDate.year,
            returnDate.month,
            returnDate.day,
            23,
            59,
            59,
          ),
        );

    final displayedStatus = isOverdue ? 'Terlambat' : status;
    final displayedStatusColor = _getStatusColor(displayedStatus);
    final displayedStatusBackground =
        _getStatusBackground(displayedStatus);

    final isOnTime = isCompleted &&
        actualReturnDate != null &&
        !actualReturnDate.isAfter(returnDate);

    final timingLabel = isCompleted
        ? (isOnTime ? 'Dikembalikan tepat waktu' : 'Dikembalikan terlambat')
        : (isOverdue || isLate ? 'Terlambat mengembalikan' : 'Tepat waktu');

    final timingColor = isCompleted
        ? (isOnTime ? const Color(0xFF43845B) : const Color(0xFFC54B4B))
        : (isOverdue || isLate
            ? const Color(0xFFC54B4B)
            : const Color(0xFF43845B));

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COVER BUKU DI KIRI
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

          // INFORMASI BUKU DI TENGAH
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
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
                      height: 1.25,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isCompleted && isOnTime
                            ? Icons.check_circle_rounded
                            : (isOverdue || isLate ||
                                    (isCompleted && !isOnTime)
                                ? Icons.error_rounded
                                : Icons.access_time_filled_rounded),
                        size: 12,
                        color: timingColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          timingLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                    icon: isCompleted
                        ? Icons.event_available_rounded
                        : Icons.event_rounded,
                    label: isCompleted ? 'Kembali' : 'Batas',
                    date: isCompleted && actualReturnDate != null
                        ? actualReturnDate
                        : returnDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),

          // BADGE STATUS DI KANAN
          Container(
            constraints: const BoxConstraints(maxWidth: 78),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: displayedStatusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              displayedStatus,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: displayedStatusColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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

  // BOTTOM NAVIGATION
  Widget _buildBottomNavigation() {
    const items = [
      {'icon': Icons.home_outlined, 'label': 'Beranda'},
      {'icon': Icons.search_rounded, 'label': 'Cari'},
      {'icon': Icons.menu_book_outlined, 'label': 'Peminjaman'},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Koleksi'},
      {'icon': Icons.person_outline_rounded, 'label': 'Akun'},
    ];

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
              final active = selectedNav == index;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => _navigateTo(index),
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

  void _navigateTo(int index) {
    if (index == selectedNav) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SearchPageScreen(),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CollectionScreen(),
        ),
      );
    } else if (index == 2) {
      setState(() => selectedNav = 2);
    } else {
      setState(() => selectedNav = index);
      _showMessage('Halaman akun akan dibuat berikutnya.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }
}
