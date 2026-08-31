import 'package:flutter/material.dart';
import '../models/country_model.dart';
import '../../core/services/http_api_service.dart';

/// Local market calculation engine.
///
/// When the backend `/api/markets/:code` endpoint is unavailable
/// (e.g. Market collection not seeded), this service calculates
/// gold/silver prices + currency exchange rates locally using:
///
/// **Data Sources:**
/// 1. Gold/Silver ounce prices → `/api/prices` (scraped from multiple global sources)
/// 2. FX exchange rates → `/api/currencies/cross-rates` (live from Fawaz Ahmed / Frankfurter / Open ER APIs)
///
/// These are the same sources used by the backend `multiMarketService.js`.
class LocalMarketCalculator {
  static final LocalMarketCalculator _instance = LocalMarketCalculator._();
  factory LocalMarketCalculator() => _instance;
  LocalMarketCalculator._();

  // Fallback FX rates (used when live fetch fails)
  Map<String, double> _fxRates = {
    'USD': 1.0,
    'DZD': 134.5,
    'EGP': 50.0,
    'SAR': 3.75,
    'AED': 3.6725,
    'IQD': 1310.0,
    'KWD': 0.307,
    'QAR': 3.64,
    'JOD': 0.709,
    'LBP': 89500.0,
    'LYD': 4.85,
    'TRY': 38.5,
    'EUR': 0.93,
    'SYP': 13500.0,
    'BHD': 0.376,
    'OMR': 0.385,
  };

  double _goldOunceUSD = 0;
  double _silverOunceUSD = 0;
  DateTime? _lastUpdate;
  String _goldSource = 'fallback';
  String _fxSource = 'fallback';

  /// All scraped prices from /api/prices (keyed by id)
  Map<String, Map<String, dynamic>> _scrapedPrices = {};

  DateTime? get lastUpdate => _lastUpdate;
  String get goldSource => _goldSource;
  String get fxSource => _fxSource;

  /// Look up a scraped price by id. Returns null if not found.
  Map<String, dynamic>? getScrapedPrice(String id) => _scrapedPrices[id];

