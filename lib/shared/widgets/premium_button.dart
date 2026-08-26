import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum PremiumButtonType { primary, secondary, outline, text }

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final PremiumButtonType type;
  final bool isLoading;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.type = PremiumButtonType.primary,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 54.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case PremiumButtonType.primary:
        backgroundColor = isDark ? AppColors.majlisGold : AppColors.darkGreen;
        textColor = isDark ? AppColors.majlisGreen : Colors.white;
        break;
      case PremiumButtonType.secondary:
        backgroundColor = (isDark ? AppColors.majlisGold : AppColors.gold).withValues(alpha: 0.15);
        textColor = isDark ? AppColors.majlisGold : AppColors.darkGreen;
        break;
      case PremiumButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.majlisGold : AppColors.darkGreen;
        borderSide = BorderSide(color: textColor, width: 2);
        break;
      case PremiumButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.majlisGold : AppColors.darkGreen;
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: (type == PremiumButtonType.primary) ? 4 : 0,
      shadowColor: (type == PremiumButtonType.primary)
          ? (isDark ? AppColors.majlisGold : AppColors.darkGreen).withValues(alpha: 0.4)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: borderSide,
      ),
      padding: padding,
    );

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, size: 24, color: textColor),
          const SizedBox(width: 12),
        ],
        Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: type == PremiumButtonType.text
          ? TextButton(
              onPressed: isLoading ? null : onPressed,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: padding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            ),
    );
  }
}
