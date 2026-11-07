
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Warna utama LokaBaca
  static const Color navy = Color(0xFF2E4057);
  static const Color cream = Color(0xFFF8F4EA);
  static const Color mutedText = Color(0xFF92929B);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController oldPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isOldPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  bool get hasMinLength =>
      newPasswordController.text.length >= 8;

  bool get hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(newPasswordController.text);

  bool get hasNumberAndSymbol =>
      RegExp(r'[0-9]').hasMatch(newPasswordController.text) &&
      RegExp(r'[^a-zA-Z0-9]').hasMatch(newPasswordController.text);

  bool get isPasswordMatch =>
      newPasswordController.text.isNotEmpty &&
      newPasswordController.text ==
          confirmPasswordController.text;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // PASSWORD INPUT
  // ==========================================

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    bool isLast = false,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        textInputAction:
            isLast ? TextInputAction.done : TextInputAction.next,
        style: const TextStyle(
          color: navy,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: mutedText,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: navy,
              size: 23,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bagian ini wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  // ==========================================
  // PASSWORD REQUIREMENT CHECK
  // ==========================================

  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 17,
            color: isValid ? const Color(0xFF777777) : mutedText,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: isValid ? const Color(0xFF777777) : mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SAVE PASSWORD
  // ==========================================

  void _savePassword() {
    if (!_formKey.currentState!.validate()) return;

    if (!hasMinLength ||
        !hasUppercase ||
        !hasNumberAndSymbol) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password belum memenuhi persyaratan.'),
          backgroundColor: navy,
        ),
      );
      return;
    }

    if (!isPasswordMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak sama.'),
          backgroundColor: navy,
        ),
      );
      return;
    }

    // Frontend: tampilkan konfirmasi sementara.
    // Hubungkan dengan Supabase untuk menyimpan password sebenarnya.

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
                size: 55,
              ),
              const SizedBox(height: 12),
              const Text(
                'Validasi Berhasil!',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Password baru sudah memenuhi semua persyaratan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
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
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
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
                        'Ubah Kata Sandi',
                        style: TextStyle(
                          color: navy,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOGO LOKABACA
                      SizedBox(
                        width: double.infinity,
                        height: 225,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF173C66),
                                  size: 85,
                                ),
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF173C66),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.auto_stories_rounded,
                                      color: Colors.white,
                                      size: 27,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Loka',
                                    style: TextStyle(
                                      color: Color(0xFF173C66),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Baca',
                                    style: TextStyle(
                                      color: Color(0xFFFFB72B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 105,
                              height: 2,
                              color: const Color(0xFFFFB72B),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          'Buat kata sandi yang kuat untuk akunmu.',
                          style: TextStyle(
                            color: navy,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // PASSWORD LAMA
                      _buildPasswordField(
                        hint: 'Kata Sandi Lama',
                        controller: oldPasswordController,
                        isVisible: isOldPasswordVisible,
                        onToggle: () {
                          setState(() {
                            isOldPasswordVisible =
                                !isOldPasswordVisible;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // PASSWORD BARU
                      _buildPasswordField(
                        hint: 'Kata Sandi Baru',
                        controller: newPasswordController,
                        isVisible: isNewPasswordVisible,
                        onToggle: () {
                          setState(() {
                            isNewPasswordVisible =
                                !isNewPasswordVisible;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // KONFIRMASI PASSWORD
                      _buildPasswordField(
                        hint: 'Konfirmasi Kata Sandi Baru',
                        controller: confirmPasswordController,
                        isVisible: isConfirmPasswordVisible,
                        isLast: true,
                        onToggle: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      // PASSWORD REQUIREMENTS
                      _buildRequirement(
                        'Minimal 8 karakter.',
                        hasMinLength,
                      ),
                      _buildRequirement(
                        'Sertakan huruf kapital.',
                        hasUppercase,
                      ),
                      _buildRequirement(
                        'Sertakan angka & simbol.',
                        hasNumberAndSymbol,
                      ),
                      _buildRequirement(
                        'Kata sandi baru dan konfirmasi harus sama.',
                        isPasswordMatch,
                      ),

                      const SizedBox(height: 35),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 47,
                        child: ElevatedButton(
                          onPressed: _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

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
}
