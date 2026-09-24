import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

final produceRepositoryProvider = Provider<ProduceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProduceRepository(apiClient: apiClient);
});

final farmerLotsProvider =
    FutureProvider.family<List<ProduceLot>, int>((ref, farmerId) async {
  final repo = ref.watch(produceRepositoryProvider);
  return repo.getFarmerLots(farmerId);
});

/// Grades produce via POST /api/produce/grade.
/// [crop] is required; [imageBytesBase64] can be sent when a photo is taken.
/// Returns a [ProduceGradeResult] — always has is_certified=false until a real
/// YOLO/PyTorch/OpenCV model is integrated into app/services/ai_service.py.
final produceGradingProvider = FutureProvider.autoDispose
    .family<ProduceGradeResult, ({String crop, String? imageBytesBase64})>(
  (ref, params) async {
    final repo = ref.watch(produceRepositoryProvider);
    return repo.gradeProduce(
      crop: params.crop,
      imageBytesBase64: params.imageBytesBase64,
    );
  },
);

class ProduceRepository {
  const ProduceRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Creates a new produce lot: POST /api/produce/lots
  Future<ProduceLot> createProduceLot({
    required int farmerId,
    required String commodity,
    String? variety,
    required double quantityQuintal,
    String? grade,
    double? qualityScore,
    double? latitude,
    double? longitude,
    String? harvestDate,
    String? imagePath,
  }) async {
    final payload = {
      'farmer_id': farmerId,
      'commodity': commodity,
      if (variety != null && variety.isNotEmpty) 'variety': variety,
      'quantity_quintal': quantityQuintal,
      if (grade != null && grade.isNotEmpty) 'grade': grade,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (harvestDate != null && harvestDate.isNotEmpty)
        'harvest_date': harvestDate,
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.produceLots,
      data: payload,
    );

    final data = response.data;
    if (data == null) {
      throw const ApiException(message: 'Failed to create lot: empty response.');
    }
    return ProduceLot.fromJson(data);
  }

  /// Fetches all produce lots for a given farmer: GET /api/produce/lots/{farmer_id}
  Future<List<ProduceLot>> getFarmerLots(int farmerId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.farmerProduceLots(farmerId),
    );

    final data = response.data;
    if (data == null) return [];
    if (data is List) {
      return data
          .map((item) => ProduceLot.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Grades a produce image via POST /api/produce/grade.
  ///
  /// INTEGRATION BOUNDARY: The backend service is a prototype.
  /// [imageBytesBase64] is the base64-encoded image from the camera/gallery.
  /// Returns a [ProduceGradeResult] with is_certified always false until a
  /// trained YOLO / PyTorch / OpenCV pipeline replaces ai_service.py.
  Future<ProduceGradeResult> gradeProduce({
    required String crop,
    String? imagePath,
    String? imageBytesBase64,
  }) async {
    final payload = <String, dynamic>{
      'crop': crop,
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
      if (imageBytesBase64 != null && imageBytesBase64.isNotEmpty)
        'image_bytes_base64': imageBytesBase64,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.produceGrade,
      data: payload,
    );

    final data = response.data;
    if (data == null) {
      throw const ApiException(
        message: 'Failed to grade produce: empty response.',
      );
    }
    return ProduceGradeResult.fromJson(data);
  }
}
