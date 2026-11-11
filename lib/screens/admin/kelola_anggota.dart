
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_bottom_navigation.dart';
import 'dashboard_admin.dart';
import 'kelola_buku.dart';
import 'peminjaman_admin.dart';
import 'profile_admin.dart';

class KelolaAnggotaPage extends StatefulWidget {
  const KelolaAnggotaPage({super.key});

  @override
  State<KelolaAnggotaPage> createState() => _KelolaAnggotaPageState();
}

class _KelolaAnggotaPageState extends State<KelolaAnggotaPage> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color mutedText = Color(0xFF9299A3);
  static const Color borderColor = Color(0xFF50647D);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> anggota = [];

  bool isLoading = true;
  String? errorMessage;
  String keyword = '';

  int selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    loadAnggota();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // MESSAGE

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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

  // FETCH ANGGOTA FROM SUPABASE

  Future<void> loadAnggota() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await supabase
          .from('profiles')
          .select(
            'id, full_name, email, nis, status, avatar_url, created_at',
          )
          .eq('role', 'anggota')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        anggota = List<Map<String, dynamic>>.from(response);
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

  // SEARCH

  List<Map<String, dynamic>> get filteredAnggota {
    final search = keyword.trim().toLowerCase();

    if (search.isEmpty) return anggota;

    return anggota.where((item) {
      final nama =
          (item['full_name'] ?? '').toString().toLowerCase();

      final email =
          (item['email'] ?? '').toString().toLowerCase();

      final nis =
          (item['nis'] ?? '').toString().toLowerCase();

      return nama.contains(search) ||
          email.contains(search) ||
          nis.contains(search);
    }).toList();
  }

  // BOTTOM NAVIGATION

  Future<void> handleBottomNavigation(int index) async {
    if (index == selectedIndex) return;

    if (index < 0 || index > 4) return;

    Widget? page;

    switch (index) {
      case 0:
        page = const DashboardAdmin();
        break;

      case 1:
        page = const KelolaBukuScreen();
        break;

      case 2:
        setState(() {
          selectedIndex = 2;
        });
        return;

      case 3:
        page = const PeminjamanAdminScreen();
        break;

      case 4:
        page = const AdminProfileScreen();
        break;
    }

    if (page == null) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => page!,
      ),
    );
  }

  // EDIT ANGGOTA

  Future<void> editAnggota(Map<String, dynamic> item) async {
    final nisController = TextEditingController(
      text: item['nis']?.toString() ?? '',
    );

    String status = item['status']?.toString() ?? 'Aktif';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Anggota',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['full_name']?.toString() ?? 'Tanpa nama',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Nomor Induk Siswa (NIS)',
                    style: TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),

                  TextField(
                    controller: nisController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan NIS',
                      filled: true,
                      fillColor: cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: borderColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Status Anggota',
                    style: TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),

                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: borderColor,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Aktif',
                        child: Text('Aktif'),
                      ),
                      DropdownMenuItem(
                        value: 'Non Aktif',
                        child: Text('Non Aktif'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          status = value;
                        });
                      }
                    },
                  ),
                ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await saveAnggota(
        id: item['id'].toString(),
        nis: nisController.text.trim(),
        status: status,
      );
    }

    nisController.dispose();
  }

  // SAVE ANGGOTA

  Future<void> saveAnggota({
    required String id,
    required String nis,
    required String status,
  }) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({
            'nis': nis.isEmpty ? null : nis,
            'status': status,
          })
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception(
          'Data tidak berhasil diperbarui. Periksa izin UPDATE (RLS).',
        );
      }

      if (!mounted) return;

      setState(() {
        final index = anggota.indexWhere(
          (item) => item['id'].toString() == id,
        );

        if (index != -1) {
          anggota[index] = response;
        }
      });

      showMessage('Data anggota berhasil diperbarui');
    } catch (e) {
      showMessage('Gagal memperbarui data: $e');
    }
  }

  // DELETE ANGGOTA

  Future<void> deleteAnggota(Map<String, dynamic> item) async {
    final nama = item['full_name']?.toString() ?? 'anggota ini';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Anggota',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Yakin ingin menghapus data $nama?',
            style: const TextStyle(
              color: navy,
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
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('profiles')
          .delete()
          .eq('id', item['id']);

      if (!mounted) return;

      setState(() {
        anggota.removeWhere(
          (member) =>
              member['id'].toString() == item['id'].toString(),
        );
      });

      showMessage('Data anggota berhasil dihapus');
    } catch (e) {
      showMessage('Gagal menghapus anggota: $e');
    }
  }

  // AVATAR

  Widget buildAvatar(Map<String, dynamic> item) {
    final avatarUrl = item['avatar_url']?.toString() ?? '';

    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        color: navy,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _defaultAvatar();
                },
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return const Icon(
      Icons.person,
      color: Colors.white,
      size: 48,
    );
  }

  // STATUS BADGE

  Widget buildStatusBadge(String status) {
    final isActive = status.toLowerCase() == 'aktif';

    final backgroundColor = isActive
        ? const Color(0xFFDDEFE1)
        : const Color(0xFFFFE0E0);

    final foregroundColor = isActive
        ? const Color(0xFF315E3C)
        : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // MEMBER CARD

  Widget buildAnggotaCard(Map<String, dynamic> item) {
    final nama = item['full_name']?.toString() ?? 'Tanpa nama';
    final nis = item['nis']?.toString() ?? 'Belum diisi';
    final status = item['status']?.toString() ?? 'Aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: borderColor,
          width: 0.9,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          buildAvatar(item),
          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIS : $nis',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                buildStatusBadge(status),
              ],
            ),
          ),

          const SizedBox(width: 5),

          IconButton(
            tooltip: 'Edit anggota',
            onPressed: () => editAnggota(item),
            icon: const Icon(
              Icons.edit_outlined,
              color: navy,
              size: 20,
            ),
          ),

          InkWell(
            onTap: () => deleteAnggota(item),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEFF0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF5364),
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HEADER

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
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
              'Kelola Anggota',
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

  // SEARCH BAR

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 39,
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              keyword = value;
            });
          },
          style: const TextStyle(
            color: navy,
            fontSize: 11,
          ),
          decoration: InputDecoration(
            hintText: 'Cari Nama, NIS atau Email...',
            hintStyle: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 10,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: navy,
              size: 21,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: borderColor,
                width: 0.9,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: borderColor,
                width: 0.9,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: navy,
                width: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget buildEmptyState() {
    final isSearching = keyword.trim().isNotEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            color: const Color(0xFFB8C0CA),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Anggota tidak ditemukan'
                : 'Belum ada anggota',
            style: const TextStyle(
              color: navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isSearching
                ? 'Coba gunakan kata kunci lain.'
                : 'Data anggota akan ditampilkan di sini.',
            style: const TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ERROR STATE

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: navy,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Data anggota gagal dimuat',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: loadAnggota,
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

  Widget buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: navy,
          strokeWidth: 2.5,
        ),
      );
    }

    if (errorMessage != null) {
      return buildErrorState();
    }

    final data = filteredAnggota;

    if (data.isEmpty) {
      return RefreshIndicator(
        color: navy,
        onRefresh: loadAnggota,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 400,
              child: buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: navy,
      onRefresh: loadAnggota,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return buildAnggotaCard(data[index]);
        },
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            buildSearchBar(),
            const SizedBox(height: 1),
            Expanded(
              child: buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: selectedIndex,
        onTap: handleBottomNavigation,
      ),
    );
  }
}
