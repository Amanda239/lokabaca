import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'admin_bottom_navigation.dart';
import 'dashboard_admin.dart';
import 'denda_admin_screen.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';
import 'profile_admin.dart';

class PengaturanAdminPage extends StatefulWidget {
  const PengaturanAdminPage({super.key});

  @override
  State<PengaturanAdminPage> createState() => _PengaturanAdminPageState();
}

class _PengaturanAdminPageState extends State<PengaturanAdminPage> {
  bool isNotificationEnabled = true;
  bool isSigningOut = false;

  void toggleNotification() {
    setState(() {
      isNotificationEnabled = !isNotificationEnabled;
    });
  }

  void navigateTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> signOut() async {
    if (isSigningOut) return;
    setState(() => isSigningOut = true);
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSigningOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar dari akun: $e'),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun admin?',
          style: TextStyle(color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.navy),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              signOut();
            },
            child: Text(isSigningOut ? 'Keluar...' : 'Keluar'),
          ),
        ],
      ),
    );
  }

  Widget buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.navy, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                ),
              ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: AppColors.navy,
              size: 19,
            ),
        onTap: onTap,
      ),
    );
  }

  void handleNavigation(int index) {
    if (index == 5) return;
    final Widget page = switch (index) {
      0 => const DashboardAdmin(),
      1 => const KelolaBukuScreen(),
      2 => const KelolaAnggotaPage(),
      3 => const PeminjamanAdminScreen(),
      4 => const DendaAdminScreen(),
      _ => const ProfileAdminScreen(),
    };
    navigateTo(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pengaturan Admin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Atur preferensi dan informasi aplikasi.',
              style: TextStyle(color: AppColors.grey, fontSize: 11),
            ),

            const SizedBox(height: 20),

            const Text(
              'Preferensi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 9),

            buildSettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: 'Aktifkan atau nonaktifkan notifikasi',
              trailing: Switch(
                value: isNotificationEnabled,
                onChanged: (value) => toggleNotification(),
                activeColor: AppColors.white,
                activeTrackColor: AppColors.navy,
                inactiveTrackColor: AppColors.border,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Akun',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 9),

            buildSettingTile(
              icon: Icons.person_outline,
              title: 'Profil Admin',
              subtitle: 'Lihat dan edit informasi akun admin',
              onTap: () => navigateTo(const ProfileAdminScreen()),
            ),

            buildSettingTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Denda',
              subtitle: 'Kelola dan konfirmasi denda anggota',
              onTap: () => navigateTo(const DendaAdminScreen()),
            ),

            const SizedBox(height: 10),

            const Text(
              'Informasi Aplikasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 9),

            buildSettingTile(
              icon: Icons.info_outline,
              title: 'Tentang LokaBaca',
              subtitle: 'Informasi aplikasi perpustakaan',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'LokaBaca',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Aplikasi perpustakaan digital.',
                );
              },
            ),

            const SizedBox(height: 10),

            buildSettingTile(
              icon: Icons.logout,
              title: 'Keluar',
              subtitle: 'Keluar dari akun admin',
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFFD94343),
                size: 19,
              ),
              onTap: showLogoutDialog,
            ),

            const SizedBox(height: 16),

            const Center(
              child: Text(
                'LokaBaca v1.0.0',
                style: TextStyle(color: AppColors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: 5,
        onTap: handleNavigation,
      ),
    );
  }
}
