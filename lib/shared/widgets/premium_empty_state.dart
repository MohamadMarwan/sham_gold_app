import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:lottie/lottie.dart';

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDark ? AppColors.gold.withOpacity(0.5) : AppColors.gold.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.darkGreen,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : AppColors.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Optional Action Button
            if (onAction != null && actionLabel != null)
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
