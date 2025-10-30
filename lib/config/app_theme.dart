import 'package:flutter/material.dart';
import 'app_colors.dart';
class AppTheme {
  AppTheme._();

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark, 
    scaffoldBackgroundColor: AppColors.darkBgPrimary,
    primaryColor: AppColors.purple,
    cardColor: AppColors.cardBg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBg,
      hintStyle: const TextStyle(color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.green,
      error: AppColors.error,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );
}
