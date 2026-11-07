
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import 'user_bottom_navigation.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';

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
  static const Color mutedText = Color(0xFF8792A1);

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

  // ==========================================
  // LOAD PROFILE FROM SUPABASE
  // ==========================================

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
    .select(
      'id, full_name, avatar_url, role, nis, status, '
      'created_at, phone, birth_date, gender',
    )
    .eq('id', user.id)
    .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          isLoading = false;
          errorMessage =
              'Data profil belum ditemukan. Silakan hubungi administrator.';
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

  // ==========================================
  // REDIRECT TO LOGIN
  // ==========================================

  void redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> logout() async {
    if (isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: mutedText),
              ),
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

  // ==========================================
  // SNACKBAR
  // ==========================================

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

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: isLoading
                    ? _buildLoading()
                    : errorMessage != null
                        ? _buildError()
                        : _buildContent(),
              ),
            ),
          ],
        ),
      ),

      // Menggunakan bottom navigation yang sudah tersedia.
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: 4,
        onTap: (index) {
          widget.onNavigationTap?.call(index);
        },
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 15),
      child: Row(
        children: [
          const Icon(
            Icons.account_circle_rounded,
            color: navy,
            size: 35,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Akun Saya',
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : loadProfile,
            icon: const Icon(
              Icons.refresh_rounded,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOADING
  // ==========================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: cream,
        strokeWidth: 2.5,
      ),
    );
  }

  // ==========================================
  // ERROR
  // ==========================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: cream,
              size: 45,
            ),
            const SizedBox(height: 15),
            const Text(
              'Profil gagal dimuat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cream,
                foregroundColor: navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MAIN CONTENT
  // ==========================================

  Widget _buildContent() {
    final name =
        profile?['full_name']?.toString().trim().isNotEmpty == true
            ? profile!['full_name'].toString()
            : 'Pengguna';

    final nis = profile?['nis']?.toString() ?? '-';
    final role = profile?['role']?.toString() ?? 'user';
    final status = profile?['status']?.toString() ?? '-';
    final avatarUrl = profile?['avatar_url']?.toString();

    return RefreshIndicator(
      color: navy,
      backgroundColor: cream,
      onRefresh: loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 35, 20, 30),
        child: Column(
          children: [
            // FOTO PROFIL
            _buildAvatar(avatarUrl),

            const SizedBox(height: 15),

            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // INFORMASI PROFIL
            _buildSectionTitle('Informasi Profil'),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfo(
                    Icons.person_outline_rounded,
                    'Nama Lengkap',
                    name,
                  ),
                  _buildDivider(),
                  _buildInfo(
                    Icons.badge_outlined,
                    'NIS',
                    nis,
                  ),
                  _buildDivider(),
                  _buildInfo(
                    Icons.manage_accounts_outlined,
                    'Role',
                    role,
                  ),
                  _buildDivider(),
                  _buildInfo(
                    Icons.verified_user_outlined,
                    'Status Akun',
                    status,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // PENGATURAN AKUN
            _buildSectionTitle('Pengaturan Akun'),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMenu(
                  Icons.edit_outlined,
                  'Edit Profil',
                  () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          profile: profile!,
                        ),
                      ),
                    );

                        if (result == true) {
                          loadProfile();
                        }
                      },
                    ),
                  const Divider(
                    height: 1,
                    indent: 55,
                    endIndent: 15,
                  ),
                  _buildMenu(
                          Icons.lock_outline_rounded,
                          'Ubah Password',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                  const Divider(
                    height: 1,
                    indent: 55,
                    endIndent: 15,
                  ),
                  _buildMenu(
  Icons.help_outline_rounded,
  'Bantuan',
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpScreen(),
      ),
    );
  },
),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // LOGOUT
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoggingOut ? null : logout,
                icon: isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        size: 20,
                      ),
                label: Text(
                  isLoggingOut
                      ? 'Sedang Keluar...'
                      : 'Keluar dari Akun',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cream,
                  foregroundColor: navy,
                  disabledBackgroundColor: mutedText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'LokaBaca',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // AVATAR
  // ==========================================

  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cream,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _avatarPlaceholder();
                },
              )
            : _avatarPlaceholder(),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: cream,
      child: const Icon(
        Icons.person_rounded,
        color: navy,
        size: 65,
      ),
    );
  }

  // ==========================================
  // SECTION TITLE
  // ==========================================

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================
  // PROFILE INFORMATION
  // ==========================================

  Widget _buildInfo(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: navy,
              size: 21,
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
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFFEAE6DD),
      height: 12,
    );
  }

  // ==========================================
  // MENU
  // ==========================================

  Widget _buildMenu(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 3,
      ),
      leading: Icon(
        icon,
        color: navy,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: mutedText,
        size: 14,
      ),
    );
  }
}
