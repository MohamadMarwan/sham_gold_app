import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../pages/price_detail_page.dart';
import 'silver_calculator_bottom_sheet.dart';

class SilverPlatinumBanner extends ConsumerWidget {
  final bool isGrid;
  const SilverPlatinumBanner({super.key, this.isGrid = true});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('auto_str_135'.tr(), Icons.diamond_outlined),
        const SizedBox(height: 16),
        isGrid
            ? Row(
                children: [
                  if (silverOunce != null)
                    Expanded(
                      child: _buildMetalCard(
                        context,
                        title: 'auto_str_350'.tr(),
                        iconColor: const Color(0xFF94A3B8),
                        ouncePrice: silverOunce.buyPrice,
                        gramPrice: silver999?.buyPrice ?? 0,
                        isGrid: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showMetalDetails(context, 'silver', silverOunce);
                        },
                      ),
                    ),
                  if (silverOunce != null && platOunce != null)
                    const SizedBox(width: 16),
                  if (platOunce != null)
                    Expanded(
                      child: _buildMetalCard(
                        context,
                        title: 'auto_str_314'.tr(),
                        iconColor: const Color(0xFFCBD5E1),
                        ouncePrice: platOunce.buyPrice,
                        gramPrice: plat999?.buyPrice ?? 0,
                        isGrid: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showMetalDetails(context, 'platinum', platOunce);
                        },
                      ),
                    ),
                ],
              )
            : Column(
                children: [
                  if (silverOunce != null)
                    _buildMetalCard(
                      context,
                      title: 'auto_str_350'.tr(),
                      iconColor: const Color(0xFF94A3B8),
                      ouncePrice: silverOunce.buyPrice,
                      gramPrice: silver999?.buyPrice ?? 0,
                      isGrid: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showMetalDetails(context, 'silver', silverOunce);
                      },
                    ),
                  if (silverOunce != null && platOunce != null)
                    const SizedBox(height: 12),
                  if (platOunce != null)
                    _buildMetalCard(
                      context,
                      title: 'auto_str_314'.tr(),
                      iconColor: const Color(0xFFCBD5E1),
                      ouncePrice: platOunce.buyPrice,
                      gramPrice: plat999?.buyPrice ?? 0,
                      isGrid: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showMetalDetails(context, 'platinum', platOunce);
                      },
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGreen,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, Colors.orangeAccent],
              ),
              borderRadius: BorderRadius.circular(10),
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
    required bool isGrid,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.diamond_outlined, color: iconColor, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ounce Price
                  Text(
                    'auto_str_335'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mutedText,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      LivePriceWidget(
                        price: ouncePrice,
                        currency: '',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '\$',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Gram Price (if available)
                  if (gramPrice > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'auto_str_291'.tr(),
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.white70 : AppColors.mutedText,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 2),
                          LivePriceWidget(
                            price: gramPrice,
                            currency: '',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: isDark ? Colors.white70 : AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '\$',
                            style: GoogleFonts.cairo(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title Side
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.diamond_outlined, color: iconColor, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  // Price Side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'auto_str_335'.tr() + ' ',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mutedText,
                            ),
                          ),
                          LivePriceWidget(
                            price: ouncePrice,
                            currency: '',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.darkGreen,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '\$',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      if (gramPrice > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'auto_str_291'.tr(),
                                style: GoogleFonts.cairo(
                                  color: isDark ? Colors.white70 : AppColors.mutedText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                              LivePriceWidget(
                                price: gramPrice,
                                currency: '',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '\$',
                                style: GoogleFonts.cairo(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
