
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import 'register_screen.dart';
import '../admin/dashboard_admin.dart';
import '../user/dashboard_screen.dart';

enum LoginRole { user, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginRole _selectedRole = LoginRole.user;

  bool _hidePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Login menggunakan Supabase Auth
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user == null) {
        _showMessage(
          'Login belum berhasil. Silakan coba lagi.',
          isError: true,
        );
        return;
      }

      // Ambil role dari tabel profiles
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        await supabase.auth.signOut();

        _showMessage(
          'Data akun tidak ditemukan.',
          isError: true,
        );
        return;
      }

      final String actualRole = profile['role']?.toString() ?? '';

      // Pastikan role akun sesuai dengan pilihan login
      if (_selectedRole == LoginRole.admin && actualRole != 'admin') {
        await supabase.auth.signOut();

        if (!mounted) return;

        _showMessage(
          'Akun ini tidak memiliki akses admin.',
          isError: true,
        );
        return;
      }

      if (_selectedRole == LoginRole.user && actualRole != 'user') {
        await supabase.auth.signOut();

        if (!mounted) return;

        _showMessage(
          'Silakan pilih menu login yang sesuai.',
          isError: true,
        );
        return;
      }

      // Arahkan berdasarkan role asli dari database
      final Widget destination = actualRole == 'admin'
          ? const DashboardAdmin()
          : const DashboardScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        _getAuthErrorMessage(error),
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint('Login error: $error');

      _showMessage(
        'Tidak dapat terhubung ke server. Periksa koneksi internetmu.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Silakan cek emailmu.';
    }

    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }

    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }

    return error.message;
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
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
                              width: 78,
                              height: 68,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.menu_book_rounded,
                                  size: 60,
                                  color: AppColors.navy,
                                );
                              },
                            ),
                            const SizedBox(height: 5),
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

                      const SizedBox(height: 30),

                      const Text(
                        'Selamat Datang!',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Masuk ke akun LokaBaca untuk melanjutkan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // PILIH JENIS AKUN
                      const Text(
                        'Masuk sebagai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _roleButton(
                                role: LoginRole.user,
                                icon: Icons.person_outline_rounded,
                                label: 'User',
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: _roleButton(
                                role: LoginRole.admin,
                                icon: Icons.admin_panel_settings_outlined,
                                label: 'Admin',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // EMAIL
                      AuthTextField(
                        label: 'Email',
                        hint: 'nama@gmail.com',
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

                      const SizedBox(height: 17),

                      // PASSWORD
                      AuthTextField(
                        label: 'Password',
                        hint: 'Masukkan password akun',
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          return null;
                        },
                      ),

                      // INGAT SAYA & LUPA PASSWORD
                      Row(
                        children: [
                          SizedBox(
                            height: 38,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.navy,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _rememberMe =
                                                  value ?? false;
                                            });
                                          },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Ingat saya',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _showMessage(
                                      'Halaman lupa password akan dibuat berikutnya.',
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // TOMBOL MASUK
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 23),

                      // PEMBATAS
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
                              'atau masuk dengan',
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

                      const SizedBox(height: 19),

                      // SOCIAL LOGIN
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

                      const SizedBox(height: 22),

                      // DAFTAR
                      if (_selectedRole == LoginRole.user)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        );
                                      },
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_selectedRole == LoginRole.admin)
                        const Center(
                          child: Text(
                            'Khusus administrator LokaBaca',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // TOMBOL PILIH ROLE
  Widget _roleButton({
    required LoginRole role,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              setState(() {
                _selectedRole = role;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.white : AppColors.navy,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        _showMessage('Login $label belum diaktifkan.');
      },
      icon: Icon(icon, color: color, size: 25),
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
