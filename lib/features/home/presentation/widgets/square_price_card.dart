import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import 'smart_alerts_sheet.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/utils/currency_utils.dart';

class SquarePriceCard extends ConsumerStatefulWidget {
  final PriceItem priceItem;
  final double? localPrice;
  final String? localCurrencySymbol;
  final double? usdPrice;
  final bool isFeatured;
  final VoidCallback? onTap;

  const SquarePriceCard({
    super.key,
    required this.priceItem,
    this.localPrice,
    this.localCurrencySymbol,
    this.usdPrice,
    this.isFeatured = false,
    this.onTap,
  });

  @override
  ConsumerState<SquarePriceCard> createState() => _SquarePriceCardState();
}

class _SquarePriceCardState extends ConsumerState<SquarePriceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  double _prevPrice = 0.0;
  bool _priceChanged = false;

  @override
  void initState() {
    super.initState();
    _prevPrice = widget.localPrice ?? widget.priceItem.buyPrice;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant SquarePriceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentPrice = widget.localPrice ?? widget.priceItem.buyPrice;
    if (_prevPrice != currentPrice && _prevPrice != 0) {
      setState(() => _priceChanged = true);
      _animController.forward(from: 0.0).then((_) {
        _animController.reverse().then((_) {
          if (mounted) setState(() => _priceChanged = false);
        });
      });
      _prevPrice = currentPrice;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double displayLocalPrice =
        widget.localPrice ?? widget.priceItem.buyPrice;
    final String currencySymbol = CurrencyUtils.getSymbol(
        widget.localCurrencySymbol ?? widget.priceItem.currency,
        id: widget.priceItem.id,
        context: context);
    final double displayUsdPrice = widget.usdPrice ?? 0.0;
    final double sellPrice = widget.priceItem.sellPrice > 0 ? widget.priceItem.sellPrice : displayLocalPrice * 1.008;

    final historyAsync = ref.watch(priceHistoryProvider(widget.priceItem.id));

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _priceChanged ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Bounceable(
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            context.push(
              '/price-detail',
              extra: {'item': widget.priceItem},
            );
          }
        },
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            SmartAlertsSheet.show(context, preselectedItem: widget.priceItem);
          },
          child: Container(
            decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isFeatured
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              width: widget.isFeatured ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isFeatured
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.04)),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sparkline Background
              if (historyAsync.hasValue && historyAsync.value!.isNotEmpty)
                Positioned(
                  bottom: 36,
                  left: 0,
                  right: 0,
                  height: 36,
                  child: IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (historyAsync.value!.length - 1).toDouble(),
                        minY: historyAsync.value!.reduce((a, b) => a < b ? a : b),
                        maxY: historyAsync.value!.reduce((a, b) => a > b ? a : b),
                        lineBarsData: [
                          LineChartBarData(
                            spots: historyAsync.value!.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                            isCurved: true,
                            color: widget.priceItem.changePercentage >= 0 ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (widget.priceItem.changePercentage >= 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Karat Badge & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Hero(
                          tag: 'icon_square_${widget.priceItem.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: _buildKaratBadge(widget.priceItem),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.notifications_none_rounded,
                                  size: 15, color: AppColors.mutedText),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                SmartAlertsSheet.show(context,
                                    preselectedItem: widget.priceItem);
                              },
                            ),
                            const SizedBox(width: 4),
                            FavoriteToggleButton(
                              priceId: widget.priceItem.id,
                              size: 15,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Title
                    Hero(
                      tag: 'title_square_${widget.priceItem.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          widget.priceItem.translatedTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color: isDark ? Colors.white : AppColors.primaryText,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Dual-Pricing: الشراء (Buy) and المبيع (Sell) in country currency & USD
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 1. Buy Column (الشراء)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'auto_str_361'.tr(),
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mutedText,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 0.5),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LivePriceWidget(
                                        price: displayLocalPrice,
                                        currency: '',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontFamily: 'Cairo',
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        currencySymbol,
                                        style: const TextStyle(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.gold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (displayUsdPrice > 0)
                                  Text(
                                    '≈ \$${CurrencyUtils.formatLocalizedNumber(displayUsdPrice, context, decimals: 1)}',
                                    style: const TextStyle(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mutedText,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Divider
                          Container(
                            height: 24,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                          ),

                          // 2. Sell Column (المبيع)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'auto_str_343'.tr(),
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mutedText,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(height: 0.5),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyUtils.formatLocalizedNumber(sellPrice, context, decimals: 2, compactLarge: sellPrice >= 100000),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontFamily: 'Cairo',
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        currencySymbol,
                                        style: const TextStyle(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.gold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (displayUsdPrice > 0)
                                  Text(
                                    '≈ \$${CurrencyUtils.formatLocalizedNumber(((sellPrice / (displayLocalPrice > 0 ? displayLocalPrice : 1)) * displayUsdPrice), context, decimals: 1)}',
                                    style: const TextStyle(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w700,
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

                    // Bottom Row: Spread / Trend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${'spread'.tr()}: ${CurrencyUtils.formatLocalizedNumber((sellPrice - displayLocalPrice).abs(), context, decimals: 2, compactLarge: (sellPrice - displayLocalPrice).abs() >= 100000)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : AppColors.mutedText,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildTrendIcon(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildTrendIcon() {
    IconData icon;
    Color color;

    if (widget.priceItem.trend == Trend.up) {
      icon = Icons.trending_up_rounded;
      color = AppColors.success;
    } else if (widget.priceItem.trend == Trend.down) {
      icon = Icons.trending_down_rounded;
      color = AppColors.error;
    } else {
      icon = Icons.remove_rounded;
      color = AppColors.mutedText;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildKaratBadge(PriceItem item) {
    String label = '24K';
    Color badgeColor = const Color(0xFFD4AF37);

    final id = item.id.toLowerCase();
    if (id.contains('22')) {
      label = '22K';
      badgeColor = const Color(0xFFE5B80B);
    } else if (id.contains('21')) {
      label = '21K';
      badgeColor = const Color(0xFFC5A059);
    } else if (id.contains('18')) {
      label = '18K';
      badgeColor = const Color(0xFFB87333);
    } else if (id.contains('14')) {
      label = '14K';
      badgeColor = const Color(0xFF9E9E9E);
    } else if (id.contains('silver') || id.contains('xag')) {
      label = 'auto_str_380'.tr();
      badgeColor = const Color(0xFF94A3B8);
    } else if (id.contains('ounce') || id.contains('xau')) {
      label = 'auto_str_348'.tr();
      badgeColor = const Color(0xFF0F172A);
    } else if (id.contains('pound') || id.contains('lira')) {
      label = 'auto_str_362'.tr();
      badgeColor = const Color(0xFF059669);
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 9.5,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

