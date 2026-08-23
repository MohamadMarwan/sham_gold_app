/// Interface for prices data operations.
///
/// Defines the contract for fetching prices from remote or local sources.
import '../domain/entities/price_entity.dart';

abstract class PricesRepository {
  /// Fetches the latest prices for a specific [countryCode] (e.g. 'SY', 'TR').
  Future<List<PriceEntity>> getPrices(String countryCode);

  /// Fetches the global market summary (all countries combined).
  Future<Map<String, dynamic>> getGlobalSummary();
}
