import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/widgets/premium_empty_state.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/shared/widgets/premium_logo.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/last_update_ticker.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/providers/price_selectors.dart';
import 'package:gold_sham/features/home/presentation/widgets/calculator_widget.dart';
import 'package:gold_sham/features/home/presentation/widgets/currency_square_card.dart';
import 'package:gold_sham/shared/widgets/banner_placement_widget.dart';
import '../../../../core/providers/settings_provider.dart';

class CurrenciesPage extends ConsumerStatefulWidget {
  const CurrenciesPage({super.key});

  @override
  ConsumerState<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends ConsumerState<CurrenciesPage> {
  List<String> _pinnedCodes = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pinnedCodes = prefs.getStringList('pinned_currency_codes') ?? ['USD', 'EUR'];
      });
    }
  }

  void _toggleViewMode() {
    HapticFeedback.selectionClick();
    final isGrid = ref.read(settingsProvider).isGridLayout;
    ref.read(settingsProvider.notifier).setIsGridLayout(!isGrid);
  }

  Future<void> _togglePin(String currencyCode) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    final upper = currencyCode.toUpperCase();
    setState(() {
      if (_pinnedCodes.contains(upper)) {
        _pinnedCodes.remove(upper);
      } else {
        _pinnedCodes.insert(0, upper);
      }
    });
    await prefs.setStringList('pinned_currency_codes', _pinnedCodes);

    if (mounted) {
      final isNowPinned = _pinnedCodes.contains(upper);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNowPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: isNowPinned ? AppColors.gold : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isNowPinned
                    ? 'currency_pinned_toast'.tr(args: [_getNameForCurrency(upper)])
                    : 'currency_unpinned_toast'.tr(args: [_getNameForCurrency(upper)]),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.darkGreen,
        ),
      );
    }
  }

  String _extractCurrencyCode(PriceItem item) {
    final parts = item.id.split('_');
    return parts.last.toUpperCase();
  }

  String _getFlagForCurrency(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return '🇺🇸';
      case 'EUR': return '🇪🇺';
      case 'GBP': return '🇬🇧';
      case 'SAR': return '🇸🇦';
      case 'AED': return '🇦🇪';
      case 'KWD': return '🇰🇼';
      case 'QAR': return '🇶🇦';
      case 'BHD': return '🇧🇭';
      case 'OMR': return '🇴🇲';
      case 'JOD': return '🇯🇴';
      case 'EGP': return '🇪🇬';
      case 'TRY': return '🇹🇷';
      case 'SYP': return '🇸🇾';
      case 'CAD': return '🇨🇦';
      case 'AUD': return '🇦🇺';
      case 'CHF': return '🇨🇭';
      case 'IQD': return '🇮🇶';
      case 'LBP': return '🇱🇧';
      case 'LYD': return '🇱🇾';
      case 'DZD': return '🇩🇿';
      case 'MAD': return '🇲🇦';
      case 'TND': return '🇹🇳';
      case 'SDG': return '🇸🇩';
      case 'YER': return '🇾🇪';
      default: return '🌐';
    }
  }

  String _getNameForCurrency(String code) {
    final key = 'currency_name_${code.toLowerCase()}';
    final val = key.tr();
    if (val.isNotEmpty && val != key) return val;
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceService = ref.watch(priceServiceProvider);
    final allPrices = priceService.currentPrices;

    DateTime? latestUpdate;
    if (allPrices.isNotEmpty) {
      final updates = allPrices.map((e) => e.lastUpdate).whereType<DateTime>();
      if (updates.isNotEmpty) {
        latestUpdate = updates.reduce((a, b) => a.isAfter(b) ? a : b);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: priceService.settingsStream,
        initialData: priceService.currentSettings,
        builder: (context, settingsSnapshot) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.darkGreen,
                elevation: 0,
                stretch: true,
                actions: [
                  // View mode toggle button in AppBar
                  IconButton(
                    onPressed: _toggleViewMode,
                    icon: Icon(
                      ref.watch(settingsProvider).isGridLayout ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    tooltip: ref.watch(settingsProvider).isGridLayout ? 'layout_list'.tr() : 'layout_grid'.tr(),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 100),
                  title: Text('auto_str_278'.tr(),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.darkGreen, Color(0xFF0F2E25)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 40,
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
                          top: -30,
                          child: CircleAvatar(
                            radius: 100,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
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
                                    animate: priceService.isConnected),
                                if (latestUpdate != null) ...[
                                  Container(
                                    height: 12,
                                    width: 1.5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    color: Colors.white24,
                                  ),
                                  const Icon(Icons.speed_rounded,
                                      color: AppColors.gold, size: 14),
                                  const SizedBox(width: 8),
                                  LastUpdateTicker(
                                    lastUpdate: latestUpdate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
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
              ),
              StreamBuilder<List<PriceItem>>(
                stream: priceService.pricesStream,
                initialData: priceService.currentPrices,
                builder: (context, snapshot) {
                  final prices = snapshot.data ?? [];

                  if (prices.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, idx) => const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: PremiumCardShimmer()),
                          childCount: 6,
                        ),
                      ),
                    );
                  }

                  final countryProviderInstance = ref.watch(countryProvider);
                  final selectedCountry = countryProviderInstance.selectedCountry;
                  final countryCurrencies = ref.watch(countryCurrenciesProvider);

                  if (countryCurrencies.isEmpty) {
                    return _buildEmptyState();
                  }

                  // ── Split into Pinned and Unpinned Lists ──
                  final pinnedList = countryCurrencies
                      .where((item) => _pinnedCodes.contains(_extractCurrencyCode(item)))
                      .toList();
                  // Preserve pinning order
                  pinnedList.sort((a, b) {
                    final idxA = _pinnedCodes.indexOf(_extractCurrencyCode(a));
                    final idxB = _pinnedCodes.indexOf(_extractCurrencyCode(b));
                    return idxA.compareTo(idxB);
                  });

                  final unpinnedList = countryCurrencies
                      .where((item) => !_pinnedCodes.contains(_extractCurrencyCode(item)))
                      .toList();

                  final isGridView = ref.watch(settingsProvider).isGridLayout;
                  final fontScale = ref.watch(settingsProvider).fontSizeScale;
                  final gridAspectRatio = fontScale >= 1.3 ? 0.98 : (fontScale >= 1.15 ? 1.05 : 1.15);

                  Widget buildGrid(List<PriceItem> items) {
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: gridAspectRatio,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final code = _extractCurrencyCode(item);
                        final name = _getNameForCurrency(code);
                        final flag = _getFlagForCurrency(code);
                        final isPinned = _pinnedCodes.contains(code);

                        return CurrencySquareCard(
                          priceItem: item,
                          currencyCode: code,
                          currencyName: name,
                          baseCurrencySymbol: selectedCountry.localizedCurrencySymbol,
                          baseCurrencyCode: selectedCountry.currencyCode,
                          flagEmoji: flag,
                          isPinned: isPinned,
                          onTogglePin: () => _togglePin(code),
                        );
                      },
                    );
                  }

                  Widget buildList(List<PriceItem> items) {
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final code = _extractCurrencyCode(item);
                        final name = _getNameForCurrency(code);
                        final flag = _getFlagForCurrency(code);
                        final isPinned = _pinnedCodes.contains(code);

                        return CompactCurrencyCard(
                          priceItem: item,
                          currencyCode: code,
                          currencyName: name,
                          baseCurrencySymbol: selectedCountry.localizedCurrencySymbol,
                          baseCurrencyCode: selectedCountry.currencyCode,
                          flagEmoji: flag,
                          isPinned: isPinned,
                          onTogglePin: () => _togglePin(code),
                        );
                      },
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 160),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: KeyedSubtree(
                          key: ValueKey('currencies_${selectedCountry.code}_$isGridView'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── [1] إعلان أعلى صفحة العملات ──
                              const BannerPlacementWidget(
                                location: 'currencies_top',
                                height: 95.0,
                                margin: EdgeInsets.only(bottom: 14),
                              ),

                              if (priceService
                                  .shouldShow('currencyShowSummaryWelcome')) ...[
                                _buildWelcomeCard(context),
                                const SizedBox(height: 20),
                              ],

                              // ── 1. PINNED CURRENCIES SECTION ──
                              if (pinnedList.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.push_pin_rounded, color: AppColors.gold, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'pinned_currencies'.tr(),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : AppColors.darkGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${pinnedList.length}',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                isGridView ? buildGrid(pinnedList) : buildList(pinnedList),
                                const SizedBox(height: 20),
                              ],

                              // ── 2. ALL REMAINING CURRENCIES SECTION ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: (isDark ? Colors.white12 : AppColors.darkGreen.withValues(alpha: 0.08)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.currency_exchange_rounded,
                                          color: isDark ? Colors.white70 : AppColors.darkGreen,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        pinnedList.isNotEmpty ? 'other_currencies'.tr() : 'live_currency_rates'.tr(),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : AppColors.darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Quick toggle button
                                  IconButton(
                                    onPressed: _toggleViewMode,
                                    icon: Icon(
                                      isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                                      color: AppColors.gold,
                                      size: 20,
                                    ),
                                    tooltip: isGridView ? 'list_view'.tr() : 'grid_view'.tr(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              isGridView ? buildGrid(unpinnedList) : buildList(unpinnedList),

                              // ── [2] إعلان منتصف صفحة العملات ──
                              const BannerPlacementWidget(
                                location: 'currencies_mid',
                                height: 95.0,
                                margin: EdgeInsets.symmetric(vertical: 14),
                              ),

                              // Calculator Section
                              if (priceService
                                  .shouldShow('currencyShowCalculator')) ...[
                                const SizedBox(height: 10),
                                const CalculatorWidget(),
                                const SizedBox(height: 16),
                              ],

                              // ── [3] إعلان أسفل صفحة العملات ──
                              const BannerPlacementWidget(
                                location: 'currencies_bottom',
                                height: 95.0,
                                margin: EdgeInsets.only(top: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : AppColors.darkGreen.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.lightGrey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.2),
                  AppColors.gold.withValues(alpha: 0.2)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange_rounded,
                color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'currency_page_title'.tr(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'currency_page_subtitle'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: PremiumEmptyState(
        title: 'no_active_currencies'.tr(),
        subtitle: 'review_admin_currencies_desc'.tr(),
        icon: Icons.money_off_csred_rounded,
      ),
    );
  }
}
