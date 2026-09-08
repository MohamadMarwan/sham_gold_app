import 'package:easy_localization/easy_localization.dart';
import '../../core/utils/currency_utils.dart';

class CountryModel {
  final String code;
  final String name;
  final String flag;
  final String currencyCode;
  final String currencySymbol;
  final String defaultKarat;
  final String region;
  final List<String> availableKarats;
  final List<String> specialUnits;
  String get currency => currencyCode;

  /// Returns the localized country name based on the current app language.
  String get localizedName {
    final key = 'country_${code.toLowerCase()}';
    final val = key.tr();
    if (val.isNotEmpty && val != key) return val;
    if (name.isNotEmpty && !name.startsWith('country_')) return name;
    return fallbackName(code);
  }

  static String fallbackName(String code) {
    switch (code.toUpperCase()) {
      case 'DZ': return 'الجزائر';
      case 'EG': return 'مصر';
      case 'SA': return 'السعودية';
      case 'AE': return 'الإمارات';
      case 'IQ': return 'العراق';
      case 'KW': return 'الكويت';
      case 'QA': return 'قطر';
      case 'JO': return 'الأردن';
      case 'LB': return 'لبنان';
      case 'LY': return 'ليبيا';
      case 'SY': return 'سوريا';
      case 'TR': return 'تركيا';
      case 'OM': return 'سلطنة عُمان';
      case 'BH': return 'البحرين';
      case 'PS': return 'فلسطين';
      case 'YE': return 'اليمن';
      case 'MA': return 'المغرب';
      case 'TN': return 'تونس';
      case 'SD': return 'السودان';
      case 'MR': return 'موريتانيا';
      case 'SO': return 'الصومال';
      case 'US': return 'الولايات المتحدة';
      case 'GB': return 'المملكة المتحدة';
      case 'CH': return 'سويسرا';
      case 'EU': return 'أوروبا';
      case 'DE': return 'ألمانيا';
      case 'FR': return 'فرنسا';
      case 'CA': return 'كندا';
      case 'AU': return 'أستراليا';
      default: return 'البورصة العالمية';
    }
  }

  /// Returns the localized currency symbol based on the current app language.
  String get localizedCurrencySymbol => CurrencyUtils.getSymbol(currencyCode);

