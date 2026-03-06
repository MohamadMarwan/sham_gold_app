import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.darkGreen,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.darkGreen,
        secondary: AppColors.gold,
        tertiary: AppColors.tertiary,
        surface: Colors.white,
      ),
    );

    return _enhanceTheme(baseTheme);
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.majlisGold,
      scaffoldBackgroundColor: AppColors.majlisGreen,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.majlisGold,
        onPrimary: Color(0xFF03140F),
        secondary: AppColors.majlisGold,
        surface: Color(0xFF082D23),
        onSurface: Colors.white,
      ),
    );

    return _enhanceTheme(baseTheme, isDark: true);
  }

  static ThemeData _enhanceTheme(ThemeData baseTheme, {bool isDark = false}) {
    final textColor = isDark ? Colors.white : AppColors.primaryText;
    final secondaryTextColor =
        isDark ? Colors.white70 : AppColors.secondaryText;
    final mutedTextColor = isDark ? Colors.white54 : AppColors.mutedText;

    return baseTheme.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.cairo(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.cairo(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.cairo(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        // Amiri for a touch of heritage luxury
        displaySmall: GoogleFonts.amiri(
          color: AppColors.gold,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontStyle: FontStyle.italic,
        ),
        bodyLarge: GoogleFonts.cairo(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.cairo(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.cairo(
          color: mutedTextColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF0F3D30) : AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.majlisGold : AppColors.darkGreen,
          foregroundColor: isDark ? AppColors.majlisGreen : Colors.white,
          elevation: 8,
          shadowColor: AppColors.gold.withValues(alpha: 0.2),
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
