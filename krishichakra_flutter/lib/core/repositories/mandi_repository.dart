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

/// Fetches deduplicated live mandi pulse per normalized commodity
final mandiPulseProvider =
    FutureProvider.family<List<MandiPrice>, String?>((ref, state) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getMandiPulse(state: state, limit: 50);
});

/// Fetches unified normalized commodity catalogue
final commodityCatalogueProvider =
    FutureProvider.family<List<CommodityCatalogueItem>, String?>((ref, state) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getCommodityCatalogue(state: state);
});

/// Fetches historic mandi prices for a given commodity and optional market
final mandiHistoryProvider = FutureProvider.family<
    List<MandiPrice>,
    ({String commodity, String? market})>((ref, arg) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getPriceHistory(arg.commodity, market: arg.market, days: 365);
});

/// Fetches structured daily mandi price history with exact calendar window
final mandiDailyHistoryProvider = FutureProvider.family<
    MandiDailyHistory,
    ({String commodity, String? market, String? period})>((ref, arg) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getDailyPriceHistory(
    arg.commodity,
    market: arg.market,
    period: arg.period ?? '7d',
  );
});

typedef MandiFilterQuery = ({
  String? commodity,
  String? state,
  String? district,
  String? market,
  String? variety,
  int? limit,
});

/// Fetches mandi prices with multi-dimensional filtering (commodity, state, district, market, variety)
final filteredMandiPricesProvider =
    FutureProvider.family<List<MandiPrice>, MandiFilterQuery>((ref, filter) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getPrices(
    commodity: filter.commodity,
    state: filter.state,
    district: filter.district,
    market: filter.market,
    variety: filter.variety,
    limit: filter.limit ?? 100,
  );
});

typedef MandiCascadeFilterQuery = ({
  String? state,
  String? district,
  String? market,
  String? commodity,
});

/// Fetches dynamic cascaded filters (State -> District -> Market -> Commodity -> Variety)
final dynamicMandiFiltersProvider =
    FutureProvider.family<MandiFiltersData, MandiCascadeFilterQuery>((ref, query) async {
  final repo = ref.watch(mandiRepositoryProvider);
  return repo.getMandiFilters(
    state: query.state,
    district: query.district,
    market: query.market,
    commodity: query.commodity,
  );
});

/// Extracts available states, districts, markets, commodities, and varieties from current government dataset
final availableMandiFiltersProvider = FutureProvider<
    ({
      List<String> states,
      List<String> districts,
      List<String> markets,
      List<String> commodities,
      List<String> varieties,
    })>((ref) async {
  final repo = ref.watch(mandiRepositoryProvider);
  final data = await repo.getMandiFilters();
  return (
    states: data.states,
    districts: data.districts,
    markets: data.markets,
    commodities: data.commodities,
    varieties: data.varieties,
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

  /// Retrieves dynamic cascaded filters: GET /api/mandi/filters
  Future<MandiFiltersData> getMandiFilters({
    String? state,
    String? district,
    String? market,
    String? commodity,
  }) async {
    final queryParams = <String, dynamic>{
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (market != null && market.isNotEmpty) 'market': market,
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.mandiFilters,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return MandiFiltersData.empty;
    return MandiFiltersData.fromJson(data);
  }

  /// Retrieves latest prices per market: GET /api/mandi/latest
  Future<List<MandiPrice>> getLatestPrices({
    String? commodity,
    String? state,
    String? district,
    String? market,
    String? variety,
  }) async {
    final queryParams = <String, dynamic>{
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (market != null && market.isNotEmpty) 'market': market,
      if (variety != null && variety.isNotEmpty) 'variety': variety,
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

  /// Retrieves deduplicated live mandi pulse per normalized commodity: GET /api/mandi/pulse
  Future<List<MandiPrice>> getMandiPulse({
    String? state,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      if (state != null && state.isNotEmpty) 'state': state,
      'limit': limit,
    };

    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.mandiPulse,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MandiPrice.fromJson)
        .toList();
  }

  /// Retrieves unified normalized commodity catalogue: GET /api/mandi/commodities
  Future<List<CommodityCatalogueItem>> getCommodityCatalogue({
    String? state,
  }) async {
    final queryParams = <String, dynamic>{
      if (state != null && state.isNotEmpty) 'state': state,
    };

    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.mandiCommodities,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CommodityCatalogueItem.fromJson)
        .toList();
  }

  /// Retrieves all price records with optional filters: GET /api/mandi/prices
  Future<List<MandiPrice>> getPrices({
    String? commodity,
    String? state,
    String? district,
    String? market,
    String? variety,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (market != null && market.isNotEmpty) 'market': market,
      if (variety != null && variety.isNotEmpty) 'variety': variety,
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

  /// Retrieves structured daily price history: GET /api/mandi/history
  Future<MandiDailyHistory> getDailyPriceHistory(
    String commodity, {
    String? market,
    String? state,
    String? district,
    String? variety,
    int? days,
    String? period,
  }) async {
    final queryParams = <String, dynamic>{
      'commodity': commodity,
      if (market != null && market.isNotEmpty) 'market': market,
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (variety != null && variety.isNotEmpty) 'variety': variety,
      if (days != null) 'days': days,
      if (period != null && period.isNotEmpty) 'period': period,
    };

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.mandiHistory,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MandiDailyHistory.fromJson(data);
    } else if (data is List) {
      final list = data
          .whereType<Map<String, dynamic>>()
          .map(MandiHistoryPoint.fromJson)
          .toList();
      return MandiDailyHistory(
        commodity: commodity,
        market: market ?? '',
        source: 'Government Market Data',
        requestedStartDate: '',
        requestedEndDate: '',
        datesChecked: list.length,
        datesWithData: list.where((e) => e.hasData).length,
        missingDates: list.where((e) => !e.hasData).length,
        period: period ?? '7d',
        summary: MandiHistorySummary(
          recordsCount: list.where((e) => e.hasData).length,
        ),
        records: list,
      );
    }
    return MandiDailyHistory(
      commodity: commodity,
      market: market ?? '',
      source: 'Government Market Data',
      requestedStartDate: '',
      requestedEndDate: '',
      datesChecked: 0,
      datesWithData: 0,
      missingDates: 0,
      period: period ?? '7d',
      summary: const MandiHistorySummary(),
      records: const [],
    );
  }

  /// Retrieves chronological price history: GET /api/mandi/history
  Future<List<MandiPrice>> getPriceHistory(
    String commodity, {
    String? market,
    int days = 365,
  }) async {
    final history = await getDailyPriceHistory(
      commodity,
      market: market,
      days: days,
    );
    int counter = 1;
    return history.records
        .where((r) => r.hasData)
        .map<MandiPrice>((r) => MandiPrice(
              id: counter++,
              commodity: r.commodity,
              market: r.market,
              state: r.state ?? '',
              district: r.district ?? '',
              variety: r.variety ?? '',
              minPrice: r.minPrice ?? 0.0,
              modalPrice: r.modalPrice ?? 0.0,
              maxPrice: r.maxPrice ?? 0.0,
              arrivalDate: r.date,
              arrivalQuantity: null,
              unit: r.unit,
              source: r.source.isNotEmpty
                  ? r.source
                  : 'Government Market Data',
            ))
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
