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
    this.region = 'عربي',
    this.availableKarats = const ['24', '22', '21', '18', '14'],
    this.specialUnits = const [],
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      code: json['code'] ?? 'GLOBAL',
      name: json['name'] ?? 'البورصة العالمية',
      flag: json['flag'] ?? '🌐',
      currencyCode: json['currency'] ?? json['currencyCode'] ?? 'USD',
      currencySymbol: json['symbol'] ?? json['currencySymbol'] ?? '\$',
      defaultKarat: json['defaultKarat'] ?? '24',
      region: json['region'] ?? 'عربي',
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

  static List<CountryModel> get defaultCountries => const [
        CountryModel(
          code: 'DZ',
          name: 'الجزائر',
          flag: '🇩🇿',
          currencyCode: 'DZD',
          currencySymbol: 'د.ج',
          defaultKarat: '21',
          region: 'شمال أفريقيا',
          availableKarats: ['24', '22', '21', '18', '14', '9'],
          specialUnits: ['ذهب كسر 18', 'سبائك 24', 'أونصة'],
        ),
        CountryModel(
          code: 'EG',
          name: 'مصر',
          flag: '🇪🇬',
          currencyCode: 'EGP',
          currencySymbol: 'ج.م',
          defaultKarat: '21',
          region: 'شمال أفريقيا',
          availableKarats: ['24', '22', '21', '18', '14', '12'],
          specialUnits: ['الجنيه الذهب (8غ)', 'نصف جنيه', 'ربع جنيه', 'سبيكة'],
        ),
        CountryModel(
          code: 'SA',
          name: 'السعودية',
          flag: '🇸🇦',
          currencyCode: 'SAR',
          currencySymbol: 'ر.س',
          defaultKarat: '24',
          region: 'الخليج العربي',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['سبيكة 10غ', 'سبيكة 50غ', 'سبيكة 100غ', 'كيلو الذهب'],
        ),
        CountryModel(
          code: 'AE',
          name: 'الإمارات',
          flag: '🇦🇪',
          currencyCode: 'AED',
          currencySymbol: 'د.إ',
          defaultKarat: '24',
          region: 'الخليج العربي',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['تولة الذهب (11.66غ)', 'سبيكة كيلو', 'أونصة'],
        ),
        CountryModel(
          code: 'IQ',
          name: 'العراق',
          flag: '🇮🇶',
          currencyCode: 'IQD',
          currencySymbol: 'د.ع',
          defaultKarat: '21',
          region: 'المشرق العربي',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['مثقال خليجي (5غ)', 'مثقال عراقي (5غ)', 'ليرة الذهب'],
        ),
        CountryModel(
          code: 'KW',
          name: 'الكويت',
          flag: '🇰🇼',
          currencyCode: 'KWD',
          currencySymbol: 'د.ك',
          defaultKarat: '21',
          region: 'الخليج العربي',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['تولة الذهب', 'ليرة الذهب', 'أونصة الذهب'],
        ),
        CountryModel(
          code: 'QA',
          name: 'قطر',
          flag: '🇶🇦',
          currencyCode: 'QAR',
          currencySymbol: 'ر.ق',
          defaultKarat: '22',
          region: 'الخليج العربي',
          availableKarats: ['24', '22', '21', '18'],
          specialUnits: ['أونصة الذهب', 'كيلو الذهب', 'سبائك الذهب'],
        ),
        CountryModel(
          code: 'JO',
          name: 'الأردن',
          flag: '🇯🇴',
          currencyCode: 'JOD',
          currencySymbol: 'د.أ',
          defaultKarat: '21',
          region: 'المشرق العربي',
          availableKarats: ['24', '21', '18', '14'],
          specialUnits: ['الليرة الرشادية (7غ)', 'الليرة الإنجليزية (8غ)', 'أونصة'],
        ),
        CountryModel(
          code: 'LB',
          name: 'لبنان',
          flag: '🇱🇧',
          currencyCode: 'LBP',
          currencySymbol: 'ل.ل',
          defaultKarat: '21',
          region: 'المشرق العربي',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['الليرة الذهبية', 'أونصة الذهب', 'تسعير USD'],
        ),
        CountryModel(
          code: 'LY',
          name: 'ليبيا',
          flag: '🇱🇾',
          currencyCode: 'LYD',
          currencySymbol: 'د.ل',
          defaultKarat: '18',
          region: 'شمال أفريقيا',
          availableKarats: ['24', '21', '18', '14'],
          specialUnits: ['ذهب كسر 18', 'ذهب كسر 21', 'مسبوك', 'ليرة'],
        ),
        CountryModel(
          code: 'SY',
          name: 'سوريا',
          flag: '🇸🇾',
          currencyCode: 'SYP',
          currencySymbol: 'ل.س',
          defaultKarat: '21',
          region: 'المشرق العربي',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['الأونصة السورية', 'الليرة الذهبية', 'غرام 21 صاغة'],
        ),
        CountryModel(
          code: 'TR',
          name: 'تركيا',
          flag: '🇹🇷',
          currencyCode: 'TRY',
          currencySymbol: '₺',
          defaultKarat: '24',
          region: 'أوراسيا',
          availableKarats: ['24', '22', '18', '14'],
          specialUnits: ['ربع ليرة (Çeyrek)', 'نصف ليرة (Yarım)', 'ليرة تامة (Tam)', 'ذهب مسحوب'],
        ),
        CountryModel(
          code: 'EU',
          name: 'أوروبا',
          flag: '🇪🇺',
          currencyCode: 'EUR',
          currencySymbol: '€',
          defaultKarat: '24',
          region: 'أوروبا',
          availableKarats: ['24', '22', '18', '14', '9'],
          specialUnits: ['أونصة اليورو', 'كيلو الذهب', 'سبائك استثمارية'],
        ),
        CountryModel(
          code: 'GLOBAL',
          name: 'البورصة العالمية',
          flag: '🌐',
          currencyCode: 'USD',
          currencySymbol: '\$',
          defaultKarat: '24',
          region: 'عالمي',
          availableKarats: ['24', '22', '21', '18', '14'],
          specialUnits: ['أونصة الذهب (XAU)', 'أونصة الفضة (XAG)', 'كيلو الذهب', 'كيلو الفضة'],
        ),
      ];
}
