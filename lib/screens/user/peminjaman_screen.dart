import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'user_bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'searchpage_screen.dart';
import 'collection_screen.dart';
import 'profile_screen.dart';
import 'denda_screen.dart';

// =====================================================
// HALAMAN RIWAYAT PEMINJAMAN (USER)
// Mengikuti desain Figma "Riwayat Peminjaman":
//   header + tombol Dipinjam / Denda / Selesai + daftar buku.
// =====================================================

enum LoanStatus { dipinjam, selesai, terlambat }

class LoanItem {
  final String title;
  final String author;
  final String cover;
  final DateTime borrowDate;

  // Batas kembali (untuk Dipinjam / Terlambat)
  // atau tanggal dikembalikan (untuk Selesai).
  final DateTime endDate;

  final LoanStatus status;

  // Untuk buku Selesai yang dikembalikan melewati batas waktu.
  final bool returnedLate;

  const LoanItem({
    required this.title,
    required this.author,
    required this.cover,
    required this.borrowDate,
    required this.endDate,
    required this.status,
    this.returnedLate = false,
  });

  bool get isLate => status == LoanStatus.terlambat || returnedLate;
}

class PeminjamanScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedBook;

  const PeminjamanScreen({
    super.key,
    this.selectedBook,
  });

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  static const Color _darkText = Color(0xFF1E2A38);
  static const Color _authorText = Color(0xFF555555);
  static const Color _dateText = Color(0xFF6B6B6B);

  int selectedNav = 2;

  // Filter: null = tampilkan semua, atau Dipinjam / Selesai.
  // Tekan tombol yang sama sekali lagi untuk menampilkan semua.
  LoanStatus? selectedFilter;

  // DATA CONTOH (sama seperti desain Figma)
  // TODO: ganti dengan data dari Supabase.
  final List<LoanItem> loans = [
    LoanItem(
      title: 'Laut Bercerita',
      author: 'Leila S. Chudori',
      cover: 'assets/images/lautbercerita.jpeg',
      borrowDate: DateTime(2026, 3, 9),
      endDate: DateTime(2026, 3, 17),
      status: LoanStatus.dipinjam,
    ),
    LoanItem(
      title: 'Bawang Merah',
      author: 'Yudhistira Ikranegara',
      cover: 'assets/images/bawangmerah.jpeg',
      borrowDate: DateTime(2026, 6, 2),
      endDate: DateTime(2026, 8, 28),
      status: LoanStatus.selesai,
    ),
    LoanItem(
      title: 'Bahasa Indonesia',
      author: 'Kurikulum Merdeka kelas 12',
      cover: 'assets/images/bindo.jpeg',
      borrowDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 9, 8),
      status: LoanStatus.terlambat,
    ),
    LoanItem(
      title: 'Rumah Alie',
      author: 'Lenn Liu',
      cover: 'assets/images/rumahuntukalie.jpeg',
      borrowDate: DateTime(2026, 9, 6),
      endDate: DateTime(2026, 10, 17),
      status: LoanStatus.selesai,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Buku yang baru dipinjam dari form peminjaman
    // ditambahkan di urutan paling atas.
    final book = widget.selectedBook;

    if (book != null) {
      final today = DateUtils.dateOnly(DateTime.now());

      loans.insert(
        0,
        LoanItem(
          title: (book['title'] ?? 'Judul Buku').toString(),
          author: (book['author'] ?? 'Penulis').toString(),
          cover: (book['cover'] ?? '').toString(),
          borrowDate: today,
          endDate: today.add(const Duration(days: 14)),
          status: LoanStatus.dipinjam,
        ),
      );
    }
  }

  // Tombol "Dipinjam" menampilkan buku yang masih dipinjam
  // (termasuk yang sudah terlambat dikembalikan).
  List<LoanItem> get visibleLoans {
    switch (selectedFilter) {
      case LoanStatus.dipinjam:
        return loans
            .where((l) => l.status != LoanStatus.selesai)
            .toList();
      case LoanStatus.selesai:
        return loans
            .where((l) => l.status == LoanStatus.selesai)
            .toList();
      default:
        return loans;
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final list = visibleLoans;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 26),
            _buildFilterButtons(),
            const SizedBox(height: 28),
            if (list.isEmpty)
              _buildEmptyState()
            else
              ...list.map(
                (loan) => Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: _buildLoanItem(loan),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: UserBottomNavigation(
        selectedIndex: selectedNav,
        onTap: _navigateTo,
      ),
    );
  }

  // =====================================================
  // HEADER "< Riwayat Peminjaman"
  // =====================================================

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _goBack,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.navy,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Riwayat Peminjaman',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // TOMBOL "Dipinjam" | "Denda" | "Selesai"
  // =====================================================

  Widget _buildFilterButtons() {
    // Ketiga tombol dibuat sama lebar (Expanded).
    return Row(
      children: [
        Expanded(
          child: _buildPill(
            label: 'Dipinjam',
            active: selectedFilter == LoanStatus.dipinjam,
            onTap: () => _toggleFilter(LoanStatus.dipinjam),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPill(
            label: 'Denda',
            active: false,
            onTap: _openDenda,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPill(
            label: 'Selesai',
            active: selectedFilter == LoanStatus.selesai,
            onTap: () => _toggleFilter(LoanStatus.selesai),
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: active ? AppColors.yellow : AppColors.navy,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 11,
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? AppColors.navy : AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFilter(LoanStatus status) {
    setState(() {
      selectedFilter = selectedFilter == status ? null : status;
    });
  }

  // =====================================================
  // ITEM BUKU
  // =====================================================

  Widget _buildLoanItem(LoanItem loan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // COVER BUKU
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.asset(
            loan.cover,
            width: 60,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 86,
              color: AppColors.border,
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.navy,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // INFORMASI BUKU
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        loan.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(loan.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loan.author,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _authorText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                loan.isLate ? 'Terlambat' : 'Tepat waktu',
                style: TextStyle(
                  color: loan.isLate
                      ? const Color(0xFFFF0000)
                      : _dateText,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                '${_formatDate(loan.borrowDate)} - '
                '${_formatDate(loan.endDate)}',
                style: const TextStyle(
                  color: _dateText,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(LoanStatus status) {
    late final String label;
    late final Color background;

    switch (status) {
      case LoanStatus.dipinjam:
        label = 'Dipinjam';
        background = const Color(0xFFF5C85F);
        break;
      case LoanStatus.selesai:
        label = 'Selesai';
        background = const Color(0xFF53E044);
        break;
      case LoanStatus.terlambat:
        label = 'Terlambat';
        background = const Color(0xFFF25555);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _darkText,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.navy,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Riwayat',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Buku yang kamu pinjam akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FORMAT TANGGAL  (contoh: 9 Maret 2026)
  // =====================================================

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April',
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // =====================================================
  // NAVIGASI
  // =====================================================

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _openDenda() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DendaScreen()),
    );
  }

  void _navigateTo(int index) {
    if (index == selectedNav) return;

    Widget? destination;

    switch (index) {
      case 0:
        destination = const DashboardScreen();
        break;
      case 1:
        destination = const SearchPageScreen();
        break;
      case 2:
        return;
      case 3:
        destination = const CollectionScreen();
        break;
      case 4:
        destination = const ProfileScreen();
        break;
    }

    if (destination == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination!),
    );
  }
}
