import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HealthRepository(apiClient: apiClient);
});

final backendHealthProvider = FutureProvider<HealthStatus>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.checkHealth();
});

class HealthRepository {
  const HealthRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Calls GET /health to verify backend connectivity.
  Future<HealthStatus> checkHealth() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.health,
    );
    final data = response.data;
    if (data == null) {
      throw const ApiException(message: 'Empty response received from /health');
    }
    return HealthStatus.fromJson(data);
  }
}
