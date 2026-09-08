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
      title: json['title'] ?? '',
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

    // 2. ID and Karat-based translation resolution
    final lowerId = id.toLowerCase();
    if (lowerId.contains('24k') || title.contains('24')) return 'gold_24k'.tr();
    if (lowerId.contains('22k') || title.contains('22')) return 'gold_22k'.tr();
    if (lowerId.contains('21k') || title.contains('21')) return 'gold_21k'.tr();
    if (lowerId.contains('18k') || title.contains('18')) return 'gold_18k'.tr();
    if (lowerId.contains('14k') || title.contains('14')) return 'gold_14k'.tr();
    if (lowerId.contains('12k') || title.contains('12')) return 'gold_12k'.tr();
    if (lowerId.contains('10k') || title.contains('10')) return 'gold_10k'.tr();
    if (lowerId.contains('9k') || title.contains('9')) return 'gold_9k'.tr();

    if (lowerId.contains('ounce') || lowerId.contains('oz') || title.contains('أونصة')) {
      return metalType == 'silver' ? 'silver_ounce'.tr() : 'gold_ounce'.tr();
    }
    if (lowerId.contains('kilo') || lowerId.contains('kg') || title.contains('كيلو')) {
      return metalType == 'silver' ? 'silver_1kg_bar'.tr() : 'gold_kilo'.tr();
    }
    if (lowerId.contains('silver_pure') || title.contains('الفضة النقية')) {
      return 'silver_pure_gram'.tr();
    }
    if (lowerId.contains('silver_999') || title.contains('999')) return 'silver_999'.tr();
    if (lowerId.contains('silver_925') || title.contains('925')) return 'silver_925'.tr();
    if (lowerId.contains('silver_800') || title.contains('800')) return 'silver_800'.tr();

    if (lowerId.contains('rashadi') || title.contains('رشادية')) return 'coin_rashadi'.tr();
    if (lowerId.contains('english') || title.contains('إنجليزية')) return 'coin_english'.tr();
    if (lowerId.contains('half') || title.contains('نصف ليرة')) return 'coin_half'.tr();
    if (lowerId.contains('quarter') || title.contains('ربع ليرة')) return 'coin_quarter'.tr();
    if (lowerId.contains('five') || title.contains('خمس ليرات')) return 'coin_five'.tr();

    // 3. Currency items & Exchange rate pairs
    if (metalType == 'currency' || title.contains('مقابل') || title.contains('سعر صرف')) {
      return sanitizeTitle(title, currency: currency);
    }

    return sanitizeTitle(direct, currency: currency);
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
