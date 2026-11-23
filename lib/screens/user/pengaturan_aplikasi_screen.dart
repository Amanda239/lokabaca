
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'kebijakan_peminjaman_screen.dart';
import 'change_password_screen.dart';
import 'notifikasi_screen.dart';
import 'tentang_lokabaca_screen.dart';

class PengaturanAplikasiScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const PengaturanAplikasiScreen({
    super.key,
    required this.profile,
  });

  @override
  State<PengaturanAplikasiScreen> createState() =>
      _PengaturanAplikasiScreenState();
}

class _PengaturanAplikasiScreenState
    extends State<PengaturanAplikasiScreen> {
  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.cream;
  static const Color red = Color(0xFFD64545);

  bool isLoggingOut = false;

  // PESAN
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // UBAH PROFIL
  Future<void> _openEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: widget.profile,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // GANTI PASSWORD
  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );
  }

  // NOTIFIKASI
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotifikasiUserScreen(),
      ),
    );
  }

  // KEBIJAKAN PEMINJAMAN
  void _openPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const KebijakanPeminjamanScreen(),
      ),
    );
  }

  // BANTUAN
  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpScreen(),
      ),
    );
  }

  // TENTANG APLIKASI
  void _showAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TentangLokaBacaScreen(),
      ),
    );
  }

  // LOGOUT
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun LokaBaca?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await AuthService.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      _showMessage('Gagal logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: navy,
                      size: 21,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pengaturan',
                        style: TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AKUN
                    _sectionTitle('Akun'),

                    const SizedBox(height: 20),

                    _menuButton(
                      icon: Icons.person_outline_rounded,
                      title: 'Ubah Profil',
                      onTap: _openEditProfile,
                    ),

                    const SizedBox(height: 14),

                    _menuButton(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ganti Password',
                      onTap: _changePassword,
                    ),

                    const SizedBox(height: 30),

                    // APLIKASI
                    _sectionTitle('Aplikasi'),

                    const SizedBox(height: 20),

                    _menuButton(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifikasi',
                      onTap: _openNotifications,
                    ),

                    const SizedBox(height: 12),

                    // KEBIJAKAN PEMINJAMAN
                    _menuButton(
                      icon: Icons.menu_book_outlined,
                      title: 'Kebijakan Peminjaman',
                      onTap: _openPolicy,
                    ),

                    const SizedBox(height: 30),

                    // BANTUAN
                    _sectionTitle('Bantuan'),

                    const SizedBox(height: 20),

                    _menuButton(
                      icon: Icons.help_outline_rounded,
                      title: 'Bantuan',
                      onTap: _openHelp,
                    ),

                    const SizedBox(height: 14),

                    _menuButton(
                      icon: Icons.grid_view_rounded,
                      title: 'Tentang Aplikasi',
                      onTap: _showAbout,
                    ),

                    const SizedBox(height: 16),

                    // KELUAR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed:
                            isLoggingOut ? null : _logout,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: red,
                        ),
                        label: Text(
                          isLoggingOut
                              ? 'Keluar...'
                              : 'Keluar',
                          style: const TextStyle(
                            color: red,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: cream,
                          side: const BorderSide(
                            color: red,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                          ),
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
    );
  }

  // JUDUL BAGIAN
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Text(
        title,
        style: const TextStyle(
          color: navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // MENU DENGAN PANAH
  Widget _menuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: navy,
        elevation: 4,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: cream,
                  size: 23,
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: cream,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: cream,
                  size: 27,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
