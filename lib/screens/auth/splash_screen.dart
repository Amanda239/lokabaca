
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../admin/dashboard_admin.dart';
import '../user/dashboard_screen.dart';
import '../user/kebijakan_peminjaman_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Sudah login? Langsung ke dashboard sesuai peran (user/admin).
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (!AuthService.isLoggedIn) return;
    final role = await AuthService.currentRole();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => role == 'admin'
            ? const DashboardAdmin()
            : const DashboardScreen(),
      ),
    );
  }

  Future<void> _goToPolicy(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const KebijakanPeminjamanScreen(),
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // LOGO
                  Image.asset(
                    'assets/images/lokabaca.png',
                    width: 190,
                    height: 190,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 190,
                        height: 190,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 115,
                          color: AppColors.navy,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // TAGLINE
                  const Text(
                    'Perpustakaan Digital\ndi Genggamanmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // START BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _goToPolicy(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Mulai',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LOGIN LINK
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _goToPolicy(context),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
