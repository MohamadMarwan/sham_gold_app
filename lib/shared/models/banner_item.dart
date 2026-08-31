import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final Map<String, String>? translations;
  final String? imageUrl;
  final int color;
  final String type; // text, image, ad
  final String location; // home_top, syria_market_mid, etc.
  final String linkUrl;
  final String adCode;
  final String adSize;

  BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.translations,
    this.imageUrl,
    required this.color,
    this.type = 'text',
    this.location = 'home_top',
    this.linkUrl = '',
    this.adCode = '',
    this.adSize = 'banner',
  });

  String getLocalizedTitle(BuildContext context) {
    final lang = context.locale.languageCode;
    if (lang == 'en' && translations?['title_en'] != null && translations!['title_en']!.isNotEmpty) {
      return translations!['title_en']!;
    }
    if (lang == 'tr' && translations?['title_tr'] != null && translations!['title_tr']!.isNotEmpty) {
      return translations!['title_tr']!;
    }
    return title; // Default to Arabic/original
  }

  String getLocalizedSubtitle(BuildContext context) {
    final lang = context.locale.languageCode;
    if (lang == 'en' && translations?['subtitle_en'] != null && translations!['subtitle_en']!.isNotEmpty) {
      return translations!['subtitle_en']!;
    }
    if (lang == 'tr' && translations?['subtitle_tr'] != null && translations!['subtitle_tr']!.isNotEmpty) {
      return translations!['subtitle_tr']!;
    }
    return subtitle; // Default to Arabic/original
  }

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedTranslations;
    if (json['translations'] != null) {
      parsedTranslations = Map<String, String>.from(json['translations']);
    }
    
    return BannerItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      translations: parsedTranslations,
      imageUrl: json['imageUrl'],
      color: json['color'] is int
          ? json['color']
          : int.tryParse(json['color']?.toString() ?? '0') ?? 0,
      type: json['type'] ?? 'text',
      location: json['location'] ?? 'home_top',
      linkUrl: json['linkUrl'] ?? '',
      adCode: json['adCode'] ?? '',
      adSize: json['adSize'] ?? 'banner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'translations': translations,
      'imageUrl': imageUrl,
      'color': color,
      'type': type,
      'location': location,
      'linkUrl': linkUrl,
      'adCode': adCode,
      'adSize': adSize,
    };
  }
}
