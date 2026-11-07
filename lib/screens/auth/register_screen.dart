
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/password_requirements.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  // Pilihan role, default User
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();

    // Memperbarui checklist ketika password berubah.
    _passwordController.addListener(_refreshPasswordRequirements);
    _confirmPasswordController.addListener(_refreshPasswordRequirements);
  }

  void _refreshPasswordRequirements() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ==========================================
  // ROLE SELECTOR
  // ==========================================

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar sebagai',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDED9CD),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // PILIHAN USER
              Expanded(
                child: _buildRoleButton(
                  title: 'User',
                  icon: Icons.person_outline_rounded,
                  role: 'user',
                ),
              ),

              // PILIHAN ADMIN
              Expanded(
                child: _buildRoleButton(
                  title: 'Admin',
                  icon: Icons.shield_outlined,
                  role: 'admin',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required String title,
    required IconData icon,
    required String role,
  }) {
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.navy,
              size: 21,
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VALIDASI PASSWORD
  // ==========================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }

    if (!RegExp(r'(?=.*[A-Z])(?=.*[a-z])').hasMatch(value)) {
      return 'Harus mengandung huruf besar dan kecil';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Harus mengandung minimal 1 angka';
    }

    return null;
  }

  // ==========================================
  // REGISTER SUPABASE
  // ==========================================

  Future<void> _register() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),

          // Role yang dipilih
          'role': _selectedRole,
        },
      );

      if (!mounted) return;

      if (response.user == null) {
        _showMessage(
          'Akun belum berhasil dibuat. Silakan coba lagi.',
          isError: true,
        );
        return;
      }

      if (response.session == null) {
        _showMessage(
          'Akun berhasil dibuat. Silakan cek email untuk verifikasi.',
        );
      } else {
        _showMessage('Registrasi berhasil! Silakan masuk.');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        _getAuthErrorMessage(error),
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Tidak dapat terhubung ke server. Periksa koneksi internetmu.',
        isError: true,
      );

      debugPrint('Register error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // AUTH ERROR MESSAGE
  // ==========================================

  String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }

    if (message.contains('password')) {
      return 'Password tidak memenuhi persyaratan.';
    }

    if (message.contains('email')) {
      return 'Email tidak valid atau tidak dapat digunakan.';
    }

    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }

    return error.message;
  }

  // ==========================================
  // SNACKBAR
  // ==========================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? Colors.red.shade700 : AppColors.navy,
        ),
      );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.navy,
            size: 30,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 2, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOGO
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/lokabaca.png',
                        width: 72,
                        height: 58,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.menu_book_rounded,
                            size: 52,
                            color: AppColors.navy,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Jendela Literasi & Koleksi Buku',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // HEADING
                const Text(
                  'Buat Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Yuk, bergabung dan mulai jelajahi ribuan buku!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),

                const SizedBox(height: 21),

                // ==================================
                // PILIHAN USER DAN ADMIN
                // ==================================

                _buildRoleSelector(),

                const SizedBox(height: 21),

                // NAMA LENGKAP
                AuthTextField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline_rounded,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 13),

                // EMAIL
                AuthTextField(
                  label: 'Email',
                  hint: 'Masukkan email',
                  icon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        !RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 13),

                // NOMOR TELEPON
                AuthTextField(
                  label: 'Nomor Telepon',
                  hint: 'Masukkan nomor telepon',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor telepon wajib diisi';
                    }

                    if (!RegExp(r'^[0-9+\-\s()]{8,20}$')
                        .hasMatch(value.trim())) {
                      return 'Nomor telepon tidak valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 13),

                // PASSWORD
                AuthTextField(
                  label: 'Password',
                  hint: 'Masukkan password',
                  icon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.navy,
                    ),
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 12),

                // CHECKLIST PASSWORD
                PasswordRequirements(
                  password: _passwordController.text,
                  confirmPassword: _confirmPasswordController.text,
                  showConfirmation: true,
                ),

                const SizedBox(height: 13),

                // KONFIRMASI PASSWORD
                AuthTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Masukkan ulang password',
                  icon: Icons.lock_outline_rounded,
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.navy,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }

                    if (value != _passwordController.text) {
                      return 'Konfirmasi password tidak cocok';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // TOMBOL DAFTAR
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor:
                          AppColors.navy.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 19),

                // DIVIDER
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.border),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: Text(
                        'atau daftar dengan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.border),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // SOCIAL BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Google',
                      color: const Color(0xFF4285F4),
                    ),
                    const SizedBox(width: 18),
                    _socialButton(
                      icon: Icons.apple,
                      label: 'Apple',
                      color: Colors.black,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // LOGIN NAVIGATION
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SOCIAL BUTTON
  // ==========================================

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        _showMessage(
          'Pendaftaran dengan $label belum diaktifkan.',
        );
      },
      icon: Icon(icon, color: color, size: 24),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.text,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
