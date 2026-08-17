import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../pages/price_detail_page.dart';

class SilverPlatinumBanner extends StatelessWidget {
  const SilverPlatinumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    final silverOunce = allPrices.where((p) => p.id == 'xag_usd').firstOrNull;
    final silver999 = allPrices.where((p) => p.id == 'silver_999_usd').firstOrNull;
    
    final platOunce = allPrices.where((p) => p.id == 'xpt_usd').firstOrNull;
    final plat999 = allPrices.where((p) => p.id == 'plat_999_usd').firstOrNull;

    if (silverOunce == null && platOunce == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  'المعادن الثمينة الأخرى',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Metals
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (silverOunce != null)
                  Expanded(
                    child: _buildMetalCard(
                      context,
                      title: 'الفضة',
                      iconColor: const Color(0xFF94A3B8),
                      ouncePrice: silverOunce.buyPrice,
                      gramPrice: silver999?.buyPrice ?? 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PriceDetailPage(priceItem: silverOunce)));
                      },
                    ),
                  ),
                if (silverOunce != null && platOunce != null)
                  Container(
                    width: 1.5,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                if (platOunce != null)
                  Expanded(
                    child: _buildMetalCard(
                      context,
                      title: 'البلاتين',
                      iconColor: const Color(0xFFCBD5E1),
                      ouncePrice: platOunce.buyPrice,
                      gramPrice: plat999?.buyPrice ?? 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PriceDetailPage(priceItem: platOunce)));
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetalCard(BuildContext context, {
    required String title,
    required Color iconColor,
    required double ouncePrice,
    required double gramPrice,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ounce Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '\$',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 2),
              LivePriceWidget(
                price: ouncePrice,
                currency: '',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'للأونصة',
            style: GoogleFonts.tajawal(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Gram Price
          if (gramPrice > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'غرام 999: ',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Cairo'),
                  ),
                  Text(
                    '\$${gramPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
