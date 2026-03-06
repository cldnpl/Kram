import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceLight,
        error: AppColors.errorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surfaceLight,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
        error: AppColors.errorDark,
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onSurface: Colors.white,
        onError: Colors.black87,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }
}
