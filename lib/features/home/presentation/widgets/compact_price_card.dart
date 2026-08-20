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

class CompactPriceCard extends StatefulWidget {
  final PriceItem priceItem;
  final double? localPrice; // Price in country currency
  final String? localCurrencySymbol;
  final double? usdPrice;
  final bool isFeatured;
  final VoidCallback? onTap;

  const CompactPriceCard({
    super.key,
    required this.priceItem,
    this.localPrice,
    this.localCurrencySymbol,
    this.usdPrice,
    this.isFeatured = false,
    this.onTap,
  });

  @override
  State<CompactPriceCard> createState() => _CompactPriceCardState();
}

class _CompactPriceCardState extends State<CompactPriceCard>
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
  void didUpdateWidget(covariant CompactPriceCard oldWidget) {
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
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
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKaratBadge(widget.priceItem),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.priceItem.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isDark ? Colors.white : AppColors.primaryText,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.isFeatured)
                              const Text(
                                'auto_str_124'.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.mutedText),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          SmartAlertsSheet.show(context, preselectedItem: widget.priceItem);
                        },
                      ),
                      // Favorite button
                      FavoriteToggleButton(priceId: widget.priceItem.id),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x15000000)),
                  const SizedBox(height: 12),

                  // --- Row 2: Prominent Local Price & Global USD Subtext ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Main Local Price (Big & Bold)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              LivePriceWidget(
                                price: displayLocalPrice,
                                currency: '',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontFamily: 'Cairo',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currencySymbol,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          // Global USD Equivalent (Subtext)
                          if (displayUsdPrice > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.public, size: 12, color: AppColors.mutedText),
                                const SizedBox(width: 4),
                                Text(
                                  '≈ \$${displayUsdPrice.toStringAsFixed(2)} USD',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mutedText,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      // Buy / Sell Spread or Trend
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'auto_str_343'.tr(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mutedText,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  numberFormat.format(sellPrice),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.primaryText,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'شراء: ${numberFormat.format(displayLocalPrice)}',
                              style: const TextStyle(
                                fontSize: 11,
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
                  
                  // --- Row 3: Metrics (Purity, Open, High/Low) ---
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricBadge('auto_str_332'.tr(), _getPurity(widget.priceItem), Icons.diamond_outlined),
                      _buildMetricBadge('auto_str_313'.tr(), numberFormat.format(displayLocalPrice / (1 + (widget.priceItem.changePercentage / 100))), Icons.login_rounded),
                      _buildMetricBadge('auto_str_299'.tr(), '${numberFormat.format(displayLocalPrice * 1.002)} / ${numberFormat.format(displayLocalPrice * 0.998)}', Icons.swap_vert_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  String _getPurity(PriceItem item) {
    final id = item.id.toLowerCase();
    if (id.contains('24') || id.contains('ounce') || id.contains('xau') || id.contains('999')) return '999.9';
    if (id.contains('22')) return '916.6';
    if (id.contains('21')) return '875.0';
    if (id.contains('18')) return '750.0';
    if (id.contains('14')) return '583.3';
    if (id.contains('silver') || id.contains('xag')) return '999.0';
    if (id.contains('pt') || id.contains('plat')) return '999.5';
    return '---';
  }

  Widget _buildMetricBadge(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.primaryText,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
