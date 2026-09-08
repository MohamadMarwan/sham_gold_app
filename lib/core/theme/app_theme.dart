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
      scaffoldBackgroundColor: AppColors.darkScaffold,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.majlisGold,
        onPrimary: AppColors.darkScaffold,
        secondary: AppColors.majlisGold,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
        surfaceContainerHighest: AppColors.darkSurfaceRaised,
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
      scaffoldBackgroundColor: isDark ? AppColors.darkScaffold : AppColors.background,
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
        color: isDark ? AppColors.darkSurface : AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? AppColors.gold.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceRaised : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: isDark ? AppColors.gold.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceRaised : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.majlisGold : AppColors.darkGreen,
          foregroundColor: isDark ? AppColors.majlisGreen : Colors.white,
          elevation: 4,
          shadowColor: AppColors.gold.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
