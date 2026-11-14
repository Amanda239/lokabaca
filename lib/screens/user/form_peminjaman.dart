
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
  int selectedDuration = 14;

  final TextEditingController noteController =
      TextEditingController();

  bool isLoading = false;

  DateTime get dueDate {
    return DateTime.now().add(
      Duration(days: selectedDuration),
    );
  }

  String get formattedDate {
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

    return '${dueDate.day.toString().padLeft(2, '0')} '
        '${months[dueDate.month - 1]} ${dueDate.year}';
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
  }

  void _submitBorrowing() {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Sementara menampilkan konfirmasi.
    // Proses penyimpanan ke Supabase ditambahkan setelah
    // struktur tabel borrowings dipastikan.

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Form peminjaman siap diajukan.',
      );
    });
  }

  Widget _buildCover(String cover) {
    if (cover.isEmpty) {
      return Container(
        color: const Color(0xFFECE5D5),
        child: const Icon(
          Icons.menu_book_rounded,
          size: 45,
          color: AppColors.navy,
        ),
      );
    }

    if (cover.startsWith('http')) {
      return Image.network(
        cover,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.menu_book_rounded,
            color: AppColors.navy,
            size: 45,
          );
        },
      );
    }

    return Image.asset(
      cover,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.menu_book_rounded,
          color: AppColors.navy,
          size: 45,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    final title = book['title']?.toString() ?? 'Judul Buku';
    final author = book['author']?.toString() ?? 'Penulis';
    final cover = (book['cover_url'] ?? book['cover'] ?? '')
        .toString();

    final stock = book['stock'] ?? 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navy,
                      size: 21,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Form Peminjaman',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  34,
                  25,
                  34,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INFORMASI BUKU
                    Row(
                      children: [
                        Container(
                          width: 98,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 5,
                                offset: const Offset(2, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: _buildCover(cover),
                          ),
                        ),

                        const SizedBox(width: 23),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                author,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 52),
                              Text(
                                'Tersedia $stock',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 42),

                    // DURASI PEMINJAMAN
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Durasi Peminjaman',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'Dapat diperpanjang 1x',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        _durationButton(7),
                        const SizedBox(width: 24),
                        _durationButton(14),
                      ],
                    ),

                    const SizedBox(height: 27),

                    // TANGGAL JATUH TEMPO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 4,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.navy,
                            size: 22,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'JATUH TEMPO PENGEMBALIAN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA9D9B8),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Bebas Biaya (Gratis)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF355B43),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // CATATAN
                    const Text(
                      'Catatan (opsional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Tulis catatan jika diperlukan..',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // INFORMASI DENDA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5D7CC),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.navy,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Maksimal perpanjangan masa pinjam 1x per buku. Denda keterlambatan buku berlaku Rp1.000/hari.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TOMBOL AJUKAN
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : _submitBorrowing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ajukan Peminjaman',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TOMBOL DURASI
  Widget _durationButton(int days) {
    final isSelected = selectedDuration == days;

    return InkWell(
      onTap: () {
        setState(() {
          selectedDuration = days;
        });
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 90,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.navy
              : const Color(0xFFFAF5EB),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Text(
          '$days Hari',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? Colors.white
                : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
