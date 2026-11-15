import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';

// =====================================================
// HALAMAN DENDA SAYA (USER)
// Mengikuti desain Figma "Denda":
//   1. Dialog "Pembayaran Berhasil!"
//   2. Halaman "Denda Saya"
//   3. Dialog "Pembayaran Denda" (QR)
// =====================================================

enum FineStatus { belumBayar, menunggu, lunas }

class FineItem {
  final String title;
  final String author;
  final String cover;
  final DateTime dueDate;
  final int lateDays;
  final int feePerDay;
  final String borrowerName;
  final String borrowerId;
  final FineStatus status;

  const FineItem({
    required this.title,
    required this.author,
    required this.cover,
    required this.dueDate,
    required this.lateDays,
    required this.feePerDay,
    required this.borrowerName,
    required this.borrowerId,
    required this.status,
  });

  int get amount => lateDays * feePerDay;

  FineItem copyWith({FineStatus? status}) {
    return FineItem(
      title: title,
      author: author,
      cover: cover,
      dueDate: dueDate,
      lateDays: lateDays,
      feePerDay: feePerDay,
      borrowerName: borrowerName,
      borrowerId: borrowerId,
      status: status ?? this.status,
    );
  }
}

class DendaScreen extends StatefulWidget {
  const DendaScreen({super.key});

  @override
  State<DendaScreen> createState() => _DendaScreenState();
}

class _DendaScreenState extends State<DendaScreen> {
  // WARNA KHUSUS HALAMAN DENDA
  static const Color _cardYellow = Color(0xFFF9D68C);
  static const Color _orange = Color(0xFFF08A24);
  static const Color _darkText = Color(0xFF1E2A38);

  int selectedTab = 0;

  // Total denda sesuai desain Figma (Rp 15.000).
  // TODO: setelah terhubung ke Supabase, ganti dengan hasil penjumlahan
  // denda dari daftar `fines` yang belum lunas.
  int totalUnpaid = 15000;

  // DATA CONTOH (sama seperti desain Figma)
  // TODO: ganti dengan data dari Supabase.
  List<FineItem> fines = [
    FineItem(
      title: 'Hujan',
      author: 'Tere Liye',
      cover: 'assets/images/hujan.jpeg',
      dueDate: DateTime(2027, 4, 17),
      lateDays: 3,
      feePerDay: 1000,
      borrowerName: 'Nasya A.',
      borrowerId: 'A-023',
      status: FineStatus.belumBayar,
    ),
    FineItem(
      title: 'Hujan',
      author: 'Tere Liye',
      cover: 'assets/images/hujan.jpeg',
      dueDate: DateTime(2027, 4, 17),
      lateDays: 3,
      feePerDay: 1000,
      borrowerName: 'Nasya A.',
      borrowerId: 'A-023',
      status: FineStatus.menunggu,
    ),
  ];

  List<FineItem> get unpaidFines =>
      fines.where((f) => f.status != FineStatus.lunas).toList();

  List<FineItem> get paidFines =>
      fines.where((f) => f.status == FineStatus.lunas).toList();

