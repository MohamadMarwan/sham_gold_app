import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/square_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/compact_price_card.dart';
import 'package:gold_sham/shared/widgets/banner_placement_widget.dart';
import '../../../../core/providers/settings_provider.dart';

class BullionsCoinsPage extends ConsumerStatefulWidget {
  const BullionsCoinsPage({super.key});

  @override
  ConsumerState<BullionsCoinsPage> createState() => _BullionsCoinsPageState();
}

class _BullionsCoinsPageState extends ConsumerState<BullionsCoinsPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final priceService = ref.watch(priceServiceProvider);
    final country = ref.watch(countryProvider);
    final allPrices = priceService.currentPrices;
    
    final bullions = _getBullionsForCountry(country, allPrices);
    final coins = _getCoinsForCountry(country, allPrices);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkGreen,
            elevation: 0,
            stretch: true,
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final isGrid = ref.read(settingsProvider).isGridLayout;
                  ref.read(settingsProvider.notifier).setIsGridLayout(!isGrid);
                },
                icon: Icon(
                  !ref.watch(settingsProvider).isGridLayout ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                  color: AppColors.gold,
                ),
                tooltip: !ref.watch(settingsProvider).isGridLayout ? 'detailed_view'.tr() : 'compact_view'.tr(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                'bullions_and_coins'.tr(),
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 4))
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkGreen, Color(0xFF0F2E25)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    width: 1,
                  )
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 15),
                  unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.line_weight_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('bullions'.tr()),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('gold_coins'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              isDark,
              70.0,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildListView(bullions, country, isDark),
            _buildListView(coins, country, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<PriceItem> items, CountryProvider country, bool isDark) {
    if (items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 170),
        itemCount: 6,
        itemBuilder: (_, __) => const PremiumCardShimmer(),
      );
    }

    final isCompactView = !ref.watch(settingsProvider).isGridLayout;
    int midIndex = items.length > 3 ? (items.length / 2).ceil() : items.length;
    if (!isCompactView && midIndex % 2 != 0 && midIndex < items.length) {
      midIndex++;
    }
    final firstItems = items.sublist(0, midIndex);
    final secondItems = midIndex < items.length ? items.sublist(midIndex) : <PriceItem>[];

    final fontScale = ref.watch(settingsProvider).fontSizeScale;
    final gridAspectRatio = fontScale >= 1.3 ? 0.98 : (fontScale >= 1.15 ? 1.05 : 1.15);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── [1] إعلان أعلى صفحة السبائك والليرات ──
        const SliverBannerPlacementWidget(
          location: 'bullions_top',
          margin: EdgeInsets.fromLTRB(16, 10, 16, 6),
        ),

        // First items
        if (isCompactView)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = firstItems[index];
                  return Padding(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CompactPriceCard(
                      priceItem: item,
                      localPrice: item.buyPrice,
                      localCurrencySymbol: item.currency,
                      usdPrice: item.usdPrice,
                    ),
                  );
                },
                childCount: firstItems.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: gridAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = firstItems[index];
                  return SquarePriceCard(
                    key: ValueKey(item.id),
                    priceItem: item,
                    localPrice: item.buyPrice,
                    localCurrencySymbol: item.currency,
                    usdPrice: item.usdPrice,
                  );
                },
                childCount: firstItems.length,
              ),
            ),
          ),

        // ── [2] إعلان منتصف صفحة السبائك والليرات ──
        const SliverBannerPlacementWidget(
          location: 'bullions_mid',
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),

        // Second items (if any)
        if (secondItems.isNotEmpty)
          if (isCompactView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = secondItems[index];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CompactPriceCard(
                        priceItem: item,
                        localPrice: item.buyPrice,
                        localCurrencySymbol: item.currency,
                        usdPrice: item.usdPrice,
                      ),
                    );
                  },
                  childCount: secondItems.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: gridAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = secondItems[index];
                    return SquarePriceCard(
                      key: ValueKey(item.id),
                      priceItem: item,
                      localPrice: item.buyPrice,
                      localCurrencySymbol: item.currency,
                      usdPrice: item.usdPrice,
                    );
                  },
                  childCount: secondItems.length,
                ),
              ),
            ),

        // ── [3] إعلان أسفل صفحة السبائك والليرات ──
        const SliverBannerPlacementWidget(
          location: 'bullions_bottom',
          margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
        ),

        // ── مساحة أمان سفلية دائمة تضمن ظهور آخر بطاقة بالكامل فوق شريط التنقل السفلي ──
        const SliverToBoxAdapter(
          child: SizedBox(height: 170),
        ),
      ],
    );
  }

  List<PriceItem> _getBullionsForCountry(CountryProvider countryProvider, List<PriceItem> allPrices) {
    final country = countryProvider.selectedCountry;
    // If Syria, use the specialized sy_ items from allPrices and sort them by price ascending
    if (country.code.toUpperCase() == 'SY') {
      final list = allPrices.where((p) => p.metalType == 'bullion' && p.id.startsWith('sy_')).toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
        return list;
      }
    }

    // Otherwise, derive bullions from the country's 24K price
    final marketData = countryProvider.currentMarketData;
    final List<dynamic> marketItems = (marketData != null && marketData['items'] is List)
        ? marketData['items']
        : [];

    double k24Price = 0.0;
    double k24UsdPrice = 0.0;
    final currencySymbol = country.localizedCurrencySymbol;

    for (var item in marketItems) {
      final k = (item['karat'] ?? '').toString();
      if (k == '24') {
        k24Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
        k24UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
        break;
      }
    }

    // Fallback if market items not loaded yet
    if (k24Price == 0.0) {
      final xau = allPrices.where((p) => p.id == 'xau_usd').firstOrNull;
      final xauPrice = xau?.buyPrice ?? 2900.0;
      k24UsdPrice = xauPrice / 31.1035;
      final rate = (marketData != null && marketData['fxRateToUSD'] != null)
          ? (marketData['fxRateToUSD'] as num).toDouble()
          : (country.code == 'DZ' ? 134.5 : 1.0);
      k24Price = k24UsdPrice * rate;
    }

    // Order strictly ascending by physical weight (from 1g up to 1000g / 1kg)
    final bullionWeights = [
      {'id': '1g', 'key': 'bullion_1g', 'title': 'bullion_1g'.tr(), 'grams': 1.0},
      {'id': '5g', 'key': 'bullion_5g', 'title': 'bullion_5g'.tr(), 'grams': 5.0},
      {'id': 'half_tola', 'key': 'half_tola', 'title': 'half_tola'.tr(), 'grams': 5.83},
      {'id': '10g', 'key': 'bullion_10g', 'title': 'bullion_10g'.tr(), 'grams': 10.0},
      {'id': '1_tola', 'key': 'one_tola', 'title': 'one_tola'.tr(), 'grams': 11.66},
      {'id': '20g', 'key': 'bullion_20g', 'title': 'bullion_20g'.tr(), 'grams': 20.0},
      {'id': '1oz', 'key': 'bullion_1oz', 'title': 'bullion_1oz'.tr(), 'grams': 31.1035},
      {'id': '50g', 'key': 'bullion_50g', 'title': 'bullion_50g'.tr(), 'grams': 50.0},
      {'id': '5_tola', 'key': 'five_tola', 'title': 'five_tola'.tr(), 'grams': 58.3},
      {'id': '100g', 'key': 'bullion_100g', 'title': 'bullion_100g'.tr(), 'grams': 100.0},
      {'id': '1kg', 'key': 'bullion_1kg', 'title': 'bullion_1kg'.tr(), 'grams': 1000.0},
    ];

    final result = bullionWeights.map((b) {
      final grams = b['grams'] as double;
      final buy = double.parse((k24Price * grams).toStringAsFixed(2));
      final sell = double.parse((buy * 1.008).toStringAsFixed(2));
      final usd = double.parse((k24UsdPrice * grams).toStringAsFixed(2));
      return PriceItem(
        id: '${country.code.toLowerCase()}_bullion_${b['id']}',
        title: (b['key'] as String?)?.tr() ?? b['title'] as String,
        buyPrice: buy,
        sellPrice: sell,
        currency: currencySymbol,
        metalType: 'bullion',
        usdPrice: usd,
      );
    }).toList();

    result.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
    return result;
  }

  List<PriceItem> _getCoinsForCountry(CountryProvider countryProvider, List<PriceItem> allPrices) {
    final country = countryProvider.selectedCountry;
    // If Syria, use sy_ items and sort by price ascending
    if (country.code.toUpperCase() == 'SY') {
      final list = allPrices.where((p) => p.metalType == 'coin' && p.id.startsWith('sy_')).toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
        return list;
      }
    }

    final marketData = countryProvider.currentMarketData;
    final List<dynamic> marketItems = (marketData != null && marketData['items'] is List)
        ? marketData['items']
        : [];

    // Check if there are country-specific custom coin items in marketData (e.g. eg_gold_pound)
    final customCoins = marketItems
        .where((item) => (item['metalType'] == 'gold_coin' || item['metalType'] == 'coin'))
        .map((item) {
      return PriceItem(
        id: item['id'] ?? '',
        title: item['title'] ?? item['name'] ?? '',
        buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
        sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
        currency: item['currency'] ?? country.localizedCurrencySymbol,
        metalType: 'coin',
        usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    double k21Price = 0.0;
    double k21UsdPrice = 0.0;
    double k22Price = 0.0;
    double k22UsdPrice = 0.0;
    double k24Price = 0.0;
    double k24UsdPrice = 0.0;

    for (var item in marketItems) {
      final k = (item['karat'] ?? '').toString();
      if (k == '21') {
        k21Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
        k21UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
      }
      if (k == '22') {
        k22Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
        k22UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
      }
      if (k == '24') {
        k24Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
        k24UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final xau = allPrices.where((p) => p.id == 'xau_usd').firstOrNull;
    final xauPrice = xau?.buyPrice ?? 2900.0;
    final rate = (marketData != null && marketData['fxRateToUSD'] != null)
        ? (marketData['fxRateToUSD'] as num).toDouble()
        : (country.code == 'DZ' ? 134.5 : 1.0);

    if (k24Price == 0.0) {
      k24UsdPrice = (xauPrice / 31.1035);
      k24Price = k24UsdPrice * rate;
    }
    if (k21Price == 0.0) {
      k21UsdPrice = (xauPrice / 31.1035) * (21 / 24);
      k21Price = k21UsdPrice * rate;
    }
    if (k22Price == 0.0) {
      k22UsdPrice = (xauPrice / 31.1035) * (22 / 24);
      k22Price = k22UsdPrice * rate;
    }

    final currencySymbol = country.localizedCurrencySymbol;
    // User requested explicit list of coins
    final rawStandardCoins = [
      {'id': 'tr_gold_ceyrek_new', 'title': 'ربع ليرة تركية', 'grams': 1.75, 'price': k22Price, 'usd': k22UsdPrice},
      {'id': 'tr_gold_yarim_new', 'title': 'نصف ليرة تركية', 'grams': 3.5, 'price': k22Price, 'usd': k22UsdPrice},
      {'id': 'tr_gold_tam_new', 'title': 'ليرة تركية كاملة', 'grams': 7.0, 'price': k22Price, 'usd': k22UsdPrice},
      {'id': 'tr_gold_ata_new', 'title': 'ليرة زينة (عطا)', 'grams': 7.2, 'price': k22Price, 'usd': k22UsdPrice},
      {'id': 'en_21', 'title': 'ليرة إنجليزية', 'grams': 8.0, 'price': k21Price, 'usd': k21UsdPrice},
      {'id': 'en_22', 'title': 'ليرة إنجليزية', 'grams': 8.0, 'price': k22Price, 'usd': k22UsdPrice},
      {'id': 'pound_21', 'title': 'جنيه ذهب', 'grams': 8.0, 'price': k21Price, 'usd': k21UsdPrice},
      {'id': 'pound_22', 'title': 'جنيه ذهب', 'grams': 8.0, 'price': k22Price, 'usd': k22UsdPrice},
      {'id': 'lira_24', 'title': 'ليرة ذهبية', 'grams': 8.0, 'price': k24Price, 'usd': k24UsdPrice},
    ];

    final priceService = ref.read(priceServiceProvider);

    final standardCoins = rawStandardCoins.where((c) {
      final id = c['id'] as String;
      if (id.startsWith('tr_')) {
        return priceService.isTurkishItemVisible(id);
      }
      return true;
    }).map((c) {
      final id = c['id'] as String;
      final grams = c['grams'] as double;
      final p = c['price'] as double;
      final u = c['usd'] as double;
      final buy = double.parse((p * grams).toStringAsFixed(2));
      final sell = double.parse((buy * 1.01).toStringAsFixed(2));
      final usd = double.parse((u * grams).toStringAsFixed(2));
      return PriceItem(
        id: id.startsWith('tr_') ? id : '${country.code.toLowerCase()}_$id',
        title: c['title'] as String,
        buyPrice: buy,
        sellPrice: sell,
        currency: currencySymbol,
        metalType: 'coin',
        usdPrice: usd,
      );
    }).toList();

    final allCoins = [...customCoins, ...standardCoins];
    allCoins.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
    return allCoins;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isDark;
  final double height;

  _SliverAppBarDelegate(this.child, this.isDark, this.height);

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkScaffold : AppColors.background,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.height != height;
  }
}
