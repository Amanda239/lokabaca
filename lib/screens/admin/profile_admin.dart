
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import 'admin_bottom_navigation.dart';
import 'edit_profile_admin.dart';
import 'dashboard_admin.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';

class ProfileAdminScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigationTap;

  const ProfileAdminScreen({
    super.key,
    this.onNavigationTap,
  });

  @override
  State<ProfileAdminScreen> createState() =>
      _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color mutedText = Color(0xFF9299A5);
  static const Color yellow = Color(0xFFF4C95D);
  static const Color borderColor = Color(0xFF50647D);
  static const Color red = Color(0xFFFF4545);

  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isLoggingOut = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // LOAD PROFILE
  Future<void> loadProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = 'Sesi login tidak ditemukan.';
        });

        return;
      }

      final response = await supabase
          .from('profiles')
          .select('id, full_name, avatar_url, role, phone')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Data profil admin tidak ditemukan.';
        });

        return;
      }

      setState(() {
        profile = response;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // SNACKBAR
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  // BOTTOM NAVIGATION
  void handleNavigation(int index) {
    if (widget.onNavigationTap != null) {
      widget.onNavigationTap!(index);
      return;
    }

    if (index == 4) return;

    Widget? destination;

    switch (index) {
      case 0:
        destination = const DashboardAdmin();
        break;
      case 1:
        destination = const KelolaBukuScreen();
        break;
      case 2:
        destination = const KelolaAnggotaPage();
        break;
      case 3:
        destination = const PeminjamanAdminScreen();
        break;
    }

    if (destination == null || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
    );
  }

  // EDIT PROFILE
  Future<void> openEditProfile() async {
    if (profile == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileAdminScreen(
          profile: profile!,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadProfile();
    }
  }

  // OPEN BORROWING
  void openBorrowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PeminjamanAdminScreen(),
      ),
    );
  }

  // OPEN MEMBERS
  void openMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KelolaAnggotaPage(),
      ),
    );
  }

  // LOGOUT CONFIRMATION
  Future<void> confirmLogout() async {
    if (isLoggingOut) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun admin LokaBaca?',
            style: TextStyle(
              color: mutedText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Ya, Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) return;

    await logout();
  }

  // LOGOUT DAN KEMBALI KE LOGIN
  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      // 1. Keluar dari akun Supabase.
      await supabase.auth.signOut();

      if (!mounted) return;

      // 2. Hapus seluruh halaman sebelumnya.
      // 3. Arahkan pengguna langsung ke LoginScreen.
      Navigator.of(context).pushAndRemoveUntil(
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

      showMessage('Gagal keluar dari akun: $e');
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: isLoading
            ? _buildLoading()
            : errorMessage != null
                ? _buildError()
                : _buildContent(),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: 4,
        onTap: handleNavigation,
      ),
    );
  }

  // LOADING
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: navy,
        strokeWidth: 2.5,
      ),
    );
  }

  // ERROR
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: navy,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Profil gagal dimuat',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MAIN CONTENT
  Widget _buildContent() {
    final user = supabase.auth.currentUser;

    final name = profile?['full_name']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? profile!['full_name'].toString().trim()
        : 'Admin';

    final email = user?.email ?? '-';

    final avatarUrl =
        profile?['avatar_url']?.toString() ?? '';

    return RefreshIndicator(
      color: navy,
      backgroundColor: cream,
      onRefresh: loadProfile,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Akun',
                      style: TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 27),

                  _buildProfileCard(
                    name: name,
                    email: email,
                    avatarUrl: avatarUrl,
                  ),

                  const SizedBox(height: 30),

                  const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: Text(
                      'Menu Akun',
                      style: TextStyle(
                        color: navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Akun & Keamanan',
                    subtitle:
                        'Atur informasi pribadi dan keamanan akun',
                    onTap: openEditProfile,
                  ),

                  const SizedBox(height: 19),

                  _buildMenuItem(
                    icon: Icons.menu_book_outlined,
                    title: 'Aktivitas Peminjaman',
                    subtitle:
                        'Pantau aktivitas peminjaman buku',
                    onTap: openBorrowing,
                  ),

                  const SizedBox(height: 19),

                  _buildMenuItem(
                    icon: Icons.people_outline_rounded,
                    title: 'Kelola Anggota',
                    subtitle:
                        'Lihat dan kelola data anggota LokaBaca',
                    onTap: openMembers,
                  ),

                  const SizedBox(height: 19),

                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan Aplikasi',
                    subtitle:
                        'Sesuaikan preferensi aplikasi',
                    onTap: () {
                      showMessage(
                        'Silakan buka menu Pengaturan Admin.',
                      );
                    },
                  ),

                  const SizedBox(height: 19),

                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Dukungan dan Layanan',
                    subtitle:
                        'Temukan bantuan dan informasi layanan',
                    onTap: () {
                      showMessage(
                        'Informasi layanan belum tersedia.',
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  _buildLogoutButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // PROFILE CARD
  Widget _buildProfileCard({
    required String name,
    required String email,
    required String avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: borderColor,
          width: 0.9,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAvatar(avatarUrl),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AVATAR
  Widget _buildAvatar(String avatarUrl) {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: yellow,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) {
                return _avatarPlaceholder();
              },
            )
          : _avatarPlaceholder(),
    );
  }

  Widget _avatarPlaceholder() {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 37,
      ),
    );
  }

  // MENU ITEM
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 3,
          horizontal: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 35,
              height: 35,
              child: Icon(
                icon,
                color: navy,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              color: navy,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // LOGOUT BUTTON
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isLoggingOut ? null : confirmLogout,
        icon: isLoggingOut
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: red,
                ),
              )
            : const Icon(
                Icons.logout_rounded,
                color: red,
                size: 19,
              ),
        label: Text(
          isLoggingOut ? 'Keluar...' : 'Keluar',
          style: const TextStyle(
            color: red,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: red,
          side: const BorderSide(
            color: red,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
