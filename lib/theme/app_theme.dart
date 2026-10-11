import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF2E9E4F);
  static const darkGreen = Color(0xFF166534);
  static const lightGreen = Color(0xFFE8F5E9);
  static const red = Color(0xFFE53946);
  static const lightRed = Color(0xFFFDECEE);
  static const grey = Color(0xFFFFD5D5);
  static const border = Color(0xFFE0E0E0);
  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const blue = Color(0xFF1E88E5);
  static const orange = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.green, primary: AppColors.green),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.lightGreen,
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}