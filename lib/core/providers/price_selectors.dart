import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/price_item.dart';
import '../../shared/services/price_service.dart';
import '../../shared/services/local_market_calculator.dart';
import '../utils/currency_utils.dart';
import 'country_provider.dart';

/// Raw list of all prices from the price service
final allPricesProvider = Provider<List<PriceItem>>((ref) {
  final priceService = ref.watch(priceServiceProvider);
  return priceService.currentPrices;
});

/// Memoized selector for global bullion items (Ounce & Kilo for Gold & Silver)
/// Sorted in exact canonical order: xau_usd, xag_usd, xau_kg_usd, xag_kg_usd
final globalGoldBullionProvider = Provider<List<PriceItem>>((ref) {
  final allPrices = ref.watch(allPricesProvider);
  const order = ['xau_usd', 'xag_usd', 'xau_kg_usd', 'xag_kg_usd'];

  final items = allPrices
      .where((p) => order.contains(p.id.trim().toLowerCase()))
      .toList();

  items.sort((a, b) => order
      .indexOf(a.id.toLowerCase())
      .compareTo(order.indexOf(b.id.toLowerCase())));

  return items;
});

/// Memoized selector for global karat gold prices (24k, 22k, 21k, 18k, 14k USD)
final globalKaratPricesProvider = Provider<List<PriceItem>>((ref) {
  final allPrices = ref.watch(allPricesProvider);
  const order = [
    'gold_24k_usd',
    'gold_22k_usd',
    'gold_21k_usd',
    'gold_18k_usd',
    'gold_14k_usd'
  ];

  final karats = allPrices
      .where((p) =>
          p.id.trim().toLowerCase().startsWith('gold_') &&
          p.id.trim().toLowerCase().endsWith('_usd'))
      .toList();

  karats.sort((a, b) {
    final indexA = order.indexOf(a.id.toLowerCase());
    final indexB = order.indexOf(b.id.toLowerCase());
    if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
    return a.id.compareTo(b.id);
  });

  return karats;
});

/// Memoized selector for Syrian gold prices and coins
final syrianGoldPricesProvider = Provider<List<PriceItem>>((ref) {
  final allPrices = ref.watch(allPricesProvider);
  const order = [
    'sy_gold_21',
    'sy_gold_18',
    'sy_gold_24',
    'sy_ounce',
    'sy_lira_rashadi',
    'sy_lira_english',
  ];

  final items = allPrices
      .where((p) =>
          p.id.startsWith('sy_gold_') ||
          p.id == 'sy_ounce' ||
          p.id.startsWith('sy_lira_'))
      .toList();

  items.sort((a, b) {
    final idxA = order.indexOf(a.id.toLowerCase());
    final idxB = order.indexOf(b.id.toLowerCase());
    if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
    if (idxA != -1) return -1;
    if (idxB != -1) return 1;
    return a.id.compareTo(b.id);
  });

  return items;
});

/// Memoized selector for all currency exchange items
final currencyPricesProvider = Provider<List<PriceItem>>((ref) {
  final allPrices = ref.watch(allPricesProvider);
  return allPrices
      .where((p) =>
          p.metalType == 'currency' ||
          p.id.startsWith('sy_usd') ||
          p.id.startsWith('sy_eur') ||
          p.id.startsWith('sy_try') ||
          p.id.startsWith('sy_sar'))
      .toList();
});

/// Helper to extract currency code from price id (e.g., 'sa_fx_eur' -> 'EUR', 'tr_curr_eur' -> 'EUR', 'sy_eur' -> 'EUR')
String extractCurrencyCode(PriceItem item) {
  final id = item.id.toLowerCase();
  const known = [
    'usd', 'eur', 'gbp', 'sar', 'aed', 'kwd', 'qar', 'bhd', 'omr', 'jod',
    'egp', 'try', 'syp', 'mad', 'ils', 'cad', 'aud', 'chf', 'mru', 'sos',
    'lyd', 'dzd', 'tnd', 'iqd', 'lbp', 'yer', 'sdg'
  ];
  final parts = id.split('_');
  for (final part in parts.reversed) {
    if (known.contains(part)) return part.toUpperCase();
  }
  return parts.last.toUpperCase();
}

