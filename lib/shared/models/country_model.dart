import 'package:easy_localization/easy_localization.dart';
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
    return CountryModel(
      code: json['code'] ?? 'GLOBAL',
      name: json['name'] ?? 'country_global',
      flag: json['flag'] ?? '🌐',
      currencyCode: json['currency'] ?? json['currencyCode'] ?? 'USD',
      currencySymbol: json['symbol'] ?? json['currencySymbol'] ?? '\$',
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
        CountryModel(
          code: 'DZ',
          name: 'country_dz',
          flag: '🇩🇿',
          currencyCode: 'DZD',
          currencySymbol: 'auto_str_372'.tr(),
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
          currencySymbol: 'auto_str_369'.tr(),
          defaultKarat: '21',
          region: 'region_north_africa',
          availableKarats: ['24', '22', '21', '18', '14', '12'],
          specialUnits: ['auto_str_182'.tr(), 'auto_str_321'.tr(), 'auto_str_318'.tr(), 'auto_str_353'.tr()],
        ),
        CountryModel(
          code: 'SA',
          name: 'country_sa',
          flag: '🇸🇦',
          currencyCode: 'SAR',
          currencySymbol: 'auto_str_377'.tr(),
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
          currencySymbol: 'auto_str_371'.tr(),
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
          currencySymbol: 'auto_str_373'.tr(),
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['auto_str_211'.tr(), 'auto_str_212'.tr(), 'auto_str_295'.tr()],
        ),
        CountryModel(
          code: 'KW',
          name: 'country_kw',
          flag: '🇰🇼',
          currencyCode: 'KWD',
          currencySymbol: 'auto_str_374'.tr(),
          defaultKarat: '21',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_tola', 'unit_gold_lira', 'unit_gold_ounce'],
        ),
        CountryModel(
          code: 'QA',
          name: 'country_qa',
          flag: '🇶🇦',
          currencyCode: 'QAR',
          currencySymbol: 'auto_str_378'.tr(),
          defaultKarat: '22',
          region: 'region_arabian_gulf',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['unit_gold_ounce', 'unit_1kg_gold', 'unit_gold_bullions'],
        ),
        CountryModel(
          code: 'JO',
          name: 'country_jo',
          flag: '🇯🇴',
          currencyCode: 'JOD',
          currencySymbol: 'auto_str_370'.tr(),
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '21', '18', '14'],
          specialUnits: ['auto_str_152'.tr(), 'auto_str_133'.tr(), 'auto_str_348'.tr()],
        ),
        CountryModel(
          code: 'LB',
          name: 'country_lb',
          flag: '🇱🇧',
          currencyCode: 'LBP',
          currencySymbol: 'auto_str_382'.tr(),
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_gold_lira', 'unit_gold_ounce', 'unit_usd_pricing'],
        ),
        CountryModel(
          code: 'LY',
          name: 'country_ly',
          flag: '🇱🇾',
          currencyCode: 'LYD',
          currencySymbol: 'auto_str_375'.tr(),
          defaultKarat: '18',
          region: 'region_north_africa',
          availableKarats: ['24', '21', '18', '14'],
          specialUnits: ['unit_scrap_gold_18k', 'unit_scrap_gold_21k', 'unit_cast_gold', 'unit_lira'],
        ),
        CountryModel(
          code: 'SY',
          name: 'country_sy',
          flag: '🇸🇾',
          currencyCode: 'SYP',
          currencySymbol: 'auto_str_381'.tr(),
          defaultKarat: '21',
          region: 'region_levant',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['unit_syrian_ounce', 'unit_gold_lira', 'unit_21k_gram'],
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
        CountryModel(
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
