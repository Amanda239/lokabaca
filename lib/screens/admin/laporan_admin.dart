
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'admin_bottom_navigation.dart';
// import 'kelola_buku.dart';
// import 'kelola_anggota.dart';
// import 'peminjaman_admin.dart';
// import 'pengaturan_admin.dart';

// class LaporanAdminScreen extends StatefulWidget {
//   const LaporanAdminScreen({super.key});

//   @override
//   State<LaporanAdminScreen> createState() =>
//       _LaporanAdminScreenState();
// }

// class _LaporanAdminScreenState extends State<LaporanAdminScreen> {
//   final supabase = Supabase.instance.client;

//   static const Color navy = Color(0xFF2E4057);
//   static const Color cream = Color(0xFFF8F4EA);
//   static const Color muted = Color(0xFF8993A1);
//   static const Color border = Color(0xFFCBD0D7);
//   static const Color red = Color(0xFFE84D5B);
//   static const Color green = Color(0xFF39966A);

//   static const int finePerDay = 1000;

//   bool isLoading = true;
//   String? errorMessage;

//   List<Map<String, dynamic>> loans = [];
//   List<Map<String, dynamic>> filteredLoans = [];

//   DateTimeRange? selectedRange;

//   int totalLoans = 0;
//   int borrowedBooks = 0;
//   int activeMembers = 0;
//   String popularBook = '-';

//   double totalFine = 0;
//   double unpaidFine = 0;

//   int selectedIndex = 0;

//   final currencyFormat = NumberFormat.currency(
//     locale: 'id_ID',
//     symbol: 'Rp ',
//     decimalDigits: 0,
//   );

//   final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

//   @override
//   void initState() {
//     super.initState();

//     selectedRange = DateTimeRange(
//       start: DateTime(DateTime.now().year, 1, 1),
//       end: DateTime.now(),
//     );

//     loadReport();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   // =====================================================
//   // HELPER
//   // =====================================================

//   void showMessage(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: navy,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   DateTime? parseDate(dynamic value) {
//     if (value == null) return null;

//     return DateTime.tryParse(value.toString());
//   }

//   String formatDate(dynamic value) {
//     final date = parseDate(value);

//     if (date == null) return '-';

//     return dateFormat.format(date.toLocal());
//   }

//   String formatMoney(num value) {
//     return currencyFormat.format(value);
//   }

//   int lateDays(Map<String, dynamic> loan) {
//     final dueDate = parseDate(loan['due_date']);

//     if (dueDate == null) return 0;

//     final returnedAt = parseDate(loan['returned_at']);

//     final endDate = returnedAt ?? DateTime.now();

//     final due = DateTime(
//       dueDate.year,
//       dueDate.month,
//       dueDate.day,
//     );

//     final end = DateTime(
//       endDate.year,
//       endDate.month,
//       endDate.day,
//     );

//     final difference = end.difference(due).inDays;

//     return difference > 0 ? difference : 0;
//   }

//   double effectiveFine(Map<String, dynamic> loan) {
//     final storedFine =
//         (loan['fine_amount'] as num?)?.toDouble() ?? 0;

//     // Gunakan denda tersimpan jika sudah diatur admin.
//     if (storedFine > 0) return storedFine;

//     // Jika belum ada nominal, hitung otomatis dari keterlambatan.
//     return (lateDays(loan) * finePerDay).toDouble();
//   }

//   bool hasFine(Map<String, dynamic> loan) {
//     return effectiveFine(loan) > 0;
//   }

//   bool isPaid(Map<String, dynamic> loan) {
//     return loan['fine_paid'] == true;
//   }

//   // =====================================================
//   // LOAD REPORT
//   // =====================================================

//   Future<void> loadReport() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       // 1. Ambil data peminjaman.
//       final borrowingResponse = await supabase
//           .from('borrowings')
//           .select()
//           .order('borrowed_at', ascending: false);

//       final borrowingData =
//           List<Map<String, dynamic>>.from(borrowingResponse);

//       // 2. Ambil data profil.
//       final profileResponse = await supabase
//           .from('profiles')
//           .select('id, full_name, nis, role, status');

//       final profiles =
//           List<Map<String, dynamic>>.from(profileResponse);

//       // 3. Ambil data buku.
//       final bookResponse = await supabase
//           .from('books')
//           .select('id, title, author, cover_url, stock');

