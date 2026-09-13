import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/country_model.dart';
import '../models/price_item.dart';
import '../../core/services/http_api_service.dart';
import '../../core/utils/currency_utils.dart';

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
  final Map<String, double> _fxRates = {
    'USD': 1.0,
    'DZD': 134.5,
    'EGP': 51.34,
    'SAR': 3.75,
    'AED': 3.6725,
    'IQD': 1310.0,
    'KWD': 0.308,
    'QAR': 3.64,
    'JOD': 0.709,
    'LBP': 89500.0,
    'LYD': 4.85,
    'TRY': 48.60,
    'EUR': 0.86,
    'SYP': 132.0,
    'BHD': 0.376,
    'OMR': 0.385,
    'MAD': 9.39,
    'ILS': 3.65,
    'TND': 3.12,
    'SDG': 600.0,
    'YER': 1950.0, // Commercial market exchange rate in Yemen (Aden/gold pricing)
    'MRU': 39.5,
    'SOS': 571.0,
    'GBP': 0.74,
    'CAD': 1.41,
    'AUD': 1.58,
    'CHF': 0.89,
    'JPY': 150.0,
    'CNY': 7.20,
  };

  static double _defaultFallbackFor(String currencyCode, String countryCode) {
    switch (currencyCode.toUpperCase()) {
      case 'MRU': return 39.5;
      case 'SOS': return 571.0;
      case 'ILS': return 3.65;
      case 'MAD': return 9.39;
      case 'BHD': return 0.376;
      case 'OMR': return 0.385;
      case 'KWD': return 0.308;
      case 'QAR': return 3.64;
      case 'JOD': return 0.709;
      case 'SAR': return 3.75;
      case 'AED': return 3.6725;
      case 'EGP': return 51.34;
      case 'IQD': return 1310.0;
      case 'DZD': return 134.5;
      case 'LBP': return 89500.0;
      case 'LYD': return 4.85;
      case 'TRY': return 48.60;
      case 'EUR': return 0.86;
      case 'GBP': return 0.74;
      case 'SYP': return 132.0;
      case 'TND': return 3.12;
      case 'SDG': return 600.0;
      case 'YER': return 1950.0;
      case 'CAD': return 1.41;
      case 'AUD': return 1.58;
      case 'CHF': return 0.89;
      case 'JPY': return 150.0;
      case 'CNY': return 7.20;
      default: return 1.0;
    }
  }

  double _goldOunceUSD = 4400.0;
  double _goldOunceSellUSD = 4400.80;
  double _silverOunceUSD = 65.0;
  double _silverOunceSellUSD = 65.10;
  DateTime? _lastUpdate;
  String _goldSource = 'fallback';
  String _fxSource = 'fallback';

  /// All scraped prices from /api/prices (keyed by id)
  final Map<String, Map<String, dynamic>> _scrapedPrices = {};

  DateTime? get lastUpdate => _lastUpdate;
  String get goldSource => _goldSource;
  String get fxSource => _fxSource;

  Map<String, double> get fxRates => Map.unmodifiable(_fxRates);
  double get goldOunceUSD => _goldOunceUSD;
  double get silverOunceUSD => _silverOunceUSD;

  /// Look up a scraped price by id. Returns null if not found.
  Map<String, dynamic>? getScrapedPrice(String id) => _scrapedPrices[id];

  /// Seamlessly update local calculation engine with live PriceItem stream
  void updateFromLivePrices(List<dynamic> prices) {
    if (prices.isEmpty) return;

    for (final p in prices) {
      final id = (p.id ?? '').toString().toLowerCase();
      if (id.isEmpty) continue;

      final buyPrice = (p.buyPrice as num?)?.toDouble() ?? 0.0;
      final sellPrice = (p.sellPrice as num?)?.toDouble() ?? buyPrice;

      _scrapedPrices[id] = {
        'id': p.id,
        'title': p.title,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'currency': p.currency,
        'metalType': p.metalType,
      };

      if (id == 'xau_usd' && buyPrice > 0) {
        _goldOunceUSD = buyPrice;
        _goldOunceSellUSD = sellPrice > buyPrice ? sellPrice : (buyPrice + 0.80);
        _goldSource = 'Live PriceService (xau_usd)';
      }
      if (id == 'xag_usd' && buyPrice > 0) {
        _silverOunceUSD = buyPrice;
        _silverOunceSellUSD = sellPrice > buyPrice ? sellPrice : (buyPrice + 0.10);
      }
      if (id == 'sy_usd' && buyPrice > 10) {
        _fxRates['SYP'] = buyPrice > 1000 ? buyPrice / 100 : buyPrice;
      }
      if (id == 'sy_eur' && buyPrice > 10) {
        _scrapedPrices['sy_eur'] = {
          'buyPrice': buyPrice > 1000 ? buyPrice / 100 : buyPrice,
          'sellPrice': sellPrice > 1000 ? sellPrice / 100 : sellPrice,
        };
      }
      if (id == 'tr_curr_eur' && buyPrice > 0) {
        _scrapedPrices['tr_curr_eur'] = {
          'buyPrice': buyPrice,
          'sellPrice': sellPrice,
        };
      }
    }
    _lastUpdate = DateTime.now();
  }

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
            final sPrice = (p['sellPrice'] as num?)?.toDouble() ?? 0.0;
            _goldOunceSellUSD = sPrice > _goldOunceUSD ? sPrice : (_goldOunceUSD + 0.80);
            _goldSource = 'API /api/prices (xau_usd)';
          }
          if (id == 'xag_usd' && p['buyPrice'] != null) {
            _silverOunceUSD = (p['buyPrice'] as num).toDouble();
            final sPrice = (p['sellPrice'] as num?)?.toDouble() ?? 0.0;
            _silverOunceSellUSD = sPrice > _silverOunceUSD ? sPrice : (_silverOunceUSD + 0.10);
          }
          if (id == 'sy_usd' && p['buyPrice'] != null) {
            final val = (p['buyPrice'] as num).toDouble();
            if (val > 10) _fxRates['SYP'] = val > 1000 ? val / 100 : val;
          }
          if (id == 'sy_eur' && p['buyPrice'] != null) {
            final val = (p['buyPrice'] as num).toDouble();
            final sVal = (p['sellPrice'] as num?)?.toDouble() ?? val;
            if (val > 10) {
              _scrapedPrices['sy_eur'] = {
                'buyPrice': val > 1000 ? val / 100 : val,
                'sellPrice': sVal > 1000 ? sVal / 100 : sVal,
              };
            }
          }
          if (id == 'tr_curr_eur' && p['buyPrice'] != null) {
            final val = (p['buyPrice'] as num).toDouble();
            final sVal = (p['sellPrice'] as num?)?.toDouble() ?? val;
            if (val > 0) {
              _scrapedPrices['tr_curr_eur'] = {
                'buyPrice': val,
                'sellPrice': sVal,
              };
            }
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
          final upperKey = entry.key.toUpperCase();
          double val = (entry.value as num).toDouble();
          if (upperKey == 'SYP' && val > 1000) {
            val = val / 100;
          }
          if (upperKey == 'YER' && val < 500) {
            continue; // Keep real commercial rate (1,950 YER)
          }
          _fxRates[upperKey] = val;
          _fxRates[entry.key.toLowerCase()] = val;
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

    final rateLookup = _fxRates[currencyCode.toUpperCase()] ??
        _fxRates[currencyCode.toLowerCase()] ??
        _fxRates[code.toUpperCase()] ??
        _fxRates[code.toLowerCase()];

    final double rate;
    if (rateLookup != null && rateLookup > 0) {
      rate = rateLookup;
    } else if (currencyCode.toUpperCase() == 'USD' || code == 'US' || code == 'GLOBAL') {
      rate = 1.0;
    } else {
      rate = _defaultFallbackFor(currencyCode, code);
    }

    final bool isGlobal = code == 'GLOBAL';
    final double spreadPercent = isGlobal ? 0.0 : (0.5 / 100);
    final double g24USD = _goldOunceUSD / 31.1035;
    final double g24SellUSD = _goldOunceSellUSD / 31.1035;
    final double silverGramUSD = (_silverOunceUSD > 0 ? _silverOunceUSD : 31.5) / 31.1035;
    final double silverGramSellUSD = (_silverOunceSellUSD > 0 ? _silverOunceSellUSD : 31.6) / 31.1035;

    /// Try to use scraped price if available (e.g. sy_gold_21, tr_gold_24)
    /// Falls back to calculated price if not found.
    Map<String, dynamic> getGramPrice(String karatStr, double karatFraction) {
      final baseUSD = g24USD * karatFraction;
      final usdPrice = double.parse(baseUSD.toStringAsFixed(2));

      // Check for scraped price (e.g. 'sy_gold_21' or 'tr_gold_24' or 'gold_24k_usd')
      final scrapedId = isGlobal ? 'gold_${karatStr}k_usd' : '${lowerCode}_gold_$karatStr';
      final scraped = _scrapedPrices[scrapedId] ?? _scrapedPrices['${lowerCode}_gold_$karatStr'];
      if (scraped != null && scraped['buyPrice'] != null && (scraped['buyPrice'] as num) > 0) {
        double sBuy = (scraped['buyPrice'] as num).toDouble();
        double sSell = (scraped['sellPrice'] as num?)?.toDouble() ?? sBuy;
        if (code == 'SY' && sBuy > 100000) {
          sBuy = sBuy / 100;
          sSell = sSell / 100;
        }
        return {
          'buyPrice': sBuy,
          'sellPrice': sSell,
          'usdPrice': usdPrice,
        };
      }

      if (isGlobal) {
        final calcBuy = double.parse(baseUSD.toStringAsFixed(2));
        double calcSell = double.parse((g24SellUSD * karatFraction).toStringAsFixed(2));
        if (calcSell <= calcBuy) calcSell = double.parse((calcBuy + 0.02).toStringAsFixed(2));
        return {'buyPrice': calcBuy, 'sellPrice': calcSell, 'usdPrice': usdPrice};
      }

      final baseLocal = baseUSD * rate;
      final calcBuy = double.parse((baseLocal * (1 - spreadPercent)).toStringAsFixed(2));
      final calcSell = double.parse((baseLocal * (1 + spreadPercent)).toStringAsFixed(2));
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
      'title': 'gold_24k'.tr(),
      'subtitle': 'ذهب خالص 999.9'.tr(),
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
      'title': 'gold_22k'.tr(),
      'subtitle': 'عيار المجوهرات والسبائك'.tr(),
      'karat': '22',
      ...k22,
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold',
      'countryCode': code,
    });

    items.add({
      'id': '${code.toLowerCase()}_gold_21k',
      'title': 'gold_21k'.tr(),
      'subtitle': 'الأكثر تداولاً في الأسواق'.tr(),
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
      'title': 'gold_18k'.tr(),
      'subtitle': 'عيار المشغولات الإيطالية'.tr(),
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
      'title': 'gold_14k'.tr(),
      'subtitle': 'المشغولات الخفيفة'.tr(),
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
    final scrapedOunce = _scrapedPrices['${lowerCode}_gold_ounce'] ?? (isGlobal ? _scrapedPrices['xau_usd'] : null);
    final double ounceLocalBuy;
    final double ounceLocalSell;
    if (scrapedOunce != null && scrapedOunce['buyPrice'] != null && (scrapedOunce['buyPrice'] as num) > 0) {
      ounceLocalBuy = (scrapedOunce['buyPrice'] as num).toDouble();
      final rawSell = (scrapedOunce['sellPrice'] as num?)?.toDouble();
      ounceLocalSell = (rawSell != null && rawSell > 0) ? rawSell : (isGlobal ? ounceLocalBuy + 0.80 : ounceLocalBuy);
    } else if (isGlobal) {
      ounceLocalBuy = double.parse(_goldOunceUSD.toStringAsFixed(2));
      ounceLocalSell = double.parse(_goldOunceSellUSD.toStringAsFixed(2));
    } else {
      ounceLocalBuy = double.parse((_goldOunceUSD * rate * (1 - spreadPercent)).toStringAsFixed(2));
      ounceLocalSell = double.parse((_goldOunceUSD * rate * (1 + spreadPercent)).toStringAsFixed(2));
    }

    items.add({
      'id': '${code.toLowerCase()}_gold_ounce',
      'title': 'gold_ounce'.tr(),
      'subtitle': '31.1035 غرام (عيار 24)',
      'buyPrice': ounceLocalBuy,
      'sellPrice': ounceLocalSell,
      'usdPrice': double.parse(_goldOunceUSD.toStringAsFixed(2)),
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'gold_ounce',
      'countryCode': code,
    });

    final double kiloLocalBuy = isGlobal
        ? double.parse((_goldOunceUSD * 32.1507).toStringAsFixed(2))
        : double.parse((_goldOunceUSD * 32.1507 * rate * (1 - spreadPercent * 0.5)).toStringAsFixed(2));
    final double kiloLocalSell = isGlobal
        ? double.parse((_goldOunceSellUSD * 32.1507).toStringAsFixed(2))
        : double.parse((_goldOunceUSD * 32.1507 * rate * (1 + spreadPercent * 0.5)).toStringAsFixed(2));

    items.add({
      'id': '${code.toLowerCase()}_gold_kilo',
      'title': 'gold_kilo'.tr(),
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
    final double silverOunceUSD = _silverOunceUSD > 0 ? _silverOunceUSD : (silverGramUSD * 31.1035);
    final double silverOunceSellUSD = _silverOunceSellUSD > 0 ? _silverOunceSellUSD : (silverGramSellUSD * 31.1035);

    items.add({
      'id': '${code.toLowerCase()}_silver_gram',
      'title': 'silver_pure_gram'.tr(),
      'subtitle': 'فضة عيار 999',
      'buyPrice': isGlobal
          ? double.parse(silverGramUSD.toStringAsFixed(2))
          : double.parse((silverGramUSD * rate * 0.97).toStringAsFixed(2)),
      'sellPrice': isGlobal
          ? (silverGramSellUSD > silverGramUSD ? double.parse(silverGramSellUSD.toStringAsFixed(2)) : double.parse((silverGramUSD + 0.01).toStringAsFixed(2)))
          : double.parse((silverGramUSD * rate * 1.03).toStringAsFixed(2)),
      'usdPrice': double.parse(silverGramUSD.toStringAsFixed(2)),
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'silver',
      'countryCode': code,
    });

    items.add({
      'id': '${code.toLowerCase()}_silver_ounce',
      'title': 'silver_ounce'.tr(),
      'subtitle': '31.1035 غرام (فضة 999)',
      'buyPrice': isGlobal
          ? double.parse(silverOunceUSD.toStringAsFixed(2))
          : double.parse((silverOunceUSD * rate * 0.97).toStringAsFixed(2)),
      'sellPrice': isGlobal
          ? (silverOunceSellUSD > silverOunceUSD ? double.parse(silverOunceSellUSD.toStringAsFixed(2)) : double.parse((silverOunceUSD + 0.10).toStringAsFixed(2)))
          : double.parse((silverOunceUSD * rate * 1.03).toStringAsFixed(2)),
      'usdPrice': double.parse(silverOunceUSD.toStringAsFixed(2)),
      'currency': currencySymbol,
      'currencyCode': currencyCode,
      'metalType': 'silver',
      'countryCode': code,
    });

    final silverKiloUSD = silverGramUSD * 1000;
    final silverKiloSellUSD = silverGramSellUSD * 1000;
    items.add({
      'id': '${code.toLowerCase()}_silver_kilo',
      'title': 'silver_1kg_bar'.tr(),
      'subtitle': '1000 غرام (سبيكة فضة 999)',
      'buyPrice': isGlobal
          ? double.parse(silverKiloUSD.toStringAsFixed(2))
          : double.parse((silverKiloUSD * rate * 0.97).toStringAsFixed(2)),
      'sellPrice': isGlobal
          ? (silverKiloSellUSD > silverKiloUSD ? double.parse(silverKiloSellUSD.toStringAsFixed(2)) : double.parse((silverKiloUSD + 1.0).toStringAsFixed(2)))
          : double.parse((silverKiloUSD * rate * 1.03).toStringAsFixed(2)),
      'usdPrice': double.parse(silverKiloUSD.toStringAsFixed(2)),
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
        'id': 'eg_gold_pound', 'title': 'الجنيه الذهب'.tr(),
        'subtitle': '8 غرام عيار 21',
        'buyPrice': poundBuy, 'sellPrice': poundSell,
        'usdPrice': double.parse((k21['usdPrice'] * 8).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code, 'isPopular': true,
      });
      items.add({
        'id': 'eg_half_pound', 'title': 'نصف جنيه ذهب'.tr(),
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
        'id': 'iq_mithqal_gulf', 'title': 'مثقال الذهب الخليجي (21)'.tr(),
        'subtitle': '5 غرام عيار 21 خليجي وبارس',
        'buyPrice': mBuy, 'sellPrice': mSell,
        'usdPrice': double.parse((k21['usdPrice'] * 5).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_unit', 'countryCode': code, 'isPopular': true,
      });
      items.add({
        'id': 'iq_mithqal_local', 'title': 'مثقال الذهب العراقي (21)'.tr(),
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
        'id': '${code.toLowerCase()}_gold_tola', 'title': 'تولة الذهب'.tr(),
        'subtitle': '11.66 غرام (عيار 24)',
        'buyPrice': tolaBuy, 'sellPrice': tolaSell,
        'usdPrice': double.parse((k24['usdPrice'] * 11.6638).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_unit', 'countryCode': code, 'isPopular': true,
      });
    } else if (code == 'JO') {
      items.add({
        'id': 'jo_rashadi_lira', 'title': 'الليرة الرشادية'.tr(),
        'subtitle': '7 غرام عيار 21',
        'buyPrice': double.parse((k21['buyPrice'] * 7).toStringAsFixed(2)),
        'sellPrice': double.parse((k21['sellPrice'] * 7).toStringAsFixed(2)),
        'usdPrice': double.parse((k21['usdPrice'] * 7).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code, 'isPopular': true,
      });
      items.add({
        'id': 'jo_english_lira', 'title': 'الليرة الإنجليزية'.tr(),
        'subtitle': '8 غرام عيار 21 (جورج / فكتوريا)',
        'buyPrice': double.parse((k21['buyPrice'] * 8).toStringAsFixed(2)),
        'sellPrice': double.parse((k21['sellPrice'] * 8).toStringAsFixed(2)),
        'usdPrice': double.parse((k21['usdPrice'] * 8).toStringAsFixed(2)),
        'currency': currencySymbol, 'currencyCode': currencyCode,
        'metalType': 'gold_coin', 'countryCode': code, 'isPopular': true,
      });
    } else if (code == 'LY' || code == 'DZ') {
      items.add({
        'id': '${code.toLowerCase()}_scrap_18k', 'title': 'ذهب كسر (عيار 18)'.tr(),
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
    const majorCurrencies = [
      'USD', 'EUR', 'GBP', 'SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR', 'JOD',
      'EGP', 'TRY', 'SYP', 'MAD', 'ILS', 'CAD', 'AUD', 'CHF', 'MRU', 'SOS'
    ];

    final shortSymbol = CurrencyUtils.getSymbol(currencyCode);

    // ── Global Market (USD Base) Special Quoting ──
    if (currencyCode == 'USD') {
      const isIndirectQuote = ['EUR', 'GBP', 'AUD', 'NZD'];
      for (final targetCurr in majorCurrencies) {
        if (targetCurr.toUpperCase() == 'USD') continue;
        final targetRateRaw = _fxRates[targetCurr.toUpperCase()] ??
            _fxRates[targetCurr.toLowerCase()] ??
            _defaultFallbackFor(targetCurr, targetCurr);
        final double targetRateToUsd = (targetCurr.toUpperCase() == 'SYP' && targetRateRaw > 1000)
            ? targetRateRaw / 100
            : targetRateRaw;

        if (isIndirectQuote.contains(targetCurr.toUpperCase())) {
          final crossRate = 1.0 / targetRateToUsd;
          final buy = double.parse((crossRate * 0.998).toStringAsFixed(3));
          final sell = double.parse((crossRate * 1.002).toStringAsFixed(3));
          final formula = CurrencyUtils.getCompactFormula(targetCurr, buy, 'USD');
          items.add({
            'id': '${code.toLowerCase()}_fx_${targetCurr.toLowerCase()}',
            'title': CurrencyUtils.getCompactPairTitle(targetCurr, 'USD'),
            'subtitle': formula,
            'buyPrice': buy,
            'sellPrice': sell,
            'usdPrice': 1.0,
            'currency': r'$',
            'currencyCode': 'USD',
            'metalType': 'currency',
            'countryCode': code,
          });
        } else {
          final targetSymbol = CurrencyUtils.getSymbol(targetCurr);
          final isThreeDecimal = targetCurr == 'OMR' || targetCurr == 'KWD' || targetCurr == 'BHD' || targetCurr == 'JOD';
          final dec = isThreeDecimal ? 3 : (targetRateToUsd < 1000 ? 2 : 0);
          final buy = double.parse((targetRateToUsd * 0.998).toStringAsFixed(dec));
          final sell = double.parse((targetRateToUsd * 1.002).toStringAsFixed(dec));
          final formula = '1 \$ = ${targetRateToUsd.toStringAsFixed(dec)} $targetSymbol';
          items.add({
            'id': '${code.toLowerCase()}_fx_${targetCurr.toLowerCase()}',
            'title': 'الدولار مقابل ${CurrencyUtils.getShortName(targetCurr)}',
            'subtitle': formula,
            'buyPrice': buy,
            'sellPrice': sell,
            'usdPrice': 1.0,
            'currency': targetSymbol,
            'currencyCode': targetCurr,
            'metalType': 'currency',
            'countryCode': code,
          });
        }
      }
      return;
    }

    for (final targetCurr in majorCurrencies) {
      if (targetCurr.toUpperCase() == currencyCode.toUpperCase()) continue; // Skip self

      final targetRateRaw = _fxRates[targetCurr.toUpperCase()] ??
          _fxRates[targetCurr.toLowerCase()] ??
          _defaultFallbackFor(targetCurr, targetCurr);
      final double targetRateToUsd = (targetCurr.toUpperCase() == 'SYP' && targetRateRaw > 1000)
          ? targetRateRaw / 100
          : targetRateRaw;

      // Cross rate: 1 TargetCurrency = X LocalCurrency
      final crossRate = localRate / targetRateToUsd;

      final pairTitle = CurrencyUtils.getCompactPairTitle(targetCurr, currencyCode);

      final isThreeDecimal = targetCurr == 'OMR' || targetCurr == 'KWD' || targetCurr == 'BHD' || targetCurr == 'JOD' ||
                             currencyCode == 'OMR' || currencyCode == 'KWD' || currencyCode == 'BHD' || currencyCode == 'JOD';
      final dec = isThreeDecimal ? 3 : (crossRate < 1000 ? 2 : 0);

      double buyPrice = double.parse((crossRate * 0.998).toStringAsFixed(dec));
      double sellPrice = double.parse((crossRate * 1.002).toStringAsFixed(dec));

      // Regional live override if available
      if (targetCurr == 'EUR') {
        if (code == 'SY' && _scrapedPrices.containsKey('sy_eur')) {
          final sp = _scrapedPrices['sy_eur']!;
          final b = (sp['buyPrice'] as num?)?.toDouble() ?? 0.0;
          if (b > 0) {
            buyPrice = b;
            sellPrice = (sp['sellPrice'] as num?)?.toDouble() ?? (b * 1.004);
          }
        } else if (code == 'TR' && _scrapedPrices.containsKey('tr_curr_eur')) {
          final sp = _scrapedPrices['tr_curr_eur']!;
          final b = (sp['buyPrice'] as num?)?.toDouble() ?? 0.0;
          if (b > 0) {
            buyPrice = b;
            sellPrice = (sp['sellPrice'] as num?)?.toDouble() ?? (b * 1.004);
          }
        }
      }

      final double displayRate = (buyPrice > 0) ? buyPrice : crossRate;
      final formula = CurrencyUtils.getCompactFormula(targetCurr, displayRate, currencyCode);

      items.add({
        'id': '${code.toLowerCase()}_fx_${targetCurr.toLowerCase()}',
        'title': pairTitle,
        'subtitle': formula,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'usdPrice': double.parse((1 / targetRateToUsd).toStringAsFixed(4)),
        'currency': shortSymbol,
        'currencyCode': currencyCode,
        'metalType': 'currency',
        'countryCode': code,
      });
    }

    // For European market (EUR base), explicitly provide the EUR vs USD (Euro against Dollar) card
    if (currencyCode == 'EUR') {
      final rawEur = _fxRates['EUR'] ?? 0.862;
      final double eurUsdRate = rawEur > 0 ? (rawEur < 1.0 ? 1.0 / rawEur : rawEur) : 1.16;
      final double buy = double.parse((eurUsdRate * 0.998).toStringAsFixed(3));
      final double sell = double.parse((eurUsdRate * 1.002).toStringAsFixed(3));
      final displayRate = (buy > 0) ? buy : eurUsdRate;
      final formula = CurrencyUtils.getCompactFormula('EUR', displayRate, 'USD');

      final usdIdx = items.indexWhere((i) => i['id'] == '${code.toLowerCase()}_fx_usd');
      final insertIdx = usdIdx >= 0 ? usdIdx + 1 : items.length;
      items.insert(insertIdx, {
        'id': '${code.toLowerCase()}_fx_eur',
        'title': CurrencyUtils.getCompactPairTitle('EUR', 'USD'),
        'subtitle': formula,
        'buyPrice': buy,
        'sellPrice': sell,
        'usdPrice': 1.0,
        'currency': r'$',
        'currencyCode': 'USD',
        'metalType': 'currency',
        'countryCode': code,
      });
    }
  }

  /// Explicitly returns a guaranteed 1 EUR price item for any market.
  PriceItem? getEurPriceItemFor(CountryModel country) {
    final code = country.code.toUpperCase();
    final currencyCode = country.currencyCode.toUpperCase();
    final shortSymbol = CurrencyUtils.getSymbol(currencyCode);

    if (currencyCode == 'EUR') {
      final rawEur = _fxRates['EUR'] ?? 0.862;
      final double eurUsdRate = rawEur > 0 ? (rawEur < 1.0 ? 1.0 / rawEur : rawEur) : 1.16;
      final double buy = double.parse((eurUsdRate * 0.998).toStringAsFixed(3));
      final double sell = double.parse((eurUsdRate * 1.002).toStringAsFixed(3));
      return PriceItem(
        id: '${code.toLowerCase()}_fx_eur',
        title: CurrencyUtils.getCompactPairTitle('EUR', 'USD'),
        buyPrice: buy,
        sellPrice: sell,
        currency: r'$',
        metalType: 'currency',
        lastUpdate: DateTime.now(),
      );
    }

    final rateLookup = _fxRates[currencyCode] ??
        _fxRates[country.currencyCode.toLowerCase()] ??
        _fxRates[code] ??
        _fxRates[code.toLowerCase()];
    final double localRate = (rateLookup != null && rateLookup > 0)
        ? rateLookup
        : _defaultFallbackFor(currencyCode, code);

    final double eurRateToUsd = _fxRates['EUR'] ?? 0.86;
    final double crossRate = localRate / eurRateToUsd;

    double buy = double.parse((crossRate * 0.998).toStringAsFixed(3));
    double sell = double.parse((crossRate * 1.002).toStringAsFixed(3));

    if (code == 'SY' && _scrapedPrices.containsKey('sy_eur')) {
      final sp = _scrapedPrices['sy_eur']!;
      final b = (sp['buyPrice'] as num?)?.toDouble() ?? 0.0;
      if (b > 0) {
        buy = b;
        sell = (sp['sellPrice'] as num?)?.toDouble() ?? (b * 1.004);
      }
    } else if (code == 'TR' && _scrapedPrices.containsKey('tr_curr_eur')) {
      final sp = _scrapedPrices['tr_curr_eur']!;
      final b = (sp['buyPrice'] as num?)?.toDouble() ?? 0.0;
      if (b > 0) {
        buy = b;
        sell = (sp['sellPrice'] as num?)?.toDouble() ?? (b * 1.004);
      }
    }

    return PriceItem(
      id: '${code.toLowerCase()}_fx_eur',
      title: CurrencyUtils.getCompactPairTitle('EUR', currencyCode),
      buyPrice: buy,
      sellPrice: sell,
      currency: shortSymbol,
      metalType: 'currency',
      lastUpdate: DateTime.now(),
    );
  }
}
