import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

class LogisticsRepository {
  LogisticsRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  /// Fetch transport / logistics options with optional filters
  Future<List<LogisticsOption>> fetchLogisticsOptions({
    String? origin,
    String? destination,
    bool availableOnly = true,
  }) async {
    final queryParams = <String, dynamic>{
      'available_only': availableOnly,
    };
    if (origin != null && origin.isNotEmpty) {
      queryParams['origin'] = origin;
    }
    if (destination != null && destination.isNotEmpty) {
      queryParams['destination'] = destination;
    }

    final res = await _client.get(
      ApiEndpoints.logisticsOptions,
      queryParameters: queryParams,
    );
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => LogisticsOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Fetch storage options / facilities with optional filters
  Future<List<StorageOption>> fetchStorageOptions({
    String? location,
    String? storageType,
    bool availableOnly = true,
  }) async {
    final queryParams = <String, dynamic>{
      'available_only': availableOnly,
    };
    if (location != null && location.isNotEmpty) {
      queryParams['location'] = location;
    }
    if (storageType != null && storageType.isNotEmpty) {
      queryParams['storage_type'] = storageType;
    }

    final res = await _client.get(
      ApiEndpoints.storageOptions,
      queryParameters: queryParams,
    );
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => StorageOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Create a new transport provider option
  Future<LogisticsOption> createLogisticsOption(Map<String, dynamic> payload) async {
    final res = await _client.post(
      ApiEndpoints.logisticsOptions,
      data: payload,
    );
    return LogisticsOption.fromJson(res.data as Map<String, dynamic>);
  }

  /// Create a new storage facility option
  Future<StorageOption> createStorageOption(Map<String, dynamic> payload) async {
    final res = await _client.post(
      ApiEndpoints.storageOptions,
      data: payload,
    );
    return StorageOption.fromJson(res.data as Map<String, dynamic>);
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LogisticsRepository(apiClient: apiClient);
});

final logisticsOptionsProvider =
    FutureProvider.autoDispose<List<LogisticsOption>>((ref) async {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchLogisticsOptions();
});

final storageOptionsProvider =
    FutureProvider.autoDispose<List<StorageOption>>((ref) async {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchStorageOptions();
});

class SelectedLogisticsOptionNotifier extends Notifier<LogisticsOption?> {
  @override
  LogisticsOption? build() => null;

  void select(LogisticsOption? option) => state = option;
}

final selectedLogisticsOptionProvider =
    NotifierProvider<SelectedLogisticsOptionNotifier, LogisticsOption?>(
        SelectedLogisticsOptionNotifier.new);

class SelectedStorageOptionNotifier extends Notifier<StorageOption?> {
  @override
  StorageOption? build() => null;

  void select(StorageOption? option) => state = option;
}

final selectedStorageOptionProvider =
    NotifierProvider<SelectedStorageOptionNotifier, StorageOption?>(
        SelectedStorageOptionNotifier.new);