//       final books =
//           List<Map<String, dynamic>>.from(bookResponse);

//       final profileMap = {
//         for (final item in profiles)
//           item['id'].toString(): item
//       };

//       final bookMap = {
//         for (final item in books)
//           item['id'].toString(): item
//       };

//       // 4. Gabungkan data berdasarkan foreign key.
//       final merged = borrowingData.map((loan) {
//         final profile = profileMap[
//           loan['user_id']?.toString()
//         ];

//         final book = bookMap[
//           loan['book_id']?.toString()
//         ];

//         return {
//           ...loan,
//           'member_name':
//               profile?['full_name'] ?? 'Anggota tidak ditemukan',
//           'member_nis': profile?['nis'] ?? '-',
//           'book_title': book?['title'] ?? 'Buku tidak ditemukan',
//           'book_author': book?['author'] ?? '-',
//           'book_cover': book?['cover_url'],
//         };
//       }).toList();

//       // 5. Hitung laporan berdasarkan data database.
//       final activeLoanData = merged.where((loan) {
//         return loan['returned_at'] == null;
//       }).toList();

//       final activeProfileData = profiles.where((profile) {
//         return profile['role'] == 'anggota' &&
//             profile['status'] == 'Aktif';
//       }).toList();

//       // Buku paling populer.
//       final bookCounts = <String, int>{};
//       final bookNames = <String, String>{};

//       for (final loan in merged) {
//         final id = loan['book_id']?.toString();

//         if (id == null) continue;

//         bookCounts[id] = (bookCounts[id] ?? 0) + 1;
//         bookNames[id] = loan['book_title'].toString();
//       }

//       String mostPopular = '-';

//       if (bookCounts.isNotEmpty) {
//         final sortedEntries = bookCounts.entries.toList()
//           ..sort((a, b) => b.value.compareTo(a.value));

//         mostPopular =
//             bookNames[sortedEntries.first.key] ?? '-';
//       }

//       double allFine = 0;
//       double activeFine = 0;

//       for (final loan in merged) {
//         final amount = effectiveFine(loan);

//         allFine += amount;

//         if (!isPaid(loan)) {
//           activeFine += amount;
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         loans = merged;

//         totalLoans = merged.length;

//         borrowedBooks = activeLoanData
//             .map((item) => item['book_id'].toString())
//             .toSet()
//             .length;

//         activeMembers = activeProfileData.length;

//         popularBook = mostPopular;

//         totalFine = allFine;
//         unpaidFine = activeFine;

//         applyDateFilter();

//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = e.toString();
//       });
//     }
//   }

//   // =====================================================
//   // FILTER TANGGAL
//   // =====================================================

//   void applyDateFilter() {
//     if (selectedRange == null) {
//       filteredLoans = List.from(loans);
//       return;
//     }

//     final start = DateTime(
//       selectedRange!.start.year,
//       selectedRange!.start.month,
//       selectedRange!.start.day,
//     );

//     final end = DateTime(
//       selectedRange!.end.year,
//       selectedRange!.end.month,
//       selectedRange!.end.day,
//       23,
//       59,
//       59,
//     );

//     filteredLoans = loans.where((loan) {
//       final date = parseDate(loan['borrowed_at']);

//       if (date == null) return false;

//       return !date.isBefore(start) && !date.isAfter(end);
//     }).toList();
//   }

//   Future<void> chooseDateRange() async {
//     final result = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(
//         const Duration(days: 365),
//       ),
//       initialDateRange: selectedRange,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: navy,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: navy,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (result == null) return;

//     setState(() {
//       selectedRange = result;
//       applyDateFilter();
//     });
//   }

//   // =====================================================
//   // EDIT DENDA
//   // =====================================================

//   Future<void> editFine(Map<String, dynamic> loan) async {
//     final dueDateController = TextEditingController(
//       text: formatDate(loan['due_date']),
//     );

//     final borrowedController = TextEditingController(
//       text: formatDate(loan['borrowed_at']),
//     );

//     final returnedController = TextEditingController(
//       text: loan['returned_at'] == null
//           ? ''
//           : formatDate(loan['returned_at']),
//     );

//     final fineController = TextEditingController(
//       text: effectiveFine(loan).toStringAsFixed(0),
//     );

//     DateTime? dueDate = parseDate(loan['due_date']);
//     DateTime? borrowedDate = parseDate(loan['borrowed_at']);
//     DateTime? returnedDate = parseDate(loan['returned_at']);

