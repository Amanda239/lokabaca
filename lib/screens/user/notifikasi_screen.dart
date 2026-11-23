import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import 'denda_screen.dart';
import 'peminjaman_screen.dart';

/// Notifikasi nyata milik user yang sedang login:
/// persetujuan peminjaman, denda otomatis, dan pengingat H-1.
class NotifikasiUserScreen extends StatefulWidget {
  const NotifikasiUserScreen({super.key});

  @override
  State<NotifikasiUserScreen> createState() => _NotifikasiUserScreenState();
}

class _NotifikasiUserScreenState extends State<NotifikasiUserScreen> {
  final _db = SupabaseConfig.client;
  List<Map<String, dynamic>> _items = [];
  String _filter = 'Semua';
  bool _loading = true;

  static const filters = ['Semua', 'Belum dibaca', 'Penting'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.currentUserId;
    if (!mounted) return;
    setState(() => _loading = true);
    await NotificationService.runChecks();
    try {
      final rows = userId == null
          ? <Map<String, dynamic>>[]
          : await _db
              .from('notifications')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(100);
      if (!mounted) return;
      setState(() {
        _items = rows.map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visible {
    if (_filter == 'Belum dibaca') {
      return _items.where((item) => item['is_read'] != true).toList();
    }
    if (_filter == 'Penting') {
      return _items
          .where((item) => ['denda', 'peminjaman_ditolak'].contains(item['type']))
          .toList();
    }
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final unread = _items.where((item) => item['is_read'] != true).length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                final userId = AuthService.currentUserId;
                if (userId == null) return;
                await NotificationService.markAllRead(userId);
                await _load();
              },
              child: const Text('Baca semua',
                  style: TextStyle(fontSize: 11, color: AppColors.navy)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = filters[index];
                  final active = label == _filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ChoiceChip(
                      label: Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              color: active ? AppColors.white : AppColors.text)),
                      selected: active,
                      selectedColor: AppColors.navy,
                      backgroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.border),
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.navy))
                  : items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_none_rounded,
                                    size: 48, color: AppColors.grey),
                                SizedBox(height: 10),
                                Text('Belum ada notifikasi',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text(
                                  'Notifikasi peminjaman, denda, dan pengingat akan muncul di sini.',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontSize: 11, color: AppColors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildItem(items[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final read = item['is_read'] == true;
    final type = item['type']?.toString() ?? '';
    final icon = switch (type) {
      'denda' => Icons.payments_outlined,
      'pengingat' => Icons.schedule_rounded,
      'peminjaman_ditolak' => Icons.cancel_outlined,
      'pembayaran_denda' => Icons.receipt_long_outlined,
      _ => Icons.menu_book_outlined,
    };
    final color = switch (type) {
      'denda' || 'peminjaman_ditolak' => const Color(0xFFC0392B),
      'pengingat' => const Color(0xFFB7791F),
      _ => AppColors.navy,
    };
    final message = _cleanMessage(item['message']?.toString() ?? '');

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        await NotificationService.markRead('${item['id']}');
        if (!mounted) return;
        if (type == 'denda' || type == 'pembayaran_denda') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DendaScreen()));
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PeminjamanScreen()));
        }
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: read ? AppColors.border : AppColors.yellow),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']?.toString() ?? 'Notifikasi',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  read ? FontWeight.w600 : FontWeight.w800),
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(message,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.text, height: 1.35)),
                  const SizedBox(height: 5),
                  Text(_time(item['created_at']),
                      style: const TextStyle(fontSize: 9, color: AppColors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Buang prefix `[dedupe-key]` yang dipakai untuk mencegah duplikat.
  static String _cleanMessage(String text) {
    final start = text.indexOf('] ');
    return (start >= 0 && text.startsWith('[')) ? text.substring(start + 2) : text;
  }

  static String _time(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date.toLocal());
    } catch (_) {
      return date.toLocal().toString().substring(0, 16);
    }
  }
}
