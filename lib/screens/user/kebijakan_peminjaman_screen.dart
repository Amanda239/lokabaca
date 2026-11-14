
import 'package:flutter/material.dart';

class KebijakanPeminjamanScreen extends StatefulWidget {
  const KebijakanPeminjamanScreen({super.key});

  @override
  State<KebijakanPeminjamanScreen> createState() =>
      _KebijakanPeminjamanScreenState();
}

class _KebijakanPeminjamanScreenState
    extends State<KebijakanPeminjamanScreen> {
  static const Color navy = Color(0xFF203F70);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color borderColor = Color(0xFFDCE5F0);

  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: navy,
                      size: 21,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Kebijakan Peminjaman',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ILUSTRASI BUKU
                    SizedBox(
                      height: 125,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 5,
                            left: 65,
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4CE)
                                    .withOpacity(0.55),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.menu_book_rounded,
                            color: navy,
                            size: 112,
                          ),
                          Positioned(
                            right: 65,
                            bottom: 4,
                            child: Container(
                              width: 43,
                              height: 49,
                              decoration: BoxDecoration(
                                color: navy,
                                borderRadius:
                                    BorderRadius.circular(5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(1, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Dengan menyetujui, Anda memahami seluruh ketentuan\n'
                      'peminjaman buku berikut.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: navy,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // KARTU KEBIJAKAN
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _policyItem(
                            icon: Icons.person,
                            title: 'Ketentuan Pengguna',
                            description:
                                'Berlaku untuk seluruh anggota aktif perpustakaan.',
                          ),

                          _policyItem(
                            icon: Icons.menu_book_outlined,
                            title: 'Kebijakan Peminjaman',
                            bullets: [
                              'Maksimal 3 buku sekaligus.',
                              'Durasi peminjaman 3 hari.',
                            ],
                          ),

                          _policyItem(
                            icon: Icons.event_repeat_outlined,
                            title: 'Penambahan Hari',
                            description:
                                'Dapat diperpanjang 1x (3 hari) melalui aplikasi sebelum jatuh tempo.',
                          ),

                          _policyItem(
                            icon: Icons.payments_outlined,
                            title: 'Denda',
                            bullets: [
                              'Keterlambatan dikenakan denda Rp1.000/hari per buku.',
                              'Denda wajib dibayar melalui akun Anda.',
                            ],
                            specialIcon: 'Rp',
                          ),

                          _policyItem(
                            icon: Icons.warning_amber_rounded,
                            title: 'Jika Buku Hilang atau Rusak',
                            bullets: [
                              'Buku hilang: wajib ganti buku serupa atau bayar seharga buku.',
                              'Buku rusak: wajib ganti atau perbaiki sesuai tingkat kerusakan.',
                            ],
                          ),

                          _policyItem(
                            icon: Icons.block_rounded,
                            title: 'Sanksi Pelanggaran',
                            description:
                                'Pelanggaran dapat mengakibatkan pembekuan akun atau pencabutan hak pinjam.',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CHECKBOX PERSETUJUAN
                    InkWell(
                      onTap: () {
                        setState(() {
                          isAgreed = !isAgreed;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2E3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD4A8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isAgreed,
                              onChanged: (value) {
                                setState(() {
                                  isAgreed = value ?? false;
                                });
                              },
                              activeColor: navy,
                              side: const BorderSide(
                                color: navy,
                                width: 1.5,
                              ),
                              visualDensity:
                                  VisualDensity.compact,
                            ),
                            const Expanded(
                              child: Text(
                                'Saya telah membaca dan menyetujui seluruh ketentuan peminjaman buku ini.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // TOMBOL SETUJU
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isAgreed
                            ? () {
                                Navigator.pop(context, true);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          disabledBackgroundColor:
                              const Color(0xFFB7C2D0),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Setuju dan Lanjut',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ITEM KEBIJAKAN
  Widget _policyItem({
    required IconData icon,
    required String title,
    String? description,
    List<String>? bullets,
    String? specialIcon,
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFEDF1F5),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: specialIcon != null
                  ? navy
                  : const Color(0xFFEEF4FC),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: specialIcon != null
                ? Text(
                    specialIcon,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(
                    icon,
                    color: navy,
                    size: 20,
                  ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                if (description != null)
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF35445D),
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),

                if (bullets != null)
                  ...bullets.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 3,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '•  ',
                            style: TextStyle(
                              color: navy,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Color(0xFF35445D),
                                fontSize: 11.5,
                                height: 1.5,
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
        ],
      ),
    );
  }
}
