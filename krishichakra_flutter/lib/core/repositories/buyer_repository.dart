import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final buyerRepositoryProvider = Provider<BuyerRepository>((ref) {
  return BuyerRepository(apiClient: ref.watch(apiClientProvider));
});

/// Fetches buyer matches for a given lot ID from GET /api/buyers/matches/{lot_id}.
/// Returns real backend data — no hardcoded buyers.
final buyerMatchesProvider =
    FutureProvider.family<List<BuyerMatch>, int>((ref, lotId) {
  return ref.watch(buyerRepositoryProvider).fetchMatches(lotId);
});

/// Fetches all demo buyers from GET /api/buyers with optional query filters.
final allBuyersProvider =
    FutureProvider.family<List<Buyer>, Map<String, dynamic>>((ref, filters) {
  return ref.watch(buyerRepositoryProvider).fetchBuyers(filters);
});

/// Tracks offer submission state per [OfferParams].
final offerSubmitProvider = NotifierProvider.autoDispose
    .family<OfferSubmitNotifier, OfferSubmitState, OfferParams>(
  (params) => OfferSubmitNotifier(params),
);

// ─── Offer submit params ──────────────────────────────────────────────────────

class OfferParams {
  const OfferParams({
    required this.lotId,
    required this.buyerId,
    required this.offeredPrice,
    required this.quantityQuintal,
  });
  final int lotId;
  final int buyerId;
  final double offeredPrice;
  final double quantityQuintal;

  @override
  bool operator ==(Object other) =>
      other is OfferParams &&
      other.lotId == lotId &&
      other.buyerId == buyerId;

  @override
  int get hashCode => Object.hash(lotId, buyerId);
}

// ─── Offer submit state ───────────────────────────────────────────────────────

sealed class OfferSubmitState {}

class OfferSubmitIdle extends OfferSubmitState {}

class OfferSubmitting extends OfferSubmitState {}

class OfferSubmitSuccess extends OfferSubmitState {
  OfferSubmitSuccess(this.offer);
  final Offer offer;
}

class OfferSubmitError extends OfferSubmitState {
  OfferSubmitError(this.message);
  final String message;
}

class OfferSubmitNotifier extends Notifier<OfferSubmitState> {
  OfferSubmitNotifier(this.params);

  final OfferParams params;

  @override
  OfferSubmitState build() => OfferSubmitIdle();

  Future<void> submit() async {
    state = OfferSubmitting();
    try {
      final offer = await ref.read(buyerRepositoryProvider).submitOffer(
        lotId: params.lotId,
        buyerId: params.buyerId,
        offeredPrice: params.offeredPrice,
        quantityQuintal: params.quantityQuintal,
      );
      state = OfferSubmitSuccess(offer);
    } on ApiException catch (e) {
      state = OfferSubmitError(e.message);
    } catch (e) {
      state = OfferSubmitError('Unexpected error: $e');
    }
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

class BuyerRepository {
  const BuyerRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// GET /api/buyers/matches/{lot_id}
  /// Returns backend-ranked buyer matches with transparent match scores.
  Future<List<BuyerMatch>> fetchMatches(int lotId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.buyerMatches(lotId),
    );
    final data = response.data;
    if (data == null) return [];
    if (data is List) {
      return data
          .map((item) => BuyerMatch.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /api/buyers
  /// Returns all demo buyers filtered by commodity, location, grade, etc.
  Future<List<Buyer>> fetchBuyers([Map<String, dynamic>? queryParams]) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.buyers,
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) return [];
    if (data is List) {
      return data
          .map((item) => Buyer.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /api/buyers/offers
  /// Submits an Escrow Lock intent offer from a buyer for a lot.
  Future<Offer> submitOffer({
    required int lotId,
    required int buyerId,
    required double offeredPrice,
    required double quantityQuintal,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.buyerOffers,
      data: {
        'lot_id': lotId,
        'buyer_id': buyerId,
        'offered_price': offeredPrice,
        'quantity_quintal': quantityQuintal,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const ApiException(message: 'Empty response from offers endpoint.');
    }
    return Offer.fromJson(data);
  }
}
