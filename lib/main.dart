import 'package:flutter/material.dart';

import 'screens/login_screen.dart'; // Ubah ke login screen
import 'theme/app_colors.dart';

void main() {
  runApp(const PeriodTrackerApp());
}

class PeriodTrackerApp extends StatelessWidget {
  const PeriodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pelacak Haid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(), // <-- Set ke LoginScreen
    );
  }
}
