
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';

class UlasanBukuScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const UlasanBukuScreen({
    super.key,
    required this.book,
  });

  @override
  State<UlasanBukuScreen> createState() => _UlasanBukuScreenState();
}

class _UlasanBukuScreenState extends State<UlasanBukuScreen> {
  final supabase = Supabase.instance.client;

  static const int reviewsPerPage = 10;

  List<Map<String, dynamic>> reviews = [];
  Set<String> helpfulReviewIds = {};

  bool isLoading = true;
  bool isSubmitting = false;

  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  String get bookId => widget.book['id'].toString();

  String get bookTitle =>
      widget.book['title']?.toString() ?? 'Judul Buku';

  // LOAD ULASAN
  Future<void> loadReviews() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('reviews')
          .select()
          .eq('book_id', widget.book['id'])
          .order('created_at', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);

      Set<String> helpfulIds = {};

      if (user != null && data.isNotEmpty) {
        final reviewIds = data
            .map((review) => review['id'])
            .toList();

        final helpfulResponse = await supabase
            .from('review_helpful')
            .select('review_id')
            .eq('user_id', user.id)
            .inFilter('review_id', reviewIds);

        helpfulIds = helpfulResponse
            .map<String>(
              (item) => item['review_id'].toString(),
            )
            .toSet();
      }

      if (!mounted) return;

      setState(() {
        reviews = data;
        helpfulReviewIds = helpfulIds;
        currentPage = 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Gagal memuat ulasan: $e');
    }
  }

  // RATA-RATA RATING
  double get averageRating {
    if (reviews.isEmpty) return 0;

    final total = reviews.fold<double>(
      0,
      (sum, review) =>
          sum + (review['rating'] as num).toDouble(),
    );

    return total / reviews.length;
  }

  // JUMLAH PEMBACA UNIK
  int get totalReaders {
    return reviews
        .map((review) => review['user_id'].toString())
        .toSet()
        .length;
  }

  // PERSENTASE REKOMENDASI
  int get recommendationPercentage {
    if (reviews.isEmpty) return 0;

    final recommended = reviews.where((review) {
      return (review['rating'] as num).toDouble() >= 4;
    }).length;

    return ((recommended / reviews.length) * 100).round();
  }

  // DISTRIBUSI RATING
  int ratingCount(int star) {
    return reviews.where((review) {
      return (review['rating'] as num).round() == star;
    }).length;
  }

  double ratingPercentage(int star) {
    if (reviews.isEmpty) return 0;

    return ratingCount(star) / reviews.length;
  }

  // JUMLAH HALAMAN
  int get totalPages {
    if (reviews.isEmpty) return 0;

    return (reviews.length / reviewsPerPage).ceil();
  }

  // ULASAN DI HALAMAN AKTIF
  List<Map<String, dynamic>> get currentReviews {
    final start = currentPage * reviewsPerPage;

    if (start >= reviews.length) return [];

    final end = (start + reviewsPerPage)
        .clamp(0, reviews.length);

    return reviews.sublist(start, end);
  }

  void changePage(int page) {
    if (page < 0 || page >= totalPages) return;

    setState(() {
      currentPage = page;
    });
  }

