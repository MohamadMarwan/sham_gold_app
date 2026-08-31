/// Remote data source for prices.
///
/// Responsible for HTTP interactions. Maps raw JSON strings into Dart Maps.
/// Throws [AppException]s on failure.
import '../../../../core/services/http_api_service.dart';
import '../../../../core/error/app_exception.dart';

class PricesRemoteDataSource {
  final HttpApiService _httpService;

  PricesRemoteDataSource(this._httpService);

  /// Fetches market data for a specific country.
  Future<Map<String, dynamic>> getCountryMarketData(String countryCode) async {
    try {
      final response = await _httpService.get('/api/markets/$countryCode');
      if (response is Map<String, dynamic>) return response;
      throw ParseException('Unexpected response format for market data.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(e.toString());
    }
  }

  /// Fetches global markets summary.
  Future<Map<String, dynamic>> getGlobalSummary() async {
    try {
      final response = await _httpService.get('/api/markets/summary');
      if (response is Map<String, dynamic>) return response;
      throw ParseException('Unexpected response format for market summary.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(e.toString());
    }
  }
}
