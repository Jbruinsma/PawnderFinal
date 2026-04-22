import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppThemeController {
  AppThemeController._();

  static const _storage = FlutterSecureStorage();
  static const _themeModeKey = 'pawnder_theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> load() async {
    final savedMode = await _storage.read(key: _themeModeKey);
    mode.value = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static void setDarkMode(bool isDarkMode) {
    mode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _storage.write(key: _themeModeKey, value: isDarkMode ? 'dark' : 'light');
  }
}

class AppColors {
  static const Color seaBlue = Color(0xFF111315);
  static const Color powderBlue = Color(0xFFF2F5F6);
  static const Color shellBlue = Color(0xFFFAFBFC);
  static const Color ink = Color(0xFF101010);
  static const Color lineGray = Color(0xFFB0B8C1);
  static const Color bodyText = Color(0xFF626D78);
  static const Color inputSurface = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFDCE4E8);
  static const Color iconSurface = Color(0xFFECEFEE);

  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF151822);
  static const Color darkElevated = Color(0xFF202435);
  static const Color darkText = Color(0xFFEDECF3);
  static const Color darkMuted = Color(0xFFA6A6B3);
  static const Color darkLine = Color(0xFF2A2E3D);

  const AppColors._();
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seaBlue,
      brightness: Brightness.light,
      primary: AppColors.seaBlue,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.bodyText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.powderBlue,
      cardColor: Colors.white,
      dividerColor: AppColors.inputBorder,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkText,
      brightness: Brightness.dark,
      primary: AppColors.darkText,
      onPrimary: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkLine,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkText,
          foregroundColor: AppColors.darkBackground,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkElevated,
      ),
    );
  }
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
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    color: AppColors.seaBlue,
  );

  static const TextStyle helper = TextStyle(
    fontSize: 12,
    color: AppColors.bodyText,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 32,
    height: 1,
    fontWeight: FontWeight.w900,
    color: AppColors.seaBlue,
  );

  static const TextStyle screenSubtitle = TextStyle(
    fontSize: 13,
    color: Color(0xFF27313A),
    fontWeight: FontWeight.w700,
  );

  static const TextStyle button = TextStyle(
    fontSize: 30,
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
