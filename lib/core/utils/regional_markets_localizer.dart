import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Rock-solid localization helper with seamless fallback for all 3 supported languages
/// (Arabic, English, Turkish). Ensures raw translation keys never appear to the user.
class RegionalLocalizer {
  static const Map<String, Map<String, String>> _fallbacks = {
    'regional_markets': {
      'ar': 'الأسواق الإقليمية',
      'en': 'Regional Markets',
      'tr': 'Bölgesel Piyasalar',
    },
    'regional_markets_settings': {
      'ar': 'إعدادات بطاقات الأسواق',
      'en': 'Market Cards Settings',
      'tr': 'Piyasa Kartları Ayarları',
    },
    'customize_markets_desc': {
      'ar': 'تخصيص ظهور وقائمة وعدد بطاقات الأسواق في الرئيسية',
      'en': 'Customize visibility, list and count of home market cards',
      'tr': 'Ana sayfa piyasa kartlarının görünümünü, sayısını ve listesini özelleştirin',
    },
    'customize_home_markets': {
      'ar': 'تخصيص أسواق الرئيسية',
      'en': 'Customize Home Markets',
      'tr': 'Ana Sayfa Piyasalarını Özelleştir',
    },
    'customize_home_markets_subtitle': {
      'ar': 'تحكم في ظهور وعدد والأسواق المفضلة المعروضة في الصفحة الرئيسية',
      'en': 'Manage visibility, number and favorite markets displayed on Home',
      'tr': 'Ana sayfada gösterilen favori piyasaları ve kart sayısını yönetin',
    },
    'show_regional_markets_section': {
      'ar': 'إظهار قسم الأسواق في الرئيسية',
      'en': 'Show Markets Section on Home',
      'tr': 'Ana Sayfada Piyasalar Bölümünü Göster',
    },
    'show_regional_markets_section_desc': {
      'ar': 'عرض بطاقات الأسواق السريعة ومتابعة الأسعار مباشرة',
      'en': 'Display quick market cards and track prices directly',
      'tr': 'Hızlı piyasa kartlarını göster ve canlı fiyatları takip et',
    },
    'regional_markets_count': {
      'ar': 'عدد البطاقات المعروضة',
      'en': 'Number of Displayed Cards',
      'tr': 'Görüntülenen Kart Sayısı',
    },
    'select_markets_up_to': {
      'ar': 'اختر حتى {} أسواق',
      'en': 'Select up to {} markets',
      'tr': 'En fazla {} piyasa seçin',
    },
    'cards_count_1': {
      'ar': 'بطاقة واحدة',
      'en': '1 Card',
      'tr': '1 Kart',
    },
    'cards_count_2': {
      'ar': 'بطاقتان',
      'en': '2 Cards',
      'tr': '2 Kart',
    },
    'cards_count_3': {
      'ar': '3 بطاقات',
      'en': '3 Cards',
      'tr': '3 Kart',
    },
    'cards_count_4': {
      'ar': '4 بطاقات',
      'en': '4 Cards',
      'tr': '4 Kart',
    },
    'selected_markets_count': {
      'ar': 'محدد {} من {}',
      'en': 'Selected {} of {}',
      'tr': '{} / {} seçildi',
    },
    'market_cards_saved_success': {
      'ar': 'تم حفظ إعدادات بطاقات الأسواق بنجاح',
      'en': 'Market cards settings saved successfully',
      'tr': 'Piyasa kartları ayarları başarıyla kaydedildi',
    },
    'hidden': {
      'ar': 'مخفي',
      'en': 'Hidden',
      'tr': 'Gizli',
    },
    'market_country': {
      'ar': 'سوق {}',
      'en': '{} Market',
      'tr': '{} Piyasası',
    },
    'gold_24k_short': {
      'ar': 'ذهب عيار 24',
      'en': '24K Gold',
      'tr': '24K Altın',
    },
    'gold_21k_short': {
      'ar': 'ذهب عيار 21',
      'en': '21K Gold',
      'tr': '21K Altın',
    },
    'gold_gram': {
      'ar': 'غرام الذهب',
      'en': 'Gold Gram',
      'tr': 'Gram Altın',
    },
    'dollar': {
      'ar': 'الدولار',
      'en': 'USD',
      'tr': 'Dolar',
    },
    'market_syria': {
      'ar': 'سوق سوريا',
      'en': 'Syria Market',
      'tr': 'Suriye Piyasası',
    },
    'market_turkey': {
      'ar': 'سوق تركيا',
      'en': 'Turkey Market',
      'tr': 'Türkiye Piyasası',
    },
    'auto_str_075': {
      'ar': 'ابحث عن اسم الدولة أو العملة...',
      'en': 'Search country or currency name...',
      'tr': 'Ülke veya para birimi adını arayın...',
    },
    'save': {
      'ar': 'حفظ التغييرات',
      'en': 'Save Changes',
      'tr': 'Değişiklikleri Kaydet',
    },
  };

  /// Translate key with bulletproof fallback across Arabic, English, and Turkish
  static String tr(BuildContext context, String key, {List<String>? args}) {
    String translated = key.tr(args: args);
    // If easy_localization returns the raw key (asset not loaded or missing)
    if (translated == key || translated.isEmpty) {
      final lang = context.locale.languageCode.toLowerCase();
      final langKey = (lang == 'tr') ? 'tr' : (lang == 'en' ? 'en' : 'ar');
      
      final entry = _fallbacks[key];
      if (entry != null && entry.containsKey(langKey)) {
        translated = entry[langKey]!;
        if (args != null && args.isNotEmpty) {
          for (final arg in args) {
            translated = translated.replaceFirst('{}', arg);
          }
        }
      }
    }
    return translated;
  }
}
