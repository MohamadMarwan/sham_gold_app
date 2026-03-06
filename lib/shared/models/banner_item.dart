class BannerItem {
  final String id;
  final String title;
  final String subtitle;
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
    this.imageUrl,
    required this.color,
    this.type = 'text',
    this.location = 'home_top',
    this.linkUrl = '',
    this.adCode = '',
    this.adSize = 'banner',
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
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
