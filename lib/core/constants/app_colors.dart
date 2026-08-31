import 'package:flutter/material.dart';

class AppColors {
  // Core Brand Colors
  static const Color gold = Color(0xFFC5A059); // Premium muted gold
  static const Color darkGreen = Color(0xFF0F172A); // Emerald Dark
  static const Color accentGreen = Color(0xFF1E293B); // Emerald Light
  static const Color warmBrown = Color(0xFF8B6B2D); // Primary Gold Dark
  static const Color warmBeige = Color(0xFFF9F7F2); // Premium off-white
  static const Color lightGrey = Color(0xFFF0F2F5);
  static const Color tertiary = Color(0xFFB87333); // Copper accent
  static const Color copper = tertiary;

  // Majlis (Elite Dark Mode) Palette
  static const Color majlisGreen = Color(0xFF000000); // True Black for OLED
  static const Color majlisGold = Color(0xFFC5A059); // Royal Gold
  static const Color trueBlack = Color(0xFF000000); // OLED Black
  static const Color trueBlackCard = Color(0xFF0A0A0A); // Slightly lighter for cards

  static const Color background = warmBeige;
  static const Color primaryText = Color(0xFF1D2121); // Dark charcoal
  static const Color secondaryText = Color(0xFF4A4A4A);
  static const Color mutedText = Color(0xFF7A7A7A);

  static const Color cardBackground = Colors.white;
  static const Color priceUp = Color(0xFF2E7D32); // Professional green
  static const Color priceDown = Color(0xFFC62828); // Professional red
  static const Color stable = Color(0xFF757575);
  static const Color success = priceUp;
  static const Color error = priceDown;
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color liveGreen = Color(0xFF00FF88);

  // --- Premium Metallic Gradients ---
  static LinearGradient get goldGradient => const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFF9D423), Color(0xFFC5A059)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get platinumGradient => const LinearGradient(
        colors: [Color(0xFFE5E4E2), Colors.white, Color(0xFFB4B4B4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get emeraldGradient => const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF121212)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );

  static LinearGradient get glassGradient => LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
