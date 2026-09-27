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
    // Allow EUR vs USD card in European market even though selectedCountry currency is EUR
    final isEurVsUsdInEurope = selectedCountry.currencyCode.toUpperCase() == 'EUR' &&
        cCode.toUpperCase() == 'EUR' &&
        cItem.id.toLowerCase().contains('_eur');

    if (cCode.toUpperCase() == selectedCountry.currencyCode.toUpperCase() && !isEurVsUsdInEurope) {
      continue;
    }

    final alreadyExists = countryCurrencies.any((existing) =>
        existing.id == cItem.id ||
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

    // ── USD live sync (most important: avoids old-lira display bug) ──
    final syUsdLive = allPrices.where((p) => p.id == 'sy_usd').firstOrNull;
    if (syUsdLive != null && syUsdLive.buyPrice > 0) {
      final existingUsdIdx = countryCurrencies.indexWhere((p) => extractCurrencyCode(p) == 'USD');
      final rawBuy = syUsdLive.buyPrice;
      final rawSell = syUsdLive.sellPrice;
      final buy = rawBuy > 1000 ? rawBuy / 100 : rawBuy;
      final sell = rawSell > 1000 ? rawSell / 100 : (rawSell > 0 ? rawSell : buy * 1.004);
      const spread = 0.002;
      final liveUsd = PriceItem(
        id: 'sy_fx_usd',
        title: CurrencyUtils.getCompactPairTitle('USD', 'SYP'),
        buyPrice: double.parse((buy * (1 - spread)).toStringAsFixed(2)),
        sellPrice: double.parse((sell > buy ? sell * (1 + spread) : buy * (1 + spread)).toStringAsFixed(2)),
        currency: selectedCountry.localizedCurrencySymbol,
        metalType: 'currency',
        lastUpdate: syUsdLive.lastUpdate ?? DateTime.now(),
      );
      if (existingUsdIdx != -1) {
        countryCurrencies[existingUsdIdx] = liveUsd;
      } else {
        countryCurrencies.insert(0, liveUsd);
      }
    }

    // ── EUR live sync ──
    final syEurLive = allPrices.where((p) => p.id == 'sy_eur').firstOrNull;
    if (syEurLive != null && syEurLive.buyPrice > 0) {
      final existingEurIdx = countryCurrencies.indexWhere((p) => extractCurrencyCode(p) == 'EUR');
      final rawBuy = syEurLive.buyPrice;
      final rawSell = syEurLive.sellPrice;
      final buy = rawBuy > 1000 ? rawBuy / 100 : rawBuy;
      final sell = rawSell > 1000 ? rawSell / 100 : (rawSell > 0 ? rawSell : buy * 1.004);
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

  // 6. Guarantee absolute deduplication by unique ID
  final Set<String> seenIds = {};
  final List<PriceItem> uniqueCurrencies = [];
  for (final item in countryCurrencies) {
    if (seenIds.add(item.id)) {
      uniqueCurrencies.add(item);
    }
  }

  return uniqueCurrencies;
});

