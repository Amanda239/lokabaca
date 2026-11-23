
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/book_cover.dart';
import 'admin_bottom_navigation.dart';
import 'denda_admin_screen.dart';
import 'kelola_buku.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';
import 'profile_admin.dart';

class LaporanAdminScreen extends StatefulWidget {
  const LaporanAdminScreen({super.key});

  @override
  State<LaporanAdminScreen> createState() =>
      _LaporanAdminScreenState();
}

class _LaporanAdminScreenState extends State<LaporanAdminScreen> {
  final supabase = Supabase.instance.client;

  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.cream;
  static const Color muted = AppColors.grey;
  static const Color border = AppColors.border;
  static const Color red = Color(0xFFD94343);
  static const Color green = Color(0xFF39966A);

  static const int finePerDay = NotificationService.finePerDay;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> loans = [];
  List<Map<String, dynamic>> filteredLoans = [];

  DateTimeRange? selectedRange;

  int totalLoans = 0;
  int borrowedBooks = 0;
  int activeMembers = 0;

  String popularBook = '-';

  double totalFine = 0;
  double unpaidFine = 0;

  int selectedIndex = 0;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();

    selectedRange = DateTimeRange(
      start: DateTime(DateTime.now().year, 1, 1),
      end: DateTime.now(),
    );

