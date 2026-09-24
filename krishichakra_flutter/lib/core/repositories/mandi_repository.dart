import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

final mandiRepositoryProvider = Provider<MandiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MandiRepository(apiClient: apiClient);
});

/// Fetches the overall government mandi sync status
final mandiStatusProvider = FutureProvider<MandiStatus>((ref) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getMandiStatus();
});

/// Fetches latest mandi prices, optionally filtered by commodity
final latestMandiPricesProvider =
    FutureProvider.family<List<MandiPrice>, String?>((ref, commodity) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getLatestPrices(commodity: commodity);
});

/// Fetches historic mandi prices for a given commodity and optional market
final mandiHistoryProvider = FutureProvider.family<
    List<MandiPrice>,
    ({String commodity, String? market})>((ref, arg) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getPriceHistory(arg.commodity, market: arg.market);
});

typedef MandiFilterQuery = ({
  String? commodity,
  String? state,
  String? district,
  String? market,
  int? limit,
});

/// Fetches mandi prices with multi-dimensional filtering (commodity, state, district, market)
final filteredMandiPricesProvider =
    FutureProvider.family<List<MandiPrice>, MandiFilterQuery>((ref, filter) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getPrices(
    commodity: filter.commodity,
    state: filter.state,
    district: filter.district,
    market: filter.market,
    limit: filter.limit ?? 100,
  );
});

/// Extracts available states, districts, markets, and commodities from current government dataset
final availableMandiFiltersProvider = FutureProvider<
    ({
      List<String> states,
      List<String> districts,
      List<String> markets,
      List<String> commodities,
    })>((ref) async {
  final repo = ref.watch(mandiRepositoryProvider);
  final allPrices = await repo.getPrices(limit: 500);
  final states = allPrices
      .map((p) => p.state.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final districts = allPrices
      .map((p) => p.district.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final markets = allPrices
      .map((p) => p.market.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final commodities = allPrices
      .map((p) => p.commodity.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return (
    states: states,
    districts: districts,
    markets: markets,
    commodities: commodities,
  );
});

class MandiRepository {
  const MandiRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Retrieves sync and data provenance status: GET /api/mandi/status
  Future<MandiStatus> getMandiStatus() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.mandiStatus,
    );

    final data = response.data;
    if (data == null) {
      throw const ApiException(message: 'Failed to retrieve mandi status: empty response.');
    }
    return MandiStatus.fromJson(data);
  }

  /// Retrieves latest prices per market: GET /api/mandi/latest
  Future<List<MandiPrice>> getLatestPrices({
    String? commodity,
    String? state,
    String? district,
    String? market,
  }) async {
    final queryParams = <String, dynamic>{
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (market != null && market.isNotEmpty) 'market': market,
    };

    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.mandiLatest,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MandiPrice.fromJson)
        .toList();
  }

  /// Retrieves all price records with optional filters: GET /api/mandi/prices
  Future<List<MandiPrice>> getPrices({
    String? commodity,
    String? state,
    String? district,
    String? market,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (market != null && market.isNotEmpty) 'market': market,
      'limit': limit,
    };

    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.mandiPrices,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MandiPrice.fromJson)
        .toList();
  }

  /// Retrieves chronological price history: GET /api/mandi/history
  Future<List<MandiPrice>> getPriceHistory(
    String commodity, {
    String? market,
    int days = 30,
  }) async {
    final queryParams = <String, dynamic>{
      'commodity': commodity,
      if (market != null && market.isNotEmpty) 'market': market,
      'days': days,
    };

    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.mandiHistory,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MandiPrice.fromJson)
        .toList();
  }

  /// Manually triggers government mandi sync: POST /api/mandi/sync
  Future<Map<String, dynamic>> triggerSync() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.mandiSync,
    );
    return response.data ?? {};
  }
}