  const CountryModel({
    required this.code,
    required this.name,
    required this.flag,
    required this.currencyCode,
    required this.currencySymbol,
    this.defaultKarat = '21',
    this.region = 'region_arab',
    this.availableKarats = const ['24', '22', '21', '18', '14'],
    this.specialUnits = const [],
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    final countryCode = (json['code'] ?? 'GLOBAL').toString().toUpperCase();
    final nameKey = 'country_${countryCode.toLowerCase()}';
    final rawName = (json['name'] ?? json['nameAr'] ?? '').toString();
    final curr = (json['currency'] ?? json['currencyCode'] ?? 'USD').toString();

    return CountryModel(
      code: countryCode,
      name: (rawName.isNotEmpty && !rawName.startsWith('country_')) ? rawName : nameKey,
      flag: json['flag'] ?? '🌐',
      currencyCode: curr,
      currencySymbol: json['symbol'] ?? json['currencySymbol'] ?? CurrencyUtils.getSymbol(curr),
      defaultKarat: json['defaultKarat'] ?? '24',
      region: json['region'] ?? 'region_arab',
      availableKarats: (json['availableKarats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['24', '22', '21', '18', '14'],
      specialUnits: (json['specialUnits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'flag': flag,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'defaultKarat': defaultKarat,
        'region': region,
      };

  static List<CountryModel> get defaultCountries => [
        const CountryModel(
          code: 'DZ',
          name: 'country_dz',
          flag: '🇩🇿',
          currencyCode: 'DZD',
          currencySymbol: 'د.ج',
          defaultKarat: '21',
          region: 'region_north_africa',
          availableKarats: ['24', '22', '21', '18', '14', '9'],
          specialUnits: ['unit_scrap_gold_18k', 'unit_24k_bullions', 'unit_ounce'],
        ),
        CountryModel(
          code: 'EG',
          name: 'country_eg',
          flag: '🇪🇬',
          currencyCode: 'EGP',
          currencySymbol: 'ج.م',
          defaultKarat: '21',
          region: 'region_north_africa',
          availableKarats: ['24', '22', '21', '18', '14', '12'],
          specialUnits: ['auto_str_182'.tr(), 'auto_str_321'.tr(), 'auto_str_318'.tr(), 'auto_str_353'.tr()],
        ),
        const CountryModel(
          code: 'SA',
          name: 'country_sa',
          flag: '🇸🇦',
          currencyCode: 'SAR',
          currencySymbol: 'ر.س',
          defaultKarat: '24',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_10g_bullion', 'unit_50g_bullion', 'unit_100g_bullion', 'unit_1kg_gold'],
        ),
        CountryModel(
          code: 'AE',
          name: 'country_ae',
          flag: '🇦🇪',
          currencyCode: 'AED',
          currencySymbol: 'د.إ',
          defaultKarat: '24',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['auto_str_164'.tr(), 'auto_str_285'.tr(), 'auto_str_348'.tr()],
        ),
        CountryModel(
          code: 'IQ',
          name: 'country_iq',
          flag: '🇮🇶',
          currencyCode: 'IQD',
          currencySymbol: 'د.ع',
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['auto_str_211'.tr(), 'auto_str_212'.tr(), 'auto_str_295'.tr()],
        ),
        const CountryModel(
          code: 'KW',
          name: 'country_kw',
          flag: '🇰🇼',
          currencyCode: 'KWD',
          currencySymbol: 'د.ك',
          defaultKarat: '21',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_tola', 'unit_gold_lira', 'unit_gold_ounce'],
        ),
        const CountryModel(
          code: 'QA',
          name: 'country_qa',
          flag: '🇶🇦',
          currencyCode: 'QAR',
          currencySymbol: 'ر.ق',
          defaultKarat: '22',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce', 'unit_1kg_gold', 'unit_gold_bullions'],
        ),
        const CountryModel(
          code: 'OM',
          name: 'country_om',
          flag: '🇴🇲',
          currencyCode: 'OMR',
          currencySymbol: 'ر.ع',
          defaultKarat: '22',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce', 'unit_1kg_gold'],
        ),
        const CountryModel(
          code: 'BH',
          name: 'country_bh',
          flag: '🇧🇭',
          currencyCode: 'BHD',
          currencySymbol: 'د.ب',
          defaultKarat: '21',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce', 'unit_1kg_gold'],
        ),
        CountryModel(
          code: 'JO',
          name: 'country_jo',
          flag: '🇯🇴',
          currencyCode: 'JOD',
          currencySymbol: 'د.أ',
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '21', '18', '14'],
          specialUnits: ['auto_str_152'.tr(), 'auto_str_133'.tr(), 'auto_str_348'.tr()],
        ),
        const CountryModel(
          code: 'LB',
          name: 'country_lb',
          flag: '🇱🇧',
          currencyCode: 'LBP',
          currencySymbol: 'ل.ل',
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_gold_lira', 'unit_gold_ounce', 'unit_usd_pricing'],
        ),
        const CountryModel(
          code: 'LY',
          name: 'country_ly',
          flag: '🇱🇾',
          currencyCode: 'LYD',
          currencySymbol: 'د.ل',
          defaultKarat: '18',
          region: 'region_north_africa',
          availableKarats: ['24', '21', '18', '14'],
          specialUnits: ['unit_scrap_gold_18k', 'unit_scrap_gold_21k', 'unit_cast_gold', 'unit_lira'],
        ),
        const CountryModel(
          code: 'SY',
          name: 'country_sy',
          flag: '🇸🇾',
          currencyCode: 'SYP',
          currencySymbol: 'ل.س',
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_syrian_ounce', 'unit_gold_lira', 'unit_21k_gram'],
        ),
        const CountryModel(
          code: 'PS',
          name: 'country_ps',
          flag: '🇵🇸',
          currencyCode: 'ILS',
          currencySymbol: '₪',
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_gold_lira', 'unit_gold_ounce'],
        ),
        const CountryModel(
          code: 'YE',
          name: 'country_ye',
          flag: '🇾🇪',
          currencyCode: 'YER',
          currencySymbol: 'ر.ي',
          defaultKarat: '21',
          region: 'region_arab',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce', 'unit_gold_lira'],
        ),
        const CountryModel(
          code: 'MA',
          name: 'country_ma',
          flag: '🇲🇦',
          currencyCode: 'MAD',
          currencySymbol: 'د.م.',
          defaultKarat: '18',
          region: 'region_north_africa',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_scrap_gold_18k', 'unit_gold_ounce'],
        ),
        const CountryModel(
          code: 'TN',
          name: 'country_tn',
          flag: '🇹🇳',
          currencyCode: 'TND',
          currencySymbol: 'د.ت',
          defaultKarat: '18',
          region: 'region_north_africa',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_scrap_gold_18k', 'unit_gold_ounce'],
        ),
        const CountryModel(
          code: 'SD',
          name: 'country_sd',
          flag: '🇸🇩',
          currencyCode: 'SDG',
          currencySymbol: 'ج.س.',
          defaultKarat: '21',
          region: 'region_arab',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_gold_ounce'],
        ),
        const CountryModel(
          code: 'MR',
          name: 'country_mr',
          flag: '🇲🇷',
          currencyCode: 'MRU',
          currencySymbol: 'أ.م',
          defaultKarat: '21',
          region: 'region_arab',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce'],
        ),
        const CountryModel(
          code: 'SO',
          name: 'country_so',
          flag: '🇸🇴',
          currencyCode: 'SOS',
          currencySymbol: 'ش.ص',
          defaultKarat: '21',
          region: 'region_arab',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce'],
        ),
        CountryModel(
          code: 'TR',
          name: 'country_tr',
          flag: '🇹🇷',
          currencyCode: 'TRY',
          currencySymbol: '₺',
          defaultKarat: '24',
          region: 'region_eurasia',
          availableKarats: ['24', '22', '18', '14'],
          specialUnits: ['auto_str_187'.tr(), 'auto_str_216'.tr(), 'auto_str_227'.tr(), 'auto_str_304'.tr()],
        ),
        const CountryModel(
          code: 'EU',
          name: 'country_eu',
          flag: '🇪🇺',
          currencyCode: 'EUR',
          currencySymbol: '€',
          defaultKarat: '24',
          region: 'region_europe',
          availableKarats: ['24', '22', '18', '14', '9'],
          specialUnits: ['unit_euro_ounce', 'unit_1kg_gold', 'unit_investment_bullions'],
        ),
        const CountryModel(
          code: 'US',
          name: 'country_us',
          flag: '🇺🇸',
          currencyCode: 'USD',
          currencySymbol: '\$',
          defaultKarat: '24',
          region: 'region_global',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_gold_ounce', 'unit_1kg_gold'],
        ),
        const CountryModel(
          code: 'GB',
          name: 'country_gb',
          flag: '🇬🇧',
          currencyCode: 'GBP',
          currencySymbol: '£',
          defaultKarat: '24',
          region: 'region_europe',
          availableKarats: ['24', '22', '18', '14', '9'],
          specialUnits: ['unit_gold_ounce', 'unit_gold_sovereign'],
        ),
        const CountryModel(
          code: 'CH',
          name: 'country_ch',
          flag: '🇨🇭',
          currencyCode: 'CHF',
          currencySymbol: 'Fr',
          defaultKarat: '24',
          region: 'region_europe',
          availableKarats: ['24', '22', '18', '14', '9'],
          specialUnits: ['unit_gold_ounce', 'unit_1kg_gold'],
        ),
        CountryModel(
          code: 'GLOBAL',
          name: 'country_global',
          flag: '🌐',
          currencyCode: 'USD',
          currencySymbol: '\$',
          defaultKarat: '24',
          region: 'region_global',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['auto_str_178'.tr(), 'auto_str_179'.tr(), 'auto_str_293'.tr(), 'auto_str_294'.tr()],
        ),
      ];
}
