
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import 'user_bottom_navigation.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';

import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'peminjaman_screen.dart';
import 'collection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigationTap;

  const ProfileScreen({
    super.key,
    this.onNavigationTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF9299A5);
  static const Color yellow = Color(0xFFF4C95D);
  static const Color red = Color(0xFFFF4438);

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
        redirectToLogin();
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
          errorMessage = 'Data profil belum ditemukan.';
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

  // REDIRECT LOGIN

  void redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
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
      MaterialPageRoute(
        builder: (_) => destination!,
      ),
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
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun LokaBaca?',
            style: TextStyle(
              color: mutedText,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: mutedText),
              ),
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
      await supabase.auth.signOut();

      if (!mounted) return;

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
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: navy,
              size: 45,
            ),
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
              style: const TextStyle(
                color: mutedText,
                fontSize: 11,
              ),
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
    final currentUser = supabase.auth.currentUser;

    final name = profile?['full_name']?.toString().trim().isNotEmpty == true
        ? profile!['full_name'].toString().trim()
        : currentUser?.userMetadata?['full_name']?.toString() ?? 'Pengguna';

    final email = currentUser?.email ?? '-';
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

                  const SizedBox(height: 47),

                  // AKUN & KEAMANAN
                  // Menu ini membuka EditProfileScreen.

                  _buildMenuItem(
                    icon: Icons.security_outlined,
                    title: 'Akun & Keamanan',
                    subtitle: 'Atur info pribadi dan keamanan akunmu',
                    onTap: _openAccountSecurity,
                  ),

                  const SizedBox(height: 42),

                  // WISHLIST

                  _buildMenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Wishlist Saya',
                    subtitle: 'Cek Wishlist yang sedang kamu tunggu',
                    onTap: () {
                      showMessage('Halaman Wishlist belum tersedia.');
                    },
                  ),

                  const SizedBox(height: 42),

                  // PENGATURAN

                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan Aplikasi',
                    subtitle:
                        'Sesuaikan pengalaman membaca dan preferensi sesuai kebutuhan kamu',
                    onTap: () {
                      showMessage('Pengaturan aplikasi belum tersedia.');
                    },
                  ),

                  const SizedBox(height: 42),

                  // DUKUNGAN

                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Dukungan dan Layanan',
                    subtitle:
                        'Temukan bantuan, ajukan permintaan dan akses informasi layanan',
                    onTap: _openHelp,
                  ),

                  const SizedBox(height: 65),

                  // KELUAR

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: isLoggingOut ? null : logout,
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
                              size: 20,
                            ),
                      label: Text(
                        isLoggingOut ? 'Keluar...' : 'Keluar',
                        style: const TextStyle(
                          color: red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: red,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    return Container(
      width: 78,
      height: 78,
      decoration: const BoxDecoration(
        color: yellow,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
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
        size: 43,
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
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: navy,
              size: 32,
            ),
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
          const Icon(
            Icons.chevron_right_rounded,
            color: navy,
            size: 25,
          ),
        ],
      ),
    );
  }

  // EDIT PROFILE

  void _openAccountSecurity() async {
    if (profile == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile!,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadProfile();
    }
  }

  // HELP

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpScreen(),
      ),
    );
  }
}
