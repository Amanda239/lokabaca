
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileAdminScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileAdminScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileAdminScreen> createState() =>
      _EditProfileAdminScreenState();
}

class _EditProfileAdminScreenState
    extends State<EditProfileAdminScreen> {
  // COLORS
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color textColor = Color(0xFF304258);
  static const Color mutedText = Color(0xFF8993A1);
  static const Color borderColor = Color(0xFFD8D4CB);
  static const Color yellow = Color(0xFFF7C957);

  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController phoneController =
      TextEditingController();
  final TextEditingController birthDateController =
      TextEditingController();

  String? selectedGender;
  String? avatarUrl;

  Uint8List? selectedImageBytes;
  String? selectedImageExtension;

  bool isLoading = true;
  bool isSaving = false;

  final List<String> genderOptions = [
    'Laki-laki',
    'Perempuan',
    'Campuran',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOAD PROFILE
  // ==========================================

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      showMessage('Sesi login tidak ditemukan.');
      Navigator.pop(context);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select(
            'id, full_name, phone, birth_date, gender, avatar_url',
          )
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        nameController.text =
            data['full_name']?.toString() ?? '';

        phoneController.text =
            data['phone']?.toString() ?? '';

        birthDateController.text = _formatDate(
          data['birth_date']?.toString() ?? '',
        );

        selectedGender = data['gender']?.toString();
        avatarUrl = data['avatar_url']?.toString();

        isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD PROFILE ADMIN ERROR: $e');

      if (!mounted) return;

      setState(() {
        nameController.text =
            widget.profile['full_name']?.toString() ?? '';

        phoneController.text =
            widget.profile['phone']?.toString() ?? '';

        birthDateController.text = _formatDate(
          widget.profile['birth_date']?.toString() ?? '',
        );

        selectedGender =
            widget.profile['gender']?.toString();

        avatarUrl =
            widget.profile['avatar_url']?.toString();

        isLoading = false;
      });

      showMessage('Gagal mengambil data profil: $e');
    }
  }

  // ==========================================
  // DATE FORMAT
  // ==========================================

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

  String _dateForDatabase() {
    final parts = birthDateController.text.split('-');

    if (parts.length != 3) {
      throw Exception('Format tanggal lahir tidak valid.');
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      throw Exception('Tanggal lahir tidak valid.');
    }

    final date = DateTime(year, month, day);

    if (date.year != year ||
        date.month != month ||
        date.day != day) {
      throw Exception('Tanggal lahir tidak valid.');
    }

    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // SELECT BIRTH DATE
  // ==========================================

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

    final now = DateTime.now();

    if (initialDate.isAfter(now)) {
      initialDate = now;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
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

    if (picked != null && mounted) {
      setState(() {
        birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.year}';
      });
    }
  }

  // ==========================================
  // PICK PROFILE PHOTO
  // ==========================================

  Future<void> pickProfilePhoto() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return;

      final extension =
          image.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        showMessage(
          'Format foto harus JPG, JPEG, atau PNG.',
        );
        return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        showMessage('File foto tidak valid.');
        return;
      }

      if (bytes.length > 2 * 1024 * 1024) {
        showMessage('Ukuran foto maksimal 2 MB.');
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedImageBytes = bytes;
        selectedImageExtension = extension;
      });

      showMessage('Foto berhasil dipilih!');
    } catch (e) {
      debugPrint('IMAGE PICKER ADMIN ERROR: $e');
      showMessage('Gagal memilih foto: $e');
    }
  }

  // ==========================================
  // UPLOAD AVATAR TO SUPABASE STORAGE
  // ==========================================

  Future<String?> uploadAvatar() async {
    if (selectedImageBytes == null) {
      return avatarUrl;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Admin belum login.');
    }

    final extension = selectedImageExtension ?? 'jpg';

    final contentType = extension == 'png'
        ? 'image/png'
        : 'image/jpeg';

    final fileName =
        'admin_profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final filePath = '${user.id}/$fileName';

    try {
      await supabase.storage
          .from('profile-avatars')
          .uploadBinary(
            filePath,
            selectedImageBytes!,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      final publicUrl = supabase.storage
          .from('profile-avatars')
          .getPublicUrl(filePath);

      debugPrint('ADMIN AVATAR UPLOAD SUCCESS: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('ADMIN AVATAR UPLOAD ERROR: $e');
      rethrow;
    }
  }

  // ==========================================
  // SAVE PROFILE
  // ==========================================

  Future<void> saveProfile() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    if (selectedGender == null ||
        !genderOptions.contains(selectedGender)) {
      showMessage('Silakan pilih jenis kelamin.');
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('Silakan login kembali.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final newAvatarUrl = await uploadAvatar();

      final updateData = {
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'birth_date': _dateForDatabase(),
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Profil admin berhasil diperbarui!',
            ),
            backgroundColor: navy,
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SAVE ADMIN PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Gagal memperbarui profil: $e');
    }
  }

  // ==========================================
  // SNACKBAR
  // ==========================================

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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: navy,
                      ),
                    )
                  : Form(
                      key: formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          25,
                          16,
                          25,
                          30,
                        ),
                        children: [
                          _buildPhotoSection(),

                          const SizedBox(height: 32),

                          _buildSectionTitle('Info Pribadi'),

                          const SizedBox(height: 16),

                          _buildInput(
                            label: 'Nama Lengkap',
                            controller: nameController,
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline_rounded,
                          ),

                          const SizedBox(height: 17),

                          _buildInput(
                            label: 'Nomor Telepon',
                            controller: phoneController,
                            hint: 'Masukkan nomor telepon',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 17),

                          _buildInput(
                            label: 'Tanggal Lahir',
                            controller: birthDateController,
                            hint: 'DD-MM-YYYY',
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: selectBirthDate,
                          ),

                          const SizedBox(height: 17),

                          _buildGenderDropdown(),

                          const SizedBox(height: 32),

                          _buildSectionTitle('Email Terdaftar'),

                          const SizedBox(height: 7),

                          const Text(
                            'Email ini digunakan untuk login dan '
                            'menerima notifikasi dari LokaBaca.',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 13),

                          _buildEmailField(),

                          const SizedBox(height: 35),

                          const Divider(
                            color: borderColor,
                            thickness: 1,
                          ),

                          const SizedBox(height: 22),

                          _buildSaveButton(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              'Edit Profil Admin',
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

  // ==========================================
  // SECTION TITLE
  // ==========================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: navy,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ==========================================
  // PHOTO SECTION
  // ==========================================

  Widget _buildPhotoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: ClipOval(
            child: selectedImageBytes != null
                ? Image.memory(
                    selectedImageBytes!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  )
                : avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
          ),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed:
                    isSaving ? null : pickProfilePhoto,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: 15,
                ),
                label: const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cream,
                  foregroundColor: navy,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'JPG, JPEG, atau PNG\nMaksimal ukuran 2 MB',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 10,
                  height: 1.5,
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
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  // ==========================================
  // TEXT INPUT
  // ==========================================

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
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
              return '$label wajib diisi';
            }

            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
            filled: true,
            fillColor: cream,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            suffixIcon: icon != null
                ? Icon(
                    icon,
                    color: mutedText,
                    size: 17,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: navy,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // GENDER DROPDOWN
  // ==========================================

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Kelamin',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: genderOptions.contains(selectedGender)
              ? selectedGender
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: cream,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: navy,
                width: 1,
              ),
            ),
          ),
          hint: const Text(
            'Pilih jenis kelamin',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: navy,
          ),
          style: const TextStyle(
            color: textColor,
            fontSize: 12,
          ),
          items: genderOptions.map((gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
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
      ],
    );
  }

  // ==========================================
  // EMAIL FIELD
  // ==========================================

  Widget _buildEmailField() {
    final email =
        supabase.auth.currentUser?.email ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(11),
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

  // ==========================================
  // SAVE BUTTON
  // ==========================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 49,
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
                'Simpan Perubahan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
