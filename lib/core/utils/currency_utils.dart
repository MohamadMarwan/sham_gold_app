import 'package:intl/intl.dart';

class CurrencyUtils {
  static String getSymbol(String currency, {String id = ''}) {
    if (currency == 'USD') return '\$';
    if (currency == 'TRY' || id.startsWith('tr_')) return '₺';
    if (currency == 'EUR') return '€';
    if (currency == 'SYP') return 'ل.س';
    return currency;
  }

  static String getLocale(String currency, {String id = ''}) {
    if (currency == 'USD') return 'en_US';
    if (currency == 'TRY' || id.startsWith('tr_')) return 'tr_TR';
    if (currency == 'EUR') return 'de_DE';
    return 'ar_SY';
  }

  static String formatPrice(double price, String currency, {String id = ''}) {
    final locale = getLocale(currency, id: id);
    final symbol = getSymbol(currency, id: id);
    final format = NumberFormat("#,##0.##", locale);
    return '${format.format(price)} $symbol';
  }
}
