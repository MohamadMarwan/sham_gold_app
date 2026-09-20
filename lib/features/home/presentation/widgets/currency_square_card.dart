import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/country_flag_widget.dart';
import 'smart_alerts_sheet.dart';

class CurrencySquareCard extends ConsumerStatefulWidget {
  final PriceItem priceItem;
  final String currencyCode;
  final String currencyName;
  final String baseCurrencySymbol;
  final String? baseCurrencyCode;
  final String flagEmoji;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback? onTap;
  final int decimals;

  const CurrencySquareCard({
    super.key,
    required this.priceItem,
    required this.currencyCode,
    required this.currencyName,
    required this.baseCurrencySymbol,
    this.baseCurrencyCode,
    required this.flagEmoji,
    required this.isPinned,
    required this.onTogglePin,
    this.onTap,
    this.decimals = 3,
  });

  @override
  ConsumerState<CurrencySquareCard> createState() => _CurrencySquareCardState();
}

class _CurrencySquareCardState extends ConsumerState<CurrencySquareCard>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ambientController;
  late Animation<double> _ambientAnimation;
  double _prevPrice = 0.0;
  bool _priceChanged = false;

  @override
  void initState() {
    super.initState();
    _prevPrice = widget.priceItem.buyPrice;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Ambient pulse: subtle opacity breathing every ~1.2s for live feel
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ambientAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );
    _ambientController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CurrencySquareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_prevPrice != widget.priceItem.buyPrice && _prevPrice != 0) {
      setState(() => _priceChanged = true);
      _animController.forward(from: 0.0).then((_) {
        _animController.reverse().then((_) {
          if (mounted) setState(() => _priceChanged = false);
        });
      });
      _prevPrice = widget.priceItem.buyPrice;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  String _formatPrice(double price, BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final locale = isAr ? 'ar' : 'en_US';
    final dec = (widget.decimals == 4) ? 4 : 3;

    // For large whole numbers with no fractions (e.g. 14500 SYP or 1300000 LBP)
    if (price >= 10000 && price % 1 == 0) {
      return NumberFormat('#,##0', locale).format(price);
    }

    final pattern = (dec == 4) ? '#,##0.0000' : '#,##0.000';
    return NumberFormat(pattern, locale).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final buyPrice = widget.priceItem.buyPrice;
    final sellPrice = widget.priceItem.sellPrice > 0
        ? widget.priceItem.sellPrice
        : buyPrice * 1.004;

    final isSameCurrency = widget.currencyCode.toUpperCase() == (widget.baseCurrencyCode ?? '').toUpperCase();
    final effectiveBaseCode = isSameCurrency
        ? (widget.currencyCode.toUpperCase() == 'EUR' ? 'USD' : 'EUR')
        : (widget.baseCurrencyCode ?? widget.baseCurrencySymbol);

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
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isPinned
                    ? AppColors.gold.withValues(alpha: 0.6)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                width: widget.isPinned ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isPinned
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : (isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04)),
                  blurRadius: widget.isPinned ? 16 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Corner Pinned ribbon indicator (subtle glow)
                if (widget.isPinned)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
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
                      // 1. Header: Flag + Code Badge + Pin Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  border: Border.all(color: Colors.white24, width: 0.8),
                                ),
                                child: Center(
                                  child: CountryFlagWidget(
                                    flagEmoji: widget.flagEmoji,
                                    countryCode: widget.currencyCode,
                                    size: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: widget.isPinned
                                      ? AppColors.gold.withValues(alpha: 0.2)
                                      : (isDark ? Colors.white12 : AppColors.darkGreen.withValues(alpha: 0.08)),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  widget.currencyCode,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isPinned
                                        ? AppColors.gold
                                        : (isDark ? Colors.white : AppColors.darkGreen),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Pin Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTogglePin();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: widget.isPinned
                                    ? AppColors.gold.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 14,
                                color: widget.isPinned
                                    ? AppColors.gold
                                    : (isDark ? Colors.white38 : Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 2. Currency Name & Exchange Formula
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyUtils.getCompactPairTitle(
                              widget.currencyCode,
                              effectiveBaseCode,
                              context: context,
                            ),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.darkGreen,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.getCompactFormula(
                              widget.currencyCode,
                              buyPrice,
                              effectiveBaseCode,
                              context: context,
                              decimals: widget.decimals,
                            ),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : AppColors.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // 3. Dual Pricing Box (Buy & Sell) with live pulse
                      AnimatedBuilder(
                        animation: _ambientController,
                        builder: (context, child) {
                          final opacity = _ambientAnimation.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Buy Box
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'currency_buy'.tr(),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white54 : AppColors.mutedText,
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(buyPrice, context),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: (isDark ? Colors.white : AppColors.darkGreen).withValues(alpha: opacity),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                // Sell Box
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'currency_sell'.tr(),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white54 : AppColors.mutedText,
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(sellPrice, context),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.gold.withValues(alpha: opacity),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // 4. Sparkline or Trend + Live indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'live'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white54 : AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                          // Mini sparkline / Trend
                          SizedBox(
                            width: 60,
                            height: 20,
                            child: historyAsync.when(
                              data: (points) {
                                if (points.length < 2) {
                                  return _buildStaticTrendIndicator(buyPrice, sellPrice);
                                }
                                final isUp = points.last >= points.first;
                                final spots = points.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value);
                                }).toList();

                                return LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    minY: points.reduce((a, b) => a < b ? a : b) * 0.999,
                                    maxY: points.reduce((a, b) => a > b ? a : b) * 1.001,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        color: isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        barWidth: 1.5,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => _buildStaticTrendIndicator(buyPrice, sellPrice),
                            ),
                          ),
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

  Widget _buildStaticTrendIndicator(double buy, double sell) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(Icons.show_chart_rounded, size: 14, color: AppColors.gold),
        const SizedBox(width: 2),
        Text(
          '±0.05%',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

/// Compact List View Tile for Currencies
class CompactCurrencyCard extends StatefulWidget {
  final PriceItem priceItem;
  final String currencyCode;
  final String currencyName;
  final String baseCurrencySymbol;
  final String? baseCurrencyCode;
  final String flagEmoji;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback? onTap;
  final int decimals;

  const CompactCurrencyCard({
    super.key,
    required this.priceItem,
    required this.currencyCode,
    required this.currencyName,
    required this.baseCurrencySymbol,
    this.baseCurrencyCode,
    required this.flagEmoji,
    required this.isPinned,
    required this.onTogglePin,
    this.onTap,
    this.decimals = 3,
  });

  @override
  State<CompactCurrencyCard> createState() => _CompactCurrencyCardState();
}

class _CompactCurrencyCardState extends State<CompactCurrencyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;
  late Animation<double> _ambientAnimation;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ambientAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );
    _ambientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  String _formatPrice(double price, BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final locale = isAr ? 'ar' : 'en_US';
    final dec = (widget.decimals == 4) ? 4 : 3;

    // For large whole numbers with no fractions (e.g. 14500 SYP or 1300000 LBP)
    if (price >= 10000 && price % 1 == 0) {
      return NumberFormat('#,##0', locale).format(price);
    }

    final pattern = (dec == 4) ? '#,##0.0000' : '#,##0.000';
    return NumberFormat(pattern, locale).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buyPrice = widget.priceItem.buyPrice;
    final sellPrice = widget.priceItem.sellPrice > 0 ? widget.priceItem.sellPrice : buyPrice * 1.004;

    final isSameCurrency = widget.currencyCode.toUpperCase() == (widget.baseCurrencyCode ?? '').toUpperCase();
    final effectiveBaseCode = isSameCurrency
        ? (widget.currencyCode.toUpperCase() == 'EUR' ? 'USD' : 'EUR')
        : (widget.baseCurrencyCode ?? widget.baseCurrencySymbol);

    return Bounceable(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          context.push('/price-detail', extra: {'item': widget.priceItem});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isPinned
                ? AppColors.gold.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: widget.isPinned ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isPinned
                  ? AppColors.gold.withValues(alpha: 0.08)
                  : (isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03)),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              child: Center(
                child: CountryFlagWidget(
                  flagEmoji: widget.flagEmoji,
                  countryCode: widget.currencyCode,
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Name & Code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        CurrencyUtils.getCompactPairTitle(
                          widget.currencyCode,
                          effectiveBaseCode,
                          context: context,
                        ),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: widget.isPinned
                              ? AppColors.gold.withValues(alpha: 0.2)
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.currencyCode,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: widget.isPinned
                                ? AppColors.gold
                                : (isDark ? Colors.white70 : AppColors.darkGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    CurrencyUtils.getCompactFormula(
                      widget.currencyCode,
                      buyPrice,
                      effectiveBaseCode,
                      context: context,
                      decimals: widget.decimals,
                    ),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),

            // Buy / Sell prices with ambient pulse
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final opacity = _ambientAnimation.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${'currency_buy'.tr()}: ',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            color: isDark ? Colors.white54 : AppColors.mutedText,
                          ),
                        ),
                        Text(
                          _formatPrice(buyPrice, context),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: (isDark ? Colors.white : AppColors.darkGreen).withValues(alpha: opacity),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${'currency_sell'.tr()}: ',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 8.5,
                            color: isDark ? Colors.white54 : AppColors.mutedText,
                          ),
                        ),
                        Text(
                          _formatPrice(sellPrice, context),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold.withValues(alpha: opacity),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(width: 6),

            // Pin button
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTogglePin();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.isPinned
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 20,
                  color: widget.isPinned
                      ? AppColors.gold
                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
