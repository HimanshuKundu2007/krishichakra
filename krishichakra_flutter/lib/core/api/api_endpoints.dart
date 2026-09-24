/// All backend API endpoint paths.
/// Prefix: /api (added here, not in baseUrl, to keep baseUrl reusable).
class ApiEndpoints {
  ApiEndpoints._();

  static const String _api = '/api';

  // ── Health ─────────────────────────────────────────────────────────────────
  static const String health = '/health';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String sendOtp = '$_api/auth/send-otp';
  static const String verifyOtp = '$_api/auth/verify-otp';

  // ── Mandi / Prices ─────────────────────────────────────────────────────────
  static const String mandiPrices = '$_api/mandi/prices';
  static const String mandiLatest = '$_api/mandi/latest';
  static const String mandiHistory = '$_api/mandi/history';
  static const String mandiStatus = '$_api/mandi/status';
  static const String mandiSync = '$_api/mandi/sync';

  // ── Farmers ────────────────────────────────────────────────────────────────
  static const String farmers = '$_api/farmers';
  static String farmer(int id) => '$_api/farmers/$id';

  // ── Produce Lots ───────────────────────────────────────────────────────────
  static const String produce = '$_api/produce';
  static const String produceLots = '$_api/produce/lots';
  static String farmerProduceLots(int farmerId) => '$_api/produce/lots/$farmerId';
  static String produceLot(int id) => '$_api/produce/$id';

  // ── AI / Intelligence ──────────────────────────────────────────────────────
  static const String produceGrade = '$_api/produce/grade';
  static const String gradeProduceAi = '$_api/intelligence/grade';
  static const String recommendSale = '$_api/intelligence/recommend-sale';

  // ── Buyers ───────────────────────────────────────────────────────────────────────
  static const String buyers = '$_api/buyers';
  /// GET /api/buyers/matches/{lot_id}
  static String buyerMatches(int lotId) => '$_api/buyers/matches/$lotId';
  /// POST /api/buyers/offers
  static const String buyerOffers = '$_api/buyers/offers';
  static String buyerOffer(int id) => '$_api/buyers/offers/$id';

  // ── FPO ────────────────────────────────────────────────────────────────────
  static const String fpos = '$_api/fpo';
  static String fpo(int id) => '$_api/fpo/$id';
  static const String fpoMembers = '$_api/fpo/members';
  static String fpoMembersOf(int fpoId) => '$_api/fpo/$fpoId/members';
  static const String fpoBatches = '$_api/fpo/batches';
  static String fpoBatch(int id) => '$_api/fpo/batches/$id';

  // ── Logistics ──────────────────────────────────────────────────────────────
  static const String logisticsOptions = '$_api/logistics/options';
  static const String storageOptions = '$_api/logistics/storage';
  static const String logisticsBookings = '$_api/logistics/bookings';
  static const String storageBookings = '$_api/logistics/storage/bookings';

  // ── Transactions ───────────────────────────────────────────────────────────
  static const String transactions = '$_api/transactions';
  static String transaction(int id) => '$_api/transactions/$id';
  static String transactionPayment(int id) => '$_api/transactions/$id/payment';
  static const String disputes = '$_api/transactions/disputes';
  static String dispute(int id) => '$_api/transactions/disputes/$id';

  // ── Chatbot ────────────────────────────────────────────────────────────────
  static const String chatbot = '$_api/chatbot';
  static const String chat = '$_api/chatbot/chat';
}
