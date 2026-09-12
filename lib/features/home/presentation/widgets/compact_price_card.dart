import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../pages/price_detail_page.dart';
import 'smart_alerts_sheet.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../../../../core/utils/currency_utils.dart';

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
    final double displayLocalPrice =
        widget.localPrice ?? widget.priceItem.buyPrice;
    final String currencySymbol = CurrencyUtils.getSymbol(
        widget.localCurrencySymbol ?? widget.priceItem.currency,
        id: widget.priceItem.id,
        context: context);
    final double displayUsdPrice = widget.usdPrice ?? 0.0;
    final double sellPrice = widget.priceItem.sellPrice > 0 ? widget.priceItem.sellPrice : displayLocalPrice;
    final bool isUsdCurrency = currencySymbol == r'$' || 
        currencySymbol.toUpperCase() == 'USD' || 
        widget.priceItem.currency.toUpperCase() == 'USD';

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
                    : (isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.04)),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // 1. Karat Badge & Title
                Hero(
                  tag: 'icon_${widget.priceItem.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: _buildKaratBadge(widget.priceItem),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'title_${widget.priceItem.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            widget.priceItem.translatedTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.0,
                              color: isDark ? Colors.white : AppColors.primaryText,
                              fontFamily: 'Cairo',
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          FavoriteToggleButton(priceId: widget.priceItem.id, size: 16),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              SmartAlertsSheet.show(context, preselectedItem: widget.priceItem);
                            },
                            child: const Icon(Icons.notifications_none_rounded, size: 16, color: AppColors.mutedText),
                          ),
                          if (widget.isFeatured) ...[
                            const SizedBox(width: 4),
                            Text(
                              'auto_str_124'.tr(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Buy Column (الشراء)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'auto_str_361'.tr().replaceAll(':', '').trim(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LivePriceWidget(
                              price: displayLocalPrice,
                              currency: '',
                              style: TextStyle(
                                fontSize: 14.5,
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
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isUsdCurrency && displayUsdPrice > 0)
                        Text(
                          '≈ \$${CurrencyUtils.formatLocalizedNumber(displayUsdPrice, context, decimals: 1)}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mutedText,
                            fontFamily: 'Cairo',
                          ),
                        ),
                    ],
                  ),
                ),

                // Vertical Separator
                Container(
                  height: 32,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),

                // 3. Sell Column (المبيع)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'auto_str_343'.tr().replaceAll(':', '').trim(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyUtils.formatLocalizedNumber(sellPrice, context, decimals: 2, compactLarge: sellPrice >= 100000),
                              style: TextStyle(
                                fontSize: 14.5,
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
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isUsdCurrency && displayUsdPrice > 0)
                        Text(
                          '≈ \$${CurrencyUtils.formatLocalizedNumber(((sellPrice / (displayLocalPrice > 0 ? displayLocalPrice : 1)) * displayUsdPrice), context, decimals: 1)}',
                          style: const TextStyle(
                            fontSize: 9,
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
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
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

