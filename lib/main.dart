import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const LokaBacaApp());
}

class LokaBacaApp extends StatelessWidget {
  const LokaBacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LokaBaca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.yellow,
        ),
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}