  List<FineItem> get currentFines => selectedTab == 0 ? unpaidFines : paidFines;

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final list = currentFines;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(19, 16, 19, 28),
              children: [
                _buildTotalCard(),
                const SizedBox(height: 20),
                _buildTabs(),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  _buildEmptyState()
                else
                  ...list.map(
                    (fine) => Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: _buildFineCard(fine),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // HEADER "Denda Saya"
  // =====================================================

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, top + 16, 14, 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Denda Saya',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _formatHeaderDate(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // KARTU TOTAL DENDA (KUNING)
  // =====================================================

  Widget _buildTotalCard() {
    final bool allPaid = totalUnpaid == 0;

    const boldStyle = TextStyle(fontWeight: FontWeight.w800);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: _cardYellow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL DENDA BELUM DIBAYAR',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'RP. ${_rupiah(totalUnpaid)}',
            style: const TextStyle(
              color: _darkText,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: allPaid
                      ? const Color(0xFFA9DDB8)
                      : const Color(0xFFF4949B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  allPaid ? 'Lunas' : 'Belum Lunas',
                  style: TextStyle(
                    color: allPaid
                        ? const Color(0xFF1F7A45)
                        : const Color(0xFF9B1C2C),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (!allPaid)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _startPayment,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            color: _orange,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _orange,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          const Text.rich(
            TextSpan(
              style: TextStyle(color: _darkText, fontSize: 11.5, height: 1.3),
              children: [
                TextSpan(text: 'Pembayaran dapat dilakukan tunai di\n'),
                TextSpan(text: 'Kasir Perpustakaan', style: boldStyle),
                TextSpan(text: ' atau via '),
                TextSpan(text: 'QRIS.', style: boldStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TAB "Belum Dibayar (n)" | "Riwayat Selesai"
  // =====================================================

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTab('Belum Dibayar (${unpaidFines.length})', 0),
        _buildTab('Riwayat Selesai', 1),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final bool active = selectedTab == index;

    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.only(bottom: 4, right: active ? 8 : 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active
                  ? AppColors.navy.withOpacity(0.7)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // KARTU DENDA BUKU
  // =====================================================

  Widget _buildFineCard(FineItem fine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COVER BUKU
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  fine.cover,
                  width: 73,
                  height: 106,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 73,
                    height: 106,
                    color: AppColors.border,
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 11),

              // JUDUL, STATUS, DAN RINCIAN DENDA
              Expanded(
                child: SizedBox(
                  height: 106,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fine.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    fine.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusPill(fine.status),
                        ],
                      ),
                      const Spacer(),
                      _buildInfoLine(
                        'Jatuh Tempo: ',
                        _formatDate(fine.dueDate),
                      ),
                      const SizedBox(height: 1),
                      _buildInfoLine(
                        'Terlambat: ',
                        '${fine.lateDays} Hari '
                            '(Rp ${_rupiah(fine.feePerDay)} /hari)',
                      ),
                      const SizedBox(height: 1),
                      _buildInfoLine('Denda: ', 'Rp ${_rupiah(fine.amount)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // PEMINJAM
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.white,
                  size: 13,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Peminjam: ${fine.borrowerName} (ID: ${fine.borrowerId})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _darkText, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: _darkText, fontSize: 11.5),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildStatusPill(FineStatus status) {
    late final String label;
    late final Color background;
    late final Color foreground;

    switch (status) {
      case FineStatus.belumBayar:
        label = '[ Belum Bayar ]';
        background = const Color(0xFFF7A8A8);
        foreground = const Color(0xFFB3202A);
        break;
      case FineStatus.menunggu:
        label = '[ Menunggu ]';
        background = const Color(0xFFF6D277);
        foreground = const Color(0xFFA66A00);
        break;
      case FineStatus.lunas:
        label = '[ Lunas ]';
        background = const Color(0xFFA9DDB8);
        foreground = const Color(0xFF1F7A45);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.grey,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            selectedTab == 0
                ? 'Tidak ada denda yang belum dibayar.'
                : 'Belum ada riwayat denda.',
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ALUR PEMBAYARAN: QR -> BERHASIL
  // =====================================================

  Future<void> _startPayment() async {
    await _showTopDialog(builder: _buildQrDialog);

    if (!mounted) return;

    await _showTopDialog(builder: _buildSuccessDialog);

    if (!mounted) return;

    // Setelah dialog "Pembayaran Berhasil!" ditutup,
    // semua denda ditandai lunas dan pindah ke Riwayat Selesai.
    // TODO: simpan status pembayaran ke Supabase.
    setState(() {
      fines = fines.map((f) => f.copyWith(status: FineStatus.lunas)).toList();
      totalUnpaid = 0;
    });
  }

  // Dialog menempel di bagian atas layar dengan sudut bawah membulat,
  // dan latar belakang digelapkan (sesuai desain Figma).
  Future<void> _showTopDialog({required WidgetBuilder builder}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: AppColors.white,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: SizedBox(
              width: double.infinity,
              child: builder(dialogContext),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }

  // DIALOG "Pembayaran Denda" (QR)
  Widget _buildQrDialog(BuildContext dialogContext) {
    final top = MediaQuery.of(dialogContext).padding.top;
    final deadline = DateTime.now().add(const Duration(days: 2));

    return Padding(
      padding: EdgeInsets.fromLTRB(26, top + 20, 26, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembayaran Denda',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan QR Berikut untuk melakukan pembayaran',
                      style: TextStyle(color: AppColors.grey, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // QR CODE
          // TODO: ganti `data` dengan payload QRIS asli dari backend.
          QrImageView(
            data: 'LOKABACA-DENDA-A-023-$totalUnpaid',
            version: QrVersions.auto,
            size: 165,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.white,
          ),

          const SizedBox(height: 20),

          // TOTAL PEMBAYARAN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Rp ${_rupiah(totalUnpaid)}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batas waktu pembayaran '
                  '${deadline.day} ${_monthShort(deadline.month)} 23:59',
                  style: const TextStyle(color: AppColors.white, fontSize: 8.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildDialogButton(dialogContext),
        ],
      ),
    );
  }

  // DIALOG "Pembayaran Berhasil!"
  Widget _buildSuccessDialog(BuildContext dialogContext) {
    final top = MediaQuery.of(dialogContext).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(25, top + 20, 25, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFD9F0E1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF2E9E5B),
              size: 24,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Pembayaran Berhasil!',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _buildDialogButton(dialogContext),
        ],
      ),
    );
  }

  Widget _buildDialogButton(BuildContext dialogContext) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          'Selesai',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // =====================================================
  // FORMAT TEKS
  // =====================================================

  static String _rupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  static const List<String> _monthsShort = [
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

  static const List<String> _daysFull = [
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU',
    'MINGGU',
  ];

  static String _monthShort(int month) => _monthsShort[month - 1];

  // Contoh: 17 Apr 2027
  static String _formatDate(DateTime date) {
    return '${date.day} ${_monthShort(date.month)} ${date.year}';
  }

  // Contoh: SELASA, 20 OKT 2026
  static String _formatHeaderDate(DateTime date) {
    final day = _daysFull[date.weekday - 1];
    final month = _monthShort(date.month).toUpperCase();

    return '$day, ${date.day} $month ${date.year}';
  }
}
