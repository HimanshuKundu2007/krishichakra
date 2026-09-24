import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

/// Repository for the Transaction and Settlement workflow.
/// Connects to:
/// - POST /api/transactions
/// - GET /api/transactions/{transaction_id}
/// - PATCH /api/transactions/{transaction_id}/payment
/// - POST /api/transactions/disputes
class TransactionRepository {
  TransactionRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  /// Create an escrow-locked transaction from accepted buyer offer
  Future<TransactionRecord> createTransaction({
    required int lotId,
    required int buyerId,
    required double agreedPrice,
    required double quantityQuintal,
    String? sellerName,
    String? buyerName,
    String? commodity,
    String? batchCode,
  }) async {
    final res = await _client.post(
      ApiEndpoints.transactions,
      data: {
        'lot_id': lotId,
        'buyer_id': buyerId,
        'agreed_price': agreedPrice,
        'quantity_quintal': quantityQuintal,
        if (sellerName != null) 'seller_name': sellerName,
        if (buyerName != null) 'buyer_name': buyerName,
        if (commodity != null) 'commodity': commodity,
        if (batchCode != null) 'batch_code': batchCode,
      },
    );
    return TransactionRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Retrieve full transaction record and settlement audit
  Future<TransactionRecord> fetchTransaction(int transactionId) async {
    final res = await _client.get(ApiEndpoints.transaction(transactionId));
    return TransactionRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Update payment status without spoofing: pending, paid, failed, disputed
  Future<TransactionRecord> updatePaymentStatus(
    int transactionId,
    String status,
  ) async {
    final res = await _client.patch(
      '${ApiEndpoints.transactionPayment(transactionId)}?status=${Uri.encodeComponent(status)}',
    );
    return TransactionRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// File a crate-level or lot-level dispute/grievance
  Future<DisputeRecord> createDispute({
    required int transactionId,
    required String raisedBy,
    required String reason,
    String? crateIds,
    String? disputeType,
  }) async {
    final res = await _client.post(
      ApiEndpoints.disputes,
      data: {
        'transaction_id': transactionId,
        'raised_by': raisedBy,
        'reason': reason,
        if (crateIds != null) 'crate_ids': crateIds,
        if (disputeType != null) 'dispute_type': disputeType,
      },
    );
    return DisputeRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// List all transactions
  Future<List<TransactionRecord>> fetchTransactions() async {
    final res = await _client.get(ApiEndpoints.transactions);
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(apiClient: ref.watch(apiClientProvider));
});

/// Fetches a transaction by ID. Can be refreshed via ref.invalidate / ref.refresh.
final transactionDetailProvider =
    FutureProvider.family<TransactionRecord, int>((ref, transactionId) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.fetchTransaction(transactionId);
});
