import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/premium_empty_state.dart';
import '../../../../core/providers/portfolio_provider.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/portfolio_model.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../home/presentation/widgets/zakat_bottom_sheet.dart';

class PortfolioPage extends ConsumerStatefulWidget {
  const PortfolioPage({super.key});

  @override
  ConsumerState<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends ConsumerState<PortfolioPage> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  String _selectedFilter = 'all'; // 'all', 'bullion', 'coin', 'jewelry', 'silver'
  String _selectedSort = 'newest'; // 'newest', 'value', 'profit'

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portfolioProviderInstance = ref.watch(portfolioProvider);
    final countryProviderInstance = ref.watch(countryProvider);
    final priceService = ref.watch(priceServiceProvider);

    final country = countryProviderInstance.selectedCountry;
    final currentPrices = priceService.currentPrices;
    final numberFormat = NumberFormat('#,##0.##', context.locale.languageCode);

    final double totalValuation = portfolioProviderInstance.calculateCurrentValuation(currentPrices);
    final double totalCost = portfolioProviderInstance.totalInvestedCost;
    final double totalPnL = portfolioProviderInstance.calculateTotalPnL(currentPrices);
    final double roiPercent = portfolioProviderInstance.calculateRoiPercentage(currentPrices);
    final bool isProfit = totalPnL >= 0;

