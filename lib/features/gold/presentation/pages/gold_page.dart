import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/offline_notice_banner.dart';
import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/top_country_banner.dart';

import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/services/local_market_calculator.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/core/utils/currency_utils.dart';

import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/shared/widgets/premium_logo.dart';
import 'package:gold_sham/features/home/presentation/pages/favorites_page.dart';
import 'package:gold_sham/features/home/presentation/pages/alerts_management_page.dart';
import 'package:gold_sham/features/home/presentation/pages/portfolio_page.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/last_update_ticker.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_news_ticker.dart';
import 'package:gold_sham/shared/widgets/syrian_flag.dart';
import 'package:gold_sham/shared/widgets/turkish_flag.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_converter_widget.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/square_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/compact_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/country_switcher_sheet.dart';

import 'package:gold_sham/features/home/presentation/widgets/silver_platinum_banner.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_price_ticker.dart';
import 'package:gold_sham/shared/widgets/banner_placement_widget.dart';

class GoldPage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const GoldPage({super.key, this.onNavigate});

  @override
  ConsumerState<GoldPage> createState() => _GoldPageState();
}

class _GoldPageState extends ConsumerState<GoldPage> {
  bool _isCompactView = false;
  bool _showSyriaSummary = true;
  bool _showTurkishSummary = true;
  bool _showSilverBanner = true;
  bool _showNewsTicker = true;
  bool _showConverter = false;
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactView = prefs.getBool('home_compact_view') ?? false;
      _showSyriaSummary = prefs.getBool('home_show_syria_summary') ?? true;
      _showTurkishSummary = prefs.getBool('home_show_turkish_summary') ?? true;
      _showSilverBanner = prefs.getBool('home_show_silver_banner') ?? true;
      _showNewsTicker = prefs.getBool('home_show_news_ticker') ?? true;
      _showConverter = prefs.getBool('home_show_converter') ?? false;
    });
  }

  Future<void> _toggleCompactView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactView = !_isCompactView;
      prefs.setBool('home_compact_view', _isCompactView);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);
    final allPrices = priceService.currentPrices;

    final isConnected = priceService.isConnected;
    DateTime? latestUpdate = priceService.lastSyncTime;
    if (allPrices.isNotEmpty) {
      final updates = allPrices.map((e) => e.lastUpdate).whereType<DateTime>();
      if (updates.isNotEmpty) {
        final priceLatest = updates.reduce((a, b) => a.isAfter(b) ? a : b);
        if (latestUpdate == null || priceLatest.isAfter(latestUpdate)) {
          latestUpdate = priceLatest;
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          final status = await priceService.refreshPrices(manual: true);
          if (status != RefreshStatus.success && context.mounted) {
            // Check Admin Settings for Error Banner Behavior
            final settings = priceService.currentSettings?['apiSettings'];
            final mode =
                (settings != null && settings['connectionErrorMode'] != null)
                    ? settings['connectionErrorMode']
                    : 'always';

            if (mode == 'never') {
              return;
            }
            if (mode == 'no_internet' &&
                status != RefreshStatus.connectionError) {
              return;
            }
            if (mode == 'server_error' && status != RefreshStatus.serverError) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('check_internet'.tr(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        color: AppColors.gold,
        backgroundColor: AppColors.darkGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.darkGreen,
              elevation: 0,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text('global_market'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 22,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 4))
                        ])),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                  ),
                  child: const Stack(
                    children: [
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: PremiumLogo(
                            size: 140,
                            isBackground: true,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -30,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LiveIndicator(
                                animate: isConnected,
                                isClosed: priceService.isWeekend() &&
                                    priceService.shouldShowWeekendStatusInUI(),
                              ),
                              if (latestUpdate != null) ...[
                                Container(
                                  height: 12,
                                  width: 1.5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  color: Colors.white24,
                                ),
                                const Icon(Icons.history_toggle_off_rounded,
                                    color: AppColors.gold, size: 14),
                                const SizedBox(width: 8),
                                LastUpdateTicker(
                                  lastUpdate: latestUpdate,
                                  showOnlySeconds: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ] else if (!isConnected) ...[
                                const SizedBox(width: 10),
                                Text(
                                  'offline_active'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (priceService.shouldShow('headerShowCountrySelector', defaultValue: true)) ...[
                  _buildHeaderIcon(Icons.public, () {
                    HapticFeedback.selectionClick();
                    CountrySwitcherSheet.show(context);
                  }),
                  const SizedBox(width: 8),
                ],
                if (priceService.shouldShow('headerShowPortfolio', defaultValue: true)) ...[
                  _buildHeaderIcon(Icons.account_balance_wallet_outlined, () {
                    HapticFeedback.selectionClick();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioPage()));
                  }),
                  const SizedBox(width: 8),
                ],
                if (priceService.shouldShow('headerShowAlerts', defaultValue: true)) ...[
                  _buildHeaderIcon(Icons.notifications_active_outlined, () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AlertsManagementPage()));
                  }),
                  const SizedBox(width: 8),
                ],
                if (priceService.shouldShow('headerShowFavorites', defaultValue: true)) ...[
                  _buildHeaderIcon(Icons.star_rounded, () {
                    HapticFeedback.selectionClick();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FavoritesPage()));
                  }, isGold: true),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 8),
              ],
            ),
            if (allPrices.isEmpty && isConnected)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(
                        'loading'.tr(), Icons.hourglass_empty),
                    const SizedBox(height: 20),
                    const SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(child: OunceCardShimmer()),
                          SizedBox(width: 16),
                          Expanded(child: OunceCardShimmer()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const PremiumCardShimmer(),
                    const PremiumCardShimmer(),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Offline Status Notice Banner (Shown when network is unavailable and enabled by admin)
                    if (priceService.shouldShow('homeShowOfflineBanner', defaultValue: true))
                      const OfflineNoticeBanner(),

                    // ── [1] إعلان أعلى الصفحة الرئيسية ──
                    const BannerPlacementWidget(
                      location: 'home_top',
                      margin: EdgeInsets.only(bottom: 12),
                    ),

                    if (priceService.shouldShow('homeShowPriceTicker', defaultValue: true)) ...[
                      const LivePriceTicker(),
                      const SizedBox(height: 12),
                    ],

                    // Top Country Banner with Auto-detect & Quick Switcher
                    const TopCountryBanner(),
                    const SizedBox(height: 14),

                    // Smart Dual-Pricing Cards Section for Selected Country (Grid or List)
                    _buildCountrySmartCards(context, allPrices),
                    const SizedBox(height: 14),

                    // ── [2] إعلان منتصف الصفحة الرئيسية ──
                    const BannerPlacementWidget(
                      location: 'home_mid',
                      fallbackLocations: ['global_gold_mid'],
                      margin: EdgeInsets.only(bottom: 14),
                    ),

                    if (_showNewsTicker && priceService.shouldShow('homeShowNewsTicker')) ...[
                      const QuickNewsTicker(),
                      const SizedBox(height: 14),
                    ],
                    if (priceService.shouldShow('homeShowRegionalMarkets', defaultValue: true)) ...[
                      _buildCompactRegionalMarketsSection(allPrices, priceService),
                      if ((_showSyriaSummary && priceService.shouldShow('homeShowSyriaSummary')) ||
                          (_showTurkishSummary && priceService.shouldShow('homeShowTurkishSummary')))
                        const SizedBox(height: 14),
                    ],
                    if (_showSilverBanner && priceService.shouldShow('homeShowSilverBanner', defaultValue: true)) ...[
                      const SilverPlatinumBanner(),
                      const SizedBox(height: 14),
                    ],
                    if (_showConverter && priceService.shouldShow('homeShowQuickConverter')) ...[
                      const QuickConverterWidget(),
                      const SizedBox(height: 14),
                    ],

                    // ── [3] إعلان أسفل الصفحة الرئيسية ──
                    const BannerPlacementWidget(
                      location: 'home_bottom',
                      margin: EdgeInsets.only(bottom: 14),
                    ),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
          ],
        ),
      ),
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkGreen,
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

  Widget _buildHeaderIcon(IconData icon, VoidCallback? onTap,
      {bool isGold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child:
            Icon(icon, color: isGold ? AppColors.gold : Colors.white, size: 24),
      ),
    );
  }










  // --- 3. DUAL-PRICING SMART CARDS FOR SELECTED COUNTRY ---
  Widget _buildCountrySmartCards(BuildContext context, List<PriceItem> allPrices) {
    final countryProviderInstance = ref.watch(countryProvider);
    final country = countryProviderInstance.selectedCountry;
    final selectedKarat = countryProviderInstance.selectedKaratFilter;
    final marketData = countryProviderInstance.currentMarketData;

    // Validation: ensure market data matches selected country; if not, immediately use LocalMarketCalculator
    final bool isMatchingCountry = marketData != null &&
        (marketData['countryCode']?.toString().toUpperCase() == country.code.toUpperCase());

    final List<dynamic> marketItems;
    if (isMatchingCountry && marketData['items'] != null && (marketData['items'] as List).isNotEmpty) {
      marketItems = marketData['items'];
    } else {
      final localData = LocalMarketCalculator().calculateMarketData(country);
      marketItems = (localData != null && localData['items'] != null) ? localData['items'] : [];
    }

    if (marketItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter items based on selected karat and exclude currency items (currencies have their own dedicated page)
    final filteredItems = marketItems.where((item) {
      final metal = (item['metalType'] ?? '').toString();
      if (metal == 'currency') return false;
      if (selectedKarat == 'all') return true;
      final k = (item['karat'] ?? '').toString();
      if (selectedKarat == 'silver') return metal.contains('silver');
      return k == selectedKarat;
    }).toList();

    // Financial standard sorting: Gold Ounce -> Karats (24, 22, 21, 18, 14) -> Coins/Units -> Silver items
    filteredItems.sort((a, b) {
      int getPriority(dynamic item) {
        final id = (item['id'] ?? '').toString().toLowerCase();
        final metal = (item['metalType'] ?? '').toString().toLowerCase();
        final karat = (item['karat'] ?? '').toString();

        if (id.contains('gold_ounce') || metal == 'gold_ounce') return 10;
        if (karat == '24') return 20;
        if (karat == '22') return 30;
        if (karat == '21') return 40;
        if (karat == '18') return 50;
        if (karat == '14') return 60;
        if (metal.contains('gold') || metal.contains('unit') || metal.contains('coin')) return 70;
        if (id.contains('silver_gram')) return 100;
        if (id.contains('silver_ounce')) return 110;
        if (id.contains('silver_kilo')) return 120;
        if (metal.contains('silver')) return 130;
        return 999;
      }

      return getPriority(a).compareTo(getPriority(b));
    });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey('country_cards_${country.code}_${selectedKarat}_$_isCompactView'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSectionTitle('gold'.tr(), Icons.auto_graph_rounded),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _showCustomizationSheet(context);
                    },
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    tooltip: 'customize_home'.tr(),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _toggleCompactView();
                    },
                    icon: Icon(
                      _isCompactView ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    tooltip: _isCompactView ? 'detailed_view'.tr() : 'compact_view'.tr(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isCompactView)
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final priceItem = PriceItem(
                id: item['id'] ?? '',
                title: item['title'] ?? '',
                buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                currency: item['currency'] ?? country.currencyCode,
                metalType: item['metalType'] ?? 'gold',
                usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
              );

              final isFeatured = item['karat'] == country.defaultKarat || item['isPopular'] == true;

              return CompactPriceCard(
                priceItem: priceItem,
                localPrice: (item['buyPrice'] as num?)?.toDouble(),
                localCurrencySymbol: item['currency'] ?? country.currencyCode,
                usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                isFeatured: isFeatured,
              );
            },
          )
        else
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final priceItem = PriceItem(
                id: item['id'] ?? '',
                title: item['title'] ?? '',
                buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
                sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
                currency: item['currency'] ?? country.currencyCode,
                metalType: item['metalType'] ?? 'gold',
                usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
              );

              final isFeatured = item['karat'] == country.defaultKarat || item['isPopular'] == true;

              return SquarePriceCard(
                priceItem: priceItem,
                localPrice: (item['buyPrice'] as num?)?.toDouble(),
                localCurrencySymbol: item['currency'] ?? country.currencyCode,
                usdPrice: (item['usdPrice'] as num?)?.toDouble(),
                isFeatured: isFeatured,
              );
            },
          ),
      ],
        ),
      ),
    );
  }

  Widget _buildCompactRegionalMarketsSection(List<PriceItem> allPrices, PriceService priceService) {
    final showSyria = _showSyriaSummary && priceService.shouldShow('homeShowSyriaSummary');
    final showTurkey = _showTurkishSummary && priceService.shouldShow('homeShowTurkishSummary');

    if (!showSyria && !showTurkey) return const SizedBox.shrink();

    final syriaWidget = showSyria ? _buildCompactMarketCard(
      title: 'market_syria'.tr(),
      flag: const SyrianFlag(width: 22, height: 14, borderRadius: 3),
      countryCode: 'SY',
      price1Label: 'dollar'.tr(),
      price1Value: _getSyriaUsdPrice(allPrices),
      price1Unit: CurrencyUtils.getSymbol('SYP', context: context),
      price2Label: 'gold_21k_short'.tr(),
      price2Value: _getSyriaGold21Price(allPrices),
      price2Unit: CurrencyUtils.getSymbol('SYP', context: context),
      onTap: () {
        final country = ref.read(countryProvider).allCountries.firstWhere(
          (c) => c.code.toUpperCase() == 'SY',
          orElse: () => ref.read(countryProvider).selectedCountry,
        );
        ref.read(countryProvider).selectCountry(country);
        widget.onNavigate?.call(1);
      },
    ) : null;

    final turkeyWidget = showTurkey ? _buildCompactMarketCard(
      title: 'market_turkey'.tr(),
      flag: const TurkishFlag(width: 22, height: 14, borderRadius: 3),
      countryCode: 'TR',
      price1Label: 'dollar'.tr(),
      price1Value: _getTurkeyUsdPrice(allPrices),
      price1Unit: '₺',
      price2Label: 'gold_gram'.tr(),
      price2Value: _getTurkeyGoldPrice(allPrices),
      price2Unit: '₺',
      onTap: () {
        final country = ref.read(countryProvider).allCountries.firstWhere(
          (c) => c.code.toUpperCase() == 'TR',
          orElse: () => ref.read(countryProvider).selectedCountry,
        );
        ref.read(countryProvider).selectCountry(country);
        widget.onNavigate?.call(1);
      },
    ) : null;

    if (showSyria && showTurkey) {
      return Row(
        children: [
          Expanded(child: syriaWidget!),
          const SizedBox(width: 10),
          Expanded(child: turkeyWidget!),
        ],
      );
    }

    return showSyria ? syriaWidget! : turkeyWidget!;
  }

  Widget _buildCompactMarketCard({
    required String title,
    required Widget flag,
    required String countryCode,
    required String price1Label,
    required double price1Value,
    required String price1Unit,
    required String price2Label,
    required double price2Value,
    required String price2Unit,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
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
                flag,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
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
    final usdItem = syriaItems.firstWhere((p) => p.id == 'sy_usd', orElse: () => syriaItems.first);
    final val = usdItem.buyPrice > 0 ? usdItem.buyPrice : 132.0;
    return val > 1000 ? (val / 100) : val;
  }

  double _getSyriaGold21Price(List<PriceItem> allPrices) {
    final syriaItems = allPrices.where((p) => p.id.startsWith('sy_')).toList();
    if (syriaItems.isEmpty) return 11500.0;
    final gold21 = syriaItems.firstWhere((p) => p.id == 'sy_gold_21' || p.id == 'sy_gold_21k', orElse: () => syriaItems.first);
    final val = gold21.buyPrice > 0 ? gold21.buyPrice : 11500.0;
    return val > 100000 ? (val / 100) : val;
  }

  double _getTurkeyUsdPrice(List<PriceItem> allPrices) {
    final turkishItems = allPrices.where((p) => p.id.startsWith('tr_')).toList();
    if (turkishItems.isEmpty) return 38.5;
    final tryItem = turkishItems.firstWhere((p) => p.id == 'tr_curr_usd', orElse: () => turkishItems.first);
    return tryItem.buyPrice > 0 ? tryItem.buyPrice : 38.5;
  }

  double _getTurkeyGoldPrice(List<PriceItem> allPrices) {
    final turkishItems = allPrices.where((p) => p.id.startsWith('tr_')).toList();
    if (turkishItems.isEmpty) return 3400.0;
    final goldGramItem = turkishItems.firstWhere(
        (p) => p.id == 'tr_gold_24' || p.id == 'tr_gold_gram_altin' || p.id == 'tr_gold_has_altin',
        orElse: () => turkishItems.first);
    return goldGramItem.buyPrice > 0 ? goldGramItem.buyPrice : 3400.0;
  }

  void _showCustomizationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.dashboard_customize_rounded, color: AppColors.gold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'customize_home_title'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Toggle View Mode
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'price_display_style'.tr(),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      _isCompactView ? 'compact_cards_list'.tr() : 'modern_squares_grid'.tr(),
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.mutedText),
                    ),
                    trailing: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, icon: Icon(Icons.grid_view_rounded, size: 18)),
                        ButtonSegment(value: true, icon: Icon(Icons.view_agenda_rounded, size: 18)),
                      ],
                      selected: {_isCompactView},
                      onSelectionChanged: (set) {
                        final val = set.first;
                        setState(() => _isCompactView = val);
                        setModalState(() {});
                        SharedPreferences.getInstance().then((p) => p.setBool('home_compact_view', val));
                      },
                    ),
                  ),
                  const Divider(),
                  // Banner Toggles
                  _buildCustomizationSwitch('banner_syria_summary'.tr(), _showSyriaSummary, (val) {
                    setState(() => _showSyriaSummary = val);
                    setModalState(() {});
                    SharedPreferences.getInstance().then((p) => p.setBool('home_show_syria_summary', val));
                  }),
                  _buildCustomizationSwitch('banner_turkey_summary'.tr(), _showTurkishSummary, (val) {
                    setState(() => _showTurkishSummary = val);
                    setModalState(() {});
                    SharedPreferences.getInstance().then((p) => p.setBool('home_show_turkish_summary', val));
                  }),
                  _buildCustomizationSwitch('banner_silver_platinum'.tr(), _showSilverBanner, (val) {
                    setState(() => _showSilverBanner = val);
                    setModalState(() {});
                    SharedPreferences.getInstance().then((p) => p.setBool('home_show_silver_banner', val));
                  }),
                  _buildCustomizationSwitch('banner_news_ticker'.tr(), _showNewsTicker, (val) {
                    setState(() => _showNewsTicker = val);
                    setModalState(() {});
                    SharedPreferences.getInstance().then((p) => p.setBool('home_show_news_ticker', val));
                  }),
                  _buildCustomizationSwitch('banner_quick_converter'.tr(), _showConverter, (val) {
                    setState(() => _showConverter = val);
                    setModalState(() {});
                    SharedPreferences.getInstance().then((p) => p.setBool('home_show_converter', val));
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomizationSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.gold,
      onChanged: (val) {
        HapticFeedback.selectionClick();
        onChanged(val);
      },
    );
  }
}

