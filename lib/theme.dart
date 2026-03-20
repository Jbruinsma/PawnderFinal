import 'package:flutter/material.dart';

class AppColors {
  static const Color blush = Color(0xFFE7C6CB);
  static const Color seaBlue = Color(0xFF0E889C);
  static const Color powderBlue = Color(0xFFDCE2E9);
  static const Color lineGray = Color(0xFFB0B8C1);
  static const Color bodyText = Color(0xFF7E8792);
  static const Color inputSurface = Color(0xFFF1F5F8);
  static const Color inputBorder = Color(0xFFCCD5DE);
  static const Color iconSurface = Color(0xFFE5EEF4);

  const AppColors._();
}

class AppTextStyles {
  static const TextStyle heroTitle = TextStyle(
    fontSize: 48,
    height: 1.05,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.2,
    color: Colors.white,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    color: AppColors.seaBlue,
  );

  static const TextStyle helper = TextStyle(
    fontSize: 12,
    color: AppColors.bodyText,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static const TextStyle field = TextStyle(
    fontSize: 17,
    color: AppColors.bodyText,
    fontWeight: FontWeight.w600,
  );

  const AppTextStyles._();
}