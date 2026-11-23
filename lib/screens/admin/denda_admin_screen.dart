import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/book_cover.dart';
import 'admin_bottom_navigation.dart';
import 'dashboard_admin.dart';
import 'kelola_anggota.dart';
import 'kelola_buku.dart';
import 'peminjaman_admin.dart';
import 'profile_admin.dart';

/// Halaman denda admin: rekap seluruh denda peminjaman dan konfirmasi
/// permintaan pembayaran denda dari anggota.
class DendaAdminScreen extends StatefulWidget {
  const DendaAdminScreen({super.key});

  @override
  State<DendaAdminScreen> createState() => _DendaAdminScreenState();
}

class _DendaAdminScreenState extends State<DendaAdminScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  static const int pageSize = 10;
  static const List<String> filters = [
    'Semua',
    'Belum Dibayar',
    'Lunas',
  ];

  List<Map<String, dynamic>> fines = [];
  List<Map<String, dynamic>> pendingPayments = [];

  bool isLoading = true;
  bool isProcessing = false;
  int selectedFilter = 0;
  int page = 1;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    // Pastikan denda keterlambatan tersimpan sebelum data dibaca.
    await NotificationService.runChecks();

    try {
      final rows = await supabase
          .from('borrowings')
          .select(
            'id,user_id,book_id,borrowed_at,due_date,returned_at,status,'
            'fine_amount,fine_paid,fine_paid_at,created_at',
          )
          .order('created_at', ascending: false);

      final borrowings = List<Map<String, dynamic>>.from(rows);
      final bookIds = borrowings
          .map((row) => row['book_id'])
          .where((id) => id != null)
          .toSet()
          .toList();
      final userIds = borrowings
          .map((row) => row['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> bookMap = {};
      final Map<String, Map<String, dynamic>> profileMap = {};

      if (bookIds.isNotEmpty) {
        final books = await supabase
            .from('books')
            .select('id,title,author,cover_url')
            .inFilter('id', bookIds);
        for (final book in books) {
          bookMap['${book['id']}'] = Map<String, dynamic>.from(book);
        }
      }
      if (userIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id,full_name,nis')
            .inFilter('id', userIds);
        for (final profile in profiles) {
          profileMap['${profile['id']}'] =
              Map<String, dynamic>.from(profile);
        }
      }

      final merged = borrowings.where(_hasFine).map((row) {
        final book = bookMap[row['book_id']?.toString()];
        final profile = profileMap[row['user_id']?.toString()];
        return <String, dynamic>{
          ...row,
          'book_title': book?['title'] ?? 'Buku tidak ditemukan',
          'book_author': book?['author'] ?? '-',
          'book_cover': book?['cover_url'],
          'member_name': profile?['full_name'] ?? 'Anggota tidak ditemukan',
          'member_nis': profile?['nis'] ?? '-',
        };
      }).toList();

      final adminId = AuthService.currentUserId;
      final notificationQuery = supabase
          .from('notifications')
          .select('id,user_id,title,message,type,is_read,created_at')
          .eq('type', 'pembayaran_denda')
          .eq('is_read', false);

      final notificationRows = adminId == null
          ? await notificationQuery.order('created_at', ascending: false)
          : await notificationQuery
              .eq('user_id', adminId)
              .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        fines = merged;
        // Tanpa sesi admin, hanya baris warisan (user_id null) yang ditampilkan.
        pendingPayments = adminId == null
            ? notificationRows
                .where((row) => row['user_id'] == null)
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
            : List<Map<String, dynamic>>.from(notificationRows);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Gagal memuat data denda: $e');
    }
  }

  bool _hasFine(Map<String, dynamic> row) => effectiveFine(row) > 0;

  double effectiveFine(Map<String, dynamic> row) {
    final stored = num.tryParse(row['fine_amount']?.toString() ?? '');
    if (stored != null && stored > 0) return stored.toDouble();
    return (lateDays(row) * NotificationService.finePerDay).toDouble();
  }

  int lateDays(Map<String, dynamic> row) {
    final due = DateTime.tryParse(row['due_date']?.toString() ?? '');
    if (due == null) return 0;
    final returned = DateTime.tryParse(row['returned_at']?.toString() ?? '');
    final end = returned ?? DateTime.now();
    final days = DateTime(end.year, end.month, end.day)
        .difference(DateTime(due.year, due.month, due.day))
        .inDays;
    return days > 0 ? days : 0;
  }

  bool isPaid(Map<String, dynamic> row) => row['fine_paid'] == true;

  List<Map<String, dynamic>> get filteredFines {
    if (selectedFilter == 1) {
      return fines.where((row) => !isPaid(row)).toList();
    }
    if (selectedFilter == 2) {
      return fines.where(isPaid).toList();
    }
    return fines;
  }

  int get unpaidCount => fines.where((row) => !isPaid(row)).length;
  int get paidCount => fines.length - unpaidCount;

  List<Map<String, dynamic>> get pagedFines {
    final data = filteredFines;
    final pages = totalPages;
    if (page > pages) page = pages;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, data.length);
    if (start >= data.length) return const <Map<String, dynamic>>[];
    return data.sublist(start, end);
  }

  int get totalPages {
    final count = filteredFines.length;
    return count == 0 ? 1 : ((count + pageSize - 1) / pageSize).ceil();
  }

  String cleanMessage(String text) {
    final index = text.indexOf('] ');
    if (text.startsWith('[') && index >= 0) {
      return text.substring(index + 2);
    }
    return text;
  }

  String formatMoney(num value) {
    final digits = value.toInt().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }

  void showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> markPaid(Map<String, dynamic> row) async {
    if (isProcessing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          'Tandai denda lunas?',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Denda ${formatMoney(effectiveFine(row))} untuk '
          '${row['member_name'] ?? '-'} akan ditandai lunas.',
          style: const TextStyle(color: AppColors.text, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => isProcessing = true);
    try {
      await supabase.from('borrowings').update({
        'fine_amount': effectiveFine(row),
        'fine_paid': true,
        'fine_paid_at': DateTime.now().toIso8601String(),
      }).eq('id', row['id']);
      if (!mounted) return;
      showMessage('Pembayaran denda dikonfirmasi.');
      await loadData();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mengonfirmasi denda: $e');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> adjustFine(Map<String, dynamic> row) async {
    final controller = TextEditingController(
      text: effectiveFine(row).toStringAsFixed(0),
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          'Ubah Nominal Denda',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.navy, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Nominal denda',
            prefixText: 'Rp ',
            filled: true,
            fillColor: AppColors.input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount < 0) {
                Navigator.pop(ctx, false);
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    final amount = double.tryParse(controller.text.trim());
    controller.dispose();

    if (confirm != true || amount == null || !mounted) return;
    setState(() => isProcessing = true);
    try {
      await supabase
          .from('borrowings')
          .update({'fine_amount': amount})
          .eq('id', row['id']);
      if (!mounted) return;
      showMessage('Nominal denda diperbarui.');
      await loadData();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mengubah denda: $e');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> approvePayment(
    Map<String, dynamic> notification,
    Map<String, dynamic>? row,
  ) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);
    try {
      if (row != null) {
        await supabase.from('borrowings').update({
          'fine_amount': effectiveFine(row),
          'fine_paid': true,
          'fine_paid_at': DateTime.now().toIso8601String(),
        }).eq('id', row['id']);
      }
      await NotificationService.markRead('${notification['id']}');
      if (!mounted) return;
      showMessage(row == null
          ? 'Notifikasi pembayaran ditandai dibaca.'
          : 'Pembayaran denda berhasil dikonfirmasi.');
      await loadData();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mengonfirmasi pembayaran: $e');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Map<String, dynamic>? borrowingOf(Map<String, dynamic> notification) {
    final match = RegExp(r'#(\d+)').firstMatch(
      notification['message']?.toString() ?? '',
    );
    if (match == null) return null;
    final id = match.group(1);
    for (final fine in fines) {
      if ('${fine['id']}' == id) return fine;
    }
    return null;
  }

  void handleNavigation(int index) {
    if (index == 4) return;
    final Widget page = switch (index) {
      0 => const DashboardAdmin(),
      1 => const KelolaBukuScreen(),
      2 => const KelolaAnggotaPage(),
      3 => const PeminjamanAdminScreen(),
      5 => const ProfileAdminScreen(),
      _ => const DashboardAdmin(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (pendingPayments.isNotEmpty && !isLoading)
              _pendingSection(),
            _filters(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    )
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: loadData,
                      child: pagedFines.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 90),
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 44,
                                  color: AppColors.grey,
                                ),
                                const SizedBox(height: 10),
                                const Center(
                                  child: Text(
                                    'Belum ada data denda',
                                    style: TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: pagedFines.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) =>
                                  _fineCard(pagedFines[index]),
                            ),
                    ),
            ),
            _pagination(),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: 4,
        onTap: handleNavigation,
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
              size: 19,
            ),
          ),
          const Expanded(
            child: Text(
              'Denda',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pending_actions_rounded,
                color: AppColors.navy,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                'Menunggu konfirmasi (${pendingPayments.length})',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pendingPayments.map((notification) {
            final row = borrowingOf(notification);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${row?['member_name'] ?? 'Anggota'} · '
                      '${formatMoney(effectiveFine(row ?? notification))}\n'
                      '${cleanMessage(notification['message']?.toString() ?? '')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  MaterialButton(
                    minWidth: 0,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.navy,
                    textColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () => approvePayment(notification, row),
                    child: const Text(
                      'Setujui',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...List.generate(filters.length, (index) {
            final selected = selectedFilter == index;
            final count = index == 0
                ? fines.length
                : index == 1
                    ? unpaidCount
                    : paidCount;
            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(
                  '${filters[index]} ($count)',
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.navy,
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.border),
                onSelected: (_) {
                  setState(() {
                    selectedFilter = index;
                    page = 1;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _fineCard(Map<String, dynamic> row) {
    final amount = effectiveFine(row);
    final paid = isPaid(row);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          BookCover(
            imageUrl: row['book_cover']?.toString(),
            width: 38,
            height: 54,
            radius: 6,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['book_title']?.toString() ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row['member_name']?.toString() ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      formatMoney(amount),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: paid
                            ? AppColors.cream
                            : const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        paid ? 'Lunas' : 'Belum dibayar',
                        style: TextStyle(
                          color: paid
                              ? AppColors.grey
                              : const Color(0xFFB83232),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (!paid)
            IconButton(
              tooltip: 'Tandai lunas',
              onPressed: isProcessing ? null : () => markPaid(row),
              icon: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF315F46),
                size: 20,
              ),
            ),
          IconButton(
            tooltip: 'Ubah nominal',
            onPressed: isProcessing ? null : () => adjustFine(row),
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.navy,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    if (filteredFines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1
                ? () => setState(() => page--)
                : null,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.navy,
            ),
          ),
          Text(
            'Halaman $page dari $totalPages',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: page < totalPages
                ? () => setState(() => page++)
                : null,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
