import 'package:flutter_test/flutter_test.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/core/config/app_config.dart';
import 'package:gold_sham/features/home/presentation/widgets/candlestick_chart_widget.dart';
import 'package:gold_sham/shared/services/local_market_calculator.dart';
import 'package:gold_sham/shared/models/country_model.dart';
import 'package:gold_sham/core/utils/currency_utils.dart';
import 'package:gold_sham/core/services/location_detector_service.dart';

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

  group('GPS Location Resolver Unit Tests', () {
    test('Resolves coordinates of major cities to accurate country codes', () async {
      final detector = LocationDetectorService();

      expect(await detector.resolveCoordinatesToCountry(33.5731, -7.5898), 'MA'); // Casablanca
      expect(await detector.resolveCoordinatesToCountry(23.5880, 58.3829), 'OM'); // Muscat
      expect(await detector.resolveCoordinatesToCountry(12.7855, 45.0187), 'YE'); // Aden
      expect(await detector.resolveCoordinatesToCountry(24.7136, 46.6753), 'SA'); // Riyadh
      expect(await detector.resolveCoordinatesToCountry(30.0444, 31.2357), 'EG'); // Cairo
      expect(await detector.resolveCoordinatesToCountry(33.5138, 36.2765), 'SY'); // Damascus
      expect(await detector.resolveCoordinatesToCountry(33.8938, 35.5018), 'LB'); // Beirut
      expect(await detector.resolveCoordinatesToCountry(41.0082, 28.9784), 'TR'); // Istanbul
      expect(await detector.resolveCoordinatesToCountry(25.2048, 55.2708), 'AE'); // Dubai
      expect(await detector.resolveCoordinatesToCountry(29.3759, 47.9774), 'KW'); // Kuwait City
    });
  });

  group('USD Currency Calculation & Formatting Tests', () {
    test('Morocco (MA), Oman (OM), and Yemen (YE) prices are commercially accurate', () {
      final calculator = LocalMarketCalculator();

      // Morocco (MAD ~ 9.39)
      const maCountry = CountryModel(code: 'MA', name: 'المغرب', flag: '🇲🇦', currencyCode: 'MAD', currencySymbol: 'د.م.');
      final maData = calculator.calculateMarketData(maCountry);
      expect(maData, isNotNull);
      final maItems = maData!['items'] as List;
      final maUsd = maItems.firstWhere((i) => i['id'] == 'ma_fx_usd');
      expect(maUsd['buyPrice'], closeTo(9.37, 0.20));

      // Oman (OMR ~ 0.385)
      const omCountry = CountryModel(code: 'OM', name: 'سلطنة عُمان', flag: '🇴🇲', currencyCode: 'OMR', currencySymbol: 'ر.ع');
      final omData = calculator.calculateMarketData(omCountry);
      expect(omData, isNotNull);
      final omItems = omData!['items'] as List;
      final omUsd = omItems.firstWhere((i) => i['id'] == 'om_fx_usd');
      expect(omUsd['buyPrice'], closeTo(0.384, 0.005));

      // Yemen (YE ~ 1,950 YER - NOT 250!)
      const yeCountry = CountryModel(code: 'YE', name: 'اليمن', flag: '🇾🇪', currencyCode: 'YER', currencySymbol: 'ر.ي');
      final yeData = calculator.calculateMarketData(yeCountry);
      expect(yeData, isNotNull);
      final yeItems = yeData!['items'] as List;
      final yeUsd = yeItems.firstWhere((i) => i['id'] == 'ye_fx_usd');
      expect(yeUsd['buyPrice'], greaterThan(1500.0));
      expect(yeUsd['buyPrice'], closeTo(1946.0, 50.0));
    });

    test('3-Decimal currencies format correctly with 3 decimals without digit truncation', () {
      // Oman
      expect(CurrencyUtils.getCompactFormula('USD', 0.385, 'OMR'), contains('0.385'));
      // Kuwait
      expect(CurrencyUtils.getCompactFormula('USD', 0.308, 'KWD'), contains('0.308'));
      // Bahrain
      expect(CurrencyUtils.getCompactFormula('USD', 0.376, 'BHD'), contains('0.376'));
      // Jordan
      expect(CurrencyUtils.getCompactFormula('USD', 0.709, 'JOD'), contains('0.709'));
    });
  });
}
