import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/shared/models/price_item.dart';

/// بطاقة الترحيب (Welcome Card)
/// تعرض رسالة الترحيب مع ملخص السوق السريع (Market Pulse) مثل:
/// 'auto_str_226'.tr() بالإضافة للوقت والتاريخ.
/// تقرأ حالة السوق من `PriceService` وبيانات المستخدم من الكاش أو الحاضنة.
class WelcomeCard extends StatelessWidget {
  final List<PriceItem> items;

  const WelcomeCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final goldOunce = items.where((p) => p.id == 'xau_usd').firstOrNull;
    final isUp = (goldOunce?.changePercentage ?? 0) >= 0;
    final changePercent =
        (goldOunce?.changePercentage ?? 0).abs().toStringAsFixed(2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C16), // Dark emerald
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Header: [Percentage] ... [Title][Live]
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Right Section: Title and Live Badge (Placed first in code, rightmost in RTL)
                Row(
                  children: [
                    Text(
                      'market_pulse'.tr(),
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildLiveBadge(),
                  ],
                ),

                // 2. Percentage Pill (Placed second in code, leftmost in RTL)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$changePercent%',
                        style: TextStyle(
                          color: isUp ? const Color(0xFF00FF88) : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isUp ? const Color(0xFF00FF88) : Colors.red,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Metrics: [Liquidity] [Volatility] [Direction]
            Row(
              children: [
                Expanded(
                  child: _buildPulseMetricCard(
                    'liquidity'.tr(),
                    'high'.tr(),
                    Icons.water_drop_rounded,
                    const Color(0xFF00C2FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPulseMetricCard(
                    'volatility'.tr(),
                    'stable'.tr(),
                    Icons.bolt_rounded,
                    const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPulseMetricCard(
                    'direction'.tr(),
                    isUp ? 'going_up'.tr() : 'going_down'.tr(),
                    isUp ? Icons.north_east_rounded : Icons.south_east_rounded,
                    isUp ? const Color(0xFF00FF88) : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'live'.tr(),
            style: GoogleFonts.tajawal(
              color: const Color(0xFF00FF88),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          _buildLiveDot(),
        ],
      ),
    );
  }

  Widget _buildLiveDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.tajawal(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.tajawal(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
