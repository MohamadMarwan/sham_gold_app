import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../pages/price_detail_page.dart';
import 'smart_alerts_sheet.dart';
import '../../../../shared/widgets/live_price_widget.dart';

class SquarePriceCard extends StatefulWidget {
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
  State<SquarePriceCard> createState() => _SquarePriceCardState();
}

class _SquarePriceCardState extends State<SquarePriceCard>
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
    final numberFormat = NumberFormat('#,##0.##', 'ar');
    final double displayLocalPrice =
        widget.localPrice ?? widget.priceItem.buyPrice;
    final String currencySymbol =
        widget.localCurrencySymbol ?? widget.priceItem.currency;
    final double displayUsdPrice = widget.usdPrice ?? 0.0;
    final double sellPrice = widget.priceItem.sellPrice > 0 ? widget.priceItem.sellPrice : displayLocalPrice * 1.008;

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PriceDetailPage(priceItem: widget.priceItem),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
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
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                              size: 18, color: AppColors.mutedText),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            SmartAlertsSheet.show(context,
                                preselectedItem: widget.priceItem);
                          },
                        ),
                        const SizedBox(width: 4),
                        FavoriteToggleButton(
                          priceId: widget.priceItem.id,
                          size: 18,
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
                      widget.priceItem.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Buy Price & Currency
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          LivePriceWidget(
                            price: displayLocalPrice,
                            currency: '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontFamily: 'Cairo',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            currencySymbol,
                            style: const TextStyle(
                              fontSize: 11,
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
                        '≈ \$${displayUsdPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                  ],
                ),

                // Bottom Row: Sell Price & Trend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مبيع: ${numberFormat.format(sellPrice)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      _buildTrendIcon(),
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

    if (widget.priceItem.trend == 0) {
      icon = Icons.trending_up_rounded;
      color = AppColors.success;
    } else if (widget.priceItem.trend == 1) {
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