//     Future<DateTime?> pickDate(DateTime? initial) async {
//       return showDatePicker(
//         context: context,
//         initialDate: initial ?? DateTime.now(),
//         firstDate: DateTime(2000),
//         lastDate: DateTime(2100),
//         builder: (context, child) {
//           return Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: const ColorScheme.light(
//                 primary: navy,
//                 onPrimary: Colors.white,
//               ),
//             ),
//             child: child!,
//           );
//         },
//       );
//     }

//     Future<void> chooseDueDate(StateSetter setDialogState) async {
//       final result = await pickDate(dueDate);

//       if (result == null) return;

//       setDialogState(() {
//         dueDate = result;
//         dueDateController.text = dateFormat.format(result);
//       });
//     }

//     Future<void> chooseBorrowedDate(
//         StateSetter setDialogState) async {
//       final result = await pickDate(borrowedDate);

//       if (result == null) return;

//       setDialogState(() {
//         borrowedDate = result;
//         borrowedController.text = dateFormat.format(result);
//       });
//     }

//     Future<void> chooseReturnedDate(
//         StateSetter setDialogState) async {
//       final result = await pickDate(returnedDate);

//       if (result == null) return;

//       setDialogState(() {
//         returnedDate = result;
//         returnedController.text = dateFormat.format(result);
//       });
//     }

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               backgroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               title: const Text(
//                 'Edit Data Denda',
//                 style: TextStyle(
//                   color: navy,
//                   fontSize: 17,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               content: SingleChildScrollView(
//                 child: SizedBox(
//                   width: 340,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Perbarui data denda dan peminjaman.',
//                         style: TextStyle(
//                           color: muted,
//                           fontSize: 11,
//                         ),
//                       ),
//                       const SizedBox(height: 18),
//                       _dialogLabel('Informasi'),
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: cream,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: border),
//                         ),
//                         child: Text(
//                           'Peminjam : ${loan['member_name']}\n'
//                           'Buku : ${loan['book_title']}\n'
//                           'NIS : ${loan['member_nis']}',
//                           style: const TextStyle(
//                             color: navy,
//                             fontSize: 11,
//                             height: 1.6,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       _dialogLabel('Tanggal Jatuh Tempo'),
//                       _dateInput(
//                         controller: dueDateController,
//                         onTap: () => chooseDueDate(setDialogState),
//                       ),

//                       const SizedBox(height: 12),

//                       _dialogLabel('Tanggal Pinjam'),
//                       _dateInput(
//                         controller: borrowedController,
//                         onTap: () =>
//                             chooseBorrowedDate(setDialogState),
//                       ),

//                       const SizedBox(height: 12),

//                       _dialogLabel('Tanggal Kembali'),
//                       _dateInput(
//                         controller: returnedController,
//                         onTap: () =>
//                             chooseReturnedDate(setDialogState),
//                         hint: 'Belum dikembalikan',
//                       ),

//                       const SizedBox(height: 12),

//                       _dialogLabel('Jumlah Hari Terlambat'),
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(13),
//                         decoration: BoxDecoration(
//                           color: cream,
//                           border: Border.all(color: border),
//                           borderRadius: BorderRadius.circular(9),
//                         ),
//                         child: Text(
//                           '${_calculateLateDays(dueDate, returnedDate)} Hari',
//                           style: const TextStyle(
//                             color: navy,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       _dialogLabel('Total Denda'),
//                       TextField(
//                         controller: fineController,
//                         keyboardType: TextInputType.number,
//                         decoration: _inputDecoration(
//                           hint: 'Masukkan nominal denda',
//                           prefix: 'Rp ',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () =>
//                       Navigator.pop(dialogContext, false),
//                   child: const Text(
//                     'Batal',
//                     style: TextStyle(color: muted),
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     final amount =
//                         double.tryParse(fineController.text);

//                     if (dueDate == null ||
//                         borrowedDate == null ||
//                         amount == null ||
//                         amount < 0) {
//                       showMessage('Periksa kembali data denda.');
//                       return;
//                     }

//                     Navigator.pop(dialogContext, true);
//                   },
//                   icon: const Icon(Icons.save_outlined, size: 16),
//                   label: const Text('Simpan Perubahan'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: navy,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     if (result == true) {
//       try {
//         final amount = double.parse(fineController.text);

