
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // ==========================================
  // COLORS
  // ==========================================

  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.cream;
  static const Color gold = Color(0xFF8A6800);
  static const Color textColor = AppColors.text;
  static const Color mutedText = Color(0xFF65758A);

  static const String whatsappNumber = '081330662135';

  // FAQ mengikuti kebijakan peminjaman LokaBaca yang berlaku.
  final List<Map<String, String>> faqList = [
    {
      'question': 'Bagaimana cara meminjam buku di LokaBaca?',
      'answer':
          'Cari buku melalui menu Jelajah atau Pencarian, buka detail buku, '
          'lalu tekan "Ajukan Peminjaman". Pilih durasi 3 hari dan kirim '
          'pengajuan. Maksimal 3 buku dapat dipinjam sekaligus. Pengajuan '
          'akan diproses oleh admin sebelum buku dapat diambil.',
      'tip':
          'Cek status pengajuan melalui menu Riwayat Peminjaman.',
    },
    {
      'question': 'Berapa lama masa pinjam dan boleh diperpanjang?',
      'answer':
          'Masa peminjaman standar adalah 3 hari per buku. Perpanjangan '
          'dapat dilakukan 1 kali untuk tambahan 3 hari, melalui aplikasi '
          'sebelum batas jatuh tempo.',
      'tip':
          'Perpanjang lebih awal agar tidak dikenakan denda keterlambatan.',
    },
    {
      'question': 'Bagaimana perhitungan denda keterlambatan?',
      'answer':
          'Denda dikenakan Rp1.000 per hari untuk setiap buku yang telat '
          'dikembalikan. Tagihan muncul otomatis di menu "Denda Saya". '
          'Bayar melalui QRIS, lalu kirim bukti pembayaran untuk diverifikasi '
          'admin. Status denda baru berubah lunas setelah konfirmasi admin.',
      'tip':
          'Simpan bukti transfer sampai status denda berubah menjadi Lunas.',
    },
    {
      'question': 'Bagaimana cara mengembalikan buku?',
      'answer':
          'Kembalikan buku fisik ke petugas perpustakaan sebelum jatuh tempo. '
          'Petugas akan mengonfirmasi pengembalian di aplikasi sehingga status '
          'peminjaman berubah menjadi Selesai.',
      'tip':
          'Pastikan kondisi buku tetap baik saat dikembalikan.',
    },
    {
      'question': 'Apa bedanya Koleksi dan Wishlist?',
      'answer':
          'Wishlist berisi buku yang ingin kamu baca (tombol hati) dan belum '
          'tentu dipinjam. Koleksi berisi buku yang sedang atau pernah kamu '
          'pinjam dari hasil pengajuan peminjaman yang disetujui.',
      'tip':
          'Gunakan hati untuk wishlist dan tombol "Ajukan Peminjaman" '
          'untuk menambah koleksi.',
    },
  ];

  // ==========================================
  // WHATSAPP SERVICE
  // ==========================================

  Future<void> _contactWhatsApp() async {
    final greeting = Uri.encodeComponent(
      'Halo LokaBaca, saya membutuhkan bantuan terkait peminjaman buku.',
    );
    // Format WhatsApp internasional: 0813... -> 62813...
    final internationalNumber =
        whatsappNumber.replaceFirst('0', '62');
    final url = Uri.parse(
      'https://wa.me/$internationalNumber?text=$greeting',
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp.'),
            backgroundColor: navy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka WhatsApp.'),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 13,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: navy,
              size: 22,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Bantuan',
                style: TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  // ==========================================
  // WHATSAPP CARD
  // ==========================================

  Widget _buildWhatsAppCard() {
    return InkWell(
      onTap: _contactWhatsApp,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ICON WHATSAPP
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_outlined,
                color: Color(0xFFFFC34D),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // TEXT
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Layanan WhatsApp',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '081330662135 (08.00 - 20.00)',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ICON EXTERNAL LINK
            Container(
              width: 37,
              height: 37,
              decoration: const BoxDecoration(
                color: navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FAQ TITLE
  // ==========================================

  Widget _buildFAQTitle() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Pertanyaan umum',
        style: TextStyle(
          color: navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================
  // FAQ CARD
  // ==========================================

  Widget _buildFAQCard(Map<String, String> faq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 7,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            15, 0, 15, 15,
          ),
          iconColor: mutedText,
          collapsedIconColor: mutedText,

          // PERTANYAAN
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.circle,
                  color: gold,
                  size: 8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  faq['question'] ?? '',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          // JAWABAN DAN TIPS
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq['answer'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFF514B40),
                      fontSize: 12,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TIPS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: gold,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: gold,
                              fontSize: 10,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Tips: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: faq['tip'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  22, 20, 22, 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WHATSAPP
                    _buildWhatsAppCard(),

                    const SizedBox(height: 55),

                    // FAQ TITLE
                    _buildFAQTitle(),

                    const SizedBox(height: 22),

                    // FAQ LIST
                    ...faqList.map(
                      (faq) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 15,
                        ),
                        child: _buildFAQCard(faq),
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
}