    loadReport();
    NotificationService.runChecks().whenComplete(() {
      if (mounted) loadReport();
    });
  }

  Future<void> refresh() async {
    await NotificationService.runChecks();
    await loadReport();
  }

  // =====================================================
  // HELPER
  // =====================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String formatDate(dynamic value) {
    final date = parseDate(value);
    if (date == null) return '-';
    return dateFormat.format(date.toLocal());
  }

  String formatMoney(num value) {
    return currencyFormat.format(value);
  }

  int lateDays(Map<String, dynamic> loan) {
    final dueDate = parseDate(loan['due_date']);
    if (dueDate == null) return 0;

    final returnedAt = parseDate(loan['returned_at']);
    final endDate = returnedAt ?? DateTime.now();

    final due = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );

    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    final difference = end.difference(due).inDays;

    return difference > 0 ? difference : 0;
  }

  double effectiveFine(Map<String, dynamic> loan) {
    final storedFine =
        (loan['fine_amount'] as num?)?.toDouble() ?? 0;

    if (storedFine > 0) return storedFine;

    return (lateDays(loan) * finePerDay).toDouble();
  }

  bool hasFine(Map<String, dynamic> loan) {
    return effectiveFine(loan) > 0;
  }

  bool isPaid(Map<String, dynamic> loan) {
    return loan['fine_paid'] == true;
  }

  // =====================================================
  // LOAD REPORT
  // =====================================================

  Future<void> loadReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final borrowingResponse = await supabase
          .from('borrowings')
          .select()
          .order('borrowed_at', ascending: false);

      final borrowingData =
          List<Map<String, dynamic>>.from(borrowingResponse);

      final profileResponse = await supabase
          .from('profiles')
          .select('id, full_name, nis, role, status');

      final profiles =
          List<Map<String, dynamic>>.from(profileResponse);

      final bookResponse = await supabase
          .from('books')
          .select('id, title, author, cover_url, stock');

      final books =
          List<Map<String, dynamic>>.from(bookResponse);

      final profileMap = {
        for (final item in profiles)
          item['id'].toString(): item,
      };

      final bookMap = {
        for (final item in books)
          item['id'].toString(): item,
      };

      final merged = borrowingData.map((loan) {
        final profile =
            profileMap[loan['user_id']?.toString()];

        final book =
            bookMap[loan['book_id']?.toString()];

        return {
          ...loan,
          'member_name':
              profile?['full_name'] ?? 'Anggota tidak ditemukan',
          'member_nis': profile?['nis'] ?? '-',
          'member_role': profile?['role'],
          'member_status': profile?['status'],
          'book_title':
              book?['title'] ?? 'Buku tidak ditemukan',
          'book_author': book?['author'] ?? '-',
          'book_cover': book?['cover_url'],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        loans = merged;
        // Ringkasan dihitung dari data yang sudah difilter tanggalnya.
        applyDateFilter();
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

  // =====================================================
  // FILTER TANGGAL
  // =====================================================

  void applyDateFilter() {
    if (selectedRange == null) {
      filteredLoans = List.from(loans);
    } else {
      final start = DateTime(
        selectedRange!.start.year,
        selectedRange!.start.month,
        selectedRange!.start.day,
      );

      final end = DateTime(
        selectedRange!.end.year,
        selectedRange!.end.month,
        selectedRange!.end.day,
        23,
        59,
        59,
      );

      filteredLoans = loans.where((loan) {
        final date = parseDate(loan['borrowed_at']);

        if (date == null) return false;

        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();
    }

    recomputeSummary();
  }

  /// Semua statistik ringkasan mengikuti rentang tanggal aktif.
  void recomputeSummary() {
    final data = filteredLoans;
    totalLoans = data.length;
    borrowedBooks = data
        .where((loan) => loan['returned_at'] == null)
        .map((loan) => loan['book_id'].toString())
        .toSet()
        .length;
    activeMembers = data
        .where(
          (loan) =>
              loan['member_role'] == 'user' &&
              loan['member_status'] == 'Aktif',
        )
        .map((loan) => loan['user_id'].toString())
        .toSet()
        .length;

    final bookCounts = <String, int>{};
    final bookNames = <String, String>{};
    for (final loan in data) {
      final id = loan['book_id']?.toString();
      if (id == null) continue;
      bookCounts[id] = (bookCounts[id] ?? 0) + 1;
      bookNames[id] = loan['book_title'].toString();
    }
    if (bookCounts.isEmpty) {
      popularBook = '-';
    } else {
      final sorted = bookCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      popularBook = bookNames[sorted.first.key] ?? '-';
    }

    double allFine = 0;
    double unpaid = 0;
    for (final loan in data) {
      final amount = effectiveFine(loan);
      allFine += amount;
      if (!isPaid(loan)) unpaid += amount;
    }
    totalFine = allFine;
    unpaidFine = unpaid;
  }

  Future<void> chooseDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: navy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    setState(() {
      selectedRange = result;
      applyDateFilter();
    });
  }

  // =====================================================
  // EDIT DENDA
  // =====================================================

  Future<void> editFine(Map<String, dynamic> loan) async {
    final dueDateController = TextEditingController(
      text: formatDate(loan['due_date']),
    );

    final borrowedController = TextEditingController(
      text: formatDate(loan['borrowed_at']),
    );

    final returnedController = TextEditingController(
      text: loan['returned_at'] == null
          ? ''
          : formatDate(loan['returned_at']),
    );

    final fineController = TextEditingController(
      text: effectiveFine(loan).toStringAsFixed(0),
    );

    DateTime? dueDate = parseDate(loan['due_date']);
    DateTime? borrowedDate = parseDate(loan['borrowed_at']);
    DateTime? returnedDate = parseDate(loan['returned_at']);

    Future<DateTime?> pickDate(DateTime? initial) async {
      return showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: navy,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
    }

    Future<void> chooseDueDate(
      StateSetter setDialogState,
    ) async {
      final result = await pickDate(dueDate);

      if (result == null) return;

      setDialogState(() {
        dueDate = result;
        dueDateController.text = dateFormat.format(result);
      });
    }

    Future<void> chooseBorrowedDate(
      StateSetter setDialogState,
    ) async {
      final result = await pickDate(borrowedDate);

      if (result == null) return;

      setDialogState(() {
        borrowedDate = result;
        borrowedController.text = dateFormat.format(result);
      });
    }

    Future<void> chooseReturnedDate(
      StateSetter setDialogState,
    ) async {
      final result = await pickDate(returnedDate);

      if (result == null) return;

      setDialogState(() {
        returnedDate = result;
        returnedController.text = dateFormat.format(result);
      });
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Edit Data Denda',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 340,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perbarui data denda dan peminjaman.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _dialogLabel('Informasi'),
                      _loanInfo(loan),
                      const SizedBox(height: 14),
                      _dialogLabel('Tanggal Jatuh Tempo'),
                      _dateInput(
                        controller: dueDateController,
                        onTap: () =>
                            chooseDueDate(setDialogState),
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Tanggal Pinjam'),
                      _dateInput(
                        controller: borrowedController,
                        onTap: () =>
                            chooseBorrowedDate(setDialogState),
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Tanggal Kembali'),
                      _dateInput(
                        controller: returnedController,
                        onTap: () =>
                            chooseReturnedDate(setDialogState),
                        hint: 'Belum dikembalikan',
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Jumlah Hari Terlambat'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: cream,
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${_calculateLateDays(dueDate, returnedDate)} Hari',
                          style: const TextStyle(
                            color: navy,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Total Denda'),
                      TextField(
                        controller: fineController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: 'Masukkan nominal denda',
                          prefix: 'Rp ',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: muted),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final amount =
                        double.tryParse(fineController.text);

                    if (dueDate == null ||
                        borrowedDate == null ||
                        amount == null ||
                        amount < 0) {
                      showMessage(
                        'Periksa kembali data denda.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                    size: 16,
                  ),
                  label: const Text('Simpan Perubahan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        final amount = double.parse(fineController.text);

        await supabase.from('borrowings').update({
          'due_date': DateFormat('yyyy-MM-dd').format(dueDate!),
          'borrowed_at': borrowedDate!.toIso8601String(),
          'returned_at': returnedDate?.toIso8601String(),
          'fine_amount': amount,
        }).eq('id', loan['id']);

        if (!mounted) return;

        showMessage('Data denda berhasil diperbarui.');
        await loadReport();
      } catch (e) {
        showMessage('Gagal mengubah denda: $e');
      }
    }

    dueDateController.dispose();
    borrowedController.dispose();
    returnedController.dispose();
    fineController.dispose();
  }

  int _calculateLateDays(
    DateTime? due,
    DateTime? returned,
  ) {
    if (due == null) return 0;

    final end = returned ?? DateTime.now();

    final difference = DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(
      DateTime(due.year, due.month, due.day),
    ).inDays;

    return difference > 0 ? difference : 0;
  }

  // =====================================================
  // TAMBAH DENDA
  // =====================================================

  Future<void> addFine() async {
    final eligible = loans.where((loan) {
      return loan['fine_paid'] != true;
    }).toList();

    if (eligible.isEmpty) {
      showMessage(
        'Tidak ada peminjaman yang bisa diberi denda.',
      );
      return;
    }

    String? selectedId = eligible.first['id'].toString();

    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Tambah Denda',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedId,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        hint: 'Pilih peminjaman',
                      ),
                      items: eligible.map((loan) {
                        return DropdownMenuItem<String>(
                          value: loan['id'].toString(),
                          child: Text(
                            '${loan['member_name']} - ${loan['book_title']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: 'Nominal denda',
                        prefix: 'Rp ',
                      ),
                    ),
                  ],
                ),
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
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text);

                    if (selectedId == null ||
                        amount == null ||
                        amount <= 0) {
                      showMessage(
                        'Masukkan nominal denda yang valid.',
                      );
                      return;
                    }

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

    final chosenId = selectedId;
    if (result == true && chosenId != null) {
      try {
        final amount = double.tryParse(amountController.text.trim()) ?? 0;
        // borrowing.id bertipe INTEGER; hindari int.parse yang melempar.
        final int? numericId = int.tryParse(chosenId.trim());
        await supabase.from('borrowings').update({
          'fine_amount': amount,
          'fine_paid': false,
          'fine_paid_at': null,
        }).eq('id', numericId ?? chosenId);

        if (!mounted) return;

        showMessage('Denda berhasil ditambahkan.');
        await loadReport();
      } catch (e) {
        showMessage('Gagal menambahkan denda: $e');
      }
    }

    amountController.dispose();
  }

  // =====================================================
  // HAPUS DENDA
  // =====================================================

  Future<void> deleteFine(
    Map<String, dynamic> loan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogIcon(
                Icons.delete_outline,
                red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Data Denda?',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Yakin ingin menghapus data denda berikut?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _loanInfo(loan),
              const SizedBox(height: 12),
              const Text(
                'Data yang dihapus tidak dapat dipulihkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
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
      await supabase.from('borrowings').update({
        'fine_amount': 0,
        'fine_paid': false,
        'fine_paid_at': null,
      }).eq('id', loan['id']);

      if (!mounted) return;

      showMessage('Data denda berhasil dihapus.');
      await loadReport();
    } catch (e) {
      showMessage('Gagal menghapus denda: $e');
    }
  }

  // =====================================================
  // KONFIRMASI PELUNASAN
  // =====================================================

  Future<void> payFine(
    Map<String, dynamic> loan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogIcon(
                Icons.account_balance_wallet_rounded,
                green,
              ),
              const SizedBox(height: 15),
              const Text(
                'Konfirmasi Pelunasan',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Apakah kamu yakin ingin mengubah status denda menjadi lunas?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _loanInfo(loan),
              const SizedBox(height: 10),
              Text(
                'Nominal: ${formatMoney(effectiveFine(loan))}',
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Sudah Lunas'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await supabase.from('borrowings').update({
        'fine_amount': effectiveFine(loan),
        'fine_paid': true,
        'fine_paid_at': DateTime.now().toIso8601String(),
      }).eq('id', loan['id']);

      if (!mounted) return;

      await loadReport();

      if (!mounted) return;

      showPaymentSuccess();
    } catch (e) {
      showMessage('Gagal mengonfirmasi pembayaran: $e');
    }
  }

  void showPaymentSuccess() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogIcon(
                Icons.check_circle_outline,
                green,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Denda buku telah berhasil dinyatakan lunas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

  Future<void> navigateToPage(
    int index,
    Widget page,
  ) async {
    setState(() => selectedIndex = index);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;

    setState(() => selectedIndex = 0);

    await loadReport();
  }

  void handleNavigation(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      navigateToPage(1, const KelolaBukuScreen());
    } else if (index == 2) {
      navigateToPage(2, const KelolaAnggotaPage());
    } else if (index == 3) {
      navigateToPage(3, const PeminjamanAdminScreen());
    } else if (index == 4) {
      navigateToPage(4, const DendaAdminScreen());
    } else if (index == 5) {
      navigateToPage(5, const ProfileAdminScreen());
    }
  }

  // =====================================================
  // WIDGET HELPERS
  // =====================================================

  Widget _dialogIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 29,
      ),
    );
  }

  Widget _dialogLabel(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        value,
        style: const TextStyle(
          color: navy,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: const TextStyle(
        color: muted,
        fontSize: 11,
      ),
      filled: true,
      fillColor: cream,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: navy),
      ),
    );
  }

  Widget _dateInput({
    required TextEditingController controller,
    required VoidCallback onTap,
    String? hint,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: IgnorePointer(
        child: TextField(
          controller: controller,
          decoration: _inputDecoration(
            hint: hint ?? 'Pilih tanggal',
          ).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: navy,
              size: 18,
            ),
          ),
          style: const TextStyle(
            color: navy,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _loanInfo(Map<String, dynamic> loan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Peminjam : ${loan['member_name']}\n'
        'Buku : ${loan['book_title']}\n'
        'NIS : ${loan['member_nis']}',
        style: const TextStyle(
          color: navy,
          fontSize: 11,
          height: 1.6,
        ),
      ),
    );
  }

  // =====================================================
  // STATISTIC CARD
  // =====================================================

  Widget statisticCard({
    required String title,
    required String value,
    required IconData icon,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: navy,
              size: 17,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: navy,
                  fontSize: compact ? 13 : 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FINE CARD
  // =====================================================

  Widget fineCard(Map<String, dynamic> loan) {
    final amount = effectiveFine(loan);
    final paid = isPaid(loan);
    final days = lateDays(loan);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                imageUrl: loan['book_cover']?.toString(),
                width: 68,
                height: 94,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan['book_title']?.toString() ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan['book_author']?.toString() ?? '-',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: paid
                            ? green.withValues(alpha: 0.10)
                            : red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        paid ? 'Lunas' : 'Belum Bayar',
                        style: TextStyle(
                          color: paid ? green : red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: border, height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 17,
                color: muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  loan['member_name']?.toString() ?? '-',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'NIS: ${loan['member_nis']}',
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cream.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _fineDetailRow(
                  'Tanggal jatuh tempo',
                  formatDate(loan['due_date']),
                ),
                const SizedBox(height: 9),
                _fineDetailRow(
                  'Keterlambatan',
                  '$days hari',
                ),
                const SizedBox(height: 9),
                Divider(color: border, height: 1),
                const SizedBox(height: 9),
                _fineDetailRow(
                  'Total denda',
                  formatMoney(amount),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _fineActionButton(
                  'Edit',
                  Icons.edit_outlined,
                  navy,
                  () => editFine(loan),
                  outlined: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _fineActionButton(
                  'Hapus',
                  Icons.delete_outline,
                  red,
                  () => deleteFine(loan),
                  outlined: true,
                ),
              ),
              if (!paid) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _fineActionButton(
                    'Lunas',
                    Icons.check_circle_outline,
                    green,
                    () => payFine(loan),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fineDetailRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: navy,
              fontSize: 10,
              fontWeight: bold
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fineActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return SizedBox(
      height: 38,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 14),
              label: Text(title),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(
                  color: color.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 14),
              label: Text(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Laporan',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: navy,
                      size: 21,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 38,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: navy,
                      size: 21,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 38,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ringkasan aktivitas perpustakaan',
            style: TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: chooseDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: navy,
                    size: 19,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Periode laporan',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedRange == null
                              ? 'Semua tanggal'
                              : '${dateFormat.format(selectedRange!.start)} - ${dateFormat.format(selectedRange!.end)}',
                          style: const TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: navy,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: const BoxDecoration(
              color: cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: navy,
              size: 29,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Belum Ada Data Denda',
            style: TextStyle(
              color: navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Data denda peminjaman akan ditampilkan di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CONTENT
  // =====================================================

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth >= 650 ? 3 : 2;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            14,
            12,
            14,
            20,
          ),
          children: [
            const Text(
              'Ringkasan',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Statistik keseluruhan perpustakaan.',
              style: TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 1.5,
              children: [
                statisticCard(
                  title: 'Total Peminjaman',
                  value: totalLoans.toString(),
                  icon: Icons.library_books_outlined,
                ),
                statisticCard(
                  title: 'Buku Terpinjam',
                  value: borrowedBooks.toString(),
                  icon: Icons.menu_book_outlined,
                ),
                statisticCard(
                  title: 'Anggota Aktif',
                  value: activeMembers.toString(),
                  icon: Icons.people_outline_rounded,
                ),
                statisticCard(
                  title: 'Buku Populer',
                  value: popularBook,
                  icon: Icons.auto_stories_outlined,
                  compact: true,
                ),
                statisticCard(
                  title: 'Total Denda',
                  value: formatMoney(totalFine),
                  icon: Icons.account_balance_wallet_outlined,
                  compact: true,
                ),
                statisticCard(
                  title: 'Denda Belum Dibayar',
                  value: formatMoney(unpaidFine),
                  icon: Icons.pending_actions_outlined,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Denda',
                        style: TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${filteredLoans.where(hasFine).length} data ditemukan',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: addFine,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 17,
                  ),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (filteredLoans.where(hasFine).isEmpty)
              _buildEmpty()
            else
              ...filteredLoans
                  .where(hasFine)
                  .map((loan) => fineCard(loan)),
          ],
        );
      },
    );
  }

  // =====================================================
  // ERROR STATE
  // =====================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: navy,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal Memuat Laporan',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
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

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: navy,
                      ),
                    )
                  : errorMessage != null
                      ? _buildError()
                      : RefreshIndicator(
                          color: navy,
                          onRefresh: refresh,
                          child: _buildContent(),
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
}