//         await supabase.from('borrowings').update({
//           'due_date': DateFormat('yyyy-MM-dd').format(dueDate!),
//           'borrowed_at': borrowedDate!.toIso8601String(),
//           'returned_at': returnedDate?.toIso8601String(),
//           'fine_amount': amount,
//         }).eq('id', loan['id']);

//         if (!mounted) return;

//         showMessage('Data denda berhasil diperbarui.');
//         await loadReport();
//       } catch (e) {
//         showMessage('Gagal mengubah denda: $e');
//       }
//     }

//     dueDateController.dispose();
//     borrowedController.dispose();
//     returnedController.dispose();
//     fineController.dispose();
//   }

//   int _calculateLateDays(DateTime? due, DateTime? returned) {
//     if (due == null) return 0;

//     final end = returned ?? DateTime.now();

//     final difference = DateTime(
//       end.year,
//       end.month,
//       end.day,
//     ).difference(
//       DateTime(due.year, due.month, due.day),
//     ).inDays;

//     return difference > 0 ? difference : 0;
//   }

//   // =====================================================
//   // TAMBAH DENDA
//   // =====================================================

//   Future<void> addFine() async {
//     final eligible = loans.where((loan) {
//       return loan['fine_paid'] != true;
//     }).toList();

//     if (eligible.isEmpty) {
//       showMessage('Tidak ada peminjaman yang bisa diberi denda.');
//       return;
//     }

//     String? selectedId = eligible.first['id'].toString();

