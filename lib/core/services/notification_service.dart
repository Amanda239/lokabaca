import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Pusat notifikasi & denda otomatis.
///
/// Dipanggil sekali saat aplikasi jalan (lihat `main.dart`) dan bisa dipanggil
/// ulang dari pull-to-refresh. Semua data ditulis ke tabel Supabase nyata:
/// `notifications`, `borrowings`, `profiles` dan `books`.
class NotificationService {
  NotificationService._();

  static final SupabaseClient _db = SupabaseConfig.client;
  static Timer? _timer;
  static bool _started = false;
  static Future<void>? _running;

  /// Tarif denda sesuai kebijakan LokaBaca: Rp1.000 per hari.
  static const int finePerDay = 1000;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    await runChecks();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => runChecks());
  }

  /// Sinkronisasi denda keterlambatan + pengingat H-1.
  static Future<void> runChecks() {
    final active = _running;
    if (active != null) return active;
    _running = _runChecks().whenComplete(() => _running = null);
    return _running!;
  }

  static Future<void> _runChecks() async {
    await syncOverdueFines();
    await sendDueReminders();
  }

  /// Denda otomatis: setiap peminjaman yang sudah lewat jatuh tempo dan belum
  /// dikembalikan akan mendapat `fine_amount = jumlah hari telat * 1000`.
  /// Notifikasi hanya dibuat sekali per peminjaman.
  static Future<void> syncOverdueFines() async {
    try {
      final now = DateTime.now().toUtc();
      final rows = await _db
          .from('borrowings')
          .select(
            'id,user_id,book_id,due_date,fine_amount,returned_at,status',
          )
          .isFilter('returned_at', null)
          .lt('due_date', now.toIso8601String());

      for (final row in rows) {
        final due = _dateOf(row['due_date']);
        if (due == null) continue;
        final currentFine = _number(row['fine_amount']);
        if (currentFine > 0) continue;

        final days = ((now.difference(due).inMinutes / 1440).ceil()).clamp(1, 365);
        final amount = days * finePerDay;
        final id = row['id'];

        try {
          final update = <String, dynamic>{'fine_amount': amount.toDouble()};
          final status = row['status']?.toString().toLowerCase() ?? '';
          if (status == 'dipinjam' || status == 'borrowed') {
            update['status'] = 'Terlambat';
          }
          await _db.from('borrowings').update(update).eq('id', id);
        } catch (_) {
          // Baris mungkin berubah dari perangkat lain; coba lagi berikutnya.
          continue;
        }

        await createNotification(
          userId: '${row['user_id']}',
          title: 'Denda keterlambatan',
          message:
              'Peminjaman #$_shortId(id) melewati batas waktu ($days hari). '
              'Denda ${_rupiah(amount)} otomatis tercatat.',
          type: 'denda',
          dedupeKey: 'denda-$id',
        );
      }
    } catch (_) {
      // Jangan biarkan kegagalan sinkronisasi mengganggu aplikasi.
    }
  }

  /// Pengingat 1 hari sebelum jatuh tempo, hanya sekali per hari.
  static Future<void> sendDueReminders() async {
    try {
      final now = DateTime.now().toUtc();
      final limit = now.add(const Duration(hours: 24));
      final rows = await _db
          .from('borrowings')
          .select('id,user_id,book_id,due_date,returned_at,status')
          .isFilter('returned_at', null)
          .gte('due_date', now.toIso8601String())
          .lte('due_date', limit.toIso8601String());

      for (final row in rows) {
        final due = _dateOf(row['due_date']);
        if (due == null) continue;
        final id = row['id'];
        await createNotification(
          userId: '${row['user_id']}',
          title: 'Pengingat peminjaman',
          message:
              'Peminjaman #$_shortId(id) jatuh tempo besok ('
              '${_formatDate(due)}). Kembalikan tepat waktu agar tidak kena denda.',
          type: 'pengingat',
          dedupeKey: 'pengingat-$id-${_dateKey(now)}',
        );
      }
    } catch (_) {}
  }

  /// Notifikasi saat admin menyetujui / menolak peminjaman atau konfirmasi
  /// pengembalian. Dipanggil dari layar admin setelah RPC selesai.
  static Future<void> notifyBorrowingStatus(String borrowingId, String status) async {
    final normalized = status.trim().toLowerCase();
    final title = switch (normalized) {
      'dipinjam' || 'disetujui' || 'approved' => 'Peminjaman disetujui',
      'ditolak' || 'rejected' => 'Peminjaman ditolak',
      'selesai' || 'dikembalikan' || 'returned' => 'Pengembalian dikonfirmasi',
      _ => 'Status peminjaman diperbarui',
    };
    final type = switch (normalized) {
      'ditolak' || 'rejected' => 'peminjaman_ditolak',
      'selesai' || 'dikembalikan' || 'returned' => 'pengembalian',
      _ => 'peminjaman',
    };

    try {
      final borrowing = await _db
          .from('borrowings')
          .select('user_id,book_id')
          .eq('id', borrowingId)
          .maybeSingle();
      if (borrowing == null) return;
      await createNotification(
        userId: '${borrowing['user_id']}',
        title: title,
        message: 'Peminjaman #${_shortId(borrowingId)}: '
            '${title.toLowerCase()}.',
        type: type,
        dedupeKey: 'status-$borrowingId-$normalized-${_dateKey(DateTime.now())}',
      );
    } catch (_) {}
  }

  /// User mengirim bukti pembayaran denda -> admin yang dapat konfirmasi.
  static Future<void> notifyPaymentPending({
    required String borrowingId,
    required double amount,
    String? reference,
  }) async {
    final admins = await _adminIds();
    for (final adminId in admins) {
      await createNotification(
        userId: adminId,
        title: 'Konfirmasi pembayaran denda',
        message:
            'Peminjaman #$_shortId(borrowingId) mengirim bukti bayar denda '
            '${_rupiah(amount)}${reference == null || reference.isEmpty ? '' : ' (ref: $reference)'}. '
            'Mohon diverifikasi.',
        type: 'pembayaran_denda',
        dedupeKey: 'bayar-$borrowingId-${_dateKey(DateTime.now())}',
      );
    }
  }

  /// Pengajuan peminjaman baru masuk ke notifikasi admin untuk diproses.
  static Future<void> notifyNewLoanRequest(String borrowingId) async {
    final admins = await _adminIds();
    for (final adminId in admins) {
      await createNotification(
        userId: adminId,
        title: 'Pengajuan peminjaman baru',
        message: 'Peminjaman #$_shortId(borrowingId) menunggu persetujuan admin.',
        type: 'peminjaman',
        dedupeKey: 'pengajuan-$borrowingId',
      );
    }
  }

  static Future<List<String>> _adminIds() async {
    try {
      final rows = await _db.from('profiles').select('id').eq('role', 'admin');
      return rows.map((row) => '${row['id']}').toList();
    } catch (_) {
      return const <String>[];
    }
  }

  /// Insert notifikasi. [dedupeKey] disimpan di awal pesan supaya pengingat
  /// yang sama tidak menumpuk saat aplikasi dibuka berkali-kali.
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? dedupeKey,
  }) async {
    if (userId.isEmpty || userId == 'null') return;
    final today = DateTime.now().toUtc();
    final start = DateTime.utc(today.year, today.month, today.day);
    try {
      if (dedupeKey != null) {
        final existing = await _db
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('type', type)
            .gte('created_at', start.toIso8601String())
            .like('message', '$dedupeKey%');
        if (existing.isNotEmpty) return;
      }
      await _db.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': dedupeKey == null ? message : '[$dedupeKey] $message',
        'type': type,
        'is_read': false,
      });
    } catch (_) {}
  }

  static Future<void> markRead(String notificationId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  static Future<void> markAllRead(String userId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true}).eq('user_id', userId);
    } catch (_) {}
  }

  static int _number(dynamic value) =>
      num.tryParse(value?.toString() ?? '')?.toInt() ?? 0;

  static DateTime? _dateOf(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _formatDate(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  static String _shortId(dynamic id) {
    final text = id?.toString() ?? '';
    return text.length > 8 ? text.substring(0, 8) : text;
  }

  static String _rupiah(num amount) {
    final digits = amount.toInt().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }
}
