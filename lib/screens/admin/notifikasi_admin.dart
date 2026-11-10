
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_bottom_navigation.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';
import 'pengaturan_admin.dart';

class NotifikasiAdminScreen extends StatefulWidget {
  const NotifikasiAdminScreen({super.key});

  @override
  State<NotifikasiAdminScreen> createState() =>
      _NotifikasiAdminScreenState();
}

class _NotifikasiAdminScreenState
    extends State<NotifikasiAdminScreen> {
  final supabase = Supabase.instance.client;

  static const navy = Color(0xFF2E4057);
  static const cream = Color(0xFFF8F4EA);
  static const muted = Color(0xFF8993A1);
  static const border = Color(0xFFCBD0D7);

  List<Map<String, dynamic>> notifications = [];

  bool loading = true;
  bool showUnreadOnly = false;

  int selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    loadNotifications();
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

  Future<void> loadNotifications() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final response = await supabase
          .from('notifications')
          .select(
            'id, title, message, type, is_read, created_at',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        notifications =
            List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      message('Gagal mengambil notifikasi: $e');
    }
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (!showUnreadOnly) return notifications;

    return notifications.where((item) {
      return item['is_read'] == false;
    }).toList();
  }

  int get unreadCount {
    return notifications.where((item) {
      return item['is_read'] == false;
    }).length;
  }

  Future<void> markAsRead(
    Map<String, dynamic> item,
  ) async {
    if (item['is_read'] == true) return;

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', item['id']);

      if (!mounted) return;

      setState(() {
        item['is_read'] = true;
      });
    } catch (e) {
      message('Gagal memperbarui notifikasi: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false);

      if (!mounted) return;

      setState(() {
        for (final item in notifications) {
          item['is_read'] = true;
        }
      });

      message('Semua notifikasi sudah dibaca');
    } catch (e) {
      message('Gagal memperbarui notifikasi: $e');
    }
  }

  IconData notificationIcon(String? type) {
    switch (type) {
      case 'borrowing':
        return Icons.menu_book_rounded;
      case 'overdue':
        return Icons.warning_amber_rounded;
      case 'member':
        return Icons.person_add_alt_1_rounded;
      case 'returned':
        return Icons.assignment_return_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color notificationColor(String? type) {
    switch (type) {
      case 'overdue':
        return Colors.redAccent;
      case 'member':
        return const Color(0xFF65A77A);
      case 'returned':
        return const Color(0xFF4787A8);
      default:
        return navy;
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    final local = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day ${months[local.month - 1]} '
        '${local.year} - $hour:$minute';
  }

  Future<void> openNotification(
    Map<String, dynamic> item,
  ) async {
    await markAsRead(item);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          item['title']?.toString() ?? 'Notifikasi',
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['message']?.toString() ?? '-',
              style: const TextStyle(
                color: navy,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              formatDate(item['created_at']),
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(color: navy),
            ),
          ),
        ],
      ),
    );
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
      case 4:
        page = const PengaturanAdminScreen();
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
    final data = filteredNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            header(),
            tabButtons(),
            const SizedBox(height: 15),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: navy,
                      ),
                    )
                  : data.isEmpty
                      ? emptyState()
                      : RefreshIndicator(
                          color: navy,
                          onRefresh: loadNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              20,
                            ),
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              return notificationCard(data[index]);
                            },
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
              'Notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: unreadCount == 0 ? null : markAllAsRead,
            icon: const Icon(
              Icons.done_all_rounded,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget tabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: tabButton(
              'Semua',
              !showUnreadOnly,
              () {
                setState(() => showUnreadOnly = false);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: tabButton(
              'Belum Dibaca ($unreadCount)',
              showUnreadOnly,
              () {
                setState(() => showUnreadOnly = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget tabButton(
    String title,
    bool selected,
    VoidCallback action,
  ) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? navy : Colors.white,
          foregroundColor: selected ? Colors.white : navy,
          side: const BorderSide(color: navy),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: FittedBox(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget notificationCard(Map<String, dynamic> item) {
    final type = item['type']?.toString();
    final color = notificationColor(type);
    final isRead = item['is_read'] == true;

    return InkWell(
      onTap: () => openNotification(item),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFFFAFBFD),
          border: Border.all(
            color: isRead ? border : navy.withOpacity(0.55),
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: navy,
                shape: BoxShape.circle,
              ),
              child: Icon(
                notificationIcon(type),
                color: color == navy ? Colors.white : color,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? 'Notifikasi',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['message']?.toString() ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(item['created_at']),
                    style: const TextStyle(
                      color: muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4787A8),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    return RefreshIndicator(
      color: navy,
      onRefresh: loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: cream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: navy,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    showUnreadOnly
                        ? 'Tidak ada notifikasi baru'
                        : 'Belum ada notifikasi',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Notifikasi aktivitas akan muncul di sini.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
