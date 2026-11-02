
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import 'login_admin.dart';
import 'dashboard_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mwcjntpvfxyvfosxjwrk.supabase.co',
    publishableKey: 'sb_publishable_doU8rB3Cj8DdO02xDzXSCg_2-9yhE_q',
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LokaBaca Admin',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.yellow,
        ),
        fontFamily: 'Poppins',
      ),

      home: const LoginAdmin(),

      routes: {
        '/admin-login': (context) => const LoginAdmin(),
        '/dashboard-admin': (context) => const DashboardAdmin(),
      },
    );
  }
}
