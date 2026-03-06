import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/price_chart_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/price_alert_dialog.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';

import '../../../../shared/widgets/premium_logo.dart';
import '../../../../core/services/ad_service.dart';

class PriceDetailPage extends StatefulWidget {
  final PriceItem priceItem;
  const PriceDetailPage({super.key, required this.priceItem});

  @override
  State<PriceDetailPage> createState() => _PriceDetailPageState();
}

class _PriceDetailPageState extends State<PriceDetailPage> {
  List<PriceHistoryPoint> historyPoints = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedRange = 'day';
  double? _dynamicChange;
  Trend? _dynamicTrend;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _setupRealtimeListener();

    // Trigger Ad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService().showInterstitialAd();
    });
  }

  void _setupRealtimeListener() {
    final service = Provider.of<PriceService>(context, listen: false);
    service.pricesStream.listen((prices) {
      if (!mounted) return;
      final currentItem =
          prices.where((p) => p.id == widget.priceItem.id).firstOrNull;
      if (currentItem != null && currentItem.lastUpdate != null) {
        // Only append if price actually changed significantly
        final lastPoint = historyPoints.lastOrNull;
        if (lastPoint == null ||
            (currentItem.lastUpdate!.isAfter(lastPoint.timestamp) &&
                (currentItem.buyPrice - lastPoint.price).abs() > 0.001)) {
          setState(() {
            historyPoints.add(PriceHistoryPoint(
              timestamp: currentItem.lastUpdate!,
              price: currentItem.buyPrice,
            ));
            // Keep memory low
            if (historyPoints.length > 50) historyPoints.removeAt(0);
          });
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
      final service = Provider.of<PriceService>(context, listen: false);
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

          // Calculate dynamic change if in day view
          if (selectedRange == 'day' && historyPoints.length >= 2) {
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
          errorMessage = 'فشل تحميل البيانات';
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

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.##', 'en_US');
    final isGold = widget.priceItem.metalType == 'gold';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 50),
              child: Column(
                children: [
                  _buildPriceStatsCard(format),
                  const SizedBox(height: 32),
                  _buildChartSection(isGold),
                  const SizedBox(height: 32),
                  _buildHistoryList(format),
                  const SizedBox(height: 32),
                  _buildMarketInfoTile(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.darkGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      actions: [
        FavoriteToggleButton(priceId: widget.priceItem.id, size: 24),
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
                        child: Text(
                          widget.priceItem.title,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 15))
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildStatColumn(
                  'سعر الشراء',
                  format.format(widget.priceItem.buyPrice),
                  widget.priceItem.currency,
                  Colors.blue)),
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
                  'سعر المبيع',
                  format.format(widget.priceItem.sellPrice),
                  widget.priceItem.currency,
                  AppColors.gold)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, String unit, Color color) {
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
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGreen,
                  fontFamily: 'Roboto')),
        ),
        const SizedBox(height: 4),
        Text(unit,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.gold,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildChartSection(bool isGold) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الرسم البياني',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.darkGreen)),
              _buildRangeSelector(),
            ],
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const ChartShimmer()
          else if (errorMessage.isNotEmpty)
            _buildErrorState()
          else
            PriceChartWidget(
              history: historyPoints,
              title: '',
              range: selectedRange,
              lineColor: isGold ? AppColors.gold : Colors.blue,
              dailyChangePercentage:
                  _dynamicChange ?? widget.priceItem.changePercentage,
            ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    final ranges = {'day': 'يوم', 'week': 'أسبوع', 'month': 'شهر'};
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.entries.map((e) {
          final isSelected = selectedRange == e.key;
          return GestureDetector(
            onTap: () => _onRangeChanged(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6)
                      ]
                    : null,
              ),
              child: Text(e.value,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.darkGreen
                          : AppColors.mutedText)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(NumberFormat format) {
    String title = 'سجل التغيرات الأخير';
    if (selectedRange == 'week') title = 'سجل الإغلاق اليومي (أسبوع)';
    if (selectedRange == 'month') title = 'سجل الإغلاق اليومي (شهر)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.darkGreen)),
              if (selectedRange == 'day')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('مباشر',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        if (historyPoints.isEmpty && !isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('لا توجد بيانات سجل متوفرة حالياً',
                style: TextStyle(color: Colors.grey)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                color: AppColors.background.withValues(alpha: 0.5),
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
                    DateFormat(isDaily ? 'EEEE, dd MMMM' : 'dd MMMM، hh:mm a',
                            'ar_SA')
                        .format(point.timestamp.toLocal()),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.darkGreen)),
                const SizedBox(height: 2),
                Text(isDaily ? 'سعر الإغلاق النهائي' : 'تحديث آلي من البورصة',
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.darkGreen,
                          fontFamily: 'Roboto')),
                  const SizedBox(width: 4),
                  Text(widget.priceItem.currency,
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
            onPressed: _fetchHistory, child: const Text('إعادة المحاولة')),
      ],
    );
  }

  Widget _buildMarketInfoTile() {
    final priceService = Provider.of<PriceService>(context, listen: false);
    final displaySettings = priceService.currentSettings?['displaySettings'];
    final showNote = displaySettings?['showHistoryNote'] ?? true;

    if (!showNote) return const SizedBox.shrink();

    final noteText = displaySettings?['historyNoteText'] ??
        'ملاحظة: البيانات التاريخية تُحدث كل 5-20 دقيقة حسب حركة السوق العالمية.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.platinum.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.platinum.withValues(alpha: 0.2))),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded,
              color: AppColors.darkGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(noteText,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.darkGreen,
                    height: 1.5,
                    fontStyle: FontStyle.normal)),
          ),
        ],
      ),
    );
  }
}
