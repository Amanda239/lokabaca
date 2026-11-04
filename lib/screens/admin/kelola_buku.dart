import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KelolaBukuScreen extends StatefulWidget {
  const KelolaBukuScreen({super.key});

  @override
  State<KelolaBukuScreen> createState() => _KelolaBukuScreenState();
}

class _KelolaBukuScreenState extends State<KelolaBukuScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFFCBD0D7);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> books = [];
  bool isLoading = true;
  String searchQuery = '';

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.home_outlined, 'label': 'Beranda'},
    {'icon': Icons.menu_book_outlined, 'label': 'Buku'},
    {'icon': Icons.people_outline_rounded, 'label': 'Anggota'},
    {'icon': Icons.swap_horiz_rounded, 'label': 'Peminjaman'},
    {'icon': Icons.person_outline_rounded, 'label': 'Akun'},
  ];

  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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

  // ================= FETCH BOOKS =================

  Future<void> fetchBooks() async {
    try {
      setState(() => isLoading = true);

      final response = await supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        books = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Gagal mengambil data buku: $e');
    }
  }

  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.toLowerCase();

    return books.where((book) {
      final title = (book['title'] ?? '').toString().toLowerCase();
      final author = (book['author'] ?? '').toString().toLowerCase();
      final category = (book['category'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          author.contains(query) ||
          category.contains(query);
    }).toList();
  }

  // ================= ADD BOOK =================

  Future<void> openAddBook() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const FormBukuScreen(),
      ),
    );

    if (result == true) {
      fetchBooks();
    }
  }

  // ================= EDIT BOOK =================

  Future<void> openEditBook(Map<String, dynamic> book) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormBukuScreen(book: book),
      ),
    );

    if (result == true) {
      fetchBooks();
    }
  }

  // ================= DELETE BOOK =================

  Future<void> deleteBook(Map<String, dynamic> book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Hapus Buku',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Yakin ingin menghapus "${book['title']}"?',
            style: const TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
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
      await supabase
          .from('books')
          .delete()
          .eq('id', book['id']);

      if (!mounted) return;

      setState(() {
        books.removeWhere((item) => item['id'] == book['id']);
      });

      showMessage('Buku berhasil dihapus');
    } catch (e) {
      showMessage('Gagal menghapus buku: $e');
    }
  }

  // ================= MAIN UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),

            const SizedBox(height: 18),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: navy,
                      ),
                    )
                  : filteredBooks.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: navy,
                          onRefresh: fetchBooks,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              20,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];

                              return _buildBookCard(book);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              'Kelola Buku',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          InkWell(
            onTap: openAddBook,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SEARCH =================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() => searchQuery = value);
        },
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: 'Cari Judul, Penulis atau Kategori',
          hintStyle: const TextStyle(
            color: mutedText,
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: navy,
            size: 21,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: navy,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ================= EMPTY STATE =================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: const BoxDecoration(
              color: cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: navy,
              size: 35,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Buku tidak ditemukan',
            style: TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Coba gunakan kata kunci lain.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOOK CARD =================

  Widget _buildBookCard(Map<String, dynamic> book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: navy.withOpacity(0.45),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          BookCover(
            cover: book['cover_url'],
            title: book['title'] ?? '',
            width: 55,
            height: 82,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  book['author'] ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${book['category'] ?? '-'} · '
                  '${book['published_year'] ?? '-'} · '
                  '${book['pages'] ?? '-'} hlm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Stok: ${book['stock'] ?? 0}',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: navy,
              size: 20,
            ),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'edit') {
                openEditBook(book);
              } else if (value == 'delete') {
                deleteBook(book);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: navy,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text('Edit Buku'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text('Hapus Buku'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM NAVIGATION =================

  Widget _buildBottomNavigation() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: cream,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E0D5),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(
            menuItems.length,
            (index) {
              final item = menuItems[index];
              final bool isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });

                    if (index != 1) {
                      showMessage('Menu ${item['label']} dipilih');
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'],
                        size: 21,
                        color: isSelected
                            ? navy
                            : const Color(0xFF69624F),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        item['label'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? navy
                              : const Color(0xFF69624F),
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
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

// ======================================================
// FORM TAMBAH / EDIT BUKU
// ======================================================

class FormBukuScreen extends StatefulWidget {
  final Map<String, dynamic>? book;

  const FormBukuScreen({
    super.key,
    this.book,
  });

  @override
  State<FormBukuScreen> createState() => _FormBukuScreenState();
}

class _FormBukuScreenState extends State<FormBukuScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFFCBC5BA);

  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final yearController = TextEditingController();
  final pagesController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();

  File? coverImage;
  String? oldCoverUrl;
  String? selectedCategory;
  bool isSaving = false;

  final List<String> categories = [
    'Fiksi',
    'Nonfiksi',
    'Novel',
    'Fantasi',
    'Filsafat',
    'Sejarah',
    'Pendidikan',
    'Biografi',
  ];

  bool get isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final book = widget.book!;

      titleController.text = book['title']?.toString() ?? '';
      authorController.text = book['author']?.toString() ?? '';
      yearController.text = book['published_year']?.toString() ?? '';
      pagesController.text = book['pages']?.toString() ?? '';
      stockController.text = book['stock']?.toString() ?? '';
      descriptionController.text =
          book['description']?.toString() ?? '';

      selectedCategory = book['category']?.toString();
      oldCoverUrl = book['cover_url']?.toString();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    yearController.dispose();
    pagesController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ================= PICK COVER =================

  Future<void> pickCover(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image != null && mounted) {
        setState(() {
          coverImage = File(image.path);
        });
      }
    } catch (e) {
      showMessage('Gagal memilih gambar: $e');
    }
  }

  void showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  isEdit ? 'Ubah Cover Buku' : 'Tambah Cover Buku',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: navy,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    pickCover(ImageSource.gallery);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: navy,
                  ),
                  title: const Text('Ambil Foto dengan Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    pickCover(ImageSource.camera);
                  },
                ),

                if (coverImage != null || oldCoverUrl != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Hapus Cover'),
                    onTap: () {
                      Navigator.pop(context);

                      setState(() {
                        coverImage = null;
                        oldCoverUrl = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= SAVE BOOK =================

  Future<void> saveBook() async {
    if (!formKey.currentState!.validate()) return;

    if (coverImage == null && oldCoverUrl == null) {
      showMessage('Silakan tambahkan cover buku terlebih dahulu.');
      return;
    }

    try {
      setState(() => isSaving = true);

      String? coverUrl = oldCoverUrl;

      if (coverImage != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.jpg';

        final storagePath = 'covers/$fileName';

        await supabase.storage
            .from('book-covers')
            .upload(
              storagePath,
              coverImage!,
              fileOptions: const FileOptions(
                upsert: true,
              ),
            );

        coverUrl = supabase.storage
            .from('book-covers')
            .getPublicUrl(storagePath);
      }

      final bookData = {
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'category': selectedCategory,
        'published_year': int.parse(yearController.text.trim()),
        'pages': int.parse(pagesController.text.trim()),
        'stock': int.parse(stockController.text.trim()),
        'description': descriptionController.text.trim(),
        'cover_url': coverUrl,
      };

      if (isEdit) {
        await supabase
            .from('books')
            .update(bookData)
            .eq('id', widget.book!['id']);
      } else {
        await supabase
            .from('books')
            .insert(bookData);
      }

      if (!mounted) return;

      showMessage(
        isEdit
            ? 'Buku berhasil diperbarui'
            : 'Buku berhasil ditambahkan',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        showMessage('Gagal menyimpan buku: $e');
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= FORM UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoverUpload(),

                      const SizedBox(height: 16),

                      _buildLabel('Judul Buku *'),
                      _buildTextField(
                        controller: titleController,
                        hint: 'Masukkan judul buku',
                      ),

                      const SizedBox(height: 13),

                      _buildLabel('Penulis *'),
                      _buildTextField(
                        controller: authorController,
                        hint: 'Masukkan nama penulis',
                      ),

                      const SizedBox(height: 13),

                      _buildLabel('Kategori *'),
                      _buildCategoryDropdown(),

                      const SizedBox(height: 13),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tahun Terbit *'),
                                _buildTextField(
                                  controller: yearController,
                                  hint: 'YYYY',
                                  keyboardType: TextInputType.number,
                                  numericOnly: true,
                                  maxLength: 4,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Jumlah Halaman *'),
                                _buildTextField(
                                  controller: pagesController,
                                  hint: 'Masukkan jumlah',
                                  keyboardType: TextInputType.number,
                                  numericOnly: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 13),

                      _buildLabel('Stok *'),
                      _buildTextField(
                        controller: stockController,
                        hint: 'Masukkan stok',
                        keyboardType: TextInputType.number,
                        numericOnly: true,
                      ),

                      const SizedBox(height: 13),

                      _buildLabel('Deskripsi *'),
                      _buildTextField(
                        controller: descriptionController,
                        hint: 'Masukkan deskripsi buku',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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

          Expanded(
            child: Text(
              isEdit ? 'Edit Buku' : 'Tambah Buku',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  // ================= COVER UPLOAD =================

  Widget _buildCoverUpload() {
    final bool hasCover = coverImage != null || oldCoverUrl != null;

    return InkWell(
      onTap: showImagePicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: cream,
          border: Border.all(
            color: navy.withOpacity(0.45),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: hasCover
            ? Stack(
                alignment: Alignment.center,
                children: [
                  BookCover(
                    cover: coverImage?.path ?? oldCoverUrl,
                    title: titleController.text,
                    width: 85,
                    height: 125,
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: navy,
                    size: 35,
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Upload Cover Buku',
                    style: TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'JPG, PNG, JPEG (maks. 2MB)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ================= LABEL =================

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 6,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool numericOnly = false,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bagian ini wajib diisi';
        }

        if (numericOnly && int.tryParse(value.trim()) == null) {
          return 'Masukkan angka yang valid';
        }

        if (numericOnly && int.parse(value.trim()) < 0) {
          return 'Angka tidak boleh negatif';
        }

        if (controller == yearController) {
          final year = int.tryParse(value.trim());

          if (year == null || value.trim().length != 4) {
            return 'Tahun tidak valid';
          }

          if (year < 1000 || year > DateTime.now().year) {
            return 'Tahun tidak valid';
          }
        }

        return null;
      },
      style: const TextStyle(
        color: textColor,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: mutedText,
          fontSize: 11,
        ),
        counterText: '',
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: navy,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  // ================= CATEGORY =================

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilih kategori buku';
        }

        return null;
      },
      decoration: InputDecoration(
        hintText: 'Pilih Kategori',
        hintStyle: const TextStyle(
          color: mutedText,
          fontSize: 11,
        ),
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: navy,
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(
            category,
            style: const TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCategory = value;
        });
      },
    );
  }

  // ================= SAVE BUTTON =================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: isSaving ? null : saveBook,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: mutedText,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isEdit ? 'Simpan Perubahan' : 'Simpan',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ======================================================
// REUSABLE BOOK COVER
// ======================================================

class BookCover extends StatelessWidget {
  final dynamic cover;
  final String title;
  final double width;
  final double height;

  const BookCover({
    super.key,
    required this.cover,
    required this.title,
    this.width = 55,
    this.height = 82,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (cover == null || cover.toString().isEmpty) {
      imageWidget = _fallbackCover();
    } else if (cover is File) {
      imageWidget = Image.file(
        cover as File,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackCover(),
      );
    } else if (cover is String &&
        (cover as String).startsWith('http')) {
      imageWidget = Image.network(
        cover as String,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackCover(),
      );
    } else if (cover is String &&
        (cover as String).startsWith('/')) {
      imageWidget = Image.file(
        File(cover as String),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackCover(),
      );
    } else {
      imageWidget = _fallbackCover();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2E4057),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}