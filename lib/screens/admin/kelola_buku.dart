
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_bottom_navigation.dart';
import 'dashboard_admin.dart';
import 'kelola_anggota.dart';
import 'peminjaman_admin.dart';
import 'profile_admin.dart';

class KelolaBukuScreen extends StatefulWidget {
  const KelolaBukuScreen({super.key});

  @override
  State<KelolaBukuScreen> createState() => _KelolaBukuScreenState();
}

class _KelolaBukuScreenState extends State<KelolaBukuScreen> {
  static const navy = Color(0xFF2E4057);
  static const cream = Color(0xFFF7F3E9);
  static const muted = Color(0xFF8B929C);
  static const border = Color(0xFFC9C4BA);

  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> books = [];

  bool loading = true;
  String? loadError;
  String keyword = '';
  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
      ),
    );
  }

  Future<void> loadBooks() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final rows = await supabase
          .from('books')
          .select(
            'id,title,author,category,description,cover_url,rating,stock,created_at',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        books = List<Map<String, dynamic>>.from(rows);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get visibleBooks {
    final q = keyword.trim().toLowerCase();

    if (q.isEmpty) return books;

    return books.where((book) {
      return (book['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q) ||
          (book['author'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q) ||
          (book['category'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q);
    }).toList();
  }

  Future<void> openForm({Map<String, dynamic>? book}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormBukuScreen(book: book),
      ),
    );

    if (!mounted || saved != true) return;

    await loadBooks();

    message(
      book == null
          ? 'Buku berhasil ditambahkan.'
          : 'Buku berhasil diperbarui.',
    );
  }

  Future<void> deleteBook(Map<String, dynamic> book) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hapus Buku?',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Buku "${book['title'] ?? '-'}" akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: navy),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94343),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await supabase
          .from('books')
          .delete()
          .eq('id', book['id']);

      await loadBooks();

      message('Buku berhasil dihapus.');
    } catch (e) {
      message('Gagal menghapus buku: $e');
    }
  }

  // BOTTOM NAVIGATION
  Future<void> onBottomTap(int index) async {
    if (index == selectedIndex) return;

    if (index < 0 || index > 4) return;

    Widget? page;

    switch (index) {
      case 0:
        page = const DashboardAdmin();
        break;
      case 1:
        setState(() => selectedIndex = 1);
        return;
      case 2:
        page = const KelolaAnggotaPage();
        break;
      case 3:
        page = const PeminjamanAdminScreen();
        break;
      case 4:
        page = const AdminProfileScreen();
        break;
    }

    if (page == null) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _search(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: navy,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Koleksi Buku',
                    style: TextStyle(
                      color: navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${visibleBooks.length} buku',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _bookBody()),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentIndex: selectedIndex,
        onTap: onBottomTap,
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 18, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: navy,
              size: 19,
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
          Material(
            color: navy,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => openForm(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() => keyword = value);
        },
        style: const TextStyle(
          color: navy,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: 'Cari judul, penulis, atau kategori',
          hintStyle: const TextStyle(
            color: muted,
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: navy,
            size: 20,
          ),
          filled: true,
          fillColor: cream,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: navy,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: navy),
      );
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: navy,
                size: 42,
              ),
              const SizedBox(height: 10),
              const Text(
                'Data buku gagal dimuat',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadBooks,
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

    if (visibleBooks.isEmpty) {
      return RefreshIndicator(
        color: navy,
        onRefresh: loadBooks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 330,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 54,
                    color: navy.withOpacity(.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    keyword.isEmpty
                        ? 'Belum ada buku'
                        : 'Buku tidak ditemukan',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tarik ke bawah untuk memuat ulang.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: navy,
      onRefresh: loadBooks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
        itemCount: visibleBooks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _bookCard(visibleBooks[index]);
        },
      ),
    );
  }

  Widget _bookCard(Map<String, dynamic> book) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navy.withOpacity(.28)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(.045),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          BookCover(
            cover: book['cover_url'],
            width: 62,
            height: 88,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (book['title'] ?? 'Tanpa judul').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (book['author'] ?? 'Penulis tidak diketahui').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (book['category'] ?? 'Tanpa kategori').toString(),
                  style: const TextStyle(
                    color: navy,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stok: ${book['stock'] ?? 0}',
                  style: const TextStyle(
                    color: navy,
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
            ),
            onSelected: (value) {
              if (value == 'edit') {
                openForm(book: book);
              } else if (value == 'delete') {
                deleteBook(book);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: navy, size: 18),
                    SizedBox(width: 9),
                    Text('Edit Buku'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    SizedBox(width: 9),
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
}

// FORM TAMBAH DAN EDIT BUKU

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
  static const navy = Color(0xFF2E4057);
  static const cream = Color(0xFFF7F3E9);
  static const muted = Color(0xFF9297A0);
  static const border = Color(0xFFC9C4BA);

  final supabase = Supabase.instance.client;
  final picker = ImagePicker();
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final stockController = TextEditingController();
  final descriptionController = TextEditingController();

  final List<String> categories = [
    'Fiksi',
    'Nonfiksi',
    'Novel',
    'Fantasi',
    'Filsafat',
    'Sejarah',
    'Pendidikan',
    'Biografi',
    'Komik',
    'Agama',
    'Sains',
  ];

  String? category;
  String? existingCover;

  Uint8List? pickedBytes;
  XFile? pickedFile;

  bool saving = false;
  bool coverRemoved = false;

  bool get isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();

    final book = widget.book;

    if (book != null) {
      titleController.text = (book['title'] ?? '').toString();
      authorController.text = (book['author'] ?? '').toString();
      stockController.text = (book['stock'] ?? 0).toString();
      descriptionController.text =
          (book['description'] ?? '').toString();

      category = book['category']?.toString();
      existingCover = book['cover_url']?.toString().trim();

      if (category != null &&
          category!.isNotEmpty &&
          !categories.contains(category)) {
        categories.add(category!);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> chooseCover() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Cover Buku',
                style: TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: navy,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: navy,
                ),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (bytes.length > 2 * 1024 * 1024) {
        message('Ukuran cover maksimal 2 MB.');
        return;
      }

      if (!mounted) return;

      setState(() {
        pickedFile = file;
        pickedBytes = bytes;
        coverRemoved = false;
      });
    } catch (e) {
      message('Gagal memilih cover: $e');
    }
  }

  void removeCover() {
    setState(() {
      pickedFile = null;
      pickedBytes = null;
      existingCover = null;
      coverRemoved = true;
    });
  }

  Future<String?> _uploadCover() async {
    if (pickedFile == null || pickedBytes == null) {
      return coverRemoved ? null : existingCover;
    }

    final originalExt = pickedFile!.name.contains('.')
        ? pickedFile!.name.split('.').last.toLowerCase()
        : 'jpg';

    final ext = ['jpg', 'jpeg', 'png', 'webp'].contains(originalExt)
        ? originalExt
        : 'jpg';

    final path =
        'covers/${DateTime.now().microsecondsSinceEpoch}.$ext';

    await supabase.storage.from('book-covers').uploadBinary(
      path,
      pickedBytes!,
      fileOptions: FileOptions(
        contentType: pickedFile!.mimeType ?? _mimeType(ext),
        upsert: false,
      ),
    );

    return supabase.storage.from('book-covers').getPublicUrl(path);
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> save() async {
    if (saving) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    final hasCover = pickedBytes != null ||
        (!coverRemoved &&
            existingCover != null &&
            existingCover!.trim().isNotEmpty);

    if (!hasCover) {
      message('Cover buku wajib ditambahkan.');
      return;
    }

    setState(() => saving = true);

    try {
      final coverUrl = await _uploadCover();

      final payload = <String, dynamic>{
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'category': category,
        'description': descriptionController.text.trim(),
        'cover_url': coverUrl,
        'stock': int.parse(stockController.text.trim()),
      };

      if (isEdit) {
        final updated = await supabase
            .from('books')
            .update(payload)
            .eq('id', widget.book!['id'])
            .select('id')
            .maybeSingle();

        if (updated == null) {
          throw Exception(
            'Data tidak berubah. Periksa izin UPDATE pada RLS tabel books.',
          );
        }
      } else {
        await supabase.from('books').insert(payload);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => saving = false);
      message('Gagal menyimpan buku: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _formHeader(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 38,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _coverArea(),
                            const SizedBox(height: 18),
                            _label('Judul Buku *'),
                            _input(
                              controller: titleController,
                              hint: 'Masukkan judul buku',
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            _label('Penulis *'),
                            _input(
                              controller: authorController,
                              hint: 'Masukkan nama penulis',
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            _label('Kategori *'),
                            _categoryField(),
                            const SizedBox(height: 12),
                            _label('Stok *'),
                            _input(
                              controller: stockController,
                              hint: 'Masukkan stok',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final number =
                                    int.tryParse((value ?? '').trim());

                                if (number == null) {
                                  return 'Masukkan stok berupa angka.';
                                }

                                if (number < 0) {
                                  return 'Stok tidak boleh negatif.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _label('Deskripsi *'),
                            _input(
                              controller: descriptionController,
                              hint: 'Masukkan deskripsi buku',
                              maxLines: 3,
                              validator: _required,
                            ),
                            const SizedBox(height: 24),
                            _actions(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: saving ? null : () => Navigator.pop(context),
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
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _coverArea() {
    final hasPicked = pickedBytes != null;

    final hasExisting = !coverRemoved &&
        existingCover != null &&
        existingCover!.trim().isNotEmpty;

    final hasCover = hasPicked || hasExisting;

    if (isEdit && hasCover) {
      return Container(
        height: 126,
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cream,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasPicked
                  ? Image.memory(
                      pickedBytes!,
                      width: 68,
                      height: 104,
                      fit: BoxFit.cover,
                    )
                  : BookCover(
                      cover: existingCover,
                      width: 68,
                      height: 104,
                    ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: InkWell(
                onTap: saving ? null : chooseCover,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  height: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: navy,
                        size: 25,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Ubah Cover',
                        style: TextStyle(
                          color: navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: saving ? null : removeCover,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: saving ? null : chooseCover,
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: navy.withOpacity(.75),
          radius: 10,
        ),
        child: Container(
          width: double.infinity,
          height: 128,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: hasPicked
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        pickedBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        onPressed: saving ? null : removeCover,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.delete_outline),
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
                      size: 42,
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Upload Cover Buku',
                      style: TextStyle(
                        color: navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'JPG, PNG, JPEG (maks. 2MB)',
                      style: TextStyle(
                        color: navy,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bagian ini wajib diisi.';
    }

    return null;
  }

  Widget _label(String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 6),
      child: Text(
        value,
        style: const TextStyle(
          color: navy,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: !saving,
      style: const TextStyle(color: navy, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: muted, fontSize: 11),
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        errorStyle: const TextStyle(fontSize: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navy, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _categoryField() {
    final items = List<String>.from(categories);

    if (category != null &&
        category!.isNotEmpty &&
        !items.contains(category)) {
      items.add(category!);
    }

    return DropdownButtonFormField<String>(
      value: category,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilih kategori buku.';
        }

        return null;
      },
      decoration: InputDecoration(
        hintText: 'Pilih Kategori',
        hintStyle: const TextStyle(color: muted, fontSize: 11),
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        errorStyle: const TextStyle(fontSize: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navy, width: 1.2),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: navy,
        size: 25,
      ),
      dropdownColor: Colors.white,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: navy, fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: saving
          ? null
          : (value) {
              setState(() => category = value);
            },
    );
  }

  Widget _actions() {
    if (!isEdit) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: saving ? null : save,
          style: ElevatedButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: muted,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _buttonText('Simpan'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: OutlinedButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: saving ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: muted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _buttonText('Simpan'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buttonText(String label) {
    if (saving) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// DASHED BORDER

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        final end = (distance + 5)
            .clamp(0.0, metric.length)
            .toDouble();

        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}

// BOOK COVER

class BookCover extends StatelessWidget {
  final dynamic cover;
  final double width;
  final double height;

  const BookCover({
    super.key,
    required this.cover,
    this.width = 55,
    this.height = 82,
  });

  bool get _isNetworkImage {
    final value = cover?.toString().trim() ?? '';
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (cover is Uint8List) {
      return _frame(
        Image.memory(
          cover as Uint8List,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }

    final path = cover?.toString().trim() ?? '';

    if (path.isEmpty) {
      return _frame(_placeholder());
    }

    if (_isNetworkImage) {
      return _frame(
        Image.network(
          path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return Container(
              width: width,
              height: height,
              color: const Color(0xFFEAE6DE),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2E4057),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }

    return _frame(
      Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _frame(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2E4057),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 27,
      ),
    );
  }
}
