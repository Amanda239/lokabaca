
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  // WARNA LOKABACA
  static const Color navy = AppColors.navy;
  static const Color cream = AppColors.cream;
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
  bool isLoading = false;

  // VALIDASI PASSWORD
  bool get hasMinLength =>
      newPasswordController.text.length >= 8;

  bool get hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(newPasswordController.text);

  bool get hasNumberAndSymbol =>
      RegExp(r'[0-9]').hasMatch(newPasswordController.text) &&
      RegExp(r'[^a-zA-Z0-9]').hasMatch(
        newPasswordController.text,
      );

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

  // PESAN
  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // PASSWORD INPUT
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
            color: Colors.black.withValues(alpha: 0.20),
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
        onChanged: (_) {
          if (controller == newPasswordController ||
              controller == confirmPasswordController) {
            setState(() {});
          }
        },
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

  // CHECKLIST PERSYARATAN PASSWORD
  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 17,
            color: isValid ? Colors.green : mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isValid ? Colors.green : mutedText,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SIMPAN PASSWORD KE SUPABASE
  Future<void> _savePassword() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (!hasMinLength ||
        !hasUppercase ||
        !hasNumberAndSymbol) {
      _showMessage(
        'Password belum memenuhi persyaratan.',
      );
      return;
    }

    if (!isPasswordMatch) {
      _showMessage(
        'Konfirmasi password tidak sama.',
      );
      return;
    }

    final oldPassword = oldPasswordController.text;
    final newPassword = newPasswordController.text;

    if (oldPassword == newPassword) {
      _showMessage(
        'Password baru harus berbeda dari password lama.',
      );
      return;
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) {
      _showMessage(
        'Sesi akun tidak ditemukan. Silakan login kembali.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. VERIFIKASI PASSWORD LAMA
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: oldPassword,
      );

      // 2. UPDATE PASSWORD BARU
      await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (!mounted) return;

      _showMessage(
        'Kata sandi berhasil diperbarui!',
        success: true,
      );

      // 3. KEMBALI KE HALAMAN SEBELUMNYA
      Navigator.pop(context, true);

    } on AuthException catch (e) {
      if (!mounted) return;

      final message = e.message.toLowerCase();

      if (message.contains('invalid') ||
          message.contains('credentials') ||
          message.contains('password')) {
        _showMessage('Kata sandi lama tidak sesuai.');
      } else {
        _showMessage(
          'Gagal mengganti kata sandi: ${e.message}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Terjadi kesalahan saat mengganti kata sandi.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

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
                        child: Center(
                          child: Image.asset(
                            'assets/images/lokabaca.png',
                            width: 170,
                            height: 170,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    color: navy,
                                    size: 85,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'LokaBaca',
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
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

                      const SizedBox(height: 65),

                      // TOMBOL SIMPAN
                      SizedBox(
                        width: double.infinity,
                        height: 47,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.grey,
                            elevation: 3,
                            shadowColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
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
