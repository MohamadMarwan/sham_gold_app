import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/widgets/promotion_banner.dart';

import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/welcome_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/ounce_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/karat_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/offline_notice_banner.dart';
import 'package:gold_sham/features/home/presentation/widgets/gold_page_components/top_country_banner.dart';

import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/models/price_item.dart';

import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/shared/widgets/premium_logo.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import 'package:gold_sham/features/home/presentation/pages/price_detail_page.dart';
import 'package:gold_sham/features/home/presentation/pages/favorites_page.dart';
import 'package:gold_sham/features/home/presentation/pages/alerts_management_page.dart';
import 'package:gold_sham/features/home/presentation/pages/portfolio_page.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/last_update_ticker.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_news_ticker.dart';
import 'package:gold_sham/features/home/presentation/widgets/unified_summary_card.dart';
import 'package:gold_sham/shared/widgets/syrian_flag.dart';
import 'package:gold_sham/shared/widgets/turkish_flag.dart';
import 'package:gold_sham/features/home/presentation/widgets/watch_ad_reward_widget.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_converter_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_sham/shared/widgets/ad_banner_widget.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/square_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/country_switcher_sheet.dart';

import 'package:gold_sham/features/home/presentation/widgets/interactive_market_chart.dart';
import 'package:gold_sham/features/home/presentation/widgets/silver_platinum_banner.dart';
import 'package:gold_sham/shared/widgets/staggered_slide_in.dart';

class GoldPage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const GoldPage({super.key, this.onNavigate});

  @override
  ConsumerState<GoldPage> createState() => _GoldPageState();
}

