import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/utils/currency_utils.dart';

enum Trend { up, down, stable }

class PriceItem {
  final String id;
  final String title;
  final double buyPrice;
  final double sellPrice;
  final String currency;
  final Trend trend;
  final String metalType;
  final double changePercentage;
  final double usdPrice;
  final String? externalId;
  final DateTime? lastUpdate;
  final bool isManual;

  PriceItem({
    required this.id,
    required this.title,
    required this.buyPrice,
    required this.sellPrice,
    required this.currency,
    this.trend = Trend.stable,
    required this.metalType,
    this.changePercentage = 0.0,
    this.usdPrice = 0.0,
    this.externalId,
    this.lastUpdate,
    this.isManual = false,
  });

  factory PriceItem.fromJson(Map<String, dynamic> json) {
    return PriceItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      buyPrice: (json['buyPrice'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'SYP',
      trend: Trend.values[(json['trend'] as int?) ?? 2],
      metalType: json['metalType'] ?? 'gold',
      changePercentage: (json['changePercentage'] as num?)?.toDouble() ?? 0.0,
      usdPrice: (json['usdPrice'] as num?)?.toDouble() ?? 0.0,
      externalId: json['externalId'],
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'])
          : null,
      isManual: json['isManual'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'currency': currency,
      'trend': trend.index,
      'metalType': metalType,
      'changePercentage': changePercentage,
      'usdPrice': usdPrice,
      'externalId': externalId,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'isManual': isManual,
    };
  }

  factory PriceItem.empty() {
    return PriceItem(
      id: '',
      title: '',
      buyPrice: 0.0,
      sellPrice: 0.0,
      currency: 'SYP',
      trend: Trend.stable,
      metalType: 'gold',
    );
  }
  
  String get translatedTitle {
    // 1. Direct key/string translation
    final direct = title.tr();
    if (direct.isNotEmpty && direct != title) {
      return direct;
    }

    // 2. Pattern: 'العملة (الدولة)' -> e.g. 'الريال السعودي (سوريا)'
    final parenRegex = RegExp(r'^(.*?)\s*\((.*?)\)$');
    final match = parenRegex.firstMatch(title);
    if (match != null) {
      final baseCurrency = match.group(1)!.trim();
      final countryTag = match.group(2)!.trim();
      final translatedCurrency = _translateCurrencyName(baseCurrency);
      final translatedCountry = _translateCountryTag(countryTag);
      if (translatedCurrency.isNotEmpty && translatedCountry.isNotEmpty && 
          (translatedCurrency != baseCurrency || translatedCountry != countryTag)) {
        return '$translatedCurrency ($translatedCountry)';
      }
    }

    // 3. Known ID-based currency resolution (e.g. sy_sar, sy_try, tr_curr_sar)
    final lowerId = id.toLowerCase();
    if (lowerId.startsWith('sy_') || lowerId.startsWith('tr_curr_')) {
      final idResolved = _resolveCurrencyById(lowerId);
      if (idResolved.isNotEmpty) return idResolved;
    }

    // 4. Single currency name translation (e.g. 'الريال السعودي', 'الليرة التركية')
    final singleCurrency = _translateCurrencyName(title);
    if (singleCurrency != title) {
      return singleCurrency;
    }

    // 5. ID and Karat-based translation resolution
    final lowerTitle = title.toLowerCase();
    if (lowerId.contains('24k') || title.contains('24')) return 'gold_24k'.tr();
    if (lowerId.contains('22k') || title.contains('22')) return 'gold_22k'.tr();
    if (lowerId.contains('21k') || title.contains('21')) return 'gold_21k'.tr();
    if (lowerId.contains('18k') || title.contains('18')) return 'gold_18k'.tr();
    if (lowerId.contains('14k') || title.contains('14')) return 'gold_14k'.tr();
    if (lowerId.contains('12k') || title.contains('12')) return 'gold_12k'.tr();
    if (lowerId.contains('10k') || title.contains('10')) return 'gold_10k'.tr();
    if (lowerId.contains('9k') || title.contains('9')) return 'gold_9k'.tr();

    final isSilver = metalType == 'silver' ||
        lowerId.contains('silver') ||
        lowerId.contains('xag') ||
        title.contains('فضة') ||
        title.contains('فضه') ||
        lowerTitle.contains('silver') ||
        lowerTitle.contains('gümüş');

    if (lowerId.contains('ounce') || lowerId.contains('oz') || title.contains('أونصة') || lowerTitle.contains('ounce') || lowerTitle.contains('ons')) {
      return isSilver ? 'silver_ounce'.tr() : 'gold_ounce'.tr();
    }
    if (lowerId.contains('kilo') || lowerId.contains('kg') || title.contains('كيلو') || lowerTitle.contains('kilo')) {
      return isSilver ? 'silver_1kg_bar'.tr() : 'gold_kilo'.tr();
    }
    if (lowerId.contains('silver_pure') || title.contains('الفضة النقية') || title.contains('فضة نقية') || lowerTitle.contains('pure silver') || lowerTitle.contains('saf gümüş')) {
      return 'silver_pure_gram'.tr();
    }
    if (lowerId.contains('silver_999') || (isSilver && title.contains('999'))) return 'silver_999'.tr();
    if (lowerId.contains('silver_925') || (isSilver && title.contains('925'))) return 'silver_925'.tr();
    if (lowerId.contains('silver_800') || (isSilver && title.contains('800'))) return 'silver_800'.tr();

    if (lowerId.contains('rashadi') || title.contains('رشادية')) return 'coin_rashadi'.tr();
    if (lowerId.contains('english') || title.contains('إنجليزية')) return 'coin_english'.tr();
    if (lowerId.contains('half') || title.contains('نصف ليرة')) return 'coin_half'.tr();
    if (lowerId.contains('quarter') || title.contains('ربع ليرة')) return 'coin_quarter'.tr();
    if (lowerId.contains('five') || title.contains('خمس ليرات')) return 'coin_five'.tr();

    // 6. Currency items & Exchange rate pairs
    if (metalType == 'currency' || title.contains('مقابل') || title.contains('سعر صرف')) {
      return sanitizeTitle(title, currency: currency);
    }

    return sanitizeTitle(direct, currency: currency);
  }

  static String _translateCurrencyName(String name) {
    final clean = name.trim();
    final direct = clean.tr();
    if (direct.isNotEmpty && direct != clean) return direct;

    switch (clean) {
      case 'الدولار':
      case 'الدولار الأمريكي':
      case 'دولار أمريكي':
      case 'دولار':
        return 'currency_name_usd'.tr();
      case 'اليورو':
      case 'اليورو الأوروبي':
      case 'يورو أوروبي':
      case 'يورو':
        return 'currency_name_eur'.tr();
      case 'الليرة التركية':
      case 'ليرة تركية':
      case 'تركي':
        return 'currency_name_try'.tr();
      case 'الريال السعودي':
      case 'ريال سعودي':
        return 'currency_name_sar'.tr();
      case 'الدرهم الإماراتي':
      case 'درهم إماراتي':
        return 'currency_name_aed'.tr();
      case 'الدينار الكويتي':
      case 'دينار كويتي':
        return 'currency_name_kwd'.tr();
      case 'الدينار الأردني':
      case 'دينار أردني':
        return 'currency_name_jod'.tr();
      case 'الريال القطري':
      case 'ريال قطري':
        return 'currency_name_qar'.tr();
      case 'الجنيه المصري':
      case 'جنيه مصري':
        return 'currency_name_egp'.tr();
      case 'الليرة اللبنانية':
      case 'ليرة لبنانية':
        return 'currency_name_lbp'.tr();
      case 'الجنيه الإسترليني':
      case 'جنيه إسترليني':
      case 'إسترليني':
        return 'currency_name_gbp'.tr();
      case 'الدينار البحريني':
      case 'دينار بحريني':
        return 'currency_name_bhd'.tr();
      case 'الريال العماني':
      case 'ريال عماني':
        return 'currency_name_omr'.tr();
      case 'الليرة السورية':
      case 'ليرة سورية':
      case 'سوري':
        return 'currency_name_syp'.tr();
      case 'الدينار العراقي':
      case 'دينار عراقي':
        return 'currency_name_iqd'.tr();
      case 'الدينار الجزائري':
      case 'دينار جزائري':
        return 'currency_name_dzd'.tr();
      case 'الدرهم المغربي':
      case 'درهم مغربي':
        return 'currency_name_mad'.tr();
      case 'الدينار التونسي':
      case 'دينار تونسي':
        return 'currency_name_tnd'.tr();
      case 'الجنيه السوداني':
      case 'جنيه سوداني':
        return 'currency_name_sdg'.tr();
      case 'الريال اليمني':
      case 'ريال يمني':
        return 'currency_name_yer'.tr();
      case 'الدولار الكندي':
      case 'دولار كندي':
        return 'currency_name_cad'.tr();
      case 'الدولار الأسترالي':
      case 'دولار أسترالي':
        return 'currency_name_aud'.tr();
      case 'الفرنك السويسري':
      case 'فرنك سويسري':
        return 'currency_name_chf'.tr();
      default:
        return clean;
    }
  }

  static String _translateCountryTag(String tag) {
    final clean = tag.trim();
    final direct = clean.tr();
    if (direct.isNotEmpty && direct != clean) return direct;

    switch (clean) {
      case 'سوريا':
      case 'سورية':
        return 'country_sy'.tr();
      case 'تركيا':
        return 'country_tr'.tr();
      case 'مصر':
        return 'country_eg'.tr();
      case 'السعودية':
        return 'country_sa'.tr();
      case 'الإمارات':
        return 'country_ae'.tr();
      case 'الكويت':
        return 'country_kw'.tr();
      case 'الأردن':
        return 'country_jo'.tr();
      case 'قطر':
        return 'country_qa'.tr();
      case 'عمان':
      case 'عُمان':
        return 'country_om'.tr();
      case 'البحرين':
        return 'country_bh'.tr();
      case 'العراق':
        return 'country_iq'.tr();
      case 'لبنان':
        return 'country_lb'.tr();
      case 'المغرب':
        return 'country_ma'.tr();
      case 'الجزائر':
        return 'country_dz'.tr();
      case 'تونس':
        return 'country_tn'.tr();
      case 'السودان':
        return 'country_sd'.tr();
      case 'اليمن':
        return 'country_ye'.tr();
      default:
        return clean;
    }
  }

  static String _resolveCurrencyById(String lowerId) {
    if (lowerId == 'sy_usd') return '${'currency_name_usd'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_eur') return '${'currency_name_eur'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_try') return '${'currency_name_try'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_sar') return '${'currency_name_sar'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_aed') return '${'currency_name_aed'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_kwd') return '${'currency_name_kwd'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_jod') return '${'currency_name_jod'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_qar') return '${'currency_name_qar'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_egp') return '${'currency_name_egp'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'sy_lbp') return '${'currency_name_lbp'.tr()} (${'country_sy'.tr()})';
    if (lowerId == 'tr_curr_usd') return '${'currency_name_usd'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_eur') return '${'currency_name_eur'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_gbp') return '${'currency_name_gbp'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_sar') return '${'currency_name_sar'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_aed') return '${'currency_name_aed'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_kwd') return '${'currency_name_kwd'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_jod') return '${'currency_name_jod'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_qar') return '${'currency_name_qar'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_bhd') return '${'currency_name_bhd'.tr()} (${'country_tr'.tr()})';
    if (lowerId == 'tr_curr_omr') return '${'currency_name_omr'.tr()} (${'country_tr'.tr()})';
    return '';
  }

  /// Sanitizes long titles (e.g. 'سعر صرف الدولار الكندي مقابل دينار جزائري' -> 'الدولار الكندي مقابل د.ج' in AR, or 'CAD vs DZD' in EN/TR)
  static String sanitizeTitle(String rawTitle, {String currency = '', BuildContext? context}) {
    var t = rawTitle.trim();

    // Strip leading 'سعر صرف '
    if (t.startsWith('سعر صرف ')) {
      t = t.substring('سعر صرف '.length).trim();
    }

    final isAr = (context != null)
        ? context.locale.languageCode == 'ar'
        : (Intl.defaultLocale?.startsWith('ar') ?? true);

    // Process 'A مقابل B' or 'A vs B' or 'A / B'
    if (t.contains(' مقابل ') || t.contains(' vs ') || t.contains(' / ')) {
      final delimiter = t.contains(' مقابل ')
          ? ' مقابل '
          : (t.contains(' vs ') ? ' vs ' : ' / ');
      final parts = t.split(delimiter);
      if (parts.length == 2) {
        var left = parts[0].trim();
        var right = parts[1].trim();

        if (!isAr) {
          final leftCode = CurrencyUtils.normalizeCurrencyCode(left);
          final rightCode = CurrencyUtils.normalizeCurrencyCode(right.isNotEmpty ? right : currency);
          return '$leftCode vs $rightCode';
        }

        // Shorten long currency names on the left for Arabic
        if (left == 'الدولار الأمريكي' || left == 'دولار أمريكي') left = 'الدولار';
        if (left == 'اليورو الأوروبي' || left == 'يورو أوروبي') left = 'اليورو';
        if (left == 'الجنيه الإسترليني' || left == 'جنيه إسترليني') left = 'الإسترليني';

        // Shorten right side to standard currency symbol
        final rightSymbol = CurrencyUtils.getSymbol(right.isNotEmpty ? right : currency, context: context);
        if (rightSymbol.isNotEmpty) {
          right = rightSymbol;
        }

        return '$left مقابل $right';
      }
    }

    return t;
  }
}