  /// Fetch live gold ounce price, FX rates, and country-specific prices.
  Future<void> refreshData(HttpApiService httpService) async {
    try {
      // 1. Get ALL prices from /api/prices (gold, silver, currencies, scraped country prices)
      final pricesResponse = await httpService.get('/api/prices');
      if (pricesResponse is List) {
        for (final p in pricesResponse) {
          final id = p['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          // Store every price for lookup
          _scrapedPrices[id] = Map<String, dynamic>.from(p);

          if (id == 'xau_usd' && p['buyPrice'] != null) {
            _goldOunceUSD = (p['buyPrice'] as num).toDouble();
            _goldSource = 'API /api/prices (xau_usd)';
          }
          if (id == 'xag_usd' && p['buyPrice'] != null) {
            _silverOunceUSD = (p['buyPrice'] as num).toDouble();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch prices: $e');
    }

    try {
      // 2. Get FX rates from /api/currencies/cross-rates
      final fxResponse = await httpService.get('/api/currencies/cross-rates');
      if (fxResponse is Map && fxResponse['rates'] != null) {
        final rates = fxResponse['rates'] as Map<String, dynamic>;
        for (final entry in rates.entries) {
          _fxRates[entry.key] = (entry.value as num).toDouble();
        }
        _fxSource = 'API /api/currencies/cross-rates (live)';
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch FX rates: $e');
    }

    _lastUpdate = DateTime.now();
    debugPrint('📊 LocalMarketCalculator refreshed: Gold=\$$_goldOunceUSD, Silver=\$$_silverOunceUSD, ScrapedPrices=${_scrapedPrices.length}, FX=$_fxSource');
  }

  /// Calculate market data for a country, mimicking the backend shape exactly.
  Map<String, dynamic>? calculateMarketData(CountryModel country) {
    if (_goldOunceUSD <= 0) return null;

    final code = country.code.toUpperCase();
    final lowerCode = code.toLowerCase();
    final currencyCode = country.currencyCode;
    final currencySymbol = country.currencySymbol;
    final rate = _fxRates[currencyCode] ?? _fxRates[code] ?? 1.0;

    final double spreadPercent = 0.5 / 100;
    final double g24USD = _goldOunceUSD / 31.1035;
    final double silverGramUSD = (_silverOunceUSD > 0 ? _silverOunceUSD : 31.5) / 31.1035;

    /// Try to use scraped price if available (e.g. sy_gold_21, tr_gold_24)
    /// Falls back to calculated price if not found.
    Map<String, dynamic> getGramPrice(String karatStr, double karatFraction) {
      final calcSpread = spreadPercent;
      final baseUSD = g24USD * karatFraction;
      final baseLocal = baseUSD * rate;
      final calcBuy = double.parse((baseLocal * (1 - calcSpread)).toStringAsFixed(2));
      final calcSell = double.parse((baseLocal * (1 + calcSpread)).toStringAsFixed(2));
      final usdPrice = double.parse(baseUSD.toStringAsFixed(2));

      // Check for scraped price (e.g. 'sy_gold_21' or 'tr_gold_24')
      final scrapedId = '${lowerCode}_gold_$karatStr';
      final scraped = _scrapedPrices[scrapedId];
      if (scraped != null && scraped['buyPrice'] != null && (scraped['buyPrice'] as num) > 0) {
        return {
          'buyPrice': (scraped['buyPrice'] as num).toDouble(),
          'sellPrice': (scraped['sellPrice'] as num?)?.toDouble() ?? (scraped['buyPrice'] as num).toDouble(),
          'usdPrice': usdPrice,
        };
      }

      return {'buyPrice': calcBuy, 'sellPrice': calcSell, 'usdPrice': usdPrice};
    }

    final k24 = getGramPrice('24', 1.0);
    final k22 = getGramPrice('22', 22 / 24);
    final k21 = getGramPrice('21', 21 / 24);
    final k18 = getGramPrice('18', 18 / 24);
    final k14 = getGramPrice('14', 14 / 24);

    final List<Map<String, dynamic>> items = [];

    // ════════════════════════════════════════════
    // 1. GOLD KARAT ITEMS
    // ════════════════════════════════════════════
    items.add({
      'id': '${code.toLowerCase()}_gold_24k',
      'title': 'ذهب عيار 24',
      'subtitle': 'ذهب خالص 999.9',
      'karat': '24',
      ...k24,
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold',
      'countryCode': code,
      'isPopular': ['SA', 'AE', 'KW', 'QA'].contains(code),
    });

    items.add({
      'id': '${code.toLowerCase()}_gold_22k',
      'title': 'ذهب عيار 22',
      'subtitle': 'عيار المجوهرات والسبائك',
      'karat': '22',
      ...k22,
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold',
      'countryCode': code,
    });

    items.add({
      'id': '${code.toLowerCase()}_gold_21k',
      'title': 'ذهب عيار 21',
      'subtitle': 'الأكثر تداولاً في الأسواق',
      'karat': '21',
      ...k21,
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold',
      'countryCode': code,
      'isPopular': ['EG', 'IQ', 'JO', 'SY', 'DZ', 'LY', 'LB'].contains(code),
    });

    items.add({
      'id': '${code.toLowerCase()}_gold_18k',
      'title': 'ذهب عيار 18',
      'subtitle': 'عيار المشغولات الإيطالية',
      'karat': '18',
      ...k18,
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold',
      'countryCode': code,
      'isPopular': ['EG', 'LB', 'DZ'].contains(code),
    });

    items.add({
      'id': '${code.toLowerCase()}_gold_14k',
      'title': 'ذهب عيار 14',
      'subtitle': 'المشغولات الخفيفة',
      'karat': '14',
      ...k14,
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold',
      'countryCode': code,
    });

    // ════════════════════════════════════════════
    // 2. GOLD UNITS (Ounce, Kilo, Country-specific)
    // ════════════════════════════════════════════
    final ounceLocalBuy = double.parse((_goldOunceUSD * rate * (1 - spreadPercent)).toStringAsFixed(2));
    final ounceLocalSell = double.parse((_goldOunceUSD * rate * (1 + spreadPercent)).toStringAsFixed(2));
    items.add({
      'id': '${code.toLowerCase()}_gold_ounce',
      'title': 'أونصة الذهب',
      'subtitle': '31.1035 غرام (عيار 24)',
      'buyPrice': ounceLocalBuy,
      'sellPrice': ounceLocalSell,
      'usdPrice': double.parse(_goldOunceUSD.toStringAsFixed(2)),
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold_ounce',
      'countryCode': code,
    });

    final kiloLocalBuy = double.parse((_goldOunceUSD * 32.1507 * rate * (1 - spreadPercent * 0.5)).toStringAsFixed(2));
    final kiloLocalSell = double.parse((_goldOunceUSD * 32.1507 * rate * (1 + spreadPercent * 0.5)).toStringAsFixed(2));
    items.add({
      'id': '${code.toLowerCase()}_gold_kilo',
      'title': 'كيلو الذهب',
      'subtitle': '1000 غرام (سبيكة 24K)',
      'buyPrice': kiloLocalBuy,
      'sellPrice': kiloLocalSell,
      'usdPrice': double.parse((_goldOunceUSD * 32.1507).toStringAsFixed(2)),
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold_kilo',
      'countryCode': code,
    });

    // Country-specific special items
    _addCountrySpecificItems(items, code, k24, k21, k18, currencySymbol, currencyCode);

    // ════════════════════════════════════════════
    // 3. SILVER
    // ════════════════════════════════════════════
    items.add({
      'id': '${code.toLowerCase()}_silver_gram',
      'title': 'غرام الفضة النقية',
      'subtitle': 'فضة عيار 999',
      'buyPrice': double.parse((silverGramUSD * rate * 0.97).toStringAsFixed(2)),
      'sellPrice': double.parse((silverGramUSD * rate * 1.03).toStringAsFixed(2)),
      'usdPrice': double.parse(silverGramUSD.toStringAsFixed(2)),
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'silver',
      'countryCode': code,
    });

    // ════════════════════════════════════════════
    // 4. CURRENCY EXCHANGE RATES
    // ════════════════════════════════════════════
    _addCurrencyItems(items, code, currencyCode, currencySymbol, rate);

    return {
      'countryCode': code,
      'countryName': country.name,
      'flagEmoji': country.flag,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'fxRateToUSD': rate,
      'isMarketEnabled': true,
      'lastUpdate': DateTime.now().toIso8601String(),
      'items': items,
      '_isLocalCalculation': true,
      '_dataSources': {
        'goldPrice': _goldSource,
        'fxRates': _fxSource,
        'lastRefresh': _lastUpdate?.toIso8601String(),
      },
    };
  }

  /// Add country-specific gold items (coins, units, etc.)
  void _addCountrySpecificItems(
    List<Map<String, dynamic>> items,
    String code,
    Map<String, dynamic> k24,
    Map<String, dynamic> k21,
    Map<String, dynamic> k18,
    String currencySymbol,
    String currencyCode,
  ) {
    if (code == 'EG') {
      final poundBuy = double.parse((k21['buyPrice'] * 8).toStringAsFixed(2));
      final poundSell = double.parse((k21['sellPrice'] * 8).toStringAsFixed(2));
      items.add({
        'id': 'eg_gold_pound', 'title': 'الجنيه الذهب',
        'subtitle': '8 غرام عيار 21',
        'buyPrice': poundBuy, 'sellPrice': poundSell,
        'usdPrice': double.parse((k21['usdPrice'] * 8).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code, 'isPopular': true,
      });
      items.add({
        'id': 'eg_half_pound', 'title': 'نصف جنيه ذهب',
        'subtitle': '4 غرام عيار 21',
        'buyPrice': double.parse((poundBuy / 2).toStringAsFixed(2)),
        'sellPrice': double.parse((poundSell / 2).toStringAsFixed(2)),
        'usdPrice': double.parse(((k21['usdPrice'] * 8) / 2).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code,
      });
    } else if (code == 'IQ') {
      final mBuy = double.parse((k21['buyPrice'] * 5).toStringAsFixed(0));
      final mSell = double.parse((k21['sellPrice'] * 5).toStringAsFixed(0));
      items.add({
        'id': 'iq_mithqal_gulf', 'title': 'مثقال الذهب الخليجي (21)',
        'subtitle': '5 غرام عيار 21 خليجي وبارس',
        'buyPrice': mBuy, 'sellPrice': mSell,
        'usdPrice': double.parse((k21['usdPrice'] * 5).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_unit', 'countryCode': code, 'isPopular': true,
      });
      items.add({
        'id': 'iq_mithqal_local', 'title': 'مثقال الذهب العراقي (21)',
        'subtitle': '5 غرام عيار 21 صياغة محلية',
        'buyPrice': double.parse((mBuy * 0.98).toStringAsFixed(0)),
        'sellPrice': double.parse((mSell * 0.98).toStringAsFixed(0)),
        'usdPrice': double.parse((k21['usdPrice'] * 5 * 0.98).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_unit', 'countryCode': code,
      });
    } else if (code == 'AE' || code == 'KW') {
      final tolaBuy = double.parse((k24['buyPrice'] * 11.6638).toStringAsFixed(2));
      final tolaSell = double.parse((k24['sellPrice'] * 11.6638).toStringAsFixed(2));
      items.add({
        'id': '${code.toLowerCase()}_gold_tola', 'title': 'تولة الذهب',
        'subtitle': '11.66 غرام (عيار 24)',
        'buyPrice': tolaBuy, 'sellPrice': tolaSell,
        'usdPrice': double.parse((k24['usdPrice'] * 11.6638).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_unit', 'countryCode': code, 'isPopular': true,
      });
    } else if (code == 'JO') {
      items.add({
        'id': 'jo_rashadi_lira', 'title': 'الليرة الرشادية',
        'subtitle': '7 غرام عيار 21',
        'buyPrice': double.parse((k21['buyPrice'] * 7).toStringAsFixed(2)),
        'sellPrice': double.parse((k21['sellPrice'] * 7).toStringAsFixed(2)),
        'usdPrice': double.parse((k21['usdPrice'] * 7).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code, 'isPopular': true,
      });
      items.add({
        'id': 'jo_english_lira', 'title': 'الليرة الإنجليزية',
        'subtitle': '8 غرام عيار 21 (جورج / فكتوريا)',
        'buyPrice': double.parse((k21['buyPrice'] * 8).toStringAsFixed(2)),
        'sellPrice': double.parse((k21['sellPrice'] * 8).toStringAsFixed(2)),
        'usdPrice': double.parse((k21['usdPrice'] * 8).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code, 'isPopular': true,
      });
    } else if (code == 'LY' || code == 'DZ') {
      items.add({
        'id': '${code.toLowerCase()}_scrap_18k', 'title': 'ذهب كسر (عيار 18)',
        'subtitle': 'سعر شراء المستعمل من الزبون',
        'buyPrice': double.parse((k18['buyPrice'] * 0.985).toStringAsFixed(2)),
        'sellPrice': double.parse((k18['sellPrice'] * 0.985).toStringAsFixed(2)),
        'usdPrice': double.parse((k18['usdPrice'] * 0.985).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_scrap', 'countryCode': code, 'isPopular': true,
      });
    }
  }

  /// Add currency exchange rate items (matches backend multiMarketService logic).
  void _addCurrencyItems(
    List<Map<String, dynamic>> items,
    String code,
    String currencyCode,
    String currencySymbol,
    double localRate,
  ) {
    const majorCurrencies = ['USD', 'EUR', 'TRY', 'SYP', 'SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR'];
    const currencyNames = {
      'USD': 'الدولار الأمريكي',
      'EUR': 'اليورو الأوروبي',
      'TRY': 'الليرة التركية',
      'SYP': 'الليرة السورية',
      'SAR': 'الريال السعودي',
      'AED': 'الدرهم الإماراتي',
      'KWD': 'الدينار الكويتي',
      'QAR': 'الريال القطري',
      'BHD': 'الدينار البحريني',
      'OMR': 'الريال العماني',
    };

    for (final targetCurr in majorCurrencies) {
      if (targetCurr == currencyCode) continue; // Skip self

      final targetRateToUsd = _fxRates[targetCurr] ?? 1.0;

      // Cross rate: 1 TargetCurrency = X LocalCurrency
      // localRate = how many local units per 1 USD
      // targetRateToUsd = how many target units per 1 USD
      // crossRate = localRate / targetRateToUsd
      final crossRate = localRate / targetRateToUsd;

      items.add({
        'id': '${code.toLowerCase()}_fx_${targetCurr.toLowerCase()}',
        'title': 'سعر صرف ${currencyNames[targetCurr] ?? targetCurr} مقابل $currencySymbol',
        'subtitle': '1 $targetCurr = ${crossRate.toStringAsFixed(3)} $currencyCode',
        'buyPrice': double.parse((crossRate * 0.998).toStringAsFixed(3)),
        'sellPrice': double.parse((crossRate * 1.002).toStringAsFixed(3)),
        'usdPrice': double.parse((1 / targetRateToUsd).toStringAsFixed(4)),
        'currency': currencySymbol,
        'currencyCode': currencyCode,
        'metalType': 'currency',
        'countryCode': code,
      });
    }
  }
}
