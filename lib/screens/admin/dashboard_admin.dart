
import 'package:flutter/material.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  static const Color navy = Color(0xFF2E4057);
  static const Color yellow = Color(0xFFFFBC35);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);

  int selectedIndex = 0;

  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.home_outlined,
      'label': 'Beranda',
    },
    {
      'icon': Icons.menu_book_outlined,
      'label': 'Buku',
    },
    {
      'icon': Icons.person_add_alt_1_outlined,
      'label': 'Anggota',
    },
    {
      'icon': Icons.auto_stories_outlined,
      'label': 'Peminjaman',
    },
    {
      'icon': Icons.person_outline,
      'label': 'Akun',
    },
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
      'icon': Icons.person_outline,
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
      'title': 'Keajaiban Toko\nKelontong Namiya',
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
            // HEADER
            _buildHeader(),

            // DASHBOARD CONTENT
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(55),
                    topRight: Radius.circular(55),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    58,
                    14,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // STATISTIK
                      _buildStatistics(),

                      const SizedBox(height: 26),

                      // JUDUL PEMINJAMAN
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Peminjaman Terbaru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          InkWell(
                            onTap: () {
                              showMessage(
                                'Halaman semua peminjaman',
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // DAFTAR PEMINJAMAN
                      ...recentLoans.map(
                        (loan) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 20,
                          ),
                          child: _buildLoanCard(loan),
                        ),
                      ),

                      const SizedBox(height: 0),

                      // TOMBOL CEK LAPORAN
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              showMessage(
                                'Halaman laporan akan dibuka',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cream,
                              foregroundColor: navy,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(11),
                              ),
                            ),
                            child: const Text(
                              'Cek Laporan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        16,
        12,
      ),
      child: Row(
        children: [
          // LOGO
          Image.asset(
            'assets/images/lokabaca.png',
            width: 82,
            height: 88,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 82,
                height: 88,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 55,
                  color: navy,
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // SAPAAN ADMIN
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, Admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'Selamat datang di panel admin\nLokaBaca',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF68788D),
                  ),
                ),
              ],
            ),
          ),

          // NOTIFIKASI
          IconButton(
            onPressed: () {
              showMessage('Belum ada notifikasi baru');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: navy,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // PROFIL
          InkWell(
            onTap: () {
              setState(() {
                selectedIndex = 4;
              });
              showMessage('Menu Akun');
            },
            child: const Icon(
              Icons.account_circle,
              color: navy,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }

  // KARTU STATISTIK
  Widget _buildStatistics() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statistics.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = statistics[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: cream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'],
                      color: navy,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item['value'],
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: navy,
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

  // KARTU PEMINJAMAN
  Widget _buildLoanCard(Map<String, String> loan) {
    return Container(
      width: double.infinity,
      height: 108,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),

          // COVER BUKU
          _buildBookCover(loan['cover']!),

          const SizedBox(width: 22),

          // INFORMASI BUKU
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
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  loan['author']!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  loan['date']!,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // STATUS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFB6E4CC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'DIPINJAM',
              style: TextStyle(
                color: Color(0xFF315F46),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // COVER BUKU SEMENTARA
  Widget _buildBookCover(String cover) {
    final bool isNamiya = cover == 'namiya';

    return Container(
      width: 57,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: isNamiya
            ? const Color(0xFF283B80)
            : const Color(0xFF50C4E6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 34,
            ),
            Positioned(
              bottom: 8,
              child: Text(
                isNamiya ? 'NAMIYA' : 'HUJAN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNavigation() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2DED4),
            width: 1,
          ),
        ),
      ),
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
                    showMessage(
                      'Menu ${item['label']} dipilih',
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'],
                      size: 22,
                      color: isSelected
                          ? navy
                          : const Color(0xFF69624F),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      item['label'],
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
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
    );
  }
}
