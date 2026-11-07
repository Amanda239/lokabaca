
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFFD8D4CB);
  static const Color yellow = Color(0xFFF7C957);

  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final birthDateController = TextEditingController();

  String? selectedGender;
  String? avatarUrl;
  File? selectedImage;

  bool isSaving = false;

  final List<String> genderOptions = [
    'Laki-laki',
    'Perempuan',
    'Campuran',
  ];

  @override
  void initState() {
    super.initState();

    nameController.text =
        widget.profile['full_name']?.toString() ?? '';

    phoneController.text =
        widget.profile['phone']?.toString() ?? '';

    final birthDate =
        widget.profile['birth_date']?.toString() ?? '';

    birthDateController.text = _formatDate(birthDate);

    selectedGender =
        widget.profile['gender']?.toString();

    avatarUrl =
        widget.profile['avatar_url']?.toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  // FORMAT TANGGAL
  String _formatDate(String date) {
    if (date.isEmpty) return '';

    try {
      final parsed = DateTime.parse(date);

      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  // PILIH TANGGAL LAHIR
  Future<void> selectBirthDate() async {
    DateTime initialDate = DateTime(2005);

    if (birthDateController.text.isNotEmpty) {
      try {
        final parts = birthDateController.text.split('-');

        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: navy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.year}';
      });
    }
  }

  // PILIH FOTO PROFIL
  Future<void> pickProfilePhoto() async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image != null && mounted) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      showMessage('Gagal memilih foto: $e');
    }
  }

  // UPLOAD FOTO KE SUPABASE STORAGE
  Future<String?> uploadAvatar() async {
    if (selectedImage == null) return avatarUrl;

    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final extension =
        selectedImage!.path.split('.').last.toLowerCase();

    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final path = 'avatars/$fileName';

    await supabase.storage
        .from('profile-avatars')
        .upload(
          path,
          selectedImage!,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return supabase.storage
        .from('profile-avatars')
        .getPublicUrl(path);
  }

  // SIMPAN PROFIL
  Future<void> saveProfile() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    if (selectedGender == null) {
      showMessage('Silakan pilih jenis kelamin.');
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('Silakan login kembali.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final newAvatarUrl = await uploadAvatar();

      final parts = birthDateController.text.split('-');

      final formattedDate =
          '${parts[2]}-${parts[1]}-${parts[0]}';

      final updateData = {
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'birth_date': formattedDate,
        'gender': selectedGender,
        'avatar_url': newAvatarUrl,
      };

      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => isSaving = false);

      showMessage('Gagal memperbarui profil: $e');
    }
  }

  // SNACKBAR
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
        ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  29, 15, 29, 30,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoSection(),

                      const SizedBox(height: 65),

                      const Text(
                        'Info Pribadi',
                        style: TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 13),

                      _buildInput(
                        label: 'Nama Lengkap',
                        controller: nameController,
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 14),

                      _buildInput(
                        label: 'Nomor Telepon',
                        controller: phoneController,
                        hint: 'Masukkan nomor telepon',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 14),

                      _buildInput(
                        label: 'Tanggal Lahir',
                        controller: birthDateController,
                        hint: 'DD-MM-YYYY',
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: selectBirthDate,
                      ),

                      const SizedBox(height: 14),

                      _buildGenderDropdown(),

                      const SizedBox(height: 38),

                      const Text(
                        'Email Terdaftar',
                        style: TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      const Text(
                        'Email ini digunakan sebagai login atau menerima notifikasi dari LokaBaca.',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(height: 17),

                      _buildEmailField(),

                      const SizedBox(height: 48),

                      const Divider(
                        color: borderColor,
                        thickness: 1,
                      ),

                      const SizedBox(height: 30),

                      _buildSaveButton(),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: navy,
              size: 30,
            ),
          ),

          const Expanded(
            child: Text(
              'Akun',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  // FOTO PROFIL
  Widget _buildPhotoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
            width: 72,
            height: 72,
            child: selectedImage != null
                ? Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                  )
                : avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
          ),
        ),

        const SizedBox(width: 30),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 37,
                child: ElevatedButton(
                  onPressed: pickProfilePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cream,
                    foregroundColor: textColor,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ubah Foto Profil',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Format foto harus jpg.jpeg.png dan ukuran file max 2mb',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: yellow,
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 42,
      ),
    );
  }

  // INPUT TEXT
  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.17),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Bagian ini wajib diisi';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: mutedText,
            fontSize: 9,
          ),
          hintStyle: const TextStyle(
            color: mutedText,
            fontSize: 11,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: navy,
              width: 1,
            ),
          ),
          errorStyle: const TextStyle(fontSize: 9),
          suffixIcon: icon != null
              ? Icon(
                  icon,
                  color: mutedText,
                  size: 16,
                )
              : null,
        ),
      ),
    );
  }

  // DROPDOWN JENIS KELAMIN
  Widget _buildGenderDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.17),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: genderOptions.contains(selectedGender)
            ? selectedGender
            : null,
        decoration: const InputDecoration(
          labelText: 'Jenis Kelamin',
          labelStyle: TextStyle(
            color: mutedText,
            fontSize: 9,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 5),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: navy,
          size: 20,
        ),
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        items: genderOptions.map((gender) {
          return DropdownMenuItem(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedGender = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Pilih jenis kelamin';
          }
          return null;
        },
      ),
    );
  }

  // EMAIL READ ONLY
  Widget _buildEmailField() {
    final email =
        supabase.auth.currentUser?.email ?? '';

    return Container(
      height: 39,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        email,
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }

  // BUTTON SIMPAN
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        onPressed: isSaving ? null : saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: mutedText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
