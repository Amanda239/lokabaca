
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/book_cover.dart';

class FormPeminjamanScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const FormPeminjamanScreen({
    super.key,
    required this.book,
  });

  @override
  State<FormPeminjamanScreen> createState() =>
      _FormPeminjamanScreenState();
}

class _FormPeminjamanScreenState
    extends State<FormPeminjamanScreen> {
  // Durasi standar sesuai kebijakan LokaBaca (3 hari, dapat diperpanjang 3 hari).
  int? selectedDuration = 3;

  final TextEditingController noteController =
      TextEditingController();

  final supabase = Supabase.instance.client;

  bool isLoading = false;

  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.input;
  static const Color muted = AppColors.grey;
  static const Color border = AppColors.border;

  DateTime? get dueDate {
    if (selectedDuration == null) return null;

    return DateTime.now().add(
      Duration(days: selectedDuration!),
    );
  }

  String get formattedDate {
    if (dueDate == null) return '-';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${dueDate!.day.toString().padLeft(2, '0')} '
        '${months[dueDate!.month - 1]} ${dueDate!.year}';
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
      ),
    );
  }

  // =====================================================
  // SUBMIT BORROWING TO SUPABASE
  // =====================================================

  Future<void> _submitBorrowing() async {
    if (isLoading) return;

    if (selectedDuration == null) {
      _showMessage(
        'Pilih durasi peminjaman terlebih dahulu.',
      );
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Silakan login terlebih dahulu.',
      );
      return;
    }

    final bookId = widget.book['id'];

    if (bookId == null) {
      _showMessage(
        'Data buku tidak ditemukan.',
      );
      return;
    }

    final stock = int.tryParse(
          widget.book['stock']?.toString() ?? '0',
        ) ??
        0;

    if (stock <= 0) {
      _showMessage(
        'Maaf, stok buku sedang tidak tersedia.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Cegah pengajuan ganda: buku yang sama masih menunggu approval admin
      // atau sedang dipinjam. (Server juga menjaga ini lewat trigger.)
      final existing = await supabase
          .from('borrowings')
          .select('id,status')
          .eq('user_id', user.id)
          .eq('book_id', bookId)
          .inFilter('status', [
        'Menunggu',
        'Dipinjam',
        'Terlambat',
        'Menunggu Pengembalian',
      ]).limit(1);

      if (existing.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        final waiting =
            existing.first['status']?.toString().toLowerCase() == 'menunggu';
        _showMessage(
          waiting
              ? 'Pengajuan untuk buku ini masih menunggu persetujuan admin.'
              : 'Kamu masih meminjam buku ini.',
        );
        return;
      }

      final now = DateTime.now();

      final selectedDueDate = now.add(
        Duration(days: selectedDuration!),
      );

      final dueDateString =
          '${selectedDueDate.year}-'
          '${selectedDueDate.month.toString().padLeft(2, '0')}-'
          '${selectedDueDate.day.toString().padLeft(2, '0')}';

      // Status Menunggu: admin yang menyetujui atau menolak pengajuan.
      final inserted = await supabase
          .from('borrowings')
          .insert({
            'user_id': user.id,
            'book_id': bookId,
            'borrowed_at': now.toUtc().toIso8601String(),
            'due_date': dueDateString,
            'status': 'Menunggu',
            'note': noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
          })
          .select('id')
          .single();

      final borrowingId = inserted['id']?.toString();
      if (borrowingId != null) {
        try {
          await NotificationService.notifyNewLoanRequest(borrowingId);
        } catch (e) {
          // Pengajuan tetap tersimpan walaupun notifikasi gagal dikirim.
          debugPrint('NOTIF PENGAJUAN ERROR: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      await _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Gagal mengajukan peminjaman: $e',
      );
    }
  }

  // =====================================================
  // SUCCESS DIALOG
  // =====================================================

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF65A77A),
                size: 58,
              ),

              const SizedBox(height: 15),

              const Text(
                'Pengajuan Berhasil!',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Pengajuan peminjaman buku berhasil dikirim.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // BOOK COVER
  // =====================================================

  Widget _buildCover(String cover) {
    // BookCover menangani baik path aset maupun URL http Supabase Storage.
    return BookCover(
      imageUrl: cover,
      width: 88,
      height: 126,
      radius: 7,
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    final title = book['title']?.toString() ?? 'Judul Buku';
    final author = book['author']?.toString() ?? 'Penulis';

    final cover = (
      book['cover_url'] ??
      book['cover'] ??
      ''
    ).toString();

    final stock = book['stock'] ?? 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookSection(
                      title: title,
                      author: author,
                      cover: cover,
                      stock: stock,
                    ),

                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      'Durasi Peminjaman',
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Durasi standar 3 hari (opsional 7 hari). '
                      'Perpanjang 1x untuk tambahan 3 hari.',
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _durationButton(3),
                        const SizedBox(width: 14),
                        _durationButton(7),
                      ],
                    ),

                    const SizedBox(height: 25),

                    _buildDueDateCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Catatan'),

                    const SizedBox(height: 7),

                    const Text(
                      'Tambahkan catatan jika diperlukan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildNoteField(),

                    const SizedBox(height: 20),

                    _buildFineInformation(),

                    const SizedBox(height: 24),

                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0EEE9),
          ),
        ),
      ),
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
              'Form Peminjaman',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // =====================================================
  // BOOK INFORMATION
  // =====================================================

  Widget _buildBookSection({
    required String title,
    required String author,
    required String cover,
    required dynamic stock,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 126,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: _buildCover(cover),
          ),

          const SizedBox(width: 17),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  author,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 15,
                      color: navy,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      'Tersedia $stock',
                      style: const TextStyle(
                        fontSize: 12,
                        color: navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SECTION TITLE
  // =====================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: navy,
      ),
    );
  }

  // =====================================================
  // DURATION BUTTON
  // =====================================================

  Widget _durationButton(int days) {
    final isSelected = selectedDuration == days;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedDuration = days;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? navy : cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? navy : border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 7),
              ],

              Text(
                '$days Hari',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DUE DATE
  // =====================================================

  Widget _buildDueDateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: navy,
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TANGGAL JATUH TEMPO',
                  style: TextStyle(
                    fontSize: 10,
                    color: muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1EFE3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Bebas biaya peminjaman',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF42694D),
                      fontWeight: FontWeight.w700,
                    ),
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
  // NOTE FIELD
  // =====================================================

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: noteController,
        maxLines: 3,
        style: const TextStyle(
          fontSize: 13,
          color: navy,
        ),
        decoration: const InputDecoration(
          hintText: 'Tulis catatan jika diperlukan...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: muted,
          ),
          contentPadding: EdgeInsets.all(14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // =====================================================
  // FINE INFORMATION
  // =====================================================

  Widget _buildFineInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8DF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: navy,
            size: 18,
          ),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'Masa peminjaman dapat diperpanjang 1 kali per buku. Denda keterlambatan sebesar Rp1.000 per hari.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SUBMIT BUTTON
  // =====================================================

  Widget _buildSubmitButton() {
    final canSubmit =
        selectedDuration != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 47,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitBorrowing : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          disabledBackgroundColor: const Color(0xFFD8DCE1),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: canSubmit ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Ajukan Peminjaman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
