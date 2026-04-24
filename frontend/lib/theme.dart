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
  static const Color emerald = Color(0xFF0F9D58);
  static const Color gold = Color(0xFFD4AF37);
  static const Color platinum = Color(0xFFE5E4E2);

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
  static Decoration backgroundDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 1.5,
        colors: isDark
            ? const [Color(0xFF1E1E1E), Color(0xFF121212), Color(0xFF0A0A0A)]
            : const [AppColors.platinum, Color(0xFFF5F5F5), Colors.white],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
      primary: AppColors.emerald,
      secondary: AppColors.gold,
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
          foregroundColor: AppColors.platinum,
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
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
      primary: AppColors.emerald,
      secondary: AppColors.gold,
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
  static TextStyle heroTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 48,
      height: 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.2,
      color: isDark ? Colors.white : AppColors.ink,
    );
  }

  static TextStyle cardTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.3,
      color: isDark ? AppColors.platinum : AppColors.seaBlue,
    );
  }

  static TextStyle helper(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 12,
      color: isDark ? AppColors.darkMuted : AppColors.bodyText,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle screenTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 32,
      height: 1,
      fontWeight: FontWeight.w900,
      color: isDark ? Colors.white : AppColors.seaBlue,
    );
  }

  static TextStyle screenSubtitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 13,
      color: isDark ? const Color(0xFFB0B8C1) : const Color(0xFF27313A),
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle button(BuildContext context) {
    return const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );
  }

  static TextStyle field(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 17,
      color: isDark ? AppColors.darkText : AppColors.bodyText,
      fontWeight: FontWeight.w600,
    );
  }

  const AppTextStyles._();
}