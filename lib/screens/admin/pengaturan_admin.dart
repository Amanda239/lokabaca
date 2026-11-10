
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_bottom_navigation.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';
import 'notifikasi_admin.dart';

class PengaturanAdminScreen extends StatefulWidget {
  const PengaturanAdminScreen({super.key});

  @override
  State<PengaturanAdminScreen> createState() =>
      _PengaturanAdminScreenState();
}

class _PengaturanAdminScreenState
    extends State<PengaturanAdminScreen> {
  final supabase = Supabase.instance.client;

  static const navy = Color(0xFF2E4057);
  static const cream = Color(0xFFF8F4EA);
  static const muted = Color(0xFF8993A1);
  static const border = Color(0xFFCBD0D7);

  Map<String, dynamic>? profile;

  bool loading = true;
  bool updating = false;
  bool notificationsEnabled = true;

  final int selectedIndex = 4;

  String get adminName =>
      profile?['full_name']?.toString() ?? 'Admin';

  String get adminEmail =>
      supabase.auth.currentUser?.email ?? '-';

  String? get avatarUrl =>
      profile?['avatar_url']?.toString();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> loadProfile() async {
    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Admin belum login.');
      }

      final data = await supabase
          .from('profiles')
          .select(
            'id, full_name, avatar_url, role, notifications_enabled',
          )
          .eq('id', user.id)
          .single();

      if (data['role'] != 'admin') {
        throw Exception('Akun bukan admin.');
      }

      if (!mounted) return;

      setState(() {
        profile = data;
        notificationsEnabled =
            data['notifications_enabled'] ?? true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('Gagal mengambil profil: $e');
    }
  }

  Future<void> editProfile() async {
    if (profile == null || updating) return;

    final controller = TextEditingController(
      text: adminName,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Profil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Admin',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      await saveProfile(controller.text.trim());
    }

    controller.dispose();
  }

  Future<void> saveProfile(String name) async {
    setState(() => updating = true);

    try {
      final user = supabase.auth.currentUser!;

      await supabase.from('profiles').update({
        'full_name': name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (!mounted) return;

      setState(() {
        profile!['full_name'] = name;
        updating = false;
      });

      message('Profil berhasil diperbarui');
    } catch (e) {
      if (!mounted) return;
      setState(() => updating = false);
      message('Gagal memperbarui profil: $e');
    }
  }

  Future<void> changePassword() async {
    final password = TextEditingController();
    final confirm = TextEditingController();

    bool obscure1 = true;
    bool obscure2 = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ganti Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: password,
                obscureText: obscure1,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure1
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscure1 = !obscure1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                obscureText: obscure2,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure2
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscure2 = !obscure2;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (password.text.length < 6 ||
                    password.text != confirm.text) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await savePassword(password.text);
    }

    password.dispose();
    confirm.dispose();
  }

  Future<void> savePassword(String value) async {
    setState(() => updating = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: value),
      );

      if (!mounted) return;

      setState(() => updating = false);
      message('Password berhasil diperbarui');
    } catch (e) {
      if (!mounted) return;
      setState(() => updating = false);
      message('Gagal mengganti password: $e');
    }
  }

  Future<void> changeNotifications(bool value) async {
    if (updating) return;

    final oldValue = notificationsEnabled;

    setState(() {
      notificationsEnabled = value;
      updating = true;
    });

    try {
      final user = supabase.auth.currentUser!;

      await supabase.from('profiles').update({
        'notifications_enabled': value,
      }).eq('id', user.id);

      if (!mounted) return;

      setState(() => updating = false);

      message(
        value
            ? 'Notifikasi diaktifkan'
            : 'Notifikasi dinonaktifkan',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        notificationsEnabled = oldValue;
        updating = false;
      });

      message('Gagal mengubah notifikasi: $e');
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotifikasiAdminScreen(),
      ),
    );
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      message('Gagal keluar: $e');
    }
  }

  void handleNavigation(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pop(context);
      return;
    }

    Widget? page;

    switch (index) {
      case 1:
        page = const KelolaBukuScreen();
        break;
      case 2:
        page = const KelolaAnggotaPage();
        break;
      case 3:
        page = const PeminjamanAdminScreen();
        break;
    }

    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: navy),
              )
            : Column(
                children: [
                  header(),
                  Expanded(
                    child: RefreshIndicator(
                      color: navy,
                      onRefresh: loadProfile,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          profileCard(),
                          const SizedBox(height: 17),
                          menuButton(
                            Icons.person_outline,
                            'Ubah Profil',
                            editProfile,
                          ),
                          const SizedBox(height: 11),
                          menuButton(
                            Icons.lock_outline,
                            'Ganti Password',
                            changePassword,
                          ),
                          const SizedBox(height: 11),
                          notificationButton(),
                          const SizedBox(height: 17),
                          logoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: selectedIndex,
        onTap: handleNavigation,
      ),
    );
  }

  Widget header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: navy,
              size: 19,
            ),
          ),
          const Expanded(
            child: Text(
              'Pengaturan Admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget profileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: navy,
            backgroundImage:
                avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menuButton(
    IconData icon,
    String title,
    VoidCallback action,
  ) {
    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(9),
      elevation: 2,
      child: InkWell(
        onTap: updating ? null : action,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 43,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget notificationButton() {
    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(9),
      elevation: 2,
      child: SizedBox(
        height: 43,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: InkWell(
                  onTap: openNotifications,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Notifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Switch(
                value: notificationsEnabled,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF65A77A),
                onChanged: updating
                    ? null
                    : changeNotifications,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget logoutButton() {
    return SizedBox(
      height: 43,
      child: OutlinedButton.icon(
        onPressed: logout,
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 17,
        ),
        label: const Text(
          'Keluar',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: cream,
          side: const BorderSide(
            color: Color(0xFFE5A09A),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }
}
