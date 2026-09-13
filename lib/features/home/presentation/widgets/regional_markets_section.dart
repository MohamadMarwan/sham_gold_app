import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/providers/regional_markets_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/models/country_model.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/services/local_market_calculator.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/country_flag_widget.dart';
import '../pages/country_market_page.dart';
import 'summary_markets_sheet.dart';

class RegionalMarketsSection extends ConsumerWidget {
  final Function(int)? onNavigate;

  const RegionalMarketsSection({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceService = ref.watch(priceServiceProvider);

    // 1. Check admin permission
    if (!priceService.shouldShow('homeShowRegionalMarkets', defaultValue: true)) {
      return const SizedBox.shrink();
    }

    // 2. Check user visibility preference
    final regionalState = ref.watch(regionalMarketsProvider);
    if (!regionalState.isSectionVisible) {
      return const SizedBox.shrink();
    }

    final countryState = ref.watch(countryProvider);
    final allCountries = countryState.allCountries;
    final allPrices = priceService.currentPrices;

    // Filter countries according to user selection and count
    final maxCount = regionalState.cardCount;
    final selectedCodes = regionalState.selectedCodes.take(maxCount).toList();

    final List<CountryModel> displayedCountries = [];
    for (final code in selectedCodes) {
      final match = allCountries.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
        orElse: () => CountryModel(
          code: code,
          name: code,
          currencyCode: 'USD',
          currencySymbol: '\$',
          flag: '🌐',
        ),
      );
      displayedCountries.add(match);
    }

    if (displayedCountries.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'regional_markets'.tr(),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.darkGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  SummaryMarketsSheet.show(context);
                },
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                tooltip: 'customize_home_markets'.tr(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Cards Layout
        if (displayedCountries.length == 1)
          _buildMarketCard(context, ref, displayedCountries[0], allPrices, isFullWidth: true)
        else if (displayedCountries.length == 2)
          Row(
            children: [
              Expanded(
                child: _buildMarketCard(context, ref, displayedCountries[0], allPrices),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMarketCard(context, ref, displayedCountries[1], allPrices),
              ),
            ],
          )
        else ...[
          // Grid for 3 or 4 cards
          for (int i = 0; i < displayedCountries.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMarketCard(context, ref, displayedCountries[i], allPrices),
                ),
                const SizedBox(width: 10),
                if (i + 1 < displayedCountries.length)
                  Expanded(
                    child: _buildMarketCard(context, ref, displayedCountries[i + 1], allPrices),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMarketCard(
    BuildContext context,
    WidgetRef ref,
    CountryModel country,
    List<PriceItem> allPrices, {
    bool isFullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = country.code.toUpperCase();

    String price1Label = 'dollar'.tr();
    double price1Value = 0.0;
    String price1Unit = country.currencySymbol;

    String price2Label = 'gold_21k_short'.tr();
    double price2Value = 0.0;
    String price2Unit = country.currencySymbol;

    if (code == 'SY') {
      price1Value = _getSyriaUsdPrice(allPrices);
      price1Unit = CurrencyUtils.getSymbol('SYP', context: context);
      price2Label = 'gold_21k_short'.tr();
      price2Value = _getSyriaGold21Price(allPrices);
      price2Unit = CurrencyUtils.getSymbol('SYP', context: context);
    } else if (code == 'TR') {
      price1Value = _getTurkeyUsdPrice(allPrices);
      price1Unit = '₺';
      price2Label = 'gold_gram'.tr();
      price2Value = _getTurkeyGoldPrice(allPrices);
      price2Unit = '₺';
    } else {
      // Calculate for any other country
      final localData = LocalMarketCalculator().calculateMarketData(country);
      if (localData != null) {
        final rate = (localData['fxRateToUSD'] as num?)?.toDouble() ??
            LocalMarketCalculator().fxRates[country.currencyCode] ??
            1.0;
        price1Value = rate;
        price1Unit = country.localizedCurrencySymbol;

        final items = localData['items'] as List<dynamic>? ?? [];
        dynamic bestGoldItem;
        if (items.isNotEmpty) {
          bestGoldItem = items.firstWhere(
            (it) => it['karat'] == country.defaultKarat,
            orElse: () => items.firstWhere(
              (it) => it['karat'] == '21' || it['karat'] == '24',
              orElse: () => items.first,
            ),
          );
        }

        if (bestGoldItem != null) {
          price2Value = (bestGoldItem['buyPrice'] as num?)?.toDouble() ?? 0.0;
          final karat = bestGoldItem['karat']?.toString() ?? '21';
          price2Label = karat == '24'
              ? 'gold_24k_short'.tr()
              : (karat == '21' ? 'gold_21k_short'.tr() : 'gold_gram'.tr());
        }
        price2Unit = country.localizedCurrencySymbol;
      }
    }

    final marketTitle = code == 'SY'
        ? 'market_syria'.tr()
        : (code == 'TR'
            ? 'market_turkey'.tr()
            : 'market_country'.tr(args: [country.localizedName]));

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(countryProvider).selectCountry(country);
        if (onNavigate != null) {
          onNavigate!(1);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CountryMarketPage(forcedCountry: country),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CountryFlagWidget(
                  countryCode: country.code,
                  flagEmoji: country.flag,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    marketTitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.darkGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price1Label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : AppColors.mutedText,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0').format(price1Value)} $price1Unit',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price2Label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : AppColors.mutedText,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0').format(price2Value)} $price2Unit',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getSyriaUsdPrice(List<PriceItem> allPrices) {
    final syriaItems = allPrices.where((p) => p.id.startsWith('sy_')).toList();
    if (syriaItems.isEmpty) return 132.0;
    final usdItem = syriaItems.firstWhere((p) => p.id == 'sy_usd',
        orElse: () => syriaItems.first);
    final val = usdItem.buyPrice > 0 ? usdItem.buyPrice : 132.0;
    return val > 1000 ? (val / 100) : val;
  }

  double _getSyriaGold21Price(List<PriceItem> allPrices) {
    final syriaItems = allPrices.where((p) => p.id.startsWith('sy_')).toList();
    if (syriaItems.isEmpty) return 11500.0;
    final gold21 = syriaItems.firstWhere(
        (p) => p.id == 'sy_gold_21' || p.id == 'sy_gold_21k',
        orElse: () => syriaItems.first);
    final val = gold21.buyPrice > 0 ? gold21.buyPrice : 11500.0;
    return val > 100000 ? (val / 100) : val;
  }

  double _getTurkeyUsdPrice(List<PriceItem> allPrices) {
    final turkishItems =
        allPrices.where((p) => p.id.startsWith('tr_')).toList();
    if (turkishItems.isEmpty) return 38.5;
    final tryItem = turkishItems.firstWhere((p) => p.id == 'tr_curr_usd',
        orElse: () => turkishItems.first);
    return tryItem.buyPrice > 0 ? tryItem.buyPrice : 38.5;
  }

  double _getTurkeyGoldPrice(List<PriceItem> allPrices) {
    final turkishItems =
        allPrices.where((p) => p.id.startsWith('tr_')).toList();
    if (turkishItems.isEmpty) return 3400.0;
    final goldGramItem = turkishItems.firstWhere(
        (p) =>
            p.id == 'tr_gold_24' ||
            p.id == 'tr_gold_gram_altin' ||
            p.id == 'tr_gold_has_altin',
        orElse: () => turkishItems.first);
    return goldGramItem.buyPrice > 0 ? goldGramItem.buyPrice : 3400.0;
  }
}
