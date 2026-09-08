import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../shared/models/price_item.dart';

class WidgetService {
  static const String appGroupId = 'group.com.goldsham.widget'; // For iOS
  static const String iOSWidgetName = 'GoldShamWidget';
  static const String androidWidgetName = 'GoldShamWidgetReceiver';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error initializing home_widget: $e');
    }
  }

  static Future<void> updateWidgetData(List<PriceItem> prices) async {
    if (kIsWeb) return;
    try {
      final importantPrices = prices.where((p) => 
        p.id == 'xau_usd' || p.id == 'gold_21k_usd' || p.id == 'gold_18k_usd' || p.id == 'gold_24k_usd'
      ).toList();
      
      final priceMap = {
        for (var p in importantPrices) p.id: {
          'title': p.title,
          'buyPrice': p.buyPrice,
          'currency': p.currency,
          'trend': p.trend,
        }
      };
      
      await HomeWidget.saveWidgetData('widgetData', json.encode(priceMap));
      await HomeWidget.saveWidgetData('lastUpdate', DateTime.now().toIso8601String());
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget data: $e');
    }
  }
}