    // Filter items
    var filteredItems = portfolioProviderInstance.items.where((item) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'bullion') return item.category == 'bullion';
      if (_selectedFilter == 'coin') return item.category == 'coin';
      if (_selectedFilter == 'jewelry') return item.category == 'jewelry' || item.category == 'scrap';
      if (_selectedFilter == 'silver') return item.karat == 'silver' || item.category == 'silver';
      return true;
    }).toList();

    // Sort items
    filteredItems.sort((a, b) {
      final priceA = portfolioProviderInstance.getLivePricePerGramForKarat(a.karat, currentPrices);
      final priceB = portfolioProviderInstance.getLivePricePerGramForKarat(b.karat, currentPrices);
      final valA = a.calculateCurrentValue(priceA);
      final valB = b.calculateCurrentValue(priceB);
      final pnlA = a.calculatePnL(priceA);
      final pnlB = b.calculatePnL(priceB);

      if (_selectedSort == 'value') return valB.compareTo(valA);
      if (_selectedSort == 'profit') return pnlB.compareTo(pnlA);
      return b.buyDate.compareTo(a.buyDate); // newest
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header AppBar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkScaffold : AppColors.darkGreen,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              tooltip: 'back'.tr(),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _showAssetSheet(context, country, ref, currentPrices: currentPrices);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.gold, size: 20),
                ),
                tooltip: 'auto_str_081'.tr(),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 50),
              title: Text(
                'auto_str_213'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 19,
                  fontFamily: 'Cairo',
                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                ),
              ),
              background: Transform.translate(
                offset: Offset(0, _scrollOffset * 0.5),
                child: Container(
                  decoration: BoxDecoration(gradient: AppColors.emeraldGradient),
                  child: const Center(
                    child: PremiumLogo(size: 110, isBackground: true),
                  ),
                ),
              ),
            ),
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

          // ── Main Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Wealth Overview Card
                _buildWealthOverviewCard(
                  context: context,
                  isDark: isDark,
                  totalValuation: totalValuation,
                  totalCost: totalCost,
                  totalPnL: totalPnL,
                  roiPercent: roiPercent,
                  isProfit: isProfit,
                  portfolio: portfolioProviderInstance,
                  country: country,
                  currentPrices: currentPrices,
                  numberFormat: numberFormat,
                ),

                const SizedBox(height: 14),

                // 2. Zakat Nisab Indicator
                if (portfolioProviderInstance.totalPureWeightGrams > 0)
                  _buildZakatIndicatorCard(
                    context: context,
                    isDark: isDark,
                    totalPureGoldGrams: portfolioProviderInstance.totalPureWeightGrams,
                    totalValuation: totalValuation,
                    country: country,
                    numberFormat: numberFormat,
                  ),

                // 3. Karat Weight Distribution Bar
                if (portfolioProviderInstance.items.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDistributionBar(
                    portfolio: portfolioProviderInstance,
                  ),
                ],

                const SizedBox(height: 20),

                // 4. Primary CTA: Add Asset
                SizedBox(
                  width: double.infinity,
                  child: PremiumButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showAssetSheet(context, country, ref, currentPrices: currentPrices);
                    },
                    text: 'auto_str_081'.tr(),
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Filter & Sort Bar
                if (portfolioProviderInstance.items.isNotEmpty) ...[
                  _buildFilterBar(isDark: isDark, portfolio: portfolioProviderInstance),
                  const SizedBox(height: 14),
                ],

                // 6. Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'registered_assets_count'.tr(args: [filteredItems.length.toString()]),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (portfolioProviderInstance.items.length > 1)
                      _buildSortMenu(isDark: isDark),
                  ],
                ),

                const SizedBox(height: 12),

                // 7. Assets List or Empty State
                if (portfolioProviderInstance.isEmpty)
                  PremiumEmptyState(
                    title: 'auto_str_101'.tr(),
                    subtitle: 'auto_str_017'.tr(),
                    icon: Icons.account_balance_wallet_outlined,
                  )
                else if (filteredItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'no_results_for_filter'.tr(),
                        style: const TextStyle(color: AppColors.mutedText, fontFamily: 'Cairo'),
                      ),
                    ),
                  )
                else
                  ...filteredItems.map((item) {
                    final liveGramPrice = portfolioProviderInstance.getLivePricePerGramForKarat(
                      item.karat,
                      currentPrices,
                    );
                    return _buildAssetCard(
                      context: context,
                      ref: ref,
                      item: item,
                      liveGramPrice: liveGramPrice,
                      country: country,
                      isDark: isDark,
                      numberFormat: numberFormat,
                      currentPrices: currentPrices,
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  1. Wealth Overview Card
  // ──────────────────────────────────────────────
  Widget _buildWealthOverviewCard({
    required BuildContext context,
    required bool isDark,
    required double totalValuation,
    required double totalCost,
    required double totalPnL,
    required double roiPercent,
    required bool isProfit,
    required PortfolioProvider portfolio,
    required dynamic country,
    required List<PriceItem> currentPrices,
    required NumberFormat numberFormat,
  }) {
    final currencySymbol = CurrencyUtils.getSymbol(country.currencyCode, context: context);

    // Live USD Valuation
    final xauUsd = currentPrices.where((p) => p.id == 'xau_usd').firstOrNull;
    final usdGram24 = (xauUsd != null && xauUsd.buyPrice > 0) ? (xauUsd.buyPrice / 31.1035) : 85.0;
    final totalUsd = portfolio.totalPureWeightGrams * usdGram24;

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label & Live ROI Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'portfolio_current_valuation'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfit ? const Color(0x3300FF88) : const Color(0x33FF3B30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isProfit ? AppColors.liveGreen.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isProfit ? "+" : ""}${roiPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Main Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                numberFormat.format(totalValuation),
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  letterSpacing: -0.5,
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
            ],
          ),

          // Dual USD Valuation
          if (portfolio.totalPureWeightGrams > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '≈ \$${numberFormat.format(totalUsd)} USD',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  fontFamily: 'Cairo',
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 14),

          // Financial Grid Metrics (Row 1)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'portfolio_invested_capital'.tr(),
                  value: '${numberFormat.format(totalCost)} $currencySymbol',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'portfolio_net_profit_loss'.tr(),
                  value: '${isProfit ? "+" : ""}${numberFormat.format(totalPnL)} $currencySymbol',
                  color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Financial Grid Metrics (Row 2)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'portfolio_pure_gold_weight'.tr(),
                  value: '${portfolio.totalPureWeightGrams.toStringAsFixed(2)} ${'auto_str_363'.tr()}',
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'portfolio_avg_gram_cost'.tr(),
                  value: portfolio.averageCostPerGram > 0
                      ? '${numberFormat.format(portfolio.averageCostPerGram)} $currencySymbol'
                      : '0 $currencySymbol',
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5, fontFamily: 'Cairo'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  2. Zakat Nisab Indicator
  // ──────────────────────────────────────────────
  Widget _buildZakatIndicatorCard({
    required BuildContext context,
    required bool isDark,
    required double totalPureGoldGrams,
    required double totalValuation,
    required dynamic country,
    required NumberFormat numberFormat,
  }) {
    const double nisabGrams = 85.0; // 85 grams of 24K gold
    final bool hasReachedNisab = totalPureGoldGrams >= nisabGrams;
    final double zakatGrams = totalPureGoldGrams * 0.025;
    final double zakatValue = totalValuation * 0.025;
    final currencySymbol = CurrencyUtils.getSymbol(country.currencyCode, context: context);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ZakatBottomSheet.show(context);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasReachedNisab
                ? [const Color(0xFF1E3A2B), const Color(0xFF0D2218)]
                : [
                    isDark ? const Color(0xFF1A2230) : const Color(0xFFF1F5F9),
                    isDark ? const Color(0xFF111827) : const Color(0xFFE2E8F0),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasReachedNisab ? AppColors.gold.withValues(alpha: 0.6) : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (hasReachedNisab ? AppColors.gold : Colors.grey).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasReachedNisab ? Icons.verified_rounded : Icons.savings_outlined,
                color: hasReachedNisab ? AppColors.gold : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        hasReachedNisab ? 'portfolio_zakat_due'.tr() : 'portfolio_zakat_remaining'.tr(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: hasReachedNisab ? AppColors.gold : (isDark ? Colors.white : AppColors.primaryText),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${nisabGrams.toInt()} ${'auto_str_363'.tr()})',
                        style: const TextStyle(fontSize: 10.5, color: Colors.white60, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasReachedNisab
                        ? '${'portfolio_zakat_due_desc'.tr()}: ${zakatGrams.toStringAsFixed(2)} ${'auto_str_363'.tr()} (≈ ${numberFormat.format(zakatValue)} $currencySymbol)'
                        : '${(nisabGrams - totalPureGoldGrams).toStringAsFixed(1)} ${'auto_str_363'.tr()} (${((totalPureGoldGrams / nisabGrams) * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 14),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  3. Karat Distribution Bar
  // ──────────────────────────────────────────────
  Widget _buildDistributionBar({
    required PortfolioProvider portfolio,
  }) {
    final dist = portfolio.karatDistribution;
    final totalWeight = portfolio.totalGrossWeightGrams;
    if (totalWeight <= 0) return const SizedBox.shrink();

    final colors = {
      '24': const Color(0xFFFFD700),
      '22': const Color(0xFFFFC000),
      '21': const Color(0xFFE5A910),
      '18': const Color(0xFFD4930D),
      '14': const Color(0xFFB8780B),
      'silver': const Color(0xFFC0C0C0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: dist.entries.map((entry) {
                final pct = (entry.value / totalWeight);
                final color = colors[entry.key] ?? AppColors.gold;
                return Expanded(
                  flex: (pct * 1000).toInt().clamp(1, 1000),
                  child: Container(color: color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: dist.entries.map((entry) {
            final color = colors[entry.key] ?? AppColors.gold;
            final label = entry.key == 'silver' ? 'auto_str_380'.tr() : '${entry.key}K';
            final pct = ((entry.value / totalWeight) * 100).toStringAsFixed(0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('$label ($pct%)', style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontFamily: 'Cairo')),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  4. Filter & Sort Bar
  // ──────────────────────────────────────────────
  Widget _buildFilterBar({required bool isDark, required PortfolioProvider portfolio}) {
    final filters = [
      {'key': 'all', 'label': 'portfolio_filter_all'.tr(), 'count': portfolio.items.length},
      {'key': 'bullion', 'label': 'portfolio_filter_bullion'.tr(), 'count': portfolio.items.where((e) => e.category == 'bullion').length},
      {'key': 'coin', 'label': 'portfolio_filter_coin'.tr(), 'count': portfolio.items.where((e) => e.category == 'coin').length},
      {'key': 'jewelry', 'label': 'portfolio_filter_jewelry'.tr(), 'count': portfolio.items.where((e) => e.category == 'jewelry' || e.category == 'scrap').length},
      {'key': 'silver', 'label': 'portfolio_filter_silver'.tr(), 'count': portfolio.items.where((e) => e.karat == 'silver' || e.category == 'silver').length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          final count = f['count'] as int;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(
                '${f['label']} ($count)',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? Colors.black : (isDark ? Colors.white70 : AppColors.secondaryText),
                ),
              ),
              selectedColor: AppColors.gold,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: isSelected ? AppColors.gold : Colors.transparent),
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = f['key'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortMenu({required bool isDark}) {
    return PopupMenuButton<String>(
      initialValue: _selectedSort,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        setState(() => _selectedSort = val);
      },
      color: isDark ? AppColors.darkSurfaceRaised : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort_rounded, size: 16, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            _selectedSort == 'value'
                ? 'sort_by_value'.tr()
                : (_selectedSort == 'profit' ? 'sort_by_profit'.tr() : 'sort_by_date'.tr()),
            style: const TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ],
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'newest', child: Text('sort_by_date'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
        PopupMenuItem(value: 'value', child: Text('sort_by_value'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
        PopupMenuItem(value: 'profit', child: Text('sort_by_profit'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  5. Individual Asset Card
  // ──────────────────────────────────────────────
  Widget _buildAssetCard({
    required BuildContext context,
    required WidgetRef ref,
    required PortfolioItemModel item,
    required double liveGramPrice,
    required dynamic country,
    required bool isDark,
    required NumberFormat numberFormat,
    required List<PriceItem> currentPrices,
  }) {
    final currencySymbol = CurrencyUtils.getSymbol(
      item.currencyCode.isNotEmpty ? item.currencyCode : country.currencyCode,
      context: context,
    );

    final double currentValue = item.calculateCurrentValue(liveGramPrice);
    final double pnl = item.calculatePnL(liveGramPrice);
    final double roi = item.calculateRoi(liveGramPrice);
    final bool isProfit = pnl >= 0;

    IconData categoryIcon = Icons.view_in_ar_rounded;
    if (item.category == 'coin') categoryIcon = Icons.monetization_on_rounded;
    if (item.category == 'jewelry') categoryIcon = Icons.auto_awesome_rounded;
    if (item.karat == 'silver') categoryIcon = Icons.diamond_outlined;

    final dateFormatted = DateFormat.yMMMd(context.locale.languageCode).format(item.buyDate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.gold.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon, Title, Category, and Action Menu
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.karat == 'silver'
                        ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                        : [AppColors.gold, const Color(0xFFD4930D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (item.karat == 'silver' ? Colors.grey : AppColors.gold).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(categoryIcon, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item.localizedCategory,
                          style: const TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More Actions: Edit & Delete
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.mutedText, size: 20),
                color: isDark ? AppColors.darkSurfaceRaised : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAssetSheet(context, country, ref, editingItem: item, currentPrices: currentPrices);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref, item.id);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text('portfolio_edit_asset'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text('delete'.tr(), style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 10),

          // Row 2: Live Valuation vs Invested Cost & ROI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('portfolio_asset_current_val'.tr(), style: const TextStyle(color: AppColors.mutedText, fontSize: 10.5, fontFamily: 'Cairo')),
                  Text(
                    '${numberFormat.format(currentValue)} $currencySymbol',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              // Invested Cost
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('portfolio_asset_purchase_val'.tr(), style: const TextStyle(color: AppColors.mutedText, fontSize: 10.5, fontFamily: 'Cairo')),
                  Text(
                    '${numberFormat.format(item.totalInvestedCost)} $currencySymbol',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white70, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              // ROI Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfit ? const Color(0x3300FF88) : const Color(0x33FF3B30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isProfit ? "+" : ""}${roi.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 3: Weight and Price per gram
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.weightGrams} ${'auto_str_363'.tr()} (${item.karat == 'silver' ? 'silver'.tr() : '${item.karat}K'})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold, fontFamily: 'Cairo'),
                ),
                Text(
                  '${'buy_price_short'.tr()}: ${numberFormat.format(item.buyPricePerGram)} $currencySymbol / ${'auto_str_363'.tr()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String itemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900)),
        content: Text('portfolio_delete_confirm'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr(), style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(portfolioProvider).deleteItem(itemId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('portfolio_item_deleted'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
              );
            },
            child: Text('delete'.tr(), style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  6. Add / Edit Asset Modal Sheet
  // ──────────────────────────────────────────────
  void _showAssetSheet(
    BuildContext context,
    dynamic country,
    WidgetRef ref, {
    PortfolioItemModel? editingItem,
    required List<PriceItem> currentPrices,
  }) {
    final bool isEditing = editingItem != null;
    final titleController = TextEditingController(text: editingItem?.title ?? '');
    final weightController = TextEditingController(text: editingItem != null ? editingItem.weightGrams.toString() : '');
    final buyPriceController = TextEditingController(text: editingItem != null ? editingItem.buyPricePerGram.toString() : '');
    final makingChargeController = TextEditingController(text: editingItem != null ? editingItem.makingChargePerGram.toString() : '0');
    final notesController = TextEditingController(text: editingItem?.notes ?? '');

    String selectedKarat = editingItem?.karat ?? '24';
    String selectedCategory = editingItem?.category ?? 'bullion';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          // Function to auto-fill current market price
          void fillCurrentMarketPrice() {
            final livePrice = ref.read(portfolioProvider).getLivePricePerGramForKarat(
              selectedKarat,
              currentPrices,
            );
            if (livePrice > 0) {
              setModalState(() {
                buyPriceController.text = livePrice.toStringAsFixed(2);
              });
              HapticFeedback.selectionClick();
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceRaised : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'portfolio_edit_asset'.tr() : 'auto_str_131'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Cairo'),
                        ),
                        TextButton.icon(
                          onPressed: fillCurrentMarketPrice,
                          icon: const Icon(Icons.flash_on_rounded, color: AppColors.gold, size: 16),
                          label: Text(
                            'portfolio_use_current_price'.tr(),
                            style: const TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 1. Category Selector
                    Text('category'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppColors.mutedText)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildCategoryChip(
                          label: 'portfolio_filter_bullion'.tr(),
                          icon: Icons.view_in_ar_rounded,
                          isSelected: selectedCategory == 'bullion',
                          onTap: () => setModalState(() {
                            selectedCategory = 'bullion';
                            if (selectedKarat == 'silver') selectedKarat = '24';
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'portfolio_filter_coin'.tr(),
                          icon: Icons.monetization_on_rounded,
                          isSelected: selectedCategory == 'coin',
                          onTap: () => setModalState(() {
                            selectedCategory = 'coin';
                            if (selectedKarat == 'silver') selectedKarat = '21';
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'portfolio_filter_jewelry'.tr(),
                          icon: Icons.auto_awesome_rounded,
                          isSelected: selectedCategory == 'jewelry',
                          onTap: () => setModalState(() {
                            selectedCategory = 'jewelry';
                            if (selectedKarat == 'silver') selectedKarat = '18';
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'portfolio_filter_silver'.tr(),
                          icon: Icons.diamond_outlined,
                          isSelected: selectedCategory == 'silver' || selectedKarat == 'silver',
                          onTap: () => setModalState(() {
                            selectedCategory = 'silver';
                            selectedKarat = 'silver';
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2. Title Field
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'auto_str_047'.tr(),
                        hintText: selectedCategory == 'bullion' ? 'gold_bullion_hint'.tr() : 'gold_asset_hint'.tr(),
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Karat & Weight
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedKarat,
                            items: ['24', '22', '21', '18', '14', 'silver']
                                .map((k) => DropdownMenuItem(
                                      value: k,
                                      child: Text(
                                        k == 'silver' ? 'auto_str_380'.tr() : 'gold_asset_karat'.tr(args: [k]),
                                        style: const TextStyle(fontFamily: 'Cairo'),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) => setModalState(() {
                              selectedKarat = val ?? '24';
                              if (selectedKarat == 'silver') selectedCategory = 'silver';
                            }),
                            decoration: InputDecoration(
                              labelText: 'auto_str_338'.tr(),
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '${'auto_str_261'.tr()} (${'auto_str_363'.tr()})',
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Quick Weight Presets
                    Text('portfolio_quick_weights'.tr(), style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontFamily: 'Cairo')),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1.0, 2.5, 5.0, 10.0, 20.0, 31.1, 50.0, 100.0, 1000.0].map((w) {
                          final label = w == 31.1 ? '1 oz' : (w == 1000.0 ? '1 kg' : '$w g');
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: ActionChip(
                              label: Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setModalState(() => weightController.text = w.toString());
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Buy Price & Making Charge
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: buyPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '${'auto_str_189'.tr()} / ${'auto_str_363'.tr()}',
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: makingChargeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '${'auto_str_222'.tr()} / ${'auto_str_363'.tr()}',
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 5. Notes / Invoice
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'notes'.tr(),
                        hintText: 'invoice_or_shop_hint'.tr(),
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 6. Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final weight = double.tryParse(weightController.text) ?? 0;
                          final buyPrice = double.tryParse(buyPriceController.text) ?? 0;
                          final making = double.tryParse(makingChargeController.text) ?? 0;
                          final title = titleController.text.trim().isEmpty
                              ? (selectedCategory == 'silver' ? 'auto_str_380'.tr() : 'gold_asset_karat'.tr(args: [selectedKarat]))
                              : titleController.text.trim();

                          if (weight <= 0 || buyPrice <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('auto_str_067'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                            );
                            return;
                          }

                          final item = PortfolioItemModel(
                            id: editingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            category: selectedCategory,
                            karat: selectedKarat,
                            weightGrams: weight,
                            buyPricePerGram: buyPrice,
                            makingChargePerGram: making,
                            buyDate: editingItem?.buyDate ?? DateTime.now(),
                            currencyCode: country.currencyCode,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );

                          if (isEditing) {
                            ref.read(portfolioProvider).updateItem(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('portfolio_item_updated'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                            );
                          } else {
                            ref.read(portfolioProvider).addItem(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('portfolio_item_added'.tr(), style: const TextStyle(fontFamily: 'Cairo'))),
                            );
                          }

                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          isEditing ? 'save'.tr() : 'auto_str_154'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15, fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.gold : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? AppColors.gold : Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