  // FORMAT TANGGAL
  String formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

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

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '-';
    }
  }

  // WAKTU RELATIF
  String timeAgo(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final difference = DateTime.now().difference(date);

      if (difference.inMinutes < 1) return 'Baru saja';
      if (difference.inHours < 1) {
        return '${difference.inMinutes} menit lalu';
      }
      if (difference.inDays < 1) {
        return '${difference.inHours} jam lalu';
      }
      if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      }

      return formatDate(value);
    } catch (_) {
      return '-';
    }
  }

  // TAG KOMUNITAS DARI DATA ULASAN
  List<MapEntry<String, int>> get popularTags {
    final Map<String, int> counts = {};

    for (final review in reviews) {
      final tags = review['tags'];

      if (tags is List) {
        for (final tag in tags) {
          final name = tag.toString().trim();

          if (name.isNotEmpty) {
            counts[name] = (counts[name] ?? 0) + 1;
          }
        }
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(5).toList();
  }

  // TOGGLE MEMBANTU
  Future<void> toggleHelpful(
    Map<String, dynamic> review,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    final reviewId = review['id'].toString();
    final alreadyHelpful =
        helpfulReviewIds.contains(reviewId);

    try {
      if (alreadyHelpful) {
        await supabase
            .from('review_helpful')
            .delete()
            .eq('review_id', review['id'])
            .eq('user_id', user.id);

        if (!mounted) return;

        setState(() {
          helpfulReviewIds.remove(reviewId);
        });
      } else {
        await supabase.from('review_helpful').insert({
          'review_id': review['id'],
          'user_id': user.id,
        });

        if (!mounted) return;

        setState(() {
          helpfulReviewIds.add(reviewId);
        });
      }
    } catch (e) {
      _showMessage('Gagal memperbarui vote: $e');
    }
  }

  // JUMLAH VOTE MEMBANTU
  Future<int> helpfulCount(String reviewId) async {
    try {
      final response = await supabase
          .from('review_helpful')
          .select('id')
          .eq('review_id', reviewId);

      return response.length;
    } catch (_) {
      return 0;
    }
  }

  // TAMBAH ULASAN
  Future<void> submitReview({
    required double rating,
    required String content,
    required List<String> tags,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (content.trim().isEmpty) {
      _showMessage('Isi ulasan terlebih dahulu.');
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      final metadata = user.userMetadata ?? {};

      final userName =
          metadata['full_name'] ??
          metadata['name'] ??
          user.email?.split('@').first ??
          'Pengguna';

      await supabase.from('reviews').insert({
        'book_id': widget.book['id'],
        'user_id': user.id,
        'user_name': userName.toString(),
        'rating': rating,
        'content': content.trim(),
        'tags': tags,
      });

      if (!mounted) return;

      Navigator.pop(context);

      _showMessage('Ulasan berhasil dikirim.');

      await loadReviews();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal mengirim ulasan: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // DIALOG TULIS ULASAN
  void showReviewForm() {
    final controller = TextEditingController();

    double selectedRating = 5;

    final selectedTags = <String>[];

    const availableTags = [
      'Alur Memukau',
      'Menguras Emosi',
      'Penuh Wawasan',
      'Mudah Dipahami',
      'Karakter Menarik',
      'Inspiratif',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tulis Ulasan',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      bookTitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Berikan penilaianmu',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;

                        return IconButton(
                          onPressed: () {
                            setSheetState(() {
                              selectedRating = star.toDouble();
                            });
                          },
                          icon: Icon(
                            selectedRating >= star
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC83D),
                            size: 31,
                          ),
                        );
                      }),
                    ),
                    Text(
                      '${selectedRating.toStringAsFixed(0)} dari 5',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Ceritakan pendapatmu',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText:
                            'Apa yang kamu sukai dari buku ini?',
                        filled: true,
                        fillColor: const Color(0xFFFAF5EB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih tag yang sesuai',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: availableTags.map((tag) {
                        final selected =
                            selectedTags.contains(tag);

                        return FilterChip(
                          label: Text(tag),
                          selected: selected,
                          selectedColor:
                              AppColors.yellow.withValues(alpha: 0.35),
                          onSelected: (value) {
                            setSheetState(() {
                              if (value) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                submitReview(
                                  rating: selectedRating,
                                  content: controller.text,
                                  tags: selectedTags,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Kirim Ulasan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.navy,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: loadReviews,
                      child: SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildCommunitySummary(),
                            const SizedBox(height: 25),
                            _buildWriteReviewButton(),
                            const SizedBox(height: 25),
                            if (reviews.isEmpty)
                              _buildEmptyState()
                            else ...[
                              ...currentReviews.map(
                                (review) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 16,
                                  ),
                                  child: _buildReviewCard(review),
                                ),
                              ),
                              if (totalPages > 1)
                                _buildPagination(),
                            ],
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Padding(
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
          const Expanded(
            child: Text(
              'Ulasan & Penilaian Buku',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          IconButton(
            onPressed: loadReviews,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  // RINGKASAN KOMUNITAS
  Widget _buildCommunitySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.navy),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Komunitas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              Text(
                '$totalReaders Pembaca',
                style: const TextStyle(
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
                      reviews.isEmpty
                          ? '-'
                          : averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 44,
                        color: Colors.black87,
                      ),
                    ),
                    _buildStars(averageRating),
                    const SizedBox(height: 5),
                    Text(
                      '$recommendationPercentage% Rekomendasi',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      '${reviews.length} Penilaian',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;

                    return _ratingBar(
                      star,
                      ratingPercentage(star),
                      ratingCount(star),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (popularTags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 7,
              children: popularTags.map((tag) {
                return _tag(
                  tag.key,
                  tag.value.toString(),
                );
              }).toList(),
            )
          else
            const Text(
              'Belum ada tag ulasan.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.grey,
              ),
            ),
        ],
      ),
    );
  }

  // STAR RATING
  Widget _buildStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = rating - index;

        return Icon(
          value >= 0.75
              ? Icons.star
              : value >= 0.25
                  ? Icons.star_half
                  : Icons.star_border,
          color: const Color(0xFFFFC83D),
          size: 17,
        );
      }),
    );
  }

  // RATING BAR
  Widget _ratingBar(
    int star,
    double percentage,
    int count,
  ) {
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
                value: percentage,
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
              '$count',
              textAlign: TextAlign.end,
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

  // TAG
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
      child: Text(
        '$name ($count)',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // TOMBOL TULIS ULASAN
  Widget _buildWriteReviewButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: showReviewForm,
        icon: const Icon(
          Icons.rate_review_outlined,
          size: 17,
        ),
        label: const Text(
          'Tulis Ulasan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // KARTU ULASAN
  Widget _buildReviewCard(
    Map<String, dynamic> review,
  ) {
    final reviewId = review['id'].toString();

    final isHelpful =
        helpfulReviewIds.contains(reviewId);

    final rating =
        (review['rating'] as num).toDouble();

    final userName =
        review['user_name']?.toString() ?? 'Pengguna';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFE7DDC9),
                child: Icon(
                  Icons.person,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      '${timeAgo(review['created_at'])} • '
                      'Rating ${rating.toStringAsFixed(1)}/5',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStars(rating),
          const SizedBox(height: 8),
          Text(
            review['content']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () => toggleHelpful(review),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isHelpful
                        ? const Color(0xFF54745F)
                        : AppColors.navy,
                    borderRadius: BorderRadius.circular(20),
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
                        isHelpful ? 'Membantu' : 'Membantu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FutureBuilder<int>(
                future: helpfulCount(reviewId),
                builder: (context, snapshot) {
                  return Text(
                    '${snapshot.data ?? 0} orang merasa terbantu',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 35,
            color: AppColors.navy,
          ),
          SizedBox(height: 10),
          Text(
            'Belum Ada Ulasan',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Jadilah pembaca pertama yang memberikan ulasan untuk buku ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // PAGINATION
  Widget _buildPagination() {
    return Column(
      children: [
        Text(
          'Halaman ${currentPage + 1} dari $totalPages',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: currentPage > 0
                  ? () => changePage(currentPage - 1)
                  : null,
              icon: const Icon(
                Icons.chevron_left_rounded,
              ),
              color: AppColors.navy,
            ),
            ...List.generate(totalPages, (index) {
              final selected = currentPage == index;

              return GestureDetector(
                onTap: () => changePage(index),
                child: Container(
                  width: 29,
                  height: 29,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.navy
                        : Colors.white,
                    border: Border.all(
                      color: AppColors.navy,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
            IconButton(
              onPressed: currentPage < totalPages - 1
                  ? () => changePage(currentPage + 1)
                  : null,
              icon: const Icon(
                Icons.chevron_right_rounded,
              ),
              color: AppColors.navy,
            ),
          ],
        ),
      ],
    );
  }
}
