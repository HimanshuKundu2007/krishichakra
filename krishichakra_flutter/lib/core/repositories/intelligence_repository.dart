import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

final intelligenceRepositoryProvider = Provider<IntelligenceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IntelligenceRepository(apiClient: apiClient);
});

typedef RecommendQuery = ({
  String? commodity,
  double? quantityQuintal,
  double? transportCostPerQuintal,
  double? storageCostPerQuintal,
  int? holdingDays,
  double? transportCost,
  double? storageCost,
  int? farmerId,
  int? lotId,
});

/// Riverpod FutureProvider family for sale recommendations
final saleRecommendationProvider = FutureProvider.family<
    SaleRecommendationResponse,
    RecommendQuery>((ref, query) async {
  final repo = ref.watch(intelligenceRepositoryProvider);
  return repo.getSaleRecommendation(
    commodity: query.commodity,
    quantityQuintal: query.quantityQuintal,
    transportCostPerQuintal: query.transportCostPerQuintal,
    storageCostPerQuintal: query.storageCostPerQuintal,
    holdingDays: query.holdingDays,
    transportCost: query.transportCost,
    storageCost: query.storageCost,
    farmerId: query.farmerId,
    lotId: query.lotId,
  );
});

class IntelligenceRepository {
  const IntelligenceRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Calls POST /api/intelligence/recommend-sale
  /// Returns actual government mandi price calculations with net realization
  Future<SaleRecommendationResponse> getSaleRecommendation({
    String? commodity,
    double? quantityQuintal,
    double? transportCostPerQuintal,
    double? storageCostPerQuintal,
    int? holdingDays,
    double? transportCost,
    double? storageCost,
    int? farmerId,
    int? lotId,
  }) async {
    final payload = <String, dynamic>{
      if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
      if (quantityQuintal != null) 'quantity_quintal': quantityQuintal,
      if (transportCostPerQuintal != null)
        'transport_cost_per_quintal': transportCostPerQuintal,
      if (storageCostPerQuintal != null)
        'storage_cost_per_quintal': storageCostPerQuintal,
      if (holdingDays != null) 'holding_days': holdingDays,
      if (transportCost != null) 'transport_cost': transportCost,
      if (storageCost != null) 'storage_cost': storageCost,
      if (farmerId != null) 'farmer_id': farmerId,
      if (lotId != null) 'lot_id': lotId,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.recommendSale,
      data: payload,
    );

    final data = response.data;
    if (data == null) {
      throw const ApiException(
        message: 'Empty response received from recommend-sale endpoint.',
      );
    }

    return SaleRecommendationResponse.fromJson(data);
  }
}
