import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/core/services/ad_service.dart';

class WatchAdRewardWidget extends StatefulWidget {
  const WatchAdRewardWidget({super.key});

  @override
  State<WatchAdRewardWidget> createState() => _WatchAdRewardWidgetState();
}

class _WatchAdRewardWidgetState extends State<WatchAdRewardWidget> {
  Timer? _timer;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_adService.isRewardActive) {
        if (mounted) setState(() {});
      } else {
        if (_timer != null && _timer!.isActive) {
          // We can keep it running or stop, but simple setState is fine
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRewardActive = _adService.isRewardActive;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: isRewardActive
            ? Colors.green.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isRewardActive
              ? Colors.green.withValues(alpha: 0.2)
              : AppColors.gold.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isRewardActive ? Colors.green : AppColors.gold)
                .withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildHeader(isRewardActive),
          const SizedBox(height: 16),
          _buildTitle(isRewardActive),
          const SizedBox(height: 8),
          _buildSubtitle(isRewardActive),
          const SizedBox(height: 20),
          _buildActionButton(isRewardActive),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            (isActive ? Colors.green : AppColors.gold).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isActive ? Icons.verified_user_rounded : Icons.card_giftcard_rounded,
        color: isActive ? Colors.green : AppColors.gold,
        size: 32,
      ),
    );
  }

  Widget _buildTitle(bool isActive) {
    return Text(
      isActive ? 'أنت الآن في الوضع المميّز' : 'شاهد إعلان واحصل على مكافأة',
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: AppColors.darkGreen,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle(bool isActive) {
    if (isActive) {
      return Column(
        children: [
          const Text(
            'استمتع بالتطبيق بدون إعلانات بانر نهائياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Text(
                  'المتبقي: ${_adService.remainingRewardTime}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const Text(
      'قم بمشاهدة إعلان واحد قصير لتفعيل ميزة "منع الإعلانات" في كافة صفحات التطبيق لمدة نصف ساعة كاملة',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionButton(bool isActive) {
    if (isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _adService.showRewardedAd(
            onRewardEarned: () async {
              await _adService.activateReward(30);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'تم تفعيل المكافأة! استمتع بنصف ساعة بدون إعلانات 🎁',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            onAdFailed: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'لا يوجد إعلان متاح حالياً. يرجى المحاولة لاحقاً ⏳',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: 'Cairo')),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.darkGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill_rounded, size: 22),
            SizedBox(width: 12),
            Text(
              'شاهد الآن وفعل المكافأة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
