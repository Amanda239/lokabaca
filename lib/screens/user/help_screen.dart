
import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // ==========================================
  // COLORS
  // ==========================================

  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color gold = Color(0xFF8A6800);
  static const Color textColor = Color(0xFF282828);
  static const Color mutedText = Color(0xFF65758A);

  // FAQ yang ditampilkan
  final List<Map<String, String>> faqList = [
    {
      'question': 'Berapa lama batas waktu peminjaman buku fisik?',
      'answer':
          'Maksimal peminjaman adalah 30 hari dengan kuota 2 buku. '
          'Pengguna dapat memperpanjang 1x (7 hari tambahan) melalui '
          'aplikasi selama buku tidak sedang direservasi antrean pembaca lain.',
      'tip':
          'Perpanjang H-2 sebelum jatuh tempo via menu Rak Saya.',
    },
  ];

  // ==========================================
  // WHATSAPP SERVICE
  // ==========================================

  void _contactWhatsApp() {
    // Frontend sementara.
    // Nomor WhatsApp dapat dihubungkan setelah nomor resmi tersedia.

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Layanan WhatsApp',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          content: const Text(
            'Hubungi layanan bantuan LokaBaca melalui WhatsApp pada '
            'jam operasional pukul 08.00 - 20.00.',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Tutup',
                style: TextStyle(color: navy),
              ),
            ),
          ],
        );
      },
    );
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
              color: Colors.black.withOpacity(0.20),
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
                    '+62 811-LOKABACA (08.00 - 20.00)',
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
            color: Colors.black.withOpacity(0.22),
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
