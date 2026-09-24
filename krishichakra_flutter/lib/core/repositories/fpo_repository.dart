import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

class FpoRepository {
  FpoRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  /// Create a new FPO organization
  Future<Fpo> createFpo({
    required String name,
    String? district,
    String? state,
    String? registrationNumber,
    String? hubName,
    bool verified = false,
  }) async {
    final res = await _client.post(
      ApiEndpoints.fpos,
      data: {
        'name': name,
        'district': district,
        'state': state,
        'registration_number': registrationNumber,
        'hub_name': hubName,
        'verified': verified,
      },
    );
    return Fpo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Fetch list of all registered FPOs
  Future<List<Fpo>> fetchFpos() async {
    final res = await _client.get(ApiEndpoints.fpos);
    final data = res.data;
    if (data is List) {
      return data.map((e) => Fpo.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  /// Fetch single FPO details
  Future<Fpo> fetchFpo(int fpoId) async {
    final res = await _client.get(ApiEndpoints.fpo(fpoId));
    return Fpo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Update FPO verification status
  Future<Fpo> verifyFpo(int fpoId, {bool verified = true}) async {
    final res = await _client.patch(
      '${ApiEndpoints.fpo(fpoId)}/verify?verified=$verified',
    );
    return Fpo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Add a farmer to an FPO
  Future<FpoMember> addMember({
    required int fpoId,
    required int farmerId,
    String? memberCode,
    String role = 'member',
  }) async {
    final res = await _client.post(
      ApiEndpoints.fpoMembers,
      data: {
        'fpo_id': fpoId,
        'farmer_id': farmerId,
        'member_code': memberCode,
        'role': role,
      },
    );
    return FpoMember.fromJson(res.data as Map<String, dynamic>);
  }

  /// Fetch member listing for an FPO
  Future<List<FpoMember>> fetchMembers(int fpoId) async {
    final res = await _client.get(ApiEndpoints.fpoMembersOf(fpoId));
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => FpoMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Fetch master batch aggregation with backend computations
  Future<FpoBatchAggregation> fetchBatchAggregation(int batchId) async {
    final res = await _client.get(ApiEndpoints.fpoBatch(batchId));
    return FpoBatchAggregation.fromJson(res.data as Map<String, dynamic>);
  }

  /// Add a produce lot to the batch (evaluated by backend gatekeeper)
  Future<FpoBatchAggregation> addLotToBatch(
    int batchId, {
    required String farmerName,
    required double quantityQuintal,
    required String grade,
    String? memberCode,
    String? bulbSpec,
    double? moisturePct,
    int cratesCount = 0,
  }) async {
    final res = await _client.post(
      '${ApiEndpoints.fpoBatch(batchId)}/lots',
      data: {
        'farmer_name': farmerName,
        'quantity_quintal': quantityQuintal,
        'grade': grade,
        'member_code': memberCode,
        'bulb_spec': bulbSpec,
        'moisture_pct': moisturePct,
        'crates_count': cratesCount,
      },
    );
    return FpoBatchAggregation.fromJson(res.data as Map<String, dynamic>);
  }

  /// Seal master batch & dispatch order
  Future<FpoBatchAggregation> dispatchBatch(int batchId) async {
    final res = await _client.post(
      '${ApiEndpoints.fpoBatch(batchId)}/dispatch',
    );
    return FpoBatchAggregation.fromJson(res.data as Map<String, dynamic>);
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────
final fpoRepositoryProvider = Provider<FpoRepository>((ref) {
  return FpoRepository(apiClient: ref.watch(apiClientProvider));
});

final fposListProvider = FutureProvider<List<Fpo>>((ref) {
  return ref.watch(fpoRepositoryProvider).fetchFpos();
});

final fpoDetailProvider = FutureProvider.family<Fpo, int>((ref, id) {
  return ref.watch(fpoRepositoryProvider).fetchFpo(id);
});

final fpoMembersProvider =
    FutureProvider.family<List<FpoMember>, int>((ref, fpoId) {
  return ref.watch(fpoRepositoryProvider).fetchMembers(fpoId);
});

final fpoBatchAggregationProvider =
    FutureProvider.family<FpoBatchAggregation, int>((ref, batchId) {
  return ref.watch(fpoRepositoryProvider).fetchBatchAggregation(batchId);
});
