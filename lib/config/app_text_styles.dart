import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  
  // Headers
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
}