class _GoldPageState extends ConsumerState<GoldPage> {
  bool _isCompactView = false;
  List<String> _preferredOrder = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactView = prefs.getBool('home_compact_view') ?? false;
      _preferredOrder = prefs.getStringList('home_karats_order') ?? [];
    });
  }

  Future<void> _toggleCompactView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactView = !_isCompactView;
      prefs.setBool('home_compact_view', _isCompactView);
    });
  }

  Future<void> _saveOrder(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferredOrder = newOrder;
      prefs.setStringList('home_karats_order', _preferredOrder);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);
    final allPrices = priceService.currentPrices;

    final globalDisplayItems = allPrices
        .where((p) => ['xau_usd', 'xag_usd', 'xau_kg_usd', 'xag_kg_usd']
            .contains(p.id.trim().toLowerCase()))
        .toList();

    // Sorting: Ounce Gold, Ounce Silver, Kilo Gold, Kilo Silver
    globalDisplayItems.sort((a, b) {
      final order = ['xau_usd', 'xag_usd', 'xau_kg_usd', 'xag_kg_usd'];
      return order
          .indexOf(a.id.toLowerCase())
          .compareTo(order.indexOf(b.id.toLowerCase()));
    });

    final globalKarats = allPrices
        .where((p) =>
            p.id.trim().toLowerCase().startsWith('gold_') &&
            p.id.trim().toLowerCase().endsWith('_usd'))
        .toList();
    globalKarats.sort((a, b) {
      final order = [
        'gold_24k_usd',
        'gold_22k_usd',
        'gold_21k_usd',
        'gold_18k_usd',
        'gold_14k_usd',
      ];
      final idxA = order.indexOf(a.id.toLowerCase());
      final idxB = order.indexOf(b.id.toLowerCase());
      final orderA = idxA >= 0 ? idxA : 999;
      final orderB = idxB >= 0 ? idxB : 999;
      return orderA.compareTo(orderB);
    });

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
      backgroundColor: AppColors.background,
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
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(40)),
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
                                SizedBox(width: 8),
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
                                SizedBox(width: 10),
                                Text(
                                  'offline_active'.tr(),
                                  style: TextStyle(
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
                _buildHeaderIcon(Icons.public, () {
                  HapticFeedback.selectionClick();
                  CountrySwitcherSheet.show(context);
                }),
                SizedBox(width: 8),
                _buildHeaderIcon(Icons.account_balance_wallet_outlined, () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioPage()));
                }),
                SizedBox(width: 8),
                _buildHeaderIcon(Icons.notifications_active_outlined, () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlertsManagementPage()));
                }),
                SizedBox(width: 8),
                _buildHeaderIcon(Icons.star_rounded, () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()));
                }, isGold: true),
                SizedBox(width: 16),
              ],
            ),
            if (allPrices.isEmpty && isConnected)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(
                        'loading'.tr(), Icons.hourglass_empty),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(child: OunceCardShimmer()),
                          SizedBox(width: 16),
                          Expanded(child: OunceCardShimmer()),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
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
                    // ⚠️ Offline Status Notice Banner (Shown when network is unavailable)
                    const OfflineNoticeBanner(),

                    // 🌍 Top Country Banner with Auto-detect & Quick Switcher
                    const TopCountryBanner(),
                    SizedBox(height: 16),

                    // 🏷️ Karat Filter Chips
                    _buildKaratFilterChips(context),
                    SizedBox(height: 16),

                    // 💎 Smart Dual-Pricing Cards Section for Selected Country
                    _buildCountrySmartCards(context, allPrices),
                    SizedBox(height: 24),

                    if (priceService.shouldShow('homeShowNewsTicker')) ...[
                      const QuickNewsTicker(),
                      SizedBox(height: 20),
                    ],
                    if (priceService.shouldShow('homeShowGlobalPulse')) ...[
                      WelcomeCard(items: allPrices),
                      SizedBox(height: 20),
                      InteractiveMarketChart(
                        currentPrice: allPrices.where((p) => p.id == 'xau_usd').firstOrNull?.buyPrice ?? 2650.0,
                        currency: 'USD',
                        title: 'technical_analysis'.tr(),
                      ),
                      SizedBox(height: 24),
                    ],
                    if (priceService.shouldShow('homeShowSyriaSummary')) ...[
                      _buildSyriaSummaryCard(allPrices),
                      SizedBox(height: 16),
                    ],
                    if (priceService.shouldShow('homeShowTurkishSummary')) ...[
                      _buildTurkishSummaryCard(allPrices),
                      SizedBox(height: 24),
                    ],
                    if (priceService.shouldShow('homeShowQuickConverter')) ...[
                      const QuickConverterWidget(),
                      SizedBox(height: 24),
                    ],

                    if (globalDisplayItems.isNotEmpty) ...[
                      _buildSectionTitle('global_exchange'.tr(), Icons.language),
                      _buildLocationBanners(context, 'global_gold_mid'),
                      SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: globalDisplayItems.length > 4
                            ? 4
                            : globalDisplayItems.length,
                        itemBuilder: (context, index) => StaggeredSlideIn(
                          index: index,
                          child: OunceCard(item: globalDisplayItems[index]),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (priceService.shouldShow('homeShowWatchAdSection',
                        defaultValue: false)) ...[
                      const WatchAdRewardWidget(),
                      SizedBox(height: 24),
                    ],
                    if (globalKarats.isNotEmpty) ...[
                      const SilverPlatinumBanner(),
                      if (priceService.shouldShow('homeShowGlobalPricesAdBanner'))
                        const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 24),
                          child: AdBannerWidget(
                            size: AdSize.largeBanner,
                          ),
                        ),
                      _buildReorderableSectionTitle(),
                      SizedBox(height: 16),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final newOrder = _sortKarats(globalKarats).map((e) => e.id).toList();
                          final item = newOrder.removeAt(oldIndex);
                          newOrder.insert(newIndex, item);
                          _saveOrder(newOrder);
                        },
                        children: _sortKarats(globalKarats)
                            .map((item) => ReorderableDragStartListener(
                                  key: ValueKey(item.id),
                                  index: _sortKarats(globalKarats).indexOf(item),
                                  child: StaggeredSlideIn(
                                    index: _sortKarats(globalKarats).indexOf(item),
                                    child: _isCompactView
                                        ? _buildCompactListTile(item, context)
                                        : KaratCard(item: item),
                                  ),
                                ))
                            .toList(),
                      ),
                    ] else ...[
                      SizedBox(height: 20),
                      const PremiumCardShimmer(),
                      const PremiumCardShimmer(),
                    ],
                    SizedBox(height: 24),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }



  List<PriceItem> _sortKarats(List<PriceItem> items) {
    if (_preferredOrder.isEmpty) return items;
    final sorted = List<PriceItem>.from(items);
    sorted.sort((a, b) {
      final indexA = _preferredOrder.indexOf(a.id);
      final indexB = _preferredOrder.indexOf(b.id);
      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });
    return sorted;
  }

  Widget _buildReorderableSectionTitle() {
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
                child: const Icon(Icons.grid_view_rounded, color: AppColors.gold, size: 24),
              ),
              SizedBox(width: 14),
              Text(
                'raw_gold_prices_usd'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _toggleCompactView();
                },
                icon: Icon(
                  _isCompactView ? Icons.view_agenda_rounded : Icons.view_headline_rounded,
                  color: AppColors.gold,
                ),
                tooltip: _isCompactView ? 'detailed_view'.tr() : 'compact_view'.tr(),
              ),
            ],
          ),
          SizedBox(height: 12),
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

  Widget _buildCompactListTile(PriceItem item, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PriceDetailPage(priceItem: item)));
        },
        leading: Icon(Icons.drag_indicator_rounded, color: Colors.grey.shade400),
        title: Text(
          item.title,
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.darkGreen,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\$ ', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            LivePriceWidget(
              price: item.buyPrice,
              currency: '',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.darkGreen,
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
              SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGreen,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
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





  Widget _buildLocationBanners(BuildContext context, String location) {
    final priceService = ref.watch(priceServiceProvider);
    final banners = priceService.currentBanners
        .where((b) => b.location == location)
        .toList();

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: banners.map((b) => PromotionBanner(banner: b)).toList(),
    );
  }



  // --- 2. KARAT FILTER CHIPS ---
  Widget _buildKaratFilterChips(BuildContext context) {
    final countryProviderInstance = ref.watch(countryProvider);
    final selectedKarat = countryProviderInstance.selectedKaratFilter;

    final filterOptions = [
      {'key': 'all', 'label': 'all_karats'.tr()},
      {'key': '24', 'label': 'karat_24'.tr()},
      {'key': '22', 'label': 'karat_22'.tr()},
      {'key': '21', 'label': 'karat_21'.tr()},
      {'key': '18', 'label': 'karat_18'.tr()},
      {'key': 'silver', 'label': 'silver'.tr()},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filterOptions.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = filterOptions[index];
          final isSelected = selectedKarat == opt['key'] || (selectedKarat.isEmpty && opt['key'] == 'all');

          return ChoiceChip(
            label: Text(
              opt['label']!,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.mutedText,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.gold,
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            onSelected: (bool selected) {
              if (selected) {
                HapticFeedback.selectionClick();
                countryProviderInstance.setKaratFilter(opt['key']!);
              }
            },
          );
        },
      ),
    );
  }

  // --- 3. DUAL-PRICING SMART CARDS FOR SELECTED COUNTRY ---
  Widget _buildCountrySmartCards(BuildContext context, List<PriceItem> allPrices) {
    final countryProviderInstance = ref.watch(countryProvider);
    final country = countryProviderInstance.selectedCountry;
    final selectedKarat = countryProviderInstance.selectedKaratFilter;
    final marketData = countryProviderInstance.currentMarketData;

    final List<dynamic> marketItems = (marketData != null && marketData['items'] != null)
        ? marketData['items']
        : [];

    if (marketItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter items based on selected karat
    final filteredItems = marketItems.where((item) {
      if (selectedKarat == 'all') return true;
      final k = (item['karat'] ?? '').toString();
      final metal = (item['metalType'] ?? '').toString();
      if (selectedKarat == 'silver') return metal.contains('silver');
      return k == selectedKarat;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('live_gold_prices'.tr(args: [country.name.tr()]), Icons.auto_graph_rounded),
        SizedBox(height: 12),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            final priceItem = PriceItem(
              id: item['id'] ?? '',
              title: item['title'] ?? '',
              buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
              sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
              currency: item['currency'] ?? country.currencySymbol,
              metalType: item['metalType'] ?? 'gold',
              usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
            );

            final isFeatured = item['karat'] == country.defaultKarat || item['isPopular'] == true;

            return SquarePriceCard(
              priceItem: priceItem,
              localPrice: (item['buyPrice'] as num?)?.toDouble(),
              localCurrencySymbol: item['currency'] ?? country.currencySymbol,
              usdPrice: (item['usdPrice'] as num?)?.toDouble(),
              isFeatured: isFeatured,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSyriaSummaryCard(List<PriceItem> allPrices) {
    final syriaItems = allPrices.where((p) => p.id.startsWith('sy_')).toList();
    if (syriaItems.isEmpty) return const SizedBox.shrink();

    final usdItem = syriaItems.firstWhere((p) => p.id == 'sy_usd', orElse: () => syriaItems.first);
    final gold21 = syriaItems.firstWhere((p) => p.id == 'sy_gold_21', orElse: () => syriaItems.first);

    return UnifiedSummaryCard(
      title: 'auto_str_243'.tr(),
      iconOrFlag: const SyrianFlag(width: 24, height: 16, borderRadius: 3),
      themeColor: AppColors.darkGreen,
      metrics: [
        MetricItem(label: 'auto_str_329'.tr(), price: usdItem.buyPrice, unit: 'auto_str_381'.tr()),
        MetricItem(label: 'auto_str_341'.tr(), price: gold21.buyPrice, unit: 'auto_str_381'.tr()),
      ],
      onTap: () {
        if (widget.onNavigate != null) widget.onNavigate!(1);
      },
    );
  }

  Widget _buildTurkishSummaryCard(List<PriceItem> allPrices) {
    final turkishItems = allPrices.where((p) => p.id.startsWith('tr_')).toList();
    if (turkishItems.isEmpty) return const SizedBox.shrink();

    final tryItem = turkishItems.firstWhere((p) => p.id == 'tr_curr_usd', orElse: () => turkishItems.first);
    final goldGramItem = turkishItems.firstWhere(
        (p) => p.id == 'tr_gold_24' || p.id == 'tr_gold_gram_altin' || p.id == 'tr_gold_has_altin',
        orElse: () => turkishItems.first);

    return UnifiedSummaryCard(
      title: 'turkish_market_now'.tr(),
      iconOrFlag: const TurkishFlag(width: 24, height: 16, borderRadius: 3),
      themeColor: AppColors.darkGreen,
      metrics: [
        MetricItem(label: 'auto_str_282'.tr(), price: tryItem.buyPrice, unit: '₺'),
        MetricItem(label: 'auto_str_292'.tr(), price: goldGramItem.buyPrice, unit: '₺'),
      ],
      onTap: () {
        if (widget.onNavigate != null) widget.onNavigate!(3);
      },
    );
  }
}
