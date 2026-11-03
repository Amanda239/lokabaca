
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'peminjaman_screen.dart';
import 'collection_screen.dart';
import 'user_bottom_navigation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color navy = Color(0xFF2F4156);
  static const Color cream = Color(0xFFF8F4E8);
  static const Color yellow = Color(0xFFF4C95D);
  static const Color softGrey = Color(0xFF8A9098);
  static const Color borderColor = Color(0xFFE8EAF0);

  void _navigateTo(BuildContext context, int index) {
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
        destination = const CollectionScreen();
        break;

      case 4:
        return;
    }

    if (destination != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => destination!,
        ),
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun LokaBaca?',
            style: TextStyle(
              color: softGrey,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: navy),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showMessage(
                  context,
                  'Fitur logout belum terhubung.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                18,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: navy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Kelola akun dan preferensimu',
                          style: TextStyle(
                            fontSize: 13,
                            color: softGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: navy,
                      size: 23,
                    ),
                  ),
                ],
              ),
            ),

            // PROFILE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ACCOUNT CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Akun Saya',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: navy,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.verified_user_outlined,
                                color: yellow,
                                size: 20,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              // AVATAR
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: yellow,
                                  borderRadius:
                                      BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: navy,
                                  size: 36,
                                ),
                              ),

                              const SizedBox(width: 14),

                              // USER INFORMATION
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amanda Nathania',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: navy,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'amandanathanya@gmail.com',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: softGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // EDIT PROFILE
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showMessage(
                                  context,
                                  'Halaman Edit Profile belum tersedia.',
                                );
                              },
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Edit Profil',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECTION TITLE
                    const Text(
                      'Pengaturan & Lainnya',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // MENU CARD
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          _ProfileMenuTile(
                            icon: Icons.shield_outlined,
                            title: 'Akun & Keamanan',
                            subtitle:
                                'Atur info pribadi dan keamanan akunmu',
                            onTap: () {
                              _showMessage(
                                context,
                                'Halaman Akun & Keamanan belum tersedia.',
                              );
                            },
                          ),

                          const Divider(
                            height: 1,
                            color: borderColor,
                          ),

                          _ProfileMenuTile(
                            icon: Icons.bookmark_border_rounded,
                            title: 'Wishlist Saya',
                            subtitle:
                                'Lihat buku yang ingin kamu baca',
                            onTap: () {
                              _showMessage(
                                context,
                                'Halaman Wishlist belum tersedia.',
                              );
                            },
                          ),

                          const Divider(
                            height: 1,
                            color: borderColor,
                          ),

                          _ProfileMenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Pengaturan Aplikasi',
                            subtitle:
                                'Sesuaikan tampilan dan preferensi aplikasi',
                            onTap: () {
                              _showMessage(
                                context,
                                'Halaman Pengaturan belum tersedia.',
                              );
                            },
                          ),

                          const Divider(
                            height: 1,
                            color: borderColor,
                          ),

                          _ProfileMenuTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Dukungan & Layanan',
                            subtitle:
                                'Temukan bantuan dan informasi LokaBaca',
                            onTap: () {
                              _showMessage(
                                context,
                                'Halaman Dukungan belum tersedia.',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // LOGOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFFB45C55),
                          side: const BorderSide(
                            color: Color(0xFFE8C9C5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // APP VERSION
                    const Center(
                      child: Text(
                        'LOKABACA  •  VERSION 1.0.0',
                        style: TextStyle(
                          fontSize: 10,
                          color: softGrey,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // REUSABLE USER BOTTOM NAVIGATION
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: 4,
        onTap: (index) => _navigateTo(context, index),
      ),
    );
  }
}

// PROFILE MENU TILE
class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color navy = Color(0xFF2F4156);
  static const Color softGrey = Color(0xFF8A9098);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 2,
        ),
        child: Row(
          children: [
            // ICON
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: navy,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: softGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ARROW
            const Icon(
              Icons.chevron_right_rounded,
              color: navy,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
