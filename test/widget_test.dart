import 'package:flutter_test/flutter_test.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/core/config/app_config.dart';
import 'package:gold_sham/features/home/presentation/widgets/candlestick_chart_widget.dart';

void main() {
  group('PriceItem Model Unit Tests', () {
    test('Correctly deserializes from full JSON payload', () {
      final json = {
        'id': 'gold_21k_syp',
        'title': 'ذهب عيار 21',
        'buyPrice': 1050000.0,
        'sellPrice': 1060000.0,
        'currency': 'SYP',
        'trend': 0, // Trend.up
        'metalType': 'gold',
        'changePercentage': 1.25,
        'usdPrice': 78.5,
        'externalId': 'sp_today_21',
        'lastUpdate': '2026-09-03T12:00:00.000Z',
        'isManual': false,
      };

      final item = PriceItem.fromJson(json);

      expect(item.id, 'gold_21k_syp');
      expect(item.title, 'ذهب عيار 21');
      expect(item.buyPrice, 1050000.0);
      expect(item.sellPrice, 1060000.0);
      expect(item.currency, 'SYP');
      expect(item.trend, Trend.up);
      expect(item.metalType, 'gold');
      expect(item.changePercentage, 1.25);
      expect(item.usdPrice, 78.5);
      expect(item.externalId, 'sp_today_21');
      expect(item.lastUpdate, isNotNull);
      expect(item.isManual, isFalse);
    });

    test('Handles missing / null fields gracefully with fallbacks', () {
      final minimalJson = <String, dynamic>{
        '_id': 'gold_ounce',
        'title': 'أونصة الذهب',
      };

      final item = PriceItem.fromJson(minimalJson);

      expect(item.id, 'gold_ounce');
      expect(item.title, 'أونصة الذهب');
      expect(item.buyPrice, 0.0);
      expect(item.sellPrice, 0.0);
      expect(item.currency, 'SYP');
      expect(item.trend, Trend.stable);
      expect(item.metalType, 'gold');
      expect(item.changePercentage, 0.0);
      expect(item.usdPrice, 0.0);
      expect(item.externalId, isNull);
      expect(item.lastUpdate, isNull);
      expect(item.isManual, isFalse);
    });

    test('Serializes to JSON accurately', () {
      final item = PriceItem(
        id: 'silver_gram',
        title: 'فضة عيار 999',
        buyPrice: 42.5,
        sellPrice: 45.0,
        currency: 'USD',
        trend: Trend.down,
        metalType: 'silver',
        changePercentage: -0.5,
        usdPrice: 42.5,
        isManual: true,
      );

      final json = item.toJson();

      expect(json['id'], 'silver_gram');
      expect(json['title'], 'فضة عيار 999');
      expect(json['buyPrice'], 42.5);
      expect(json['sellPrice'], 45.0);
      expect(json['currency'], 'USD');
      expect(json['trend'], Trend.down.index);
      expect(json['metalType'], 'silver');
      expect(json['changePercentage'], -0.5);
      expect(json['usdPrice'], 42.5);
      expect(json['isManual'], isTrue);
    });
  });

  group('AppConfig Configuration Tests', () {
    test('Default base URL is defined and valid format', () {
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.baseUrl.startsWith('http'), isTrue);
    });

    test('Socket.io configuration contains essential transports and retry parameters', () {
      const options = AppConfig.socketOptions;
      expect(options, contains('transports'));
      expect(options['transports'], contains('websocket'));
      expect(options['transports'], contains('polling'));
      expect(options['reconnectionAttempts'], greaterThan(0));
    });
  });

  group('Interactive Chart Models & Logic Tests', () {
    test('ChartData correctly stores OHLC points', () {
      final now = DateTime.now();
      final cd = ChartData(now, 100.0, 105.0, 98.0, 103.0);

      expect(cd.x, now);
      expect(cd.open, 100.0);
      expect(cd.high, 105.0);
      expect(cd.low, 98.0);
      expect(cd.close, 103.0);
      expect(cd.high, greaterThanOrEqualTo(cd.low));
    });
  });
}
