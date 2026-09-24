import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

final farmerRepositoryProvider = Provider<FarmerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FarmerRepository(apiClient: apiClient);
});

class CurrentFarmerIdNotifier extends Notifier<int?> {
  @override
  int? build() => 1;

  void setFarmerId(int? id) => state = id;
}

final currentFarmerIdProvider =
    NotifierProvider<CurrentFarmerIdNotifier, int?>(CurrentFarmerIdNotifier.new);

final currentFarmerProfileProvider = FutureProvider<Farmer?>((ref) async {
  final farmerId = ref.watch(currentFarmerIdProvider);
  if (farmerId == null) return null;
  final repo = ref.watch(farmerRepositoryProvider);
  return repo.getFarmer(farmerId);
});

final farmerDetailsProvider =
    FutureProvider.family<Farmer, int>((ref, id) async {
  final repo = ref.watch(farmerRepositoryProvider);
  return repo.getFarmer(id);
});

class FarmerRepository {
  const FarmerRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Registers or creates a new farmer: POST /api/farmers
  Future<Farmer> createFarmer({
    required String name,
    required String phone,
    String? village,
    String? district,
    String? state,
    double? landAcres,
    double vulnerabilityScore = 0.5,
    double liquidityNeed = 0.5,
  }) async {
    final payload = {
      'name': name,
      'phone': phone,
      if (village != null) 'village': village,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (landAcres != null) 'land_acres': landAcres,
      'vulnerability_score': vulnerabilityScore,
      'liquidity_need': liquidityNeed,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.farmers,
      data: payload,
    );

    final data = response.data;
    if (data == null) {
      throw const ApiException(message: 'Failed to create farmer: empty response.');
    }
    return Farmer.fromJson(data);
  }

  /// Retrieves an existing farmer by ID: GET /api/farmers/{farmer_id}
  Future<Farmer> getFarmer(int farmerId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.farmer(farmerId),
    );

    final data = response.data;
    if (data == null) {
      throw ApiException(message: 'Farmer #$farmerId not found.');
    }
    return Farmer.fromJson(data);
  }
}
