
import 'package:flutter/material.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8792A1);
  static const Color yellow = Color(0xFFFFBC35);

  int selectedIndex = 0;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.home_outlined, 'label': 'Beranda'},
    {'icon': Icons.menu_book_outlined, 'label': 'Buku'},
    {'icon': Icons.person_add_alt_1_outlined, 'label': 'Anggota'},
    {'icon': Icons.auto_stories_outlined, 'label': 'Peminjaman'},
    {'icon': Icons.person_outline, 'label': 'Akun'},
  ];

  final List<Map<String, dynamic>> statistics = [
    {
      'title': 'Total Buku',
      'value': '248',
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Total Anggota',
      'value': '132',
      'icon': Icons.person_outline_rounded,
    },
    {
      'title': 'Peminjam Aktif',
      'value': '86',
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'Terlambat',
      'value': '12',
      'icon': Icons.warning_rounded,
    },
  ];

  final List<Map<String, String>> recentLoans = [
    {
      'title': 'Keajaiban Toko Kelontong Namiya',
      'author': 'Keigo Higashino',
      'date': '21 September 2026',
      'cover': 'namiya',
    },
    {
      'title': 'Hujan',
      'author': 'Tere Liye',
      'date': '20 September 2026',
      'cover': 'hujan',
    },
  ];

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(48),
                    topRight: Radius.circular(48),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    50,
                    12,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatistics(),

                      const SizedBox(height: 24),

                      _buildLoanHeader(),

                      const SizedBox(height: 16),

                      ...recentLoans.map(
                        (loan) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildLoanCard(loan),
                        ),
                      ),

                      const SizedBox(height: 1),

                      _buildReportButton(),
                    ],
                  ),
                ),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 5, 14, 8),
      child: Row(
        children: [
          Image.asset(
            'assets/images/lokabaca.png',
            width: 88,
            height: 88,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 88,
                height: 88,
                child: Icon(
                  Icons.menu_book_rounded,
                  color: navy,
                  size: 48,
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Halo, Admin',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Selamat datang di panel admin\nLokaBaca',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),

          _headerIcon(
            Icons.notifications_none_rounded,
            () => showMessage('Belum ada notifikasi baru'),
          ),

          const SizedBox(width: 12),

          _headerIcon(
            Icons.account_circle_rounded,
            () {
              setState(() {
                selectedIndex = 4;
              });
              showMessage('Menu Akun');
            },
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Icon(
        icon,
        color: navy,
        size: 25,
      ),
    );
  }

  // STATISTICS
  Widget _buildStatistics() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statistics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.52,
      ),
      itemBuilder: (context, index) {
        final item = statistics[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['title'],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 51,
                    height: 51,
                    decoration: const BoxDecoration(
                      color: cream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'],
                      color: navy,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item['value'],
                        style: const TextStyle(
                          color: navy,
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // RECENT LOANS TITLE
  Widget _buildLoanHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Peminjaman Terbaru',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        InkWell(
          onTap: () {
            showMessage('Halaman semua peminjaman');
          },
          borderRadius: BorderRadius.circular(8),
          child: const Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 23,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // LOAN CARD
  Widget _buildLoanCard(Map<String, String> loan) {
    return Container(
      width: double.infinity,
      height: 96,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 7),

          _buildBookCover(loan['cover']!),

          const SizedBox(width: 17),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loan['title']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  loan['author']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  loan['date']!,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFB9E4CD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'DIPINJAM',
              style: TextStyle(
                color: Color(0xFF315F46),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOOK COVER
  Widget _buildBookCover(String cover) {
    final bool isNamiya = cover == 'namiya';

    return Container(
      width: 52,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isNamiya
            ? const Color(0xFF283B80)
            : const Color(0xFF50C4E6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: Colors.white.withOpacity(0.85),
              size: 30,
            ),
            Positioned(
              bottom: 7,
              child: Text(
                isNamiya ? 'NAMIYA' : 'HUJAN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // REPORT BUTTON
  Widget _buildReportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            showMessage('Halaman laporan akan dibuka');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cream,
            foregroundColor: navy,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Cek Laporan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNavigation() {
    return Container(
      height: 57,
      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE4DFD4),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(
            menuItems.length,
            (index) {
              final item = menuItems[index];
              final bool isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });

                    if (index != 0) {
                      showMessage('Menu ${item['label']} dipilih');
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'],
                        size: 21,
                        color: isSelected
                            ? navy
                            : const Color(0xFF69624F),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        item['label'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? navy
                              : const Color(0xFF69624F),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
