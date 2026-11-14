
import 'package:flutter/material.dart';

class TentangLokaBacaScreen extends StatelessWidget {
  const TentangLokaBacaScreen({super.key});

  static const Color navy = Color(0xFF2E4057);

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
                horizontal: 20,
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
                        'Tentang LokaBaca',
                        style: TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
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
                padding: const EdgeInsets.fromLTRB(
                  23,
                  43,
                  23,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TENTANG LOKABACA
                    _sectionTitle('Situs LokaBaca'),

                    const SizedBox(height: 5),

                    _description(
                      'LokaBaca merupakan layanan perpustakaan '
                      'digital yang memudahkan pengguna untuk '
                      'menemukan, meminjam, dan membaca berbagai '
                      'koleksi buku digital kapan saja dan di mana '
                      'saja. Melalui aplikasi LokaBaca, pengguna '
                      'dapat mengakses berbagai genre buku, mulai '
                      'dari fiksi, nonfiksi, pendidikan, hingga '
                      'referensi akademik dalam satu platform '
                      'yang praktis.',
                    ),

                    const SizedBox(height: 16),

                    _description(
                      'LokaBaca bekerja sama dengan berbagai '
                      'penerbit dan penyedia konten digital untuk '
                      'menghadirkan koleksi bacaan yang beragam '
                      'dan berkualitas. Dengan ribuan judul buku '
                      'yang tersedia, LokaBaca berkomitmen untuk '
                      'meningkatkan minat baca masyarakat melalui '
                      'akses literasi yang mudah dan modern.',
                    ),

                    const SizedBox(height: 22),

                    // CUSTOMER SERVICE
                    _sectionTitle(
                      'Di mana aku bisa menghubungi '
                      'Customer Service?',
                    ),

                    const SizedBox(height: 9),

                    _description(
                      'Perlu bantuan? Hubungi kami di:',
                    ),

                    _description(
                      'Chat : Buka aplikasi atau situs LokaBaca '
                      'dan klik ikon bantuan.',
                    ),

                    _contactText(
                      'Email : support@lokabaca.com',
                    ),

                    _contactText(
                      'Instagram : @lokabaca.id',
                    ),

                    const SizedBox(height: 25),

                    // MEDIA SOSIAL
                    _sectionTitle(
                      'Di mana aku bisa menyapa LokaBaca '
                      'di media sosial?',
                    ),

                    const SizedBox(height: 9),

                    _description(
                      'Kami hadir di berbagai platform media '
                      'sosial untuk berbagi informasi terbaru, '
                      'rekomendasi buku, dan berbagai kegiatan '
                      'literasi.',
                    ),

                    _contactText(
                      'Instagram : @lokabaca.id',
                    ),

                    _contactText(
                      'TikTok : @lokabaca.id',
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

  // JUDUL BAGIAN
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: navy,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.4,
      ),
    );
  }

  // DESKRIPSI
  Widget _description(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: navy,
        fontSize: 12.5,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.left,
    );
  }

  // INFORMASI KONTAK
  Widget _contactText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: navy,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}