/// A master provider that returns EVERY single PriceItem across the entire app
/// This is specifically used by Favorites and Alerts to resolve IDs into actual PriceItems.
final masterAppPricesProvider = Provider<List<PriceItem>>((ref) {
  final allPrices = ref.watch(allPricesProvider);
  final calculator = LocalMarketCalculator();
  final countryProv = ref.watch(countryProvider);
  final priceService = ref.watch(priceServiceProvider);

  final Map<String, PriceItem> masterMap = {};

  // 1. Add all raw items
  for (final p in allPrices) {
    masterMap[p.id] = p;
  }

  // 2. Add synthesized currencies for current country
  final currCurrencies = ref.watch(countryCurrenciesProvider);
  for (final p in currCurrencies) {
    masterMap[p.id] = p;
  }

  // 3. Synthesize bullions and coins for ALL countries
  for (final country in countryProv.allCountries) {
    final calcData = calculator.calculateMarketData(country);
    final calcItems = (calcData?['items'] as List<dynamic>?) ?? [];
    
    for (final item in calcItems) {
      final p = PriceItem(
        id: item['id'] ?? '',
        title: item['title'] ?? item['name'] ?? '',
        buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
        sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
        currency: item['currency'] ?? country.localizedCurrencySymbol,
        metalType: item['metalType'] ?? 'gold',
        usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
      );
      if (p.id.isNotEmpty) masterMap[p.id] = p;
    }
    
    double k24Price = 0, k24Usd = 0, k22Price = 0, k22Usd = 0, k21Price = 0, k21Usd = 0;
    for (final item in calcItems) {
      final k = (item['karat'] ?? '').toString();
      if (k == '24') { k24Price = (item['buyPrice'] as num?)?.toDouble() ?? 0; k24Usd = (item['usdPrice'] as num?)?.toDouble() ?? 0; }
      if (k == '22') { k22Price = (item['buyPrice'] as num?)?.toDouble() ?? 0; k22Usd = (item['usdPrice'] as num?)?.toDouble() ?? 0; }
      if (k == '21') { k21Price = (item['buyPrice'] as num?)?.toDouble() ?? 0; k21Usd = (item['usdPrice'] as num?)?.toDouble() ?? 0; }
    }

    if (k24Price == 0) {
      k24Usd = calculator.goldOunceUSD / 31.1035;
      k24Price = k24Usd * (calculator.fxRates[country.currencyCode] ?? 1.0);
    }
    if (k22Price == 0) { k22Usd = k24Usd * (22/24); k22Price = k24Price * (22/24); }
    if (k21Price == 0) { k21Usd = k24Usd * (21/24); k21Price = k24Price * (21/24); }

    final currencySymbol = country.localizedCurrencySymbol;

    final bullionWeights = [
      {'id': '1g', 'key': 'bullion_1g', 'title': '1 غرام', 'grams': 1.0},
      {'id': '5g', 'key': 'bullion_5g', 'title': '5 غرام', 'grams': 5.0},
      {'id': '10g', 'key': 'bullion_10g', 'title': '10 غرام', 'grams': 10.0},
      {'id': '1_tola', 'key': 'one_tola', 'title': '1 تولة', 'grams': 11.66},
      {'id': '20g', 'key': 'bullion_20g', 'title': '20 غرام', 'grams': 20.0},
      {'id': '1oz', 'key': 'bullion_1oz', 'title': 'أونصة', 'grams': 31.1035},
      {'id': '50g', 'key': 'bullion_50g', 'title': '50 غرام', 'grams': 50.0},
      {'id': '5_tola', 'key': 'five_tola', 'title': '5 تولة', 'grams': 58.3},
      {'id': '100g', 'key': 'bullion_100g', 'title': '100 غرام', 'grams': 100.0},
      {'id': '1kg', 'key': 'bullion_1kg', 'title': '1 كيلو', 'grams': 1000.0},
    ];

    for (final b in bullionWeights) {
      final grams = b['grams'] as double;
      double buy = double.parse((k24Price * grams).toStringAsFixed(2));
      double sell = double.parse((buy * 1.008).toStringAsFixed(2));
      double usd = double.parse((k24Usd * grams).toStringAsFixed(2));
      
      // Override for Kilo using backend specific values (e.g. AltinAPI for TR)
      if (b['id'] == '1kg') {
        if (country.code.toUpperCase() == 'TR' && marketItems != null) {
          final trKilo = marketItems.firstWhere(
            (i) => i['id'] == 'tr_gold_kilo',
            orElse: () => null,
          );
          if (trKilo != null) {
            buy = (trKilo['buyPrice'] as num).toDouble();
            sell = (trKilo['sellPrice'] as num).toDouble();
            usd = (trKilo['usdPrice'] as num).toDouble();
          }
        } else if (country.code.toUpperCase() == 'GLOBAL') {
           final xauKg = allPrices.where((p) => p.id == 'xau_kg_usd').firstOrNull;
           if (xauKg != null && xauKg.buyPrice > 0) {
             buy = xauKg.buyPrice;
             sell = xauKg.sellPrice;
             usd = xauKg.usdPrice > 0 ? xauKg.usdPrice : xauKg.buyPrice;
           }
        }
      }

      final id = '${country.code.toLowerCase()}_bullion_${b['id']}';
      masterMap[id] = PriceItem(
        id: id,
        title: b['title'] as String,
        buyPrice: buy, sellPrice: sell, currency: currencySymbol, metalType: 'bullion', usdPrice: usd,
      );
    }

    final rawStandardCoins = [
      {'id': 'en_21', 'title': 'ليرة إنجليزية (8 غ)', 'grams': 8.0, 'price': k21Price, 'usd': k21Usd},
      {'id': 'en_22', 'title': 'ليرة إنجليزية (8 غ)', 'grams': 8.0, 'price': k22Price, 'usd': k22Usd},
      {'id': 'pound_21', 'title': 'جنيه ذهب (8 غ)', 'grams': 8.0, 'price': k21Price, 'usd': k21Usd},
      {'id': 'pound_22', 'title': 'جنيه ذهب (8 غ)', 'grams': 8.0, 'price': k22Price, 'usd': k22Usd},
      {'id': 'tr_gold_tam_new', 'title': 'ليرة تركية كاملة (7 غ)', 'grams': 7.0, 'price': k22Price, 'usd': k22Usd},
      {'id': 'tr_gold_yarim_new', 'title': 'نصف ليرة تركية (3.5 غ)', 'grams': 3.5, 'price': k22Price, 'usd': k22Usd},
      {'id': 'tr_gold_ceyrek_new', 'title': 'ربع ليرة تركية (1.75 غ)', 'grams': 1.75, 'price': k22Price, 'usd': k22Usd},
      {'id': 'tr_gold_ata_new', 'title': 'ليرة زينة عطا (7.2 غ)', 'grams': 7.2, 'price': k22Price, 'usd': k22Usd},
      {'id': 'lira_24', 'title': 'ليرة ذهبية (8 غ)', 'grams': 8.0, 'price': k24Price, 'usd': k24Usd},
    ];

    for (final c in rawStandardCoins) {
      final baseId = c['id'] as String;
      if (baseId.startsWith('tr_') && !priceService.isTurkishItemVisible(baseId)) continue;
      
      final id = baseId.startsWith('tr_') ? baseId : '${country.code.toLowerCase()}_$baseId';
      final grams = c['grams'] as double;
      final p = c['price'] as double;
      final u = c['usd'] as double;
      final buy = double.parse((p * grams).toStringAsFixed(2));
      final sell = double.parse((buy * 1.01).toStringAsFixed(2));
      final usd = double.parse((u * grams).toStringAsFixed(2));
      masterMap[id] = PriceItem(
        id: id,
        title: c['title'] as String,
        buyPrice: buy, sellPrice: sell, currency: currencySymbol, metalType: 'coin', usdPrice: usd,
      );
    }
  }

  return masterMap.values.toList();
});
