import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../pages/price_detail_page.dart';
import 'silver_calculator_bottom_sheet.dart';

class SilverPlatinumBanner extends ConsumerWidget {
  const SilverPlatinumBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceService = ref.watch(priceServiceProvider);
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
                SizedBox(width: 8),
                Text(
                  'auto_str_135'.tr(),
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
                      title: 'auto_str_350'.tr(),
                      iconColor: const Color(0xFF94A3B8),
                      ouncePrice: silverOunce.buyPrice,
                      gramPrice: silver999?.buyPrice ?? 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showMetalDetails(context, 'silver', silverOunce);
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
                      title: 'auto_str_314'.tr(),
                      iconColor: const Color(0xFFCBD5E1),
                      ouncePrice: platOunce.buyPrice,
                      gramPrice: plat999?.buyPrice ?? 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showMetalDetails(context, 'platinum', platOunce);
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
              SizedBox(width: 6),
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
          SizedBox(height: 12),
          // Ounce Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(width: 2),
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
          SizedBox(height: 2),
          Text(
            'auto_str_335'.tr(),
            style: GoogleFonts.tajawal(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
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
                  Text(
                    'auto_str_291'.tr(),
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

  void _showMetalDetails(BuildContext context, String type, PriceItem ounce) {
    final isSilver = type == 'silver';
    final ouncePrice = ounce.buyPrice;
    final gram999 = ouncePrice / 31.1035;
    
    final gramSecond = isSilver ? (gram999 * 0.925) : (gram999 * 0.950);
    final title = isSilver ? 'تفاصيل الفضة' : 'تفاصيل البلاتين';
    final iconColor = isSilver ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1);
    
    final items = [
      {
        'title': 'أونصة',
        'subtitle': '31.1035 غرام',
        'price': ouncePrice
      },
      {
        'title': isSilver ? 'غرام عيار 999' : 'غرام عيار 999/999.5',
        'subtitle': 'نقي 100%',
        'price': gram999
      },
      {
        'title': isSilver ? 'غرام عيار 925' : 'غرام عيار 950',
        'subtitle': 'صياغة ومجوهرات',
        'price': gramSecond
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.diamond_outlined, color: iconColor),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$ ${(item['price'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PriceDetailPage(priceItem: ounce)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('الرسم البياني وتفاصيل أكثر', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (isSilver) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close details sheet
                    SilverCalculatorBottomSheet.show(context); // Open calculator
                  },
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('حاسبة الكسر والمصنعية للفضة', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
