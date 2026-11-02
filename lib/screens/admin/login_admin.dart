
import 'package:flutter/material.dart';

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});

  @override
  State<LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin> {
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;
  bool rememberMe = false;

  // Warna LokaBaca
  static const Color navy = Color(0xFF2E4057);
  static const Color yellow = Color(0xFFFFBC35);
  static const Color cream = Color(0xFFF8F4EA);

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Fungsi login
  void _login() {
    if (_formKey.currentState!.validate()) {
      final username = usernameController.text.trim();
      final password = passwordController.text;

      // Hubungkan dengan API login admin di sini.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data login berhasil divalidasi: $username'),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 45,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // LOGO LOKABACA
                  Image.asset(
                    'assets/images/lokabaca.png',
                    width: 175,
                    height: 175,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.menu_book_rounded,
                        size: 120,
                        color: navy,
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // JUDUL ADMIN PANEL
                  const Text(
                    'ADMIN PANEL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 13),

                  // SUBJUDUL
                  const Text(
                    'Masuk untuk mengelola perpustakaan\n'
                    'dengan mudah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: Color(0xFF718096),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // LABEL USERNAME
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // INPUT USERNAME
                  TextFormField(
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan username',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: navy,
                        size: 23,
                      ),
                      filled: true,
                      fillColor: cream,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0DDD5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: navy,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // LABEL PASSWORD
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // INPUT PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan password akun',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: navy,
                        size: 23,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: navy,
                          size: 23,
                        ),
                      ),
                      filled: true,
                      fillColor: cream,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0DDD5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: navy,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // INGAT SAYA
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: rememberMe,
                          activeColor: navy,
                          side: const BorderSide(
                            color: navy,
                            width: 2,
                          ),
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Text(
                        'Ingat saya',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: navy,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL MASUK
                  SizedBox(
                    width: double.infinity,
                    height: 43,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.black45,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
