import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Denda otomatis & pengingat jatuh tempo berjalan di latar depan aplikasi.
  // (Server-side trigger tersedia di supabase/migrations jika diinginkan.)
  unawaited(NotificationService.start());

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
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
          titleMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
          titleSmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
          bodyLarge: TextStyle(fontSize: 14, color: AppColors.text),
          bodyMedium: TextStyle(fontSize: 12, color: AppColors.text),
          bodySmall: TextStyle(fontSize: 10, color: AppColors.grey),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.navy),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}