import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class CurrencyUtils {
  /// Normalizes any currency representation (Arabic symbol, id prefix, or code)
  /// into a standard uppercase 3-letter ISO code.
  static String normalizeCurrencyCode(String currency, {String id = ''}) {
    var clean = currency.trim();
    if (id.startsWith('tr_')) return 'TRY';
    if (id.startsWith('sy_')) {
      if (id.contains('usd')) return 'USD';
      return 'SYP';
    }

    // Strip leading Arabic definite article 'ال' if present
    var stripped = clean;
    if (stripped.startsWith('ال') && stripped.length > 2) {
      stripped = stripped.substring(2).trim();
    }

    switch (clean) {
      case 'دينار جزائري':
      case 'الدينار الجزائري':
      case 'د.ج':
        return 'DZD';
      case 'جنيه مصري':
      case 'الجنيه المصري':
      case 'ج.م':
        return 'EGP';
      case 'ريال سعودي':
      case 'الريال السعودي':
      case 'ر.س':
        return 'SAR';
      case 'درهم إماراتي':
      case 'الدرهم الإماراتي':
      case 'د.إ':
        return 'AED';
      case 'دينار كويتي':
      case 'الدينار الكويتي':
      case 'د.ك':
        return 'KWD';
      case 'ريال قطري':
      case 'الريال القطري':
      case 'ر.ق':
        return 'QAR';
      case 'دينار بحريني':
      case 'الدينار البحريني':
      case 'د.ب':
        return 'BHD';
      case 'ريال عماني':
      case 'الريال العماني':
      case 'ر.ع':
        return 'OMR';
      case 'دينار أردني':
      case 'الدينار الأردني':
      case 'د.أ':
        return 'JOD';
      case 'دينار عراقي':
      case 'الدينار العراقي':
      case 'د.ع':
        return 'IQD';
      case 'ليرة سورية':
      case 'الليرة السورية':
      case 'سوري':
      case 'السوري':
      case 'ل.س':
        return 'SYP';
      case 'دينار ليبي':
      case 'الدينار الليبي':
      case 'د.ل':
        return 'LYD';
      case 'ليرة لبنانية':
      case 'الليرة اللبنانية':
      case 'ل.ل':
        return 'LBP';
      case 'درهم مغربي':
      case 'الدرهم المغربي':
      case 'د.م.':
      case 'د.م':
        return 'MAD';
      case 'دينار تونسي':
      case 'الدينار التونسي':
      case 'د.ت':
        return 'TND';
      case 'جنيه سوداني':
      case 'الجنيه السوداني':
      case 'ج.س.':
      case 'ج.س':
        return 'SDG';
      case 'ريال يمني':
      case 'الريال اليمني':
      case 'ر.ي':
        return 'YER';
      case 'أوقية موريتانية':
      case 'الأوقية الموريتانية':
      case 'أ.م':
        return 'MRU';
      case 'شلن صومالي':
      case 'الشلن الصومالي':
      case 'ش.ص':
        return 'SOS';
      case 'شيكل':
      case 'الشيكل':
      case 'شيكل فلسطيني':
      case 'شيكل إسرائيلي':
      case '₪':
        return 'ILS';
      case 'ليرة تركية':
      case 'الليرة التركية':
      case 'تركي':
      case 'التركي':
      case '₺':
        return 'TRY';
      case 'دولار أمريكي':
      case 'الدولار الأمريكي':
      case 'دولار':
      case 'الدولار':
      case '\$':
        return 'USD';
      case 'يورو':
      case 'اليورو':
      case 'يورو أوروبي':
      case 'اليورو الأوروبي':
      case '€':
        return 'EUR';
      case 'جنيه إسترليني':
      case 'الجنيه الإسترليني':
      case 'إسترليني':
      case 'الإسترليني':
      case '£':
        return 'GBP';
      case 'فرنك سويسري':
      case 'الفرنك السويسري':
      case 'فرنك':
      case 'الفرنك':
      case 'Fr':
        return 'CHF';
      case 'دولار كندي':
      case 'الدولار الكندي':
      case 'كندي':
      case 'الكندي':
      case 'C\$':
        return 'CAD';
      case 'دولار أسترالي':
      case 'الدولار الأسترالي':
      case 'أسترالي':
      case 'الأسترالي':
      case 'A\$':
        return 'AUD';
      default:
        // Try stripped version if not matched directly
        if (stripped != clean) {
          switch (stripped) {
            case 'دولار': return 'USD';
            case 'يورو': return 'EUR';
            case 'إسترليني': return 'GBP';
            case 'فرنك': return 'CHF';
            case 'كندي': return 'CAD';
            case 'أسترالي': return 'AUD';
            case 'تركي': return 'TRY';
            case 'سوري': return 'SYP';
          }
        }
        return clean.toUpperCase();
    }
  }

  /// Returns the localized currency symbol according to the active app language.
  /// E.g. in Arabic: 'DZD' -> 'د.ج', 'SYP' -> 'ل.س', 'TRY' -> '₺'
  /// In English / Turkish: 'DZD' -> 'DZD', 'SYP' -> 'SYP', 'TRY' -> '₺'
  static String getSymbol(String currency, {String id = '', BuildContext? context}) {
    final code = normalizeCurrencyCode(currency, id: id);

    // Universal symbols
    if (code == 'USD') return '\$';
    if (code == 'EUR') return '€';
    if (code == 'GBP') return '£';
    if (code == 'TRY') return '₺';
    if (code == 'ILS') return '₪';

    final isAr = (context != null)
        ? context.locale.languageCode == 'ar'
        : (Intl.defaultLocale?.startsWith('ar') ?? true);

    if (isAr) {
      switch (code) {
        case 'DZD': return 'د.ج';
        case 'EGP': return 'ج.م';
        case 'SAR': return 'ر.س';
        case 'AED': return 'د.إ';
        case 'KWD': return 'د.ك';
        case 'QAR': return 'ر.ق';
        case 'BHD': return 'د.ب';
        case 'OMR': return 'ر.ع';
        case 'JOD': return 'د.أ';
        case 'IQD': return 'د.ع';
        case 'SYP': return 'ل.س';
        case 'LYD': return 'د.ل';
        case 'LBP': return 'ل.ل';
        case 'MAD': return 'د.م.';
        case 'TND': return 'د.ت';
        case 'SDG': return 'ج.س.';
        case 'YER': return 'ر.ي';
        case 'MRU': return 'أ.م';
        case 'SOS': return 'ش.ص';
        case 'CAD': return 'C\$';
        case 'AUD': return 'A\$';
        case 'CHF': return 'Fr';
      }
    }

    return code;
  }

  static String getLocale(String currency, {String id = ''}) {
    if (currency == 'USD') return 'en_US';
    if (currency == 'TRY' || id.startsWith('tr_')) return 'tr_TR';
    if (currency == 'EUR') return 'de_DE';
    return Intl.defaultLocale ?? 'ar_SY';
  }

  /// Formats numbers strictly respecting the app locale (Arabic numerals for Arabic, Western for other languages)
  static String formatLocalizedNumber(
    double number,
    BuildContext context, {
    int decimals = 2,
    bool compactLarge = false,
  }) {
    final isAr = context.locale.languageCode == 'ar';
    final locale = isAr ? 'ar' : 'en_US';
    
    if (compactLarge && number >= 10000) {
      return NumberFormat("#,###", locale).format(number);
    }
    
    final pattern = decimals == 0 ? "#,##0" : "#,##0.${'0' * decimals}";
    return NumberFormat(pattern, locale).format(number);
  }

  static String formatPrice(double price, String currency, {String id = '', BuildContext? context}) {
    final symbol = getSymbol(currency, id: id, context: context);
    if (context != null) {
      final formatted = formatLocalizedNumber(price, context, decimals: 2, compactLarge: price >= 10000);
      return '$formatted $symbol';
    }
    final format = NumberFormat("#,##0.##", 'en_US');
    return '${format.format(price)} $symbol';
  }

  /// Returns a short, compact name for the currency (e.g. 'دولار', 'يورو', 'ل.ت', 'د.إ')
  static String getShortName(String currencyCode, {BuildContext? context}) {
    final code = normalizeCurrencyCode(currencyCode);
    final isAr = (context != null)
        ? context.locale.languageCode == 'ar'
        : (Intl.defaultLocale?.startsWith('ar') ?? true);

    if (isAr) {
      switch (code) {
        case 'USD': return 'دولار';
        case 'EUR': return 'يورو';
        case 'TRY': return 'ل.ت';
        case 'SYP': return 'ل.س';
        case 'SAR': return 'ر.س';
        case 'AED': return 'د.إ';
        case 'KWD': return 'د.ك';
        case 'GBP': return 'إسترليني';
        case 'QAR': return 'ر.ق';
        case 'EGP': return 'ج.م';
        case 'JOD': return 'د.أ';
        case 'BHD': return 'د.ب';
        case 'OMR': return 'ر.ع';
        case 'DZD': return 'د.ج';
        case 'IQD': return 'د.ع';
        case 'LBP': return 'ل.ل';
        case 'LYD': return 'د.ل';
        case 'MAD': return 'د.م';
        case 'TND': return 'د.ت';
        case 'SDG': return 'ج.س';
        case 'YER': return 'ر.ي';
        case 'CAD': return 'كندي';
        case 'AUD': return 'أسترالي';
        case 'CHF': return 'فرنك';
        case 'ILS': return 'شيكل';
        default: return code;
      }
    }
    return code;
  }

  /// Returns a sleek pair title (e.g. 'دولار مقابل ل.ت' in Arabic, or 'USD vs TRY' / 'USD vs AED')
  static String getCompactPairTitle(String targetCode, String baseCode, {BuildContext? context}) {
    final isAr = (context != null)
        ? context.locale.languageCode == 'ar'
        : (Intl.defaultLocale?.startsWith('ar') ?? true);

    final targetClean = normalizeCurrencyCode(targetCode);
    final baseClean = normalizeCurrencyCode(baseCode);

    if (isAr) {
      final targetShort = getShortName(targetClean, context: context);
      final baseShort = getShortName(baseClean, context: context);
      return '$targetShort مقابل $baseShort';
    } else {
      return '$targetClean vs $baseClean';
    }
  }

  /// Returns a compact formula string with symbols (e.g. '1 $ = 36.50 ₺' or '1 $ = 132.50 ل.س')
  static String getCompactFormula(String targetCode, double rate, String baseCode, {BuildContext? context}) {
    final targetSymbol = getSymbol(targetCode, context: context);
    final baseSymbol = getSymbol(baseCode, context: context);
    final isAr = (context != null)
        ? context.locale.languageCode == 'ar'
        : (Intl.defaultLocale?.startsWith('ar') ?? true);
    final locale = isAr ? 'ar' : 'en_US';
    final normalizedBase = normalizeCurrencyCode(baseCode);
    final isSyp = normalizedBase == 'SYP' || baseCode.contains('ل.س');

    final String formattedRate;
    if (isSyp || (rate < 1000 && rate % 1 != 0)) {
      formattedRate = NumberFormat('#,##0.00', locale).format(rate);
    } else if (rate >= 1000) {
      formattedRate = NumberFormat('#,##0', locale).format(rate);
    } else if (rate >= 10) {
      formattedRate = NumberFormat('#,##0.00', locale).format(rate);
    } else {
      formattedRate = NumberFormat('#,##0.000', locale).format(rate);
    }

    return '1 $targetSymbol = $formattedRate $baseSymbol';
  }
}
