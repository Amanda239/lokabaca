import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import 'user_bottom_navigation.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'pengaturan_aplikasi_screen.dart';
import 'notifikasi_screen.dart';
import 'wishlist_screen.dart';

import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'peminjaman_screen.dart';
import 'collection_screen.dart';
import 'denda_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigationTap;

  const ProfileScreen({super.key, this.onNavigationTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.cream;
  static const Color textColor = AppColors.text;
  static const Color mutedText = AppColors.grey;
  static const Color red = Color(0xFFD64545);

  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isLoggingOut = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Profil selalu disegarkan dari Supabase saat aplikasi aktif kembali.
    if (state == AppLifecycleState.resumed && mounted) {
      loadProfile();
    }
  }

  // LOAD PROFILE

  Future<void> loadProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = AuthService.currentUserId;

      if (userId == null) {
        redirectToLogin();
        return;
      }

      // Data asli Supabase, diambil ulang setiap masuk ke halaman ini.
      final data = await AuthService.currentProfile();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Data profil belum ditemukan.';
        });
        return;
      }

      setState(() {
        profile = data;
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

  // REDIRECT LOGIN

  void redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // BOTTOM NAVIGATION

  void _navigateTo(int index) {
    if (widget.onNavigationTap != null) {
      widget.onNavigationTap!(index);
      return;
    }

    if (index == 4) return;

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
    }

    if (destination == null || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination!),
    );
  }

  // LOGOUT

  Future<void> logout() async {
    if (isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(color: navy, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun LokaBaca?',
            style: TextStyle(color: mutedText, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal', style: TextStyle(color: mutedText)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      showMessage('Gagal logout: $e');
    }
  }

  // SNACKBAR

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // MAIN BUILD

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
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: 4,
        onTap: _navigateTo,
      ),
    );
  }

  // LOADING

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: navy, strokeWidth: 2.5),
    );
  }

  // ERROR

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: navy, size: 45),
            const SizedBox(height: 15),
            const Text(
              'Profil gagal dimuat',
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedText, fontSize: 11),
            ),
            const SizedBox(height: 20),
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

  // PROFILE CONTENT

  Widget _buildContent() {
    final name = profile?['full_name']?.toString().trim().isNotEmpty == true
        ? profile!['full_name'].toString().trim()
        : 'Pengguna';

    final email = profile?['email']?.toString() ?? AuthService.currentEmail ?? '-';
    final avatarUrl = profile?['avatar_url']?.toString();

    return RefreshIndicator(
      color: navy,
      backgroundColor: cream,
      onRefresh: loadProfile,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 25),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 25,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 43),

                  const Center(
                    child: Text(
                      'Akun',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // FOTO DAN IDENTITAS USER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(avatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: mutedText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),

                  const SizedBox(height: 20),

                  // AKUN & KEAMANAN
                  // Menu ini membuka EditProfileScreen.
                  _buildMenuItem(
                    icon: Icons.security_outlined,
                    title: 'Akun & Keamanan',
                    subtitle: 'Atur info pribadi dan keamanan akunmu',
                    onTap: _openAccountSecurity,
                  ),

                  _buildSectionDivider(),

                  // NOTIFIKASI
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifikasi',
                    subtitle:
                        'Pembaruan peminjaman, denda, dan pengingat jatuh tempo',
                    onTap: _openNotifications,
                  ),

                  _buildSectionDivider(),

                  // WISHLIST
                  _buildMenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Wishlist Saya',
                    subtitle: 'Cek buku yang ingin kamu baca',
                    onTap: _openWishlist,
                  ),

                  _buildSectionDivider(),

                  // DENDA
                  // Menu ini membuka DendaScreen.
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Denda Saya',
                    subtitle: 'Cek dan bayar denda keterlambatan buku',
                    onTap: _openDenda,
                  ),

                  _buildSectionDivider(),

                  // PENGATURAN
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan Aplikasi',
                    subtitle:
                        'Sesuaikan pengalaman membaca dan preferensi sesuai kebutuhan kamu',
                    onTap: _openSettings,
                  ),

                  _buildSectionDivider(),

                  // DUKUNGAN
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Dukungan dan Layanan',
                    subtitle:
                        'Temukan bantuan, ajukan permintaan dan akses informasi layanan',
                    onTap: _openHelp,
                  ),

                  _buildSectionDivider(),

                  const SizedBox(height: 30),

                  // KELUAR
                  Center(
                    child: SizedBox(
                      width: 190,
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: isLoggingOut ? null : logout,
                        icon: isLoggingOut
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: red,
                                ),
                              )
                            : const Icon(
                                Icons.logout_rounded,
                                color: red,
                                size: 16,
                              ),
                        label: Text(
                          isLoggingOut ? 'Keluar...' : 'Keluar',
                          style: const TextStyle(
                            color: red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: red, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // AVATAR

  Widget _buildAvatar(String? avatarUrl) {
    return UserAvatar(
      imageUrl: avatarUrl,
      size: 78,
      iconSize: 43,
    );
  }

  // PEMISAH MENU

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 13),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
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
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: navy, size: 32),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: navy, size: 25),
        ],
      ),
    );
  }

  // EDIT PROFILE

  void _openAccountSecurity() async {
    if (profile == null) return;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile!)),
    );

    // Selalu segarkan profil setelah kembali, bukan hanya saat result true.
    if (mounted) {
      await loadProfile();
    }
  }

  Future<void> _openSettings() async {
    if (profile == null) return;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PengaturanAplikasiScreen(profile: profile!),
      ),
    );

    if (mounted) {
      await loadProfile();
    }
  }

  // WISHLIST

  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishlistScreen()),
    );
  }

  // NOTIFIKASI

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotifikasiUserScreen()),
    );
  }

  // DENDA

  void _openDenda() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DendaScreen()),
    );
  }

  // HELP

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }
}