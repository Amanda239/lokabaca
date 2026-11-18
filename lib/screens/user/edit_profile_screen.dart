
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  final List<String> genderOptions = [
    'Laki-laki',
    'Perempuan',
    'Campuran',
  ];

  String? selectedGender;
  String? avatarUrl;
  Uint8List? selectedImageBytes;

  bool isLoading = true;
  bool isSaving = false;

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

  // LOAD PROFILE

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
        nameController.text = data['full_name']?.toString() ?? '';
        phoneController.text = data['phone']?.toString() ?? '';
        birthDateController.text = _formatDate(
          data['birth_date']?.toString() ?? '',
        );
        selectedGender = data['gender']?.toString();
        avatarUrl = data['avatar_url']?.toString();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        nameController.text =
            widget.profile['full_name']?.toString() ?? '';
        phoneController.text =
            widget.profile['phone']?.toString() ?? '';
        birthDateController.text = _formatDate(
          widget.profile['birth_date']?.toString() ?? '',
        );
        selectedGender = widget.profile['gender']?.toString();
        avatarUrl = widget.profile['avatar_url']?.toString();
        isLoading = false;
      });

      showMessage('Gagal mengambil data profil: $e');
    }
  }

  // DATE FORMAT

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

  // SELECT BIRTH DATE

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

  // PICK AND CROP PHOTO

  Future<void> pickProfilePhoto() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (image == null) return;

      final extension = image.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        showMessage('Format foto harus JPG, JPEG, atau PNG.');
        return;
      }

      final CroppedFile? croppedImage =
          await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(
          ratioX: 1,
          ratioY: 1,
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur Foto Profil',
            toolbarColor: navy,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: yellow,
            lockAspectRatio: true,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: 'Atur Foto Profil',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 400,
              height: 400,
            ),
          ),
        ],
      );

      if (croppedImage == null) return;

      final bytes = await croppedImage.readAsBytes();

      if (bytes.isEmpty) {
        showMessage('Hasil crop foto tidak valid.');
        return;
      }

      if (bytes.length > 2 * 1024 * 1024) {
        showMessage(
          'Ukuran foto lebih dari 2 MB. Silakan pilih foto lain.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedImageBytes = bytes;
      });

      showMessage('Foto berhasil diatur!');
    } catch (e) {
      debugPrint('PICK/CROP PHOTO ERROR: $e');

      if (!mounted) return;

      showMessage('Gagal memilih atau mengatur foto: $e');
    }
  }

  // UPLOAD AVATAR

  Future<String?> uploadAvatar() async {
    if (selectedImageBytes == null) {
      return avatarUrl;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final fileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final filePath = '${user.id}/$fileName';

    await supabase.storage
        .from('profile-avatars')
        .uploadBinary(
          filePath,
          selectedImageBytes!,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return supabase.storage
        .from('profile-avatars')
        .getPublicUrl(filePath);
  }

  // SAVE PROFILE

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

      await supabase.from('profiles').update({
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'birth_date': _dateForDatabase(),
        'gender': selectedGender,
        'avatar_url': newAvatarUrl,
      }).eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: navy,
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SAVE PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

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

  // BUILD

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

  // HEADER

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

  // SECTION TITLE

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

  // PHOTO SECTION

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFE5DFD2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(0.13),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: selectedImageBytes != null
                      ? Image.memory(
                          selectedImageBytes!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                        )
                      : avatarUrl != null && avatarUrl!.isNotEmpty
                          ? Image.network(
                              avatarUrl!,
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _photoPlaceholder(),
                            )
                          : _photoPlaceholder(),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: navy,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Foto Profil',
            style: TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Atur posisi dan ukuran foto sebelum menyimpan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 13),

          OutlinedButton.icon(
            onPressed: isSaving ? null : pickProfilePhoto,
            icon: const Icon(
              Icons.edit_rounded,
              size: 16,
            ),
            label: const Text(
              'Pilih / Atur Foto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(
                color: navy,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'JPG, JPEG, atau PNG • Maksimal 2 MB',
            style: TextStyle(
              color: mutedText,
              fontSize: 10,
            ),
          ),
        ],
      ),
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

  // TEXT INPUT

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

  // GENDER DROPDOWN

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

  // EMAIL FIELD

  Widget _buildEmailField() {
    final email = supabase.auth.currentUser?.email ?? '-';

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

  // SAVE BUTTON

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