//     final amountController = TextEditingController();

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               backgroundColor: Colors.white,
//               title: const Text(
//                 'Tambah Denda',
//                 style: TextStyle(
//                   color: navy,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               content: SizedBox(
//                 width: 340,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     DropdownButtonFormField<String>(
//                       value: selectedId,
//                       isExpanded: true,
//                       decoration: _inputDecoration(
//                         hint: 'Pilih peminjaman',
//                       ),
//                       items: eligible.map((loan) {
//                         return DropdownMenuItem<String>(
//                           value: loan['id'].toString(),
//                           child: Text(
//                             '${loan['member_name']} - ${loan['book_title']}',
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setDialogState(() {
//                           selectedId = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 14),
//                     TextField(
//                       controller: amountController,
//                       keyboardType: TextInputType.number,
//                       decoration: _inputDecoration(
//                         hint: 'Nominal denda',
//                         prefix: 'Rp ',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () =>
//                       Navigator.pop(dialogContext, false),
//                   child: const Text('Batal'),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: navy,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: () {
//                     final amount =
//                         double.tryParse(amountController.text);

//                     if (selectedId == null ||
//                         amount == null ||
//                         amount <= 0) {
//                       showMessage('Masukkan nominal denda yang valid.');
//                       return;
//                     }

//                     Navigator.pop(dialogContext, true);
//                   },
//                   child: const Text('Simpan'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     if (result == true && selectedId != null) {
//       try {
//         await supabase.from('borrowings').update({
//           'fine_amount': double.parse(amountController.text),
//           'fine_paid': false,
//           'fine_paid_at': null,
//         }).eq('id', int.parse(selectedId!));

//         if (!mounted) return;

//         showMessage('Denda berhasil ditambahkan.');
//         await loadReport();
//       } catch (e) {
//         showMessage('Gagal menambahkan denda: $e');
//       }
//     }

//     amountController.dispose();
//   }

//   // =====================================================
//   // HAPUS DENDA
//   // =====================================================

//   Future<void> deleteFine(Map<String, dynamic> loan) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(13),
//                 decoration: BoxDecoration(
//                   color: red.withOpacity(0.10),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.delete_outline,
//                   color: red,
//                   size: 25,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Hapus Data Denda?',
//                 style: TextStyle(
//                   color: navy,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 17,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Yakin ingin menghapus data denda berikut?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: muted,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _loanInfo(loan),
//               const SizedBox(height: 12),
//               const Text(
//                 'Data yang dihapus tidak dapat dipulihkan.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: muted,
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//           actionsAlignment: MainAxisAlignment.center,
//           actions: [
//             OutlinedButton(
//               onPressed: () =>
//                   Navigator.pop(dialogContext, false),
//               child: const Text('Batal'),
//             ),
//             ElevatedButton(
//               onPressed: () =>
//                   Navigator.pop(dialogContext, true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: red,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Hapus'),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirm != true) return;

//     try {
//       // Hanya menghapus data denda.
//       // Riwayat peminjaman tetap disimpan.
//       await supabase.from('borrowings').update({
//         'fine_amount': 0,
//         'fine_paid': false,
//         'fine_paid_at': null,
//       }).eq('id', loan['id']);

//       if (!mounted) return;

//       showMessage('Data denda berhasil dihapus.');
//       await loadReport();
//     } catch (e) {
//       showMessage('Gagal menghapus denda: $e');
//     }
//   }

//   // =====================================================
//   // KONFIRMASI PELUNASAN
//   // =====================================================

//   Future<void> payFine(Map<String, dynamic> loan) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(15),
//                 decoration: const BoxDecoration(
//                   color: cream,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.account_balance_wallet_rounded,
//                   color: navy,
//                   size: 27,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               const Text(
//                 'Konfirmasi Pelunasan',
//                 style: TextStyle(
//                   color: navy,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 17,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Apakah kamu yakin ingin mengubah status denda menjadi lunas?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: muted,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _loanInfo(loan),
//               const SizedBox(height: 10),
//               Text(
//                 'Nominal: ${formatMoney(effectiveFine(loan))}',
//                 style: const TextStyle(
//                   color: navy,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           actionsAlignment: MainAxisAlignment.center,
//           actions: [
//             OutlinedButton(
//               onPressed: () =>
//                   Navigator.pop(dialogContext, false),
//               child: const Text('Batal'),
//             ),
//             ElevatedButton(
//               onPressed: () =>
//                   Navigator.pop(dialogContext, true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: navy,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Ya, Sudah Lunas'),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirm != true) return;

//     try {
//       await supabase.from('borrowings').update({
//         'fine_amount': effectiveFine(loan),
//         'fine_paid': true,
//         'fine_paid_at': DateTime.now().toIso8601String(),
//       }).eq('id', loan['id']);

//       if (!mounted) return;

//       await loadReport();

//       if (!mounted) return;

//       showPaymentSuccess();
//     } catch (e) {
//       showMessage('Gagal mengonfirmasi pembayaran: $e');
//     }
//   }

//   void showPaymentSuccess() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: green.withOpacity(0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.check_circle_outline,
//                   color: green,
//                   size: 30,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Pembayaran Berhasil!',
//                 style: TextStyle(
//                   color: navy,
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Denda buku telah berhasil dinyatakan lunas.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: muted,
//                   fontSize: 11,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: navy,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Selesai'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // =====================================================
//   // NAVIGATION
//   // =====================================================

//   Future<void> navigateToPage(int index, Widget page) async {
//     setState(() => selectedIndex = index);

//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => page),
//     );

//     if (!mounted) return;

//     setState(() => selectedIndex = 0);

//     await loadReport();
//   }

//   void handleNavigation(int index) {
//     if (index == 0) {
//       Navigator.pop(context);
//     } else if (index == 1) {
//       navigateToPage(1, const KelolaBukuScreen());
//     } else if (index == 2) {
//       navigateToPage(2, const KelolaAnggotaPage());
//     } else if (index == 3) {
//       navigateToPage(3, const PeminjamanAdminScreen());
//     } else if (index == 4) {
//       // navigateToPage(4, const PengaturanAdminPage());
//     }
//   }

//   // =====================================================
//   // WIDGET HELPERS
//   // =====================================================

//   Widget _dialogLabel(String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         value,
//         style: const TextStyle(
//           color: navy,
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   InputDecoration _inputDecoration({
//     required String hint,
//     String? prefix,
//   }) {
//     return InputDecoration(
//       hintText: hint,
//       prefixText: prefix,
//       hintStyle: const TextStyle(
//         color: muted,
//         fontSize: 11,
//       ),
//       filled: true,
//       fillColor: cream,
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 12,
//       ),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(9),
//         borderSide: const BorderSide(color: border),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(9),
//         borderSide: const BorderSide(color: border),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(9),
//         borderSide: const BorderSide(color: navy),
//       ),
//     );
//   }

//   Widget _dateInput({
//     required TextEditingController controller,
//     required VoidCallback onTap,
//     String? hint,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(9),
//       child: IgnorePointer(
//         child: TextField(
//           controller: controller,
//           decoration: _inputDecoration(
//             hint: hint ?? 'Pilih tanggal',
//           ).copyWith(
//             suffixIcon: const Icon(
//               Icons.calendar_month_outlined,
//               color: navy,
//               size: 18,
//             ),
//           ),
//           style: const TextStyle(
//             color: navy,
//             fontSize: 11,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _loanInfo(Map<String, dynamic> loan) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F7FA),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Text(
//         'Peminjam : ${loan['member_name']}\n'
//         'Buku : ${loan['book_title']}\n'
//         'NIS : ${loan['member_nis']}',
//         style: const TextStyle(
//           color: navy,
//           fontSize: 11,
//           height: 1.6,
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // STATISTIC CARD
//   // =====================================================

//   Widget statisticCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     bool compact = false,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(11),
//       decoration: BoxDecoration(
//         color: cream,
//         border: Border.all(color: border),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Text(
//               title,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 color: navy,
//                 fontSize: 10,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(
//                 icon,
//                 color: navy,
//                 size: compact ? 23 : 25,
//               ),
//               const SizedBox(width: 7),
//               Expanded(
//                 child: FittedBox(
//                   fit: BoxFit.scaleDown,
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     value,
//                     style: TextStyle(
//                       color: navy,
//                       fontSize: compact ? 15 : 24,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // REPORT CARD
//   // =====================================================

//   Widget fineCard(Map<String, dynamic> loan) {
//     final amount = effectiveFine(loan);
//     final paid = isPaid(loan);
//     final days = lateDays(loan);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: navy.withOpacity(0.4)),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildCover(loan['book_cover']),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       loan['book_title']?.toString() ?? '-',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         color: navy,
//                         fontWeight: FontWeight.w800,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       loan['book_author']?.toString() ?? '-',
//                       style: const TextStyle(
//                         color: muted,
//                         fontSize: 9,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     _detailLine(
//                       'Jatuh Tempo',
//                       formatDate(loan['due_date']),
//                     ),
//                     const SizedBox(height: 3),
//                     _detailLine(
//                       'Terlambat',
//                       '$days Hari (${formatMoney(finePerDay)}/hari)',
//                     ),
//                     const SizedBox(height: 3),
//                     _detailLine(
//                       'Denda',
//                       formatMoney(amount),
//                       bold: true,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 5),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 7,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: paid
//                       ? green.withOpacity(0.12)
//                       : red.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   paid ? 'Lunas' : 'Belum Bayar',
//                   style: TextStyle(
//                     color: paid ? green : red,
//                     fontSize: 8,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               const Icon(
//                 Icons.person_outline,
//                 color: navy,
//                 size: 17,
//               ),
//               const SizedBox(width: 5),
//               Expanded(
//                 child: Text(
//                   'Peminjam: ${loan['member_name']} (ID: ${loan['member_nis']})',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: navy,
//                     fontSize: 9,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 9),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               _actionButton(
//                 'Edit',
//                 Icons.edit_outlined,
//                 navy,
//                 () => editFine(loan),
//               ),
//               const SizedBox(width: 5),
//               _actionButton(
//                 'Hapus',
//                 Icons.delete_outline,
//                 red,
//                 () => deleteFine(loan),
//               ),
//               const SizedBox(width: 5),
//               if (!paid)
//                 _actionButton(
//                   'Lunas',
//                   Icons.check,
//                   green,
//                   () => payFine(loan),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCover(dynamic url) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(7),
//       child: Container(
//         width: 65,
//         height: 94,
//         color: cream,
//         child: url != null && url.toString().isNotEmpty
//             ? Image.network(
//                 url.toString(),
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => _coverFallback(),
//               )
//             : _coverFallback(),
//       ),
//     );
//   }

//   Widget _coverFallback() {
//     return const Center(
//       child: Icon(
//         Icons.menu_book_rounded,
//         color: navy,
//         size: 30,
//       ),
//     );
//   }

//   Widget _detailLine(
//     String title,
//     String value, {
//     bool bold = false,
//   }) {
//     return RichText(
//       maxLines: 2,
//       overflow: TextOverflow.ellipsis,
//       text: TextSpan(
//         style: TextStyle(
//           color: navy,
//           fontSize: 9,
//           fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//         ),
//         children: [
//           TextSpan(text: '$title: '),
//           TextSpan(
//             text: value,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _actionButton(
//     String title,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return SizedBox(
//       height: 25,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 10),
//         label: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 9,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           padding: const EdgeInsets.symmetric(horizontal: 9),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // MAIN UI
//   // =====================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(color: navy),
//                     )
//                   : errorMessage != null
//                       ? _buildError()
//                       : RefreshIndicator(
//                           color: navy,
//                           onRefresh: loadReport,
//                           child: _buildContent(),
//                         ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: AdminBottomNavigation(
//         currentIndex: selectedIndex,
//         onTap: handleNavigation,
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(
//               Icons.arrow_back_ios_new_rounded,
//               color: navy,
//               size: 19,
//             ),
//           ),
//           const Expanded(
//             child: Text(
//               'Laporan',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: navy,
//                 fontSize: 17,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           InkWell(
//             onTap: chooseDateRange,
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 8,
//               ),
//               decoration: BoxDecoration(
//                 color: cream,
//                 border: Border.all(color: border),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.calendar_month_outlined,
//                     size: 13,
//                     color: navy,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     selectedRange == null
//                         ? 'Semua'
//                         : '${DateFormat('dd/MM/yy').format(selectedRange!.start)} - '
//                             '${DateFormat('dd/MM/yy').format(selectedRange!.end)}',
//                     style: const TextStyle(
//                       color: navy,
//                       fontSize: 8,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
//       children: [
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisSpacing: 9,
//           mainAxisSpacing: 9,
//           childAspectRatio: 1.65,
//           children: [
//             statisticCard(
//               title: 'Total Peminjaman',
//               value: totalLoans.toString(),
//               icon: Icons.calendar_month_outlined,
//             ),
//             statisticCard(
//               title: 'Buku Terpinjam',
//               value: borrowedBooks.toString(),
//               icon: Icons.assignment_turned_in_outlined,
//             ),
//             statisticCard(
//               title: 'Anggota Aktif',
//               value: activeMembers.toString(),
//               icon: Icons.person,
//             ),
//             statisticCard(
//               title: 'Buku Populer',
//               value: popularBook,
//               icon: Icons.menu_book_outlined,
//               compact: true,
//             ),
//             statisticCard(
//               title: 'Total Denda',
//               value: formatMoney(totalFine),
//               icon: Icons.account_balance_wallet_outlined,
//               compact: true,
//             ),
//             statisticCard(
//               title: 'Denda Aktif',
//               value: formatMoney(unpaidFine),
//               icon: Icons.access_time_filled,
//               compact: true,
//             ),
//           ],
//         ),
//         const SizedBox(height: 18),

//         Row(
//           children: [
//             const Expanded(
//               child: Text(
//                 'Kelola Denda Peminjaman',
//                 style: TextStyle(
//                   color: navy,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//             SizedBox(
//               height: 28,
//               child: ElevatedButton.icon(
//                 onPressed: addFine,
//                 icon: const Icon(Icons.add, size: 12),
//                 label: const Text(
//                   'Tambah Denda',
//                   style: TextStyle(fontSize: 9),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: navy,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 9),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         const Divider(color: border, height: 1),
//         const SizedBox(height: 12),

//         if (filteredLoans.where(hasFine).isEmpty)
//           _buildEmpty()
//         else
//           ...filteredLoans
//               .where(hasFine)
//               .map((loan) => fineCard(loan)),
//       ],
//     );
//   }

//   Widget _buildEmpty() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 55),
//       child: Column(
//         children: [
//           Container(
//             width: 65,
//             height: 65,
//             decoration: const BoxDecoration(
//               color: cream,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.receipt_long_outlined,
//               color: navy,
//               size: 30,
//             ),
//           ),
//           const SizedBox(height: 12),
//           const Text(
//             'Belum Ada Data Denda',
//             style: TextStyle(
//               color: navy,
//               fontWeight: FontWeight.bold,
//               fontSize: 13,
//             ),
//           ),
//           const SizedBox(height: 5),
//           const Text(
//             'Data denda peminjaman akan muncul di sini.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: muted,
//               fontSize: 10,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildError() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.cloud_off_outlined,
//               color: navy,
//               size: 45,
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'Gagal Memuat Laporan',
//               style: TextStyle(
//                 color: navy,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               errorMessage ?? '',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: muted,
//                 fontSize: 11,
//               ),
//             ),
//             const SizedBox(height: 15),
//             ElevatedButton.icon(
//               onPressed: loadReport,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Coba Lagi'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: navy,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
