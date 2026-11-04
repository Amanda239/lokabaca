
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KelolaAnggotaPage extends StatefulWidget {
  const KelolaAnggotaPage({super.key});

  @override
  State<KelolaAnggotaPage> createState() => _KelolaAnggotaPageState();
}

class _KelolaAnggotaPageState extends State<KelolaAnggotaPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> anggota = [];
  bool isLoading = true;
  String keyword = '';

  static const Color navy = Color(0xFF182B49);
  static const Color cream = Color(0xFFF8F4E9);
  static const Color yellow = Color(0xFFF4C95D);

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

  Future<void> loadAnggota() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('profiles')
          .select('id, full_name, email, nis, status, avatar_url')
          .eq('role', 'anggota')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        anggota = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Gagal mengambil data anggota: $e');
    }
  }

  List<Map<String, dynamic>> get filteredAnggota {
    final search = keyword.toLowerCase();

    return anggota.where((item) {
      final nama = (item['full_name'] ?? '').toString().toLowerCase();
      final email = (item['email'] ?? '').toString().toLowerCase();
      final nis = (item['nis'] ?? '').toString().toLowerCase();

      return nama.contains(search) ||
          email.contains(search) ||
          nis.contains(search);
    }).toList();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
              backgroundColor: cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
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
                    item['full_name'] ?? 'Tanpa nama',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Nomor Induk Siswa (NIS)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nisController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan NIS',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Status Anggota'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
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

  Future<void> saveAnggota({
    required String id,
    required String nis,
    required String status,
  }) async {
    try {
      await supabase.from('profiles').update({
        'nis': nis.isEmpty ? null : nis,
        'status': status,
      }).eq('id', id);

      if (!mounted) return;

      showMessage('Data anggota berhasil diperbarui');
      await loadAnggota();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal memperbarui data: $e');
    }
  }

  Future<void> changeStatus(Map<String, dynamic> item) async {
    final currentStatus = item['status'] ?? 'Aktif';
    final newStatus =
        currentStatus == 'Aktif' ? 'Non Aktif' : 'Aktif';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Status Anggota'),
        content: Text(
          'Ubah status ${item['full_name']} menjadi $newStatus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await saveAnggota(
        id: item['id'].toString(),
        nis: item['nis']?.toString() ?? '',
        status: newStatus,
      );
    }
  }

  Widget buildAvatar(Map<String, dynamic> item) {
    final name = (item['full_name'] ?? 'A').toString();
    final avatarUrl = item['avatar_url']?.toString();

    return CircleAvatar(
      radius: 25,
      backgroundColor: yellow,
      backgroundImage:
          avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            )
          : null,
    );
  }

  Widget buildAnggotaCard(Map<String, dynamic> item) {
    final nama = item['full_name'] ?? 'Tanpa nama';
    final email = item['email'] ?? '-';
    final nis = item['nis'] ?? 'Belum diisi';
    final status = item['status'] ?? 'Aktif';
    final isActive = status == 'Aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              buildAvatar(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama.toString(),
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toString(),
                  style: TextStyle(
                    color: isActive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                color: navy,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'NIS: $nis',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit anggota',
                onPressed: () => editAnggota(item),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: navy,
                ),
              ),
              IconButton(
                tooltip: 'Ubah status',
                onPressed: () => changeStatus(item),
                icon: const Icon(
                  Icons.swap_horiz,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredAnggota;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Anggota',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadAnggota,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Anggota',
                style: TextStyle(
                  color: navy,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Kelola informasi anggota perpustakaan',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() => keyword = value);
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama, NIS, atau email...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: navy,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    color: navy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total anggota: ${anggota.length}',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: navy,
                        ),
                      )
                    : data.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 55,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  keyword.isEmpty
                                      ? 'Belum ada anggota'
                                      : 'Anggota tidak ditemukan',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadAnggota,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                return buildAnggotaCard(data[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