/// Memoized selector for country-specific synthesized currency exchange rates.
/// Synthesizes official market items with local market calculation to guarantee
/// full currency coverage sorted in standard financial priority order,
/// and strictly guarantees a 1 EUR card is present for every market.
final countryCurrenciesProvider = Provider<List<PriceItem>>((ref) {
  final countryProv = ref.watch(countryProvider);
  final selectedCountry = countryProv.selectedCountry;
  final marketData = countryProv.currentMarketData;

  // 1. Validation: ensure market data matches selected country to prevent momentary desync
  final isMatchingCountry = marketData != null &&
      (marketData['countryCode']?.toString().toUpperCase() == selectedCountry.code.toUpperCase());
  final List<dynamic> rawItems = isMatchingCountry ? (marketData['items'] ?? []) : [];

  final List<PriceItem> countryCurrencies = rawItems
      .where((item) => item['metalType'] == 'currency' || item['id']?.toString().contains('_fx_') == true)
      .map((item) => PriceItem(
            id: item['id'],
            title: item['title'],
            buyPrice: (item['buyPrice'] ?? 0).toDouble(),
            sellPrice: (item['sellPrice'] ?? 0).toDouble(),
            currency: item['currency'] ?? selectedCountry.localizedCurrencySymbol,
            metalType: 'currency',
            lastUpdate: DateTime.now(),
          ))
      .toList();

  // 2. Full Multi-Currency Suite Synthesis via LocalMarketCalculator
  final calculator = LocalMarketCalculator();
  final calcData = calculator.calculateMarketData(selectedCountry);
  final calcItems = (calcData?['items'] as List<dynamic>?) ?? [];
  final calcCurrencies = calcItems
      .where((item) => item['metalType'] == 'currency')
      .map((item) => PriceItem(
            id: item['id'],
            title: item['title'],
            buyPrice: (item['buyPrice'] ?? 0).toDouble(),
            sellPrice: (item['sellPrice'] ?? 0).toDouble(),
            currency: item['currency'] ?? selectedCountry.localizedCurrencySymbol,
            metalType: 'currency',
            lastUpdate: DateTime.now(),
          ))
      .toList();

  for (final cItem in calcCurrencies) {
    final cCode = extractCurrencyCode(cItem);
    if (cCode.toUpperCase() == selectedCountry.currencyCode.toUpperCase()) continue;

    final alreadyExists = countryCurrencies.any((existing) =>
        extractCurrencyCode(existing).toUpperCase() == cCode.toUpperCase());
    if (!alreadyExists) {
      countryCurrencies.add(cItem);
    }
  }

  // 3. Absolute Guarantee: 1 EUR card MUST ALWAYS exist for EVERY market!
  final bool hasEur = countryCurrencies.any((item) => extractCurrencyCode(item) == 'EUR');
  if (!hasEur) {
    final eurItem = calculator.getEurPriceItemFor(selectedCountry);
    if (eurItem != null) {
      countryCurrencies.add(eurItem);
    }
  }

  // 4. Live Scraper Sync for Syria & Turkey if live market items are in allPrices
  if (selectedCountry.code.toUpperCase() == 'SY') {
    final allPrices = ref.watch(allPricesProvider);
    final syEurLive = allPrices.where((p) => p.id == 'sy_eur').firstOrNull;
    if (syEurLive != null && syEurLive.buyPrice > 0) {
      final existingEurIdx = countryCurrencies.indexWhere((p) => extractCurrencyCode(p) == 'EUR');
      final buy = syEurLive.buyPrice > 1000 ? syEurLive.buyPrice / 100 : syEurLive.buyPrice;
      final sell = syEurLive.sellPrice > 1000 ? syEurLive.sellPrice / 100 : (syEurLive.sellPrice > 0 ? syEurLive.sellPrice : buy * 1.004);
      final liveItem = PriceItem(
        id: 'sy_fx_eur',
        title: CurrencyUtils.getCompactPairTitle('EUR', 'SYP'),
        buyPrice: buy,
        sellPrice: sell,
        currency: selectedCountry.localizedCurrencySymbol,
        metalType: 'currency',
        lastUpdate: syEurLive.lastUpdate ?? DateTime.now(),
      );
      if (existingEurIdx != -1) {
        countryCurrencies[existingEurIdx] = liveItem;
      } else {
        countryCurrencies.add(liveItem);
      }
    }
  } else if (selectedCountry.code.toUpperCase() == 'TR') {
    final allPrices = ref.watch(allPricesProvider);
    final trEurLive = allPrices.where((p) => p.id == 'tr_curr_eur').firstOrNull;
    if (trEurLive != null && trEurLive.buyPrice > 0) {
      final existingEurIdx = countryCurrencies.indexWhere((p) => extractCurrencyCode(p) == 'EUR');
      final liveItem = PriceItem(
        id: 'tr_fx_eur',
        title: CurrencyUtils.getCompactPairTitle('EUR', 'TRY'),
        buyPrice: trEurLive.buyPrice,
        sellPrice: trEurLive.sellPrice > 0 ? trEurLive.sellPrice : trEurLive.buyPrice * 1.004,
        currency: selectedCountry.localizedCurrencySymbol,
        metalType: 'currency',
        lastUpdate: trEurLive.lastUpdate ?? DateTime.now(),
      );
      if (existingEurIdx != -1) {
        countryCurrencies[existingEurIdx] = liveItem;
      } else {
        countryCurrencies.add(liveItem);
      }
    }
  }

  // 5. Standard financial priority ordering: USD & EUR always first
  const currencyOrder = [
    'USD', 'EUR', 'GBP', 'SAR', 'AED', 'KWD',
    'QAR', 'BHD', 'OMR', 'JOD', 'EGP', 'TRY',
    'SYP', 'CAD', 'AUD', 'CHF'
  ];

  countryCurrencies.sort((a, b) {
    final codeA = extractCurrencyCode(a).toUpperCase();
    final codeB = extractCurrencyCode(b).toUpperCase();
    int idxA = currencyOrder.indexOf(codeA);
    int idxB = currencyOrder.indexOf(codeB);
    if (idxA == -1) idxA = 999;
    if (idxB == -1) idxB = 999;
    return idxA.compareTo(idxB);
  });

  return countryCurrencies;
});
