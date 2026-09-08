import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'dart:async';
import 'dart:ui';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/local_market_calculator.dart';
import 'package:gold_sham/core/utils/currency_utils.dart';

class LivePriceTicker extends ConsumerStatefulWidget {
  const LivePriceTicker({super.key});

  @override
  ConsumerState<LivePriceTicker> createState() => _LivePriceTickerState();
}

class _LivePriceTickerState extends ConsumerState<LivePriceTicker> {
  late ScrollController _scrollController;
  Timer? _timer;
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollPosition += 0.8;
        if (_scrollPosition >= _scrollController.position.maxScrollExtent) {
          _scrollPosition = 0;
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(_scrollPosition);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);
    final countryProviderInstance = ref.watch(countryProvider);
    final currentCountry = countryProviderInstance.selectedCountry;
    final marketData = countryProviderInstance.currentMarketData;
    final currencySymbol = CurrencyUtils.getSymbol(currentCountry.currencyCode, context: context);
    
    // Check if enabled from backend
    if (!priceService.shouldShow('homeShowPriceTicker', defaultValue: true)) {
      return const SizedBox.shrink();
    }
    
    final List<PriceItem> tickerItems = [];

    final bool isMatching = marketData != null &&
        (marketData['countryCode']?.toString().toUpperCase() == currentCountry.code.toUpperCase());
    final effectiveMarketData = isMatching
        ? marketData
        : LocalMarketCalculator().calculateMarketData(currentCountry);

    // 1. Local market items for selected country (Gold Karats, Ounces, Silver)
    if (effectiveMarketData != null && effectiveMarketData['items'] is List) {
      final List<dynamic> localItems = effectiveMarketData['items'];
      for (final raw in localItems) {
        final buyPrice = (raw['buyPrice'] as num?)?.toDouble() ?? 0.0;
        if (buyPrice > 0) {
          tickerItems.add(PriceItem(
            id: raw['id']?.toString() ?? '${currentCountry.code}_${raw['karat'] ?? 'item'}',
            title: raw['title']?.toString() ?? raw['name']?.toString() ?? '',
            buyPrice: buyPrice,
            sellPrice: (raw['sellPrice'] as num?)?.toDouble() ?? buyPrice,
            currency: raw['currency']?.toString() ?? currencySymbol,
            metalType: raw['metalType']?.toString() ?? 'gold',
            trend: raw['trend'] != null && raw['trend'] is int
                ? Trend.values[(raw['trend'] as int).clamp(0, 2)]
                : Trend.stable,
          ));
        }
      }
    }

    // Fallback: match country code prefix or currency in currentPrices
    if (tickerItems.isEmpty) {
      final prefix = '${currentCountry.code.toLowerCase()}_';
      final matching = priceService.currentPrices.where((p) {
        return p.id.toLowerCase().startsWith(prefix) ||
            p.currency.toUpperCase() == currentCountry.currencyCode.toUpperCase() ||
            p.currency == currencySymbol;
      }).toList();
      tickerItems.addAll(matching);
    }

    // 2. Local USD exchange rate for selected country if present
    if (effectiveMarketData != null && effectiveMarketData['currencies'] is List) {
      final List<dynamic> currencies = effectiveMarketData['currencies'];
      final usdRate = currencies.where((c) {
        final code = (c['code'] ?? c['id'] ?? '').toString().toUpperCase();
        return code.contains('USD');
      }).firstOrNull;
      if (usdRate != null) {
        final rate = (usdRate['buyPrice'] ?? usdRate['rate'] as num?)?.toDouble() ?? 0.0;
        if (rate > 0) {
          tickerItems.add(PriceItem(
            id: 'usd_local_rate',
            title: 'USD / ${currentCountry.currencyCode}',
            buyPrice: rate,
            sellPrice: rate,
            currency: currencySymbol,
            metalType: 'currency',
          ));
        }
      }
    }

    // 3. Global benchmarks: XAU/USD (Gold Ounce) & XAG/USD (Silver Ounce)
    final xau = priceService.currentPrices.where((p) => p.id == 'xau_usd').firstOrNull;
    if (xau != null && xau.buyPrice > 0) {
      tickerItems.add(xau);
    }
    final xag = priceService.currentPrices.where((p) => p.id == 'xag_usd').firstOrNull;
    if (xag != null && xag.buyPrice > 0) {
      tickerItems.add(xag);
    }

    if (tickerItems.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border(
              bottom: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.gold,
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Icon(Icons.show_chart, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'live_prices'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: null, // Infinite scroll
                  itemBuilder: (context, index) {
                    final item = tickerItems[index % tickerItems.length];
                    return _buildTickerItem(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTickerItem(PriceItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.translatedTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          LivePriceWidget(
            price: item.buyPrice,
            currency: item.currency,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          // A separator dot
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Icon(Icons.circle, size: 4, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}
