import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/utils/currency_utils.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'dart:ui' as ui;

class TickerTapeWidget extends ConsumerWidget {
  const TickerTapeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceService = ref.watch(priceServiceProvider);

    if (!priceService.shouldShow('homeShowTickerTape', defaultValue: true)) {
      return const SizedBox.shrink();
    }
    
    final countryProviderInstance = ref.watch(countryProvider);
    final currentCountry = countryProviderInstance.selectedCountry;
    final marketData = countryProviderInstance.currentMarketData;
    final List<dynamic> localItems = (marketData != null && marketData['items'] is List)
        ? marketData['items']
        : [];
    
    return StreamBuilder<List<PriceItem>>(
      stream: priceService.pricesStream,
      initialData: priceService.currentPrices,
      builder: (context, snapshot) {
        final prices = snapshot.data ?? [];
        final List<String> segments = [];

        // 1. If we have market items for the selected country, use them
        if (localItems.isNotEmpty) {
          for (var rawItem in localItems.take(8)) {
            final PriceItem pItem = rawItem is PriceItem
                ? rawItem
                : (rawItem is Map
                    ? PriceItem.fromJson(Map<String, dynamic>.from(rawItem))
                    : PriceItem.empty());
            final title = pItem.translatedTitle.isNotEmpty
                ? pItem.translatedTitle
                : (rawItem is Map ? (rawItem['title'] ?? rawItem['name'] ?? '').toString().tr() : '');
            final buyPrice = pItem.buyPrice > 0
                ? pItem.buyPrice
                : ((rawItem is Map ? (rawItem['buyPrice'] as num?)?.toDouble() : null) ?? 0.0);
            final curr = pItem.currency.isNotEmpty
                ? pItem.currency
                : ((rawItem is Map ? rawItem['currency'] : null) ?? currentCountry.currencyCode);
            if (title.isNotEmpty && buyPrice > 0) {
              final formattedPrice = CurrencyUtils.formatPrice(buyPrice, curr, context: context);
              segments.add('$title : $formattedPrice');
            }
          }
        } else {
          // Fallback to prices matching the country code prefix or global
          final prefix = '${currentCountry.code.toLowerCase()}_';
          final countryPrices = prices.where((p) => p.id.toLowerCase().startsWith(prefix)).toList();
          final targetPrices = countryPrices.isNotEmpty ? countryPrices : prices;
          for (var item in targetPrices.take(8)) {
            final formattedPrice = CurrencyUtils.formatPrice(item.buyPrice, item.currency, context: context);
            segments.add('${item.translatedTitle} : $formattedPrice');
          }
        }

        // 2. Append global benchmarks (XAU/USD, XAG/USD)
        final xau = prices.where((p) => p.id == 'xau_usd').firstOrNull;
        if (xau != null && xau.buyPrice > 0) {
          segments.add('XAU/USD : \$${xau.buyPrice.toStringAsFixed(2)}');
        }
        final xag = prices.where((p) => p.id == 'xag_usd').firstOrNull;
        if (xag != null && xag.buyPrice > 0) {
          segments.add('XAG/USD : \$${xag.buyPrice.toStringAsFixed(2)}');
        }

        if (segments.isEmpty) return const SizedBox.shrink();
        final tickerText = segments.join('    •    ');
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1121) : AppColors.darkGreen,
            border: Border(
              bottom: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            top: true,
            child: SizedBox(
              height: 34,
              child: Marquee(
                text: tickerText,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 60.0,
                velocity: 40.0,
                startPadding: 10.0,
                textDirection: context.locale.languageCode == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
            ),
          ),
        );
      },
    );
  }
}
