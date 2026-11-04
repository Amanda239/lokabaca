import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPeminjamanScreen extends StatefulWidget {
  final int borrowingId;

  const DetailPeminjamanScreen({
    super.key,
    required this.borrowingId,
  });

  @override
  State<DetailPeminjamanScreen> createState() =>
      _DetailPeminjamanScreenState();
}

class _DetailPeminjamanScreenState
    extends State<DetailPeminjamanScreen> {

  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFF8993A1);

  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? borrowing;

  @override
  void initState() {
    super.initState();
    loadBorrowingDetail();
  }

  // ==========================================
  // LOAD DATA PEMINJAMAN
  // ==========================================

  Future<void> loadBorrowingDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await supabase
          .from('borrowings')
          .select('''
            id,
            user_id,
            book_id,
            borrowed_at,
            due_date,
            returned_at,
            status,
            created_at,
            books (
              id,
              title,
              author,
              category,
              description,
              cover_url,
              stock
            ),
            profiles (
              id,
              full_name,
              nis,
              role,
              status
            )
          ''')
          .eq('id', widget.borrowingId)
          .single();

      if (!mounted) return;

      setState(() {
        borrowing = Map<String, dynamic>.from(response);
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

  // ==========================================
  // FORMAT TANGGAL
  // ==========================================

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

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
  }

  // ==========================================
  // STATUS PEMINJAMAN
  // ==========================================

  String getStatusText(
    String status,
    dynamic dueDate,
  ) {
    final normalized = status.toLowerCase();

    final due = DateTime.tryParse(
      dueDate?.toString() ?? '',
    );

    if (normalized == 'dipinjam' &&
        due != null &&
        due.isBefore(DateTime.now())) {
      return 'Terlambat';
    }

    switch (normalized) {
      case 'dipinjam':
        return 'Dipinjam';

      case 'borrowed':
        return 'Dipinjam';

      case 'dikembalikan':
        return 'Dikembalikan';

      case 'returned':
        return 'Dikembalikan';

      case 'terlambat':
        return 'Terlambat';

      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dikembalikan':
      case 'returned':
        return const Color(0xFFB9E4CD);

      case 'terlambat':
        return const Color(0xFFFFD6D6);

      default:
        return const Color(0xFFFFD36A);
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'dikembalikan':
      case 'returned':
        return const Color(0xFF315F46);

      case 'terlambat':
        return const Color(0xFFB83232);

      default:
        return const Color(0xFF76551A);
    }
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
              child: isLoading
                  ? _buildLoading()
                  : errorMessage != null
                      ? _buildError()
                      : borrowing == null
                          ? _buildEmpty()
                          : _buildContent(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16, 12, 16, 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: navy,
              size: 20,
            ),
          ),

          const Expanded(
            child: Text(
              'Detail Peminjaman',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ==========================================
  // LOADING
  // ==========================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: navy,
      ),
    );
  }

  // ==========================================
  // ERROR
  // ==========================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: navy,
              size: 45,
            ),

            const SizedBox(height: 12),

            const Text(
              'Gagal Memuat Detail',
              style: TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadBorrowingDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY
  // ==========================================

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Data peminjaman tidak ditemukan',
        style: TextStyle(
          color: mutedText,
          fontSize: 13,
        ),
      ),
    );
  }

  // ==========================================
  // CONTENT
  // ==========================================

  Widget _buildContent() {
    final book = borrowing!['books']
        as Map<String, dynamic>? ?? {};

    final profile = borrowing!['profiles']
        as Map<String, dynamic>? ?? {};

    final status =
        borrowing!['status']?.toString() ?? '-';

    final statusText = getStatusText(
      status,
      borrowing!['due_date'],
    );

    return RefreshIndicator(
      color: navy,
      onRefresh: loadBorrowingDetail,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16, 10, 16, 25,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // INFORMASI BUKU

            _buildBookCard(book),

            const SizedBox(height: 27),

            // INFORMASI ANGGOTA

            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: Text(
                'Informasi anggota',
                style: TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildMemberCard(profile),

            const SizedBox(height: 17),

            // INFORMASI PEMINJAMAN

            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: Text(
                'Informasi peminjaman',
                style: TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildBorrowingInfo(statusText),

          ],
        ),
      ),
    );
  }

  // ==========================================
  // BOOK CARD
  // ==========================================

  Widget _buildBookCard(
    Map<String, dynamic> book,
  ) {
    final title =
        book['title']?.toString() ?? 'Buku';

    final author =
        book['author']?.toString() ?? '-';

    final category =
        book['category']?.toString() ?? '-';

    final coverUrl =
        book['cover_url']?.toString();

    final stock =
        book['stock']?.toString() ?? '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),

      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: navy.withOpacity(0.65),
        ),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          _buildBookCover(coverUrl),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  author,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  category,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Stok: $stock',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.more_vert_rounded,
            color: navy,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOOK COVER
  // ==========================================

  Widget _buildBookCover(String? url) {
    return Container(
      width: 65,
      height: 95,

      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(8),
      ),

      clipBehavior: Clip.antiAlias,

      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,

              errorBuilder: (context, error, stackTrace) {
                return _coverPlaceholder();
              },
            )
          : _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return const Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: navy,
        size: 30,
      ),
    );
  }

  // ==========================================
  // MEMBER CARD
  // ==========================================

  Widget _buildMemberCard(
    Map<String, dynamic> profile,
  ) {
    final name =
        profile['full_name']?.toString() ?? 'Anggota';

    final nis =
        profile['nis']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: navy.withOpacity(0.65),
        ),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [

          Container(
            width: 65,
            height: 65,

            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 55,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  name,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'NISN: $nis',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Anggota LokaBaca',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BORROWING INFORMATION
  // ==========================================

  Widget _buildBorrowingInfo(
    String statusText,
  ) {
    final status =
        borrowing!['status']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),

      decoration: BoxDecoration(
        color: cream,
        border: Border.all(
          color: borderColor.withOpacity(0.7),
        ),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Column(
        children: [

          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            title: 'Tanggal pinjaman',
            value: formatDate(
              borrowing!['borrowed_at'],
            ),
          ),

          const SizedBox(height: 19),

          _buildInfoRow(
            icon: Icons.event_note_rounded,
            title: 'Tanggal jatuh tempo',
            value: formatDate(
              borrowing!['due_date'],
            ),
          ),

          const SizedBox(height: 19),

          _buildInfoRow(
            icon: Icons.assignment_return_rounded,
            title: 'Tanggal kembali',
            value: formatDate(
              borrowing!['returned_at'],
            ),
          ),

          const SizedBox(height: 19),

          _buildInfoRow(
            icon: Icons.history_rounded,
            title: 'Status',
            value: statusText,
            isStatus: true,
            originalStatus: status,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMATION ROW
  // ==========================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isStatus = false,
    String originalStatus = '',
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(
          width: 45,
          child: Icon(
            icon,
            color: navy,
            size: 29,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              if (isStatus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: getStatusColor(
                      originalStatus,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    value,
                    style: TextStyle(
                      color: getStatusTextColor(
                        originalStatus,
                      ),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================

  Widget _buildBottomNavigation() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'label': 'Beranda',
      },
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Buku',
      },
      {
        'icon': Icons.person_add_alt_1_rounded,
        'label': 'Anggota',
      },
      {
        'icon': Icons.auto_stories_rounded,
        'label': 'Peminjaman',
      },
      {
        'icon': Icons.person_outline_rounded,
        'label': 'Akun',
      },
    ];

    return Container(
      height: 58,

      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E0D5),
          ),
        ),
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: List.generate(
            items.length,
            (index) {
              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (index != 3) {
                      Navigator.pop(context);
                    }
                  },

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: index == 3
                            ? navy
                            : const Color(0xFF69624F),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: index == 3
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: index == 3
                              ? navy
                              : const Color(0xFF69624F),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}