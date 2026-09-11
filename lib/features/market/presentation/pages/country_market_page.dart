import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/models/country_model.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';
import 'package:gold_sham/features/home/presentation/widgets/square_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/compact_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/country_switcher_sheet.dart';
import 'package:gold_sham/features/home/presentation/widgets/social_share_sheet.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/services/favorites_service.dart';
import 'package:gold_sham/features/home/presentation/widgets/zakat_banner_widget.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_price_ticker.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/services/local_market_calculator.dart';
import '../../../../shared/widgets/country_flag_widget.dart';
import '../../../../shared/widgets/banner_placement_widget.dart';

class CountryMarketPage extends ConsumerStatefulWidget {
  final CountryModel? forcedCountry;
  const CountryMarketPage({super.key, this.forcedCountry});

  @override
  ConsumerState<CountryMarketPage> createState() => _CountryMarketPageState();
}

class _CountryMarketPageState extends ConsumerState<CountryMarketPage> {
  bool _isGridView = true;
  List<String> _favoriteIds = [];
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await _favoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteIds = favs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryProviderInstance = ref.watch(countryProvider);
    final priceService = ref.watch(priceServiceProvider);
    final country = widget.forcedCountry ?? countryProviderInstance.selectedCountry;
    final marketData = countryProviderInstance.currentMarketData;

    final bool isMatching = marketData != null &&
        (marketData['countryCode']?.toString().toUpperCase() == country.code.toUpperCase());
    final effectiveMarketData = isMatching
        ? marketData
        : LocalMarketCalculator().calculateMarketData(country);

    final List<dynamic> rawItems = (effectiveMarketData != null && effectiveMarketData['items'] != null)
        ? List<dynamic>.from(effectiveMarketData['items'])
        : [];
        
    // Sort items: pinned favorites first, then by isPopular, then regular
    rawItems.sort((a, b) {
      final aId = a['id'] ?? '';
      final bId = b['id'] ?? '';
      final aIsFav = _favoriteIds.contains(aId);
      final bIsFav = _favoriteIds.contains(bId);
      
      if (aIsFav && !bIsFav) return -1;
      if (!aIsFav && bIsFav) return 1;
      
      final aPopular = a['isPopular'] == true;
      final bPopular = b['isPopular'] == true;
      
      if (aPopular && !bPopular) return -1;
      if (!aPopular && bPopular) return 1;
      
      return 0;
    });

    final standardItems = rawItems.where((item) => item['metalType'] != 'custom_item').toList();
    final customItems = rawItems.where((item) => item['metalType'] == 'custom_item').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.darkGreen,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await countryProviderInstance.fetchMarketData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Sliver AppBar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: isDark ? AppColors.darkScaffold : AppColors.darkGreen,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 60),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryFlagWidget(countryCode: country.code, flagEmoji: country.flag, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'market_of'.tr(args: [country.localizedName]),
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
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: AppColors.gold, size: 20),
                  tooltip: _isGridView ? 'view_as_list'.tr() : 'view_as_grid'.tr(),
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
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
                  const LivePriceTicker(),
                  const SizedBox(height: 12),

                  // ── [1] إعلان أعلى صفحة سوق الدولة ──
                  const BannerPlacementWidget(
                    location: 'country_market_top',
                    fallbackLocations: ['market_top', 'syria_market_top', 'turkish_market_top'],
                    margin: EdgeInsets.only(bottom: 14),
                  ),

                  // Market Info Banner
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    margin: EdgeInsets.zero,
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
                          child: CountryFlagWidget(countryCode: country.code, flagEmoji: country.flag, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'official_local_prices'.tr(args: [country.localizedCurrencySymbol]),
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
                        'karats_and_units'.tr(args: [country.localizedName]),
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
                        children: List.generate(5, (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: ShimmerLoading.rectangular(width: double.infinity, height: 75),
                        )),
                      ),
                    )
                  else ...[
                    // Standard Karats & Units
                    _isGridView 
                    ? GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: standardItems.length,
                        itemBuilder: (context, index) {
                          final item = standardItems[index];
                          final priceItem = PriceItem(
                            id: item['id'] ?? '',
                            title: item['title'] ?? item['name'] ?? '',
                            buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                            sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                            currency: item['currency'] ?? country.localizedCurrencySymbol,
                            metalType: item['metalType'] ?? 'gold',
                            usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
                          );

                          return SquarePriceCard(
                            priceItem: priceItem,
                            localPrice: (item['buyPrice'] as num?)?.toDouble(),
                            localCurrencySymbol: item['currency'] ?? country.localizedCurrencySymbol,
                            usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                            isFeatured: item['isPopular'] == true || item['karat'] == country.defaultKarat,
                          );
                        },
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: standardItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = standardItems[index];
                          final priceItem = PriceItem(
                            id: item['id'] ?? '',
                            title: item['title'] ?? item['name'] ?? '',
                            buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                            sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                            currency: item['currency'] ?? country.localizedCurrencySymbol,
                            metalType: item['metalType'] ?? 'gold',
                            usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
                          );

                          return CompactPriceCard(
                            priceItem: priceItem,
                            localPrice: (item['buyPrice'] as num?)?.toDouble(),
                            localCurrencySymbol: item['currency'] ?? country.localizedCurrencySymbol,
                            usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                            isFeatured: item['isPopular'] == true || item['karat'] == country.defaultKarat,
                          );
                        },
                      ),
                    
                    // ── [2] إعلان منتصف صفحة سوق الدولة ──
                    const BannerPlacementWidget(
                      location: 'country_market_mid',
                      fallbackLocations: ['market_mid', 'syria_market_mid', 'turkish_market_mid'],
                      margin: EdgeInsets.symmetric(vertical: 14),
                    ),

                    // Custom Items Section
                    if (customItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                      ...customItems.map((item) {
                        final priceItem = PriceItem(
                          id: item['id'] ?? '',
                          title: item['title'] ?? item['name'] ?? '',
                          buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                          sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                          currency: item['currency'] ?? country.localizedCurrencySymbol,
                          metalType: item['metalType'] ?? 'gold',
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: SquarePriceCard(
                            priceItem: priceItem,
                            localPrice: (item['buyPrice'] as num?)?.toDouble(),
                            localCurrencySymbol: item['currency'] ?? country.localizedCurrencySymbol,
                            usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                            isFeatured: false,
                          ),
                        );
                      }),
                    ],
                    
                    const SizedBox(height: 16),
                    if (priceService.shouldShow('homeShowZakatBanner', defaultValue: true))
                      const ZakatBannerWidget(),

                    // ── [3] إعلان أسفل صفحة سوق الدولة ──
                    const BannerPlacementWidget(
                      location: 'country_market_bottom',
                      fallbackLocations: ['market_bottom', 'syria_market_bottom', 'turkish_market_bottom'],
                      margin: EdgeInsets.only(top: 14),
                    ),
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
