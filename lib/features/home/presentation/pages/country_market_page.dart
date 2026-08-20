import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/models/country_model.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../widgets/compact_price_card.dart';
import '../widgets/country_switcher_sheet.dart';
import '../widgets/social_share_sheet.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class CountryMarketPage extends StatelessWidget {
  final CountryModel? forcedCountry;
  const CountryMarketPage({super.key, this.forcedCountry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryProvider = Provider.of<CountryProvider>(context);
    final country = forcedCountry ?? countryProvider.selectedCountry;
    final marketData = countryProvider.currentMarketData;

    final List<dynamic> rawItems = (marketData != null && marketData['items'] != null)
        ? marketData['items']
        : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.darkGreen,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await countryProvider.fetchMarketData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Sliver AppBar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.darkGreen,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 60),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'market_of'.tr(args: [country.name.tr()]),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 19,
                        fontFamily: 'Cairo',
                        shadows: [
                          Shadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 20),
                          Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 5),
                        ],
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(gradient: AppColors.emeraldGradient),
                  child: const Center(
                    child: PremiumLogo(size: 110, isBackground: true),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    SocialShareSheet.show(context, forcedCountry: country);
                  },
                  icon: const Icon(Icons.share_rounded, color: AppColors.gold, size: 20),
                  tooltip: 'share_bulletin_image'.tr(),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    CountrySwitcherSheet.show(context);
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.gold, size: 18),
                  label: Text(
                    'change_country'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Market Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                          : [Colors.white, const Color(0xFFF8FAFC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.gold.withValues(alpha: 0.2), AppColors.gold.withValues(alpha: 0.05)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                          ),
                          child: Text(country.flag, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'official_local_prices'.tr(args: [country.currencySymbol]),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.primaryText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'default_karat_info'.tr(args: [country.defaultKarat.toString()]),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'karats_and_units'.tr(args: [country.name.tr()]),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Dynamic Market Items
                  if (rawItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: List.generate(5, (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShimmerLoading.rectangular(width: double.infinity, height: 75),
                        )),
                      ),
                    )
                  else ...[
                    // Standard Karats & Units
                    ...rawItems.where((item) => item['metalType'] != 'custom_item').map((item) {
                      final priceItem = PriceItem(
                        id: item['id'] ?? '',
                        title: item['title'] ?? item['name'] ?? '',
                        buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                        sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                        currency: item['currency'] ?? country.currencySymbol,
                        metalType: item['metalType'] ?? 'gold',
                        usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
                      );

                      return CompactPriceCard(
                        priceItem: priceItem,
                        localPrice: (item['buyPrice'] as num?)?.toDouble(),
                        localCurrencySymbol: item['currency'] ?? country.currencySymbol,
                        usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                        isFeatured: item['isPopular'] == true || item['karat'] == country.defaultKarat,
                      );
                    }),
                    
                    // Custom Items Section
                    if (rawItems.any((item) => item['metalType'] == 'custom_item')) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'auto_str_168'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.primaryText,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...rawItems.where((item) => item['metalType'] == 'custom_item').map((item) {
                        final priceItem = PriceItem(
                          id: item['id'] ?? '',
                          title: item['title'] ?? item['name'] ?? '',
                          buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                          sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                          currency: item['currency'] ?? country.currencySymbol,
                          metalType: item['metalType'] ?? 'gold',
                        );

                        return CompactPriceCard(
                          priceItem: priceItem,
                          localPrice: (item['buyPrice'] as num?)?.toDouble(),
                          localCurrencySymbol: item['currency'] ?? country.currencySymbol,
                          usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                          isFeatured: false,
                        );
                      }),
                    ]
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
