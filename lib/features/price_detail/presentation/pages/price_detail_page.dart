import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/price_chart_widget.dart';
import '../../../../features/home/presentation/widgets/candlestick_chart_widget.dart';
import '../../../../shared/widgets/interactive_fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/price_alert_dialog.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:gold_sham/features/home/presentation/widgets/item_share_sheet.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/banner_placement_widget.dart';

enum ChartType { area, candlestick }

class PriceDetailPage extends ConsumerStatefulWidget {
  final PriceItem priceItem;
  const PriceDetailPage({super.key, required this.priceItem});

  @override
  ConsumerState<PriceDetailPage> createState() => _PriceDetailPageState();
}

class _PriceDetailPageState extends ConsumerState<PriceDetailPage> {
  List<PriceHistoryPoint> historyPoints = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedRange = 'day';
  ChartType _chartType = ChartType.area;
  double? _dynamicChange;
  Trend? _dynamicTrend;
  bool _showMA = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  StreamSubscription<List<PriceItem>>? _pricesSub;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _setupRealtimeListener();

    // Trigger Ad — بعد اكتمال بناء الصفحة وانتهاء الانيميشن
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) AdService().showInterstitialOnNavigation(force: true);
      });
    });
  }

  @override
  void dispose() {
    _pricesSub?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    final service = ref.read(priceServiceProvider);
    _pricesSub = service.pricesStream.listen((prices) {
      if (!mounted) return;
      final currentItem =
          prices.where((p) => p.id == widget.priceItem.id).firstOrNull;
      if (currentItem != null && currentItem.lastUpdate != null) {
        if (widget.priceItem.lastUpdate == null ||
            currentItem.lastUpdate!.isAfter(widget.priceItem.lastUpdate!)) {
          if (mounted) {
            setState(() {
              _dynamicChange = currentItem.changePercentage;
              _dynamicTrend = currentItem.trend;
            });
            _fetchHistory();
          }
        }
      }
    });
  }

  Future<void> _fetchHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final service = ref.read(priceServiceProvider);
      final data = await service.fetchPriceHistory(widget.priceItem.id,
          range: selectedRange);

      if (mounted) {
        setState(() {
          historyPoints = data.map((item) {
            return PriceHistoryPoint(
              timestamp: DateTime.parse(item['timestamp']),
              price: (item['buyPrice'] as num).toDouble(),
            );
          }).toList();

          // Calculate dynamic change across the selected timeframe
          if (historyPoints.length >= 2) {
            final first = historyPoints.first.price;
            final last = historyPoints.last.price;
            if (first > 0) {
              _dynamicChange = ((last - first) / first) * 100;
              _dynamicTrend = _dynamicChange! > 0
                  ? Trend.up
                  : (_dynamicChange! < 0 ? Trend.down : Trend.stable);
            }
          } else {
            _dynamicChange = widget.priceItem.changePercentage;
            _dynamicTrend = widget.priceItem.trend;
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'auto_str_175'.tr();
          isLoading = false;
        });
      }
    }
  }

  void _onRangeChanged(String range) {
    if (selectedRange == range) return;
    HapticFeedback.mediumImpact();
    setState(() => selectedRange = range);
    _fetchHistory();
  }

  void _safeNavigateBack() {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.##', 'en_US');
    final isGold = widget.priceItem.metalType == 'gold';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _safeNavigateBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildPremiumHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 50),
                  child: Column(
                    children: [
                      // ── [1] إعلان أعلى صفحة تفاصيل السعر ──
                      const BannerPlacementWidget(
                        location: 'price_detail_top',
                        margin: EdgeInsets.only(bottom: 16),
                      ),

                      _buildPriceStatsCard(format),
                      const SizedBox(height: 20),

                      // ── [2] إعلان منتصف صفحة تفاصيل السعر ──
                      const BannerPlacementWidget(
                        location: 'price_detail_mid',
                        margin: EdgeInsets.only(bottom: 16),
                      ),

                      _buildChartSection(isGold),
                      const SizedBox(height: 24),
                      if (historyPoints.isNotEmpty) ...[
                        _buildPurityAndOHLCCard(format),
                        const SizedBox(height: 32),
                      ],
                      _buildHistoryList(format),
                      const SizedBox(height: 32),
                      _buildMarketInfoTile(),

                      // ── [3] إعلان أسفل صفحة تفاصيل السعر ──
                      const BannerPlacementWidget(
                        location: 'price_detail_bottom',
                        margin: EdgeInsets.only(top: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.darkGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: _safeNavigateBack,
      ),
      actions: [
        FavoriteToggleButton(priceId: widget.priceItem.id, size: 24),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          tooltip: 'export_price_card'.tr(),
          onPressed: () {
            HapticFeedback.lightImpact();
            ItemShareSheet.show(
              context,
              item: widget.priceItem,
              history: historyPoints,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_active_outlined,
              color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  PriceAlertDialog(priceItem: widget.priceItem),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppColors.emeraldGradient,
          ),
          child: Stack(
            children: [
              const Center(
                child: PremiumLogo(
                  size: 160,
                  isBackground: true,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Hero(
                          tag: 'title_${widget.priceItem.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              widget.priceItem.translatedTitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 10)
                                  ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTrendBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    final trend = _dynamicTrend ?? widget.priceItem.trend;
    Color color;
    if (trend == Trend.up) {
      color = Colors.greenAccent;
    } else if (trend == Trend.down) {
      color = Colors.redAccent;
    } else {
      color = Colors.grey;
    }

    final percentage = _dynamicChange ?? widget.priceItem.changePercentage;
    final sign = percentage > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$sign${percentage.toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPriceStatsCard(NumberFormat format) {
    final double buyUsd = widget.priceItem.usdPrice;
    final double sellUsd = (widget.priceItem.buyPrice > 0 && buyUsd > 0)
        ? (widget.priceItem.sellPrice / widget.priceItem.buyPrice) * buyUsd
        : 0.0;

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
              child: _buildStatColumn(
                  'auto_str_286'.tr(),
                  CurrencyUtils.formatPrice(widget.priceItem.buyPrice, widget.priceItem.currency, id: widget.priceItem.id),
                  '',
                  Colors.blue,
                  usdSubtext: buyUsd > 0 ? '≈ \$${buyUsd.toStringAsFixed(1)} USD' : null)),
          Container(
              width: 1.5,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withValues(alpha: 0.01),
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.01)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )),
          Expanded(
              child: _buildStatColumn(
                  'auto_str_287'.tr(),
                  CurrencyUtils.formatPrice(widget.priceItem.sellPrice, widget.priceItem.currency, id: widget.priceItem.id),
                  '',
                  AppColors.gold,
                  usdSubtext: sellUsd > 0 ? '≈ \$${sellUsd.toStringAsFixed(1)} USD' : null)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, String unit, Color color, {String? usdSubtext}) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkGreen,
                  fontFamily: 'Roboto')),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(unit,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800)),
        ],
        if (usdSubtext != null && usdSubtext.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            usdSubtext,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedText,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChartSection(bool isGold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          // ── Header Row: Title & Chart Mode Controls (Area / Candlestick / MA) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.gold, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'auto_str_250'.tr(), // الرسم البياني
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.darkGreen,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChartTypeToggle(),
                  if (_chartType == ChartType.area) ...[
                    const SizedBox(width: 6),
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: _showMA
                            ? AppColors.gold.withValues(alpha: 0.2)
                            : (isDark ? AppColors.darkSurfaceRaised : AppColors.background),
                        borderRadius: BorderRadius.circular(9),
                        border: _showMA ? Border.all(color: AppColors.gold.withValues(alpha: 0.5)) : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: _showMA ? AppColors.gold : AppColors.mutedText,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showMA = !_showMA;
                          });
                        },
                        tooltip: 'moving_average_ma'.tr(),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Range Selector Row: Full width segmented bar (24h / 1W / 1M / 1Y) ──
          _buildRangeSelector(),
          const SizedBox(height: 18),
          if (isLoading)
            const ChartShimmer()
          else if (errorMessage.isNotEmpty)
            _buildErrorState()
          else if (_chartType == ChartType.candlestick)
            CandlestickChartWidget(
              history: historyPoints,
              range: selectedRange,
              lineColor: isGold ? AppColors.gold : Colors.blue,
              dailyChangePercentage: _dynamicChange ?? widget.priceItem.changePercentage,
            )
          else
            RepaintBoundary(
              child: InteractiveFlChart(
                history: historyPoints,
                range: selectedRange,
                lineColor: isGold ? AppColors.gold : Colors.blue,
                showMA: _showMA,
              ),
            ),
          const SizedBox(height: 16),
          if (historyPoints.isNotEmpty) 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBullBearIndicator(),
                _buildPerformanceComparison(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChartTypeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartTypeOption(
            type: ChartType.area,
            icon: Icons.show_chart_rounded,
            tooltip: 'area_chart'.tr(),
          ),
          const SizedBox(width: 2),
          _buildChartTypeOption(
            type: ChartType.candlestick,
            icon: Icons.candlestick_chart_rounded,
            tooltip: 'candlestick'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeOption({
    required ChartType type,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = _chartType == type;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          if (_chartType != type) {
            HapticFeedback.selectionClick();
            setState(() => _chartType = type);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? AppColors.gold.withValues(alpha: 0.25) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? AppColors.gold : AppColors.darkGreen) : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceComparison() {
    // Mock global performance (since we don't have global history in this model)
    // We can just use the item's change percentage and pretend global is slightly different
    // In a real app, this would fetch from a global market provider.
    final double localChange = _dynamicChange ?? widget.priceItem.changePercentage;
    final double globalChange = localChange * 0.8; // Placeholder relation
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('performance_comparison'.tr(), style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniPerf('local'.tr(), localChange),
              const SizedBox(width: 12),
              _buildMiniPerf('global'.tr(), globalChange),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniPerf(String label, double value) {
    final bool isPos = value >= 0;
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Text(
          '${isPos ? '+' : ''}${value.toStringAsFixed(2)}%',
          style: TextStyle(
            color: isPos ? Colors.green : Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBullBearIndicator() {
    final double change = _dynamicChange ?? widget.priceItem.changePercentage;
    final bool isBull = change >= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBull ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBull ? Icons.trending_up : Icons.trending_down,
            color: isBull ? AppColors.success : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isBull ? 'bullish_indicator'.tr() : 'bearish_indicator'.tr(),
            style: TextStyle(
              color: isBull ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ranges = {
      'day': 'range_24h'.tr(),
      'week': 'range_1w'.tr(),
      'month': 'range_1m'.tr(),
      'year': 'range_1y'.tr(),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: ranges.entries.map((e) {
          final isSelected = selectedRange == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onRangeChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.gold.withValues(alpha: 0.25) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    e.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: isSelected
                          ? (isDark ? AppColors.gold : AppColors.darkGreen)
                          : AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(NumberFormat format) {
    String title = 'auto_str_165'.tr();
    if (selectedRange == 'week') title = 'auto_str_106'.tr();
    if (selectedRange == 'month') title = 'auto_str_119'.tr();
    if (selectedRange == 'year') title = 'annual_close_history'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkGreen)),
              if (selectedRange == 'day')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('auto_str_358'.tr(),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        if (historyPoints.isEmpty && !isLoading)
          Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text('auto_str_071'.tr(),
                style: const TextStyle(color: Colors.grey)),
          ))
        else
          ...historyPoints.reversed
              .take(selectedRange == 'day' ? 10 : 30)
              .map((p) => _buildHistoryItem(p, format)),
      ],
    );
  }

  Widget _buildHistoryItem(PriceHistoryPoint point, NumberFormat format) {
    final isDaily = selectedRange != 'day';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightGrey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: isDark ? Colors.white12 : AppColors.background.withValues(alpha: 0.5),
                shape: BoxShape.circle),
            child: Icon(
                isDaily ? Icons.calendar_today_rounded : Icons.history_rounded,
                size: 16,
                color: AppColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    DateFormat(isDaily ? 'EEEE, dd MMMM' : 'auto_str_199'.tr(),
                            context.locale.toString())
                        .format(point.timestamp.toLocal()),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.darkGreen)),
                const SizedBox(height: 2),
                Text(isDaily ? 'auto_str_166'.tr() : 'auto_str_153'.tr(),
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.mutedText.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(format.format(point.price),
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark ? AppColors.gold : AppColors.darkGreen,
                          fontFamily: 'Roboto')),
                  const SizedBox(width: 4),
                  Text(CurrencyUtils.getSymbol(widget.priceItem.currency, id: widget.priceItem.id, context: context),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(errorMessage, style: const TextStyle(color: AppColors.mutedText)),
        TextButton(
            onPressed: _fetchHistory, child: Text('auto_str_230'.tr())),
      ],
    );
  }

  Widget _buildMarketInfoTile() {
    final priceService = ref.read(priceServiceProvider);
    final displaySettings = priceService.currentSettings?['displaySettings'];
    final showNote = displaySettings?['showHistoryNote'] ?? true;

    if (!showNote) return const SizedBox.shrink();

    final rawNote = displaySettings?['historyNoteText'] as String?;
    const defaultArNote =
        'ملاحظة: البيانات التاريخية تُحدث كل 5-20 دقيقة حسب حركة السوق العالمية.';
    final noteText = (rawNote != null &&
            rawNote.isNotEmpty &&
            rawNote.trim() != defaultArNote.trim())
        ? rawNote
        : 'auto_str_028'.tr();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Icon(Icons.lock_clock_rounded,
              color: isDark ? AppColors.gold : AppColors.darkGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(noteText,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.mutedText : AppColors.darkGreen,
                    height: 1.5,
                    fontStyle: FontStyle.normal)),
          ),
        ],
      ),
    );
  }

  Widget _buildPurityAndOHLCCard(NumberFormat format) {
    // 1. Calculate OHLC
    double open = historyPoints.first.price;
    double close = historyPoints.last.price;
    double high = historyPoints.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    double low = historyPoints.map((e) => e.price).reduce((a, b) => a < b ? a : b);

    // 2. Determine Purity String
    String purity = '';
    final id = widget.priceItem.id.toLowerCase();
    if (id.contains('24')) {
      purity = '999.9 (99.9%)';
    } else if (id.contains('22')) {
      purity = '916.6 (91.6%)';
    } else if (id.contains('21')) {
      purity = '875.0 (87.5%)';
    } else if (id.contains('18')) {
      purity = '750.0 (75.0%)';
    } else if (id.contains('14')) {
      purity = '585.0 (58.5%)';
    } else if (id.contains('silver') || id.contains('xag')) {
      purity = '999.0 / 925.0';
    } else if (id.contains('ounce') || id.contains('xau')) {
      purity = '999.9 (99.9%)';
    }
    
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.gold, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'market_details'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  selectedRange == 'day'
                      ? 'range_24h'.tr()
                      : (selectedRange == 'week'
                          ? 'range_1w'.tr()
                          : (selectedRange == 'month'
                              ? 'range_1m'.tr()
                              : 'range_1y'.tr())),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (purity.isNotEmpty) ...[
            _buildOHLCRow('purity_percentage'.tr(), purity, Icons.diamond_rounded, isString: true),
            Divider(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : Colors.black12, height: 24),
          ],
          _buildOHLCRow('open_price'.tr(), format.format(open), Icons.login_rounded),
          const SizedBox(height: 12),
          _buildOHLCRow('close_price'.tr(), format.format(close), Icons.logout_rounded),
          Divider(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : Colors.black12, height: 24),
          _buildOHLCRow('high_price'.tr(), format.format(high), Icons.arrow_upward_rounded, color: AppColors.priceUp),
          const SizedBox(height: 12),
          _buildOHLCRow('low_price'.tr(), format.format(low), Icons.arrow_downward_rounded, color: AppColors.priceDown),
        ],
      ),
    );
  }

  Widget _buildOHLCRow(String label, String value, IconData icon, {Color? color, bool isString = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? AppColors.mutedText),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color ?? (isDark ? Colors.white : AppColors.darkGreen),
                fontFamily: isString ? 'Cairo' : 'Roboto',
              ),
            ),
            if (!isString) ...[
              const SizedBox(width: 4),
              Text(
                CurrencyUtils.getSymbol(widget.priceItem.currency, id: widget.priceItem.id, context: context),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }
}

