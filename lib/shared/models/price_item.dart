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
  final String? externalId;
  final DateTime? lastUpdate;
  final bool isManual;

  PriceItem({
    required this.id,
    required this.title,
    required this.buyPrice,
    required this.sellPrice,
    required this.currency,
    required this.trend,
    required this.metalType,
    this.changePercentage = 0.0,
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
}
