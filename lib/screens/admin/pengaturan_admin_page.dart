import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'dashboard_admin.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';

class PengaturanAdminPage extends StatefulWidget {
  const PengaturanAdminPage({super.key});

  @override
  State<PengaturanAdminPage> createState() => _PengaturanAdminPageState();
}

class _PengaturanAdminPageState extends State<PengaturanAdminPage> {
  bool isNotificationEnabled = true;

  static const Color navy = Color(0xFF183153);
  static const Color cream = Color(0xFFF7F3EA);
  static const Color muted = Color(0xFFE8E3D9);

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

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cream,
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun admin?',
            style: TextStyle(color: navy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: navy),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
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
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: navy),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: const TextStyle(color: Colors.grey),
              ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: navy,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 4,
      selectedItemColor: navy,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      onTap: (index) {
        switch (index) {
          case 0:
            navigateTo(const DashboardAdmin());
            break;
          case 1:
            navigateTo(const KelolaBukuScreen());
            break;
          case 2:
            navigateTo(const KelolaAnggotaPage());
            break;
          case 3:
            navigateTo(const PeminjamanAdminScreen());
            break;
          case 4:
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Buku',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Anggota',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          label: 'Peminjaman',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Pengaturan',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pengaturan Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Atur preferensi dan informasi aplikasi.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Preferensi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 12),

            buildSettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: 'Aktifkan atau nonaktifkan notifikasi',
              trailing: Switch(
                value: isNotificationEnabled,
                onChanged: (value) {
                  setState(() {
                    isNotificationEnabled = value;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF8298B0),
                inactiveTrackColor: muted,
              ),
            ),

            buildSettingTile(
              icon: Icons.language_outlined,
              title: 'Bahasa',
              subtitle: 'Bahasa Indonesia',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengaturan bahasa belum tersedia.'),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Informasi Aplikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 12),

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

            buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi',
              subtitle: 'Informasi kebijakan privasi aplikasi',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Halaman kebijakan privasi belum tersedia.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Akun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 12),

            buildSettingTile(
              icon: Icons.logout,
              title: 'Keluar',
              subtitle: 'Keluar dari akun admin',
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.red,
              ),
              onTap: showLogoutDialog,
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'LokaBaca v1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: buildBottomNavigation(),
    );
  }
}