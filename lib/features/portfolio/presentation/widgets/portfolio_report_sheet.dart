import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/portfolio_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';

class PortfolioReportSheet extends StatefulWidget {
  final PortfolioProvider portfolio;
  final dynamic country;
  final List<PriceItem> currentPrices;
  final NumberFormat numberFormat;

  const PortfolioReportSheet({
    super.key,
    required this.portfolio,
    required this.country,
    required this.currentPrices,
    required this.numberFormat,
  });

  static Future<void> show(
    BuildContext context, {
    required PortfolioProvider portfolio,
    required dynamic country,
    required List<PriceItem> currentPrices,
    required NumberFormat numberFormat,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PortfolioReportSheet(
        portfolio: portfolio,
        country: country,
        currentPrices: currentPrices,
        numberFormat: numberFormat,
      ),
    );
  }

  @override
  State<PortfolioReportSheet> createState() => _PortfolioReportSheetState();
}

class _PortfolioReportSheetState extends State<PortfolioReportSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    try {
      // Ensure layout is settled
      await Future.delayed(const Duration(milliseconds: 150));
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RenderRepaintBoundary is null');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) {
        throw Exception('Failed to generate image bytes');
      }

      final fileName = 'sham_gold_portfolio_statement_${DateTime.now().millisecondsSinceEpoch}.png';
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        text: '${'portfolio_report_title'.tr()} - ${'portfolio_report_subtitle'.tr()}\n${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
        subject: 'portfolio_report_title'.tr(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('share_error'.tr(args: [e.toString()]), style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _shareText() {
    HapticFeedback.selectionClick();
    final country = widget.country;
    final currencySymbol = CurrencyUtils.getSymbol(country.currencyCode, context: context);
    final portfolio = widget.portfolio;
    final numberFormat = widget.numberFormat;

    final totalValuation = portfolio.calculateCurrentValuation(widget.currentPrices);
    final totalCost = portfolio.totalInvestedCost;
    final totalPnL = portfolio.calculateTotalPnL(widget.currentPrices);
    final roi = portfolio.calculateRoiPercentage(widget.currentPrices);
    final pureGoldGrams = portfolio.totalPureWeightGrams;

    const double nisabGrams = 85.0;
    final hasReachedNisab = pureGoldGrams >= nisabGrams;
    final zakatGrams = pureGoldGrams * 0.025;
    final zakatVal = totalValuation * 0.025;

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('👑 *${'portfolio_report_title'.tr()}*');
    buffer.writeln('🏛️ ${'portfolio_report_subtitle'.tr()}');
    buffer.writeln('📅 $dateStr | ${country.name} (${country.currencyCode})');
    buffer.writeln('--------------------------------');
    buffer.writeln('💰 ${'portfolio_current_valuation'.tr()}: ${numberFormat.format(totalValuation)} $currencySymbol');
    buffer.writeln('💵 ${'portfolio_invested_capital'.tr()}: ${numberFormat.format(totalCost)} $currencySymbol');
    buffer.writeln('📈 ${'portfolio_net_profit_loss'.tr()}: ${totalPnL >= 0 ? "+" : ""}${numberFormat.format(totalPnL)} $currencySymbol (${roi.toStringAsFixed(1)}%)');
    buffer.writeln('⚖️ ${'portfolio_pure_gold_weight'.tr()}: ${pureGoldGrams.toStringAsFixed(2)} g (24K)');
    buffer.writeln('⚖️ ${'portfolio_gross_weight'.tr()}: ${portfolio.totalGrossWeightGrams.toStringAsFixed(2)} g');
    buffer.writeln('--------------------------------');
    buffer.writeln('🕌 *${'portfolio_report_official_seal'.tr()}*');
    if (hasReachedNisab) {
      buffer.writeln('✅ ${'portfolio_zakat_due'.tr()}: ${zakatGrams.toStringAsFixed(2)} g (≈ ${numberFormat.format(zakatVal)} $currencySymbol)');
    } else {
      buffer.writeln('⏳ ${'portfolio_zakat_remaining'.tr()}: ${(nisabGrams - pureGoldGrams).toStringAsFixed(1)} g');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('📦 *${'portfolio_statement_total_items'.tr()}: ${portfolio.items.length}*');
    for (int i = 0; i < portfolio.items.length; i++) {
      final item = portfolio.items[i];
      final itemVal = item.calculateCurrentValue(portfolio.getLivePricePerGramForKarat(item.karat, widget.currentPrices));
      buffer.writeln('${i + 1}. ${item.title} (${item.karat}K) - ${item.weightGrams}g → ${numberFormat.format(itemVal)} $currencySymbol');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('✨ ${'portfolio_report_official_seal'.tr()}');

    Share.share(buffer.toString(), subject: 'portfolio_report_title'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final country = widget.country;
    final currencySymbol = CurrencyUtils.getSymbol(country.currencyCode, context: context);
    final portfolio = widget.portfolio;
    final numberFormat = widget.numberFormat;

    final totalValuation = portfolio.calculateCurrentValuation(widget.currentPrices);
    final totalCost = portfolio.totalInvestedCost;
    final totalPnL = portfolio.calculateTotalPnL(widget.currentPrices);
    final roi = portfolio.calculateRoiPercentage(widget.currentPrices);
    final isProfit = totalPnL >= 0;
    final pureGoldGrams = portfolio.totalPureWeightGrams;

    const double nisabGrams = 85.0;
    final hasReachedNisab = pureGoldGrams >= nisabGrams;
    final zakatGrams = pureGoldGrams * 0.025;
    final zakatVal = totalValuation * 0.025;

    final xauUsd = widget.currentPrices.where((p) => p.id == 'xau_usd').firstOrNull;
    final usdGram24 = (xauUsd != null && xauUsd.buyPrice > 0) ? (xauUsd.buyPrice / 31.1035) : 85.0;
    final totalUsd = pureGoldGrams * usdGram24;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceRaised : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'portfolio_report_title'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'portfolio_report_subtitle'.tr(),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Scrollable Document Card Preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RepaintBoundary(
                key: _cardKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1914), // Luxury Deep Emerald/Black background for official look
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Certificate Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const PremiumLogo(size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SHAM GOLD • شام جولد',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  'portfolio_report_title'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Text(
                              country.name,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(color: AppColors.gold.withValues(alpha: 0.25), height: 1),
                      const SizedBox(height: 12),

                      // Date & Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${'portfolio_statement_date'.tr()}: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now())}',
                            style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo'),
                          ),
                          Text(
                            '${'portfolio_statement_total_items'.tr()}: ${portfolio.items.length}',
                            style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Highlight: Total Valuation Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A2B), Color(0xFF0F261C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'portfolio_current_valuation'.tr(),
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  numberFormat.format(totalValuation),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currencySymbol,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isProfit ? const Color(0x3300FF88) : const Color(0x33FF3B30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${isProfit ? "+" : ""}${roi.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (pureGoldGrams > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '≈ \$${numberFormat.format(totalUsd)} USD',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white60, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4 Summary Metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildCertMetric(
                              title: 'portfolio_invested_capital'.tr(),
                              value: '${numberFormat.format(totalCost)} $currencySymbol',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCertMetric(
                              title: 'portfolio_net_profit_loss'.tr(),
                              value: '${isProfit ? "+" : ""}${numberFormat.format(totalPnL)} $currencySymbol',
                              color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCertMetric(
                              title: 'portfolio_pure_gold_weight'.tr(),
                              value: '${pureGoldGrams.toStringAsFixed(2)} ${'auto_str_363'.tr()}',
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCertMetric(
                              title: 'portfolio_gross_weight'.tr(),
                              value: '${portfolio.totalGrossWeightGrams.toStringAsFixed(2)} ${'auto_str_363'.tr()}',
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Zakat Compliance Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasReachedNisab ? AppColors.gold.withValues(alpha: 0.6) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasReachedNisab ? Icons.verified_rounded : Icons.savings_outlined,
                              color: hasReachedNisab ? AppColors.gold : Colors.white60,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasReachedNisab ? 'portfolio_zakat_due'.tr() : 'portfolio_zakat_remaining'.tr(),
                                    style: TextStyle(
                                      color: hasReachedNisab ? AppColors.gold : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasReachedNisab
                                        ? '${zakatGrams.toStringAsFixed(2)} ${'auto_str_363'.tr()} (≈ ${numberFormat.format(zakatVal)} $currencySymbol)'
                                        : '${(nisabGrams - pureGoldGrams).toStringAsFixed(1)} ${'auto_str_363'.tr()} لبلوغ 85 غراماً',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Assets Inventory Breakdown List
                      const Text(
                        'قائمة مقتنيات المحفظة المفصلة',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...portfolio.items.map((item) {
                        final livePrice = portfolio.getLivePricePerGramForKarat(item.karat, widget.currentPrices);
                        final curVal = item.calculateCurrentValue(livePrice);
                        final itemPnL = item.calculatePnL(livePrice);
                        final itemProfit = itemPnL >= 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  ),
                                  Text(
                                    '${item.weightGrams}g • ${item.karat == 'silver' ? 'auto_str_380'.tr() : '${item.karat}K'}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${numberFormat.format(curVal)} $currencySymbol',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
                                  ),
                                  Text(
                                    '${itemProfit ? "+" : ""}${numberFormat.format(itemPnL)} $currencySymbol',
                                    style: TextStyle(
                                      color: itemProfit ? AppColors.liveGreen : Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                      Divider(color: AppColors.gold.withValues(alpha: 0.25), height: 1),
                      const SizedBox(height: 10),

                      // Official Digital Stamp & Watermark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'portfolio_report_official_seal'.tr(),
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareImage,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      'portfolio_report_share_image'.tr(),
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _shareText,
                  icon: const Icon(Icons.copy_all_rounded),
                  tooltip: 'portfolio_report_share_text'.tr(),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertMetric({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.w600), maxLines: 1),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Cairo'), maxLines: 1),
        ],
      ),
    );
  }
}
