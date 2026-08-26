import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasGlassEffect;
  final Color? customBackgroundColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.borderRadius = 24.0,
    this.onTap,
    this.hasGlassEffect = false,
    this.customBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Default background color if not provided
    Color bgColor = customBackgroundColor ?? (isDark 
        ? const Color(0xFF1E293B) // Dark elegant color
        : Colors.white);

    // Border color based on theme
    Color borderColor = isDark 
        ? AppColors.gold.withValues(alpha: 0.2) 
        : Colors.grey.withValues(alpha: 0.1);

    // Shadow
    List<BoxShadow> boxShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        : [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ];

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: hasGlassEffect ? bgColor.withValues(alpha: 0.7) : bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: hasGlassEffect ? [] : boxShadow,
      ),
      child: child,
    );

    if (hasGlassEffect) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: cardContent,
        ),
      );
    }

    Widget finalWidget = Container(
      margin: margin,
      child: cardContent,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: finalWidget,
      );
    }

    return finalWidget;
  }
}
