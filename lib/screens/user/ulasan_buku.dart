
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UlasanBukuScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const UlasanBukuScreen({
    super.key,
    required this.book,
  });

  @override
  State<UlasanBukuScreen> createState() =>
      _UlasanBukuScreenState();
}

class _UlasanBukuScreenState
    extends State<UlasanBukuScreen> {

  bool isHelpful = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.book['title'] ?? 'Judul Buku';
    final rating = widget.book['rating'] ?? '4.8';

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
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Ulasan & Penilaian Buku',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 8,
                ),
                child: Column(
                  children: [

                    // RINGKASAN KOMUNITAS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.navy,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 5,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Ringkasan Komunitas',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '1.240 Pembaca',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    Text(
                                      '$rating',
                                      style: const TextStyle(
                                        fontSize: 44,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star,
                                            color: Color(0xFFFFC83D),
                                            size: 17),
                                        Icon(Icons.star,
                                            color: Color(0xFFFFC83D),
                                            size: 17),
                                        Icon(Icons.star,
                                            color: Color(0xFFFFC83D),
                                            size: 17),
                                        Icon(Icons.star,
                                            color: Color(0xFFFFC83D),
                                            size: 17),
                                        Icon(Icons.star_half,
                                            color: Color(0xFFFFC83D),
                                            size: 17),
                                      ],
                                    ),
                                    const Text(
                                      '98% Rekomendasi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _ratingBar(5, 82),
                                    _ratingBar(4, 12),
                                    _ratingBar(3, 4),
                                    _ratingBar(2, 1),
                                    _ratingBar(1, 1),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Wrap(
                            spacing: 6,
                            runSpacing: 7,
                            children: [
                              _tag('Alur Memukau', '820'),
                              _tag('Menguras Emosi', '610'),
                              _tag('Penuh Wawasan Sejarah', '540'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // KARTU ULASAN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EB),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 19,
                                backgroundColor: Color(0xFFF1EDE1),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amanda Nathania',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Kemarin • Rating 4,5/5',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.more_vert,
                                color: AppColors.navy,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          const Row(
                            children: [
                              Icon(Icons.star,
                                  color: Color(0xFFFFC83D),
                                  size: 17),
                              Icon(Icons.star,
                                  color: Color(0xFFFFC83D),
                                  size: 17),
                              Icon(Icons.star,
                                  color: Color(0xFFFFC83D),
                                  size: 17),
                              Icon(Icons.star,
                                  color: Color(0xFFFFC83D),
                                  size: 17),
                              Icon(Icons.star_half,
                                  color: Color(0xFFFFC83D),
                                  size: 17),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '$title benar-benar bikin aku ikut larut dalam ceritanya. Banyak bagian yang bikin sedih, marah, sekaligus terharu karena kisah para tokohnya terasa sangat nyata. Alurnya seru dan bikin penasaran, jadi susah berhenti baca.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    isHelpful = !isHelpful;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isHelpful
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_alt_outlined,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isHelpful
                                            ? 'Membantu (25)'
                                            : 'Membantu (24)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Balas',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              const Text(
                                'Dibaca 240x',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // TOMBOL ULASAN LAINNYA
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ulasan lainnya akan segera tersedia.',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          42,
                        ),
                        foregroundColor: AppColors.navy,
                        backgroundColor:
                            const Color(0xFFFAF5EB),
                        side: const BorderSide(
                          color: AppColors.navy,
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tampilkan 18 Ulasan Lainnya',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BAR RATING
  Widget _ratingBar(int star, int percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 15,
            child: Text(
              '$star',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.navy,
              ),
            ),
          ),
          const Icon(
            Icons.star,
            color: Color(0xFFB28A00),
            size: 12,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFECE8DC),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFCC55),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 27,
            child: Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAG KOMUNITAS
  Widget _tag(String name, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ' ($count)',
              style: const TextStyle(
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
