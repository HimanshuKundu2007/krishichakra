import 'package:equatable/equatable.dart';

// ─── AsyncValue-like result type ─────────────────────────────────────────────
sealed class ApiResult<T> extends Equatable {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

final class ApiError<T> extends ApiResult<T> {
  const ApiError({required this.message, this.statusCode});
  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class ApiLoading<T> extends ApiResult<T> {
  const ApiLoading();

  @override
  List<Object?> get props => [];
}

// ─── Mandi Price model ────────────────────────────────────────────────────────
class MandiPrice extends Equatable {
  const MandiPrice({
    required this.id,
    required this.commodity,
    required this.variety,
    required this.state,
    required this.district,
    required this.market,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
    this.arrivalQuantity,
    required this.source,
    this.sourceUpdatedAt,
    this.ingestedAt,
  });

  final int id;
  final String commodity;
  final String variety;
  final String state;
  final String district;
  final String market;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String unit;
  final double? arrivalQuantity;
  final String source;
  final String? sourceUpdatedAt;
  final String? ingestedAt;

  bool get isLiveGovData =>
      source != 'DEMO_SEED' &&
      (source.contains('Government') || source.contains('AGMARKNET'));

  factory MandiPrice.fromJson(Map<String, dynamic> json) => MandiPrice(
        id: json['id'] as int? ?? 0,
        commodity: json['commodity'] as String? ?? '',
        variety: json['variety'] as String? ?? '',
        state: json['state'] as String? ?? '',
        district: json['district'] as String? ?? '',
        market: json['market'] as String? ?? '',
        arrivalDate: json['arrival_date'] as String? ?? '',
        minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
        maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
        modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'Quintal',
        arrivalQuantity: (json['arrival_quantity'] as num?)?.toDouble(),
        source: json['source'] as String? ?? 'Government Market Data',
        sourceUpdatedAt: json['source_updated_at'] as String?,
        ingestedAt: json['ingested_at'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, commodity, market, arrivalDate, modalPrice, source];
}

// ─── Mandi Status model ───────────────────────────────────────────────────────
class MandiStatus extends Equatable {
  const MandiStatus({
    required this.source,
    this.lastSync,
    this.lastSyncStatus = 'never',
    this.lastSuccessfulSync,
    this.hasEverSynced = false,
    required this.records,
    required this.govRecords,
    this.latestDataDate,
    required this.isLive,
    this.isStale = false,
    this.message,
  });

  final String source;
  final String? lastSync;
  final String lastSyncStatus; // 'success' | 'failed' | 'running' | 'never'
  final String? lastSuccessfulSync;
  final bool hasEverSynced;
  final int records;
  final int govRecords;
  final String? latestDataDate;
  final bool isLive;
  final bool isStale;
  final String? message;

  bool get hasFailedSync => lastSyncStatus == 'failed';
  bool get hasGovernmentRecords => govRecords > 0;
  bool get isNeverSynced => !hasEverSynced && govRecords == 0;

  factory MandiStatus.fromJson(Map<String, dynamic> json) => MandiStatus(
        source: json['source'] as String? ??
            'Government Market Data (AGMARKNET / data.gov.in)',
        lastSync: json['last_sync'] as String?,
        lastSyncStatus: json['last_sync_status'] as String? ?? 'never',
        lastSuccessfulSync: json['last_successful_sync'] as String?,
        hasEverSynced: json['has_ever_synced'] as bool? ??
            ((json['gov_records'] as int? ?? 0) > 0 &&
                json['last_successful_sync'] != null),
        records: json['records'] as int? ?? 0,
        govRecords: json['gov_records'] as int? ?? 0,
        latestDataDate: json['latest_data_date'] as String?,
        isLive: json['is_live'] as bool? ?? false,
        isStale: json['is_stale'] as bool? ??
            ((json['gov_records'] as int? ?? 0) > 0 &&
                (json['is_live'] != true || json['last_sync_status'] == 'failed')),
        message: json['message'] as String?,
      );

  @override
  List<Object?> get props => [
        source,
        lastSync,
        lastSyncStatus,
        lastSuccessfulSync,
        hasEverSynced,
        records,
        govRecords,
        latestDataDate,
        isLive,
        isStale,
        message,
      ];
}

// ─── Farmer model ─────────────────────────────────────────────────────────────
// ─── Health model ─────────────────────────────────────────────────────────────
class HealthStatus extends Equatable {
  const HealthStatus({
    required this.status,
    required this.service,
    required this.version,
  });

  final String status;
  final String service;
  final String version;

  bool get isHealthy => status.toLowerCase() == 'ok';

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        status: json['status'] as String? ?? 'unknown',
        service: json['service'] as String? ?? 'KrishiChakra API',
        version: json['version'] as String? ?? '2.0.0',
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'service': service,
        'version': version,
      };

  @override
  List<Object?> get props => [status, service, version];
}

// ─── Farmer model ─────────────────────────────────────────────────────────────
class Farmer extends Equatable {
  const Farmer({
    required this.id,
    required this.name,
    required this.phone,
    required this.village,
    required this.district,
    required this.state,
    this.landAcres,
    this.vulnerabilityScore,
    this.liquidityNeed,
    this.role,
    this.languagePreference,
    this.kycStatus,
  });

  final int id;
  final String name;
  final String phone;
  final String village;
  final String district;
  final String state;
  final double? landAcres;
  final double? vulnerabilityScore;
  final double? liquidityNeed;
  final String? role;
  final String? languagePreference;
  final String? kycStatus;

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        village: json['village'] as String? ?? '',
        district: json['district'] as String? ?? '',
        state: json['state'] as String? ?? '',
        landAcres: (json['land_acres'] as num?)?.toDouble(),
        vulnerabilityScore: (json['vulnerability_score'] as num?)?.toDouble() ?? 0.5,
        liquidityNeed: json['liquidity_need'] is num
            ? (json['liquidity_need'] as num).toDouble()
            : (json['liquidity_need'] == true ? 1.0 : (json['liquidity_need'] == false ? 0.0 : 0.5)),
        role: json['role'] as String?,
        languagePreference: json['language_preference'] as String?,
        kycStatus: json['kyc_status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'name': name,
        'phone': phone,
        'village': village,
        'district': district,
        'state': state,
        if (landAcres != null) 'land_acres': landAcres,
        if (vulnerabilityScore != null) 'vulnerability_score': vulnerabilityScore,
        if (liquidityNeed != null) 'liquidity_need': liquidityNeed,
      };

  @override
  List<Object?> get props => [id, phone, name];
}

// ─── Produce Lot model ────────────────────────────────────────────────────────
class ProduceLot extends Equatable {
  const ProduceLot({
    required this.id,
    required this.farmerId,
    required this.commodity,
    this.variety,
    required this.quantityQuintal,
    this.grade,
    this.qualityScore,
    this.lat,
    this.lng,
    this.harvestDate,
    required this.status,
    this.imagePath,
    this.crateCount,
    this.fpoBatchId,
  });

  final int id;
  final int farmerId;
  final String commodity;
  final String? variety;
  final double quantityQuintal;
  final String? grade;
  final double? qualityScore;
  final double? lat;
  final double? lng;
  final String? harvestDate;
  final String status;
  final String? imagePath;
  final int? crateCount;
  final int? fpoBatchId;

  factory ProduceLot.fromJson(Map<String, dynamic> json) => ProduceLot(
        id: json['id'] as int? ?? 0,
        farmerId: json['farmer_id'] as int? ?? 0,
        commodity: json['commodity'] as String? ?? '',
        variety: json['variety'] as String?,
        quantityQuintal: (json['quantity_quintal'] as num?)?.toDouble() ?? 0.0,
        grade: json['grade'] as String?,
        qualityScore: (json['quality_score'] as num?)?.toDouble(),
        lat: (json['lat'] ?? json['latitude'] as num?)?.toDouble(),
        lng: (json['lng'] ?? json['longitude'] as num?)?.toDouble(),
        harvestDate: json['harvest_date'] as String?,
        status: json['status'] as String? ?? 'available',
        imagePath: json['image_path'] as String?,
        crateCount: json['crate_count'] as int?,
        fpoBatchId: json['fpo_batch_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (id > 0) 'id': id,
        'farmer_id': farmerId,
        'commodity': commodity,
        if (variety != null) 'variety': variety,
        'quantity_quintal': quantityQuintal,
        if (grade != null) 'grade': grade,
        if (qualityScore != null) 'quality_score': qualityScore,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
        if (harvestDate != null) 'harvest_date': harvestDate,
        if (imagePath != null) 'image_path': imagePath,
      };

  @override
  List<Object?> get props => [id, farmerId, commodity, status];
}

// ─── Produce Bounding Marker model ───────────────────────────────────────────
/// Represents a single computer-vision inspection annotation.
/// In a production YOLO pipeline, these come from model.predict(image).boxes.
class ProduceBoundingMarker extends Equatable {
  const ProduceBoundingMarker({
    required this.label,
    required this.conf,
    required this.x,
    required this.y,
  });

  final String label;
  final double conf;
  final double x;
  final double y;

  factory ProduceBoundingMarker.fromJson(Map<String, dynamic> json) =>
      ProduceBoundingMarker(
        label: json['label'] as String? ?? '',
        conf: (json['conf'] as num?)?.toDouble() ?? 0.0,
        x: (json['x'] as num?)?.toDouble() ?? 0.0,
        y: (json['y'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [label, conf, x, y];
}

// ─── Produce Grade Result model ───────────────────────────────────────────────
/// Response from POST /api/produce/grade.
/// IMPORTANT: is_certified is ALWAYS false for the integration boundary prototype.
/// Replace app/services/ai_service.py with a trained YOLO/PyTorch/OpenCV pipeline
/// before making any AI-certified claims in the UI.
class ProduceGradeResult extends Equatable {
  const ProduceGradeResult({
    required this.status,
    required this.crop,
    this.grade,
    this.qualityScore,
    this.uniformityPct,
    this.moisturePct,
    this.pestDamagePct,
    this.detectedMarkers = const [],
    this.hasImage = false,
    required this.isCertified,
    required this.assessmentType,
    required this.disclaimer,
    required this.message,
  });

  final String status;
  final String crop;
  final String? grade;
  final double? qualityScore;
  final double? uniformityPct;
  final double? moisturePct;
  final double? pestDamagePct;
  final List<ProduceBoundingMarker> detectedMarkers;
  final bool hasImage;
  /// Always false for integration boundary prototype.
  final bool isCertified;
  final String assessmentType;
  final String disclaimer;
  final String message;

  bool get isPrototype => !isCertified;

  factory ProduceGradeResult.fromJson(Map<String, dynamic> json) =>
      ProduceGradeResult(
        status: json['status'] as String? ?? 'unknown',
        crop: json['crop'] as String? ?? '',
        grade: json['grade'] as String?,
        qualityScore: (json['quality_score'] as num?)?.toDouble(),
        uniformityPct: (json['uniformity_pct'] as num?)?.toDouble(),
        moisturePct: (json['moisture_pct'] as num?)?.toDouble(),
        pestDamagePct: (json['pest_damage_pct'] as num?)?.toDouble(),
        detectedMarkers: (json['detected_markers'] as List<dynamic>? ?? [])
            .map((m) => ProduceBoundingMarker.fromJson(m as Map<String, dynamic>))
            .toList(),
        hasImage: json['has_image'] as bool? ?? false,
        isCertified: json['is_certified'] as bool? ?? false,
        assessmentType: json['assessment_type'] as String? ?? 'Unknown',
        disclaimer: json['disclaimer'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  @override
  List<Object?> get props => [status, crop, grade, isCertified];
}

// ─── Buyer model ──────────────────────────────────────────────────────────────
class Buyer extends Equatable {
  const Buyer({
    required this.id,
    required this.name,
    required this.buyerType,
    this.district,
    this.state,
    required this.verified,
    this.paymentReliability,
    this.demandCommodity,
    this.minQuantity,
    this.maxQuantity,
    this.qualityRequirements,
    this.offeredPrice,
  });

  final int id;
  final String name;
  final String buyerType;
  final String? district;
  final String? state;
  final bool verified;
  final double? paymentReliability;
  final String? demandCommodity;
  final double? minQuantity;
  final double? maxQuantity;
  final String? qualityRequirements;
  final double? offeredPrice;

  factory Buyer.fromJson(Map<String, dynamic> json) => Buyer(
        id: json['id'] as int,
        name: json['name'] as String,
        buyerType: json['buyer_type'] as String? ?? 'trader',
        district: json['district'] as String?,
        state: json['state'] as String?,
        verified: json['verified'] as bool? ?? false,
        paymentReliability: (json['payment_reliability'] as num?)?.toDouble(),
        demandCommodity: json['demand_commodity'] as String?,
        minQuantity: (json['min_quantity'] as num?)?.toDouble(),
        maxQuantity: (json['max_quantity'] as num?)?.toDouble(),
        qualityRequirements: json['quality_requirements'] as String?,
        offeredPrice: (json['offered_price'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [id, name];
}

// ─── Buyer Match Score Breakdown model ──────────────────────────────────────────────
/// Transparent score components for a buyer match.
/// Formula (mirrored from buyer_matching.py):
///   match_score = 0.30*quantityFit + 0.25*qualityFit
///               + 0.25*verifiedScore + 0.20*paymentScore
class BuyerMatchScoreBreakdown extends Equatable {
  const BuyerMatchScoreBreakdown({
    required this.quantityFit,
    required this.qualityFit,
    required this.verifiedScore,
    required this.paymentScore,
  });

  /// 0-100
  final double quantityFit;
  final double qualityFit;
  final double verifiedScore;
  final double paymentScore;

  factory BuyerMatchScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      BuyerMatchScoreBreakdown(
        quantityFit: (json['quantity_fit'] as num?)?.toDouble() ?? 0,
        qualityFit: (json['quality_fit'] as num?)?.toDouble() ?? 0,
        verifiedScore: (json['verified_score'] as num?)?.toDouble() ?? 0,
        paymentScore: (json['payment_score'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props =>
      [quantityFit, qualityFit, verifiedScore, paymentScore];
}

// ─── Buyer Match model ────────────────────────────────────────────────────────────────────────
/// Response item from GET /api/buyers/matches/{lot_id}.
/// Distinct from [Buyer] — includes transparent scoring fields that the
/// Buyer CRUD model does not have.
class BuyerMatch extends Equatable {
  const BuyerMatch({
    required this.buyerId,
    required this.buyer,
    required this.buyerType,
    required this.verified,
    required this.paymentReliability,
    this.offeredPrice,
    required this.matchScore,
    required this.reason,
    required this.scoreBreakdown,
  });

  final int buyerId;
  final String buyer;
  final String buyerType;
  final bool verified;
  /// Already in percentage (0–100), as returned by the backend.
  final double paymentReliability;
  final double? offeredPrice;
  /// 0–100 transparent match score.
  final double matchScore;
  final String reason;
  final BuyerMatchScoreBreakdown scoreBreakdown;

  bool get isTopBid => matchScore >= 70;

  factory BuyerMatch.fromJson(Map<String, dynamic> json) => BuyerMatch(
        buyerId: json['buyer_id'] as int,
        buyer: json['buyer'] as String,
        buyerType: json['buyer_type'] as String? ?? 'Trader',
        verified: json['verified'] as bool? ?? false,
        paymentReliability:
            (json['payment_reliability'] as num?)?.toDouble() ?? 0.0,
        offeredPrice: (json['offered_price'] as num?)?.toDouble(),
        matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
        reason: json['reason'] as String? ?? '',
        scoreBreakdown: BuyerMatchScoreBreakdown.fromJson(
          json['score_breakdown'] as Map<String, dynamic>? ?? {},
        ),
      );

  @override
  List<Object?> get props => [buyerId, matchScore];
}

// ─── Offer model ────────────────────────────────────────────────────────────────────────────────
class Offer extends Equatable {
  const Offer({
    required this.id,
    required this.lotId,
    required this.buyerId,
    required this.offeredPrice,
    required this.quantityQuintal,
  });

  final int id;
  final int lotId;
  final int buyerId;
  final double offeredPrice;
  final double quantityQuintal;

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as int,
        lotId: json['lot_id'] as int,
        buyerId: json['buyer_id'] as int,
        offeredPrice: (json['offered_price'] as num).toDouble(),
        quantityQuintal: (json['quantity_quintal'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [id, lotId, buyerId];
}

// ─── Transaction model ────────────────────────────────────────────────────────
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.lotId,
    required this.buyerId,
    required this.agreedPrice,
    required this.quantityQuintal,
    required this.status,
    required this.paymentStatus,
    this.escrowUtr,
    this.milestoneStatus,
  });

  final int id;
  final int lotId;
  final int buyerId;
  final double agreedPrice;
  final double quantityQuintal;
  final String status;
  final String paymentStatus;
  final String? escrowUtr;
  final Map<String, dynamic>? milestoneStatus;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        lotId: json['lot_id'] as int,
        buyerId: json['buyer_id'] as int,
        agreedPrice: (json['agreed_price'] as num).toDouble(),
        quantityQuintal: (json['quantity_quintal'] as num).toDouble(),
        status: json['status'] as String? ?? 'pending',
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        escrowUtr: json['escrow_utr'] as String?,
        milestoneStatus: json['milestone_status'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [id, lotId, buyerId];
}

// ─── Dispute model ────────────────────────────────────────────────────────────
class Dispute extends Equatable {
  const Dispute({
    required this.id,
    required this.transactionId,
    required this.raisedBy,
    required this.reason,
    required this.status,
    this.resolution,
  });

  final int id;
  final int transactionId;
  final String raisedBy;
  final String reason;
  final String status;
  final String? resolution;

  factory Dispute.fromJson(Map<String, dynamic> json) => Dispute(
        id: json['id'] as int,
        transactionId: json['transaction_id'] as int,
        raisedBy: json['raised_by'] as String,
        reason: json['reason'] as String,
        status: json['status'] as String? ?? 'open',
        resolution: json['resolution'] as String?,
      );

  @override
  List<Object?> get props => [id, transactionId];
}

// ─── LogisticsOption model ────────────────────────────────────────────────────
class LogisticsOption extends Equatable {
  const LogisticsOption({
    required this.id,
    required this.providerName,
    required this.vehicleType,
    required this.origin,
    required this.destination,
    required this.costPerQuintal,
    required this.capacityQuintal,
    required this.available,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.driverRating = 4.8,
    this.verifiedTrips = 50,
    this.isEmptyReturn = false,
    this.discountPercentage = 0.0,
    this.distanceKm,
    this.transitDurationMinutes,
    this.ventilated = true,
    this.gpsActive = true,
    this.departureTime,
  });

  final int id;
  final String providerName;
  final String vehicleType;
  final String? vehicleNumber;
  final String? driverName;
  final String? driverPhone;
  final double driverRating;
  final int verifiedTrips;
  final String origin;
  final String destination;
  final double costPerQuintal;
  final double capacityQuintal;
  final bool isEmptyReturn;
  final double discountPercentage;
  final double? distanceKm;
  final int? transitDurationMinutes;
  final bool ventilated;
  final bool gpsActive;
  final String? departureTime;
  final bool available;

  factory LogisticsOption.fromJson(Map<String, dynamic> json) => LogisticsOption(
        id: json['id'] as int,
        providerName: json['provider_name'] as String,
        vehicleType: json['vehicle_type'] as String? ?? 'Truck',
        vehicleNumber: json['vehicle_number'] as String?,
        driverName: json['driver_name'] as String?,
        driverPhone: json['driver_phone'] as String?,
        driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 4.8,
        verifiedTrips: (json['verified_trips'] as num?)?.toInt() ?? 50,
        origin: json['origin'] as String? ?? 'Farm gate',
        destination: json['destination'] as String? ?? 'Mandi Hub',
        costPerQuintal: (json['cost_per_quintal'] as num).toDouble(),
        capacityQuintal: (json['capacity_quintal'] as num).toDouble(),
        isEmptyReturn: json['is_empty_return'] as bool? ?? false,
        discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        transitDurationMinutes: (json['transit_duration_minutes'] as num?)?.toInt(),
        ventilated: json['ventilated'] as bool? ?? true,
        gpsActive: json['gps_active'] as bool? ?? true,
        departureTime: json['departure_time'] as String?,
        available: json['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider_name': providerName,
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_rating': driverRating,
        'verified_trips': verifiedTrips,
        'origin': origin,
        'destination': destination,
        'cost_per_quintal': costPerQuintal,
        'capacity_quintal': capacityQuintal,
        'is_empty_return': isEmptyReturn,
        'discount_percentage': discountPercentage,
        'distance_km': distanceKm,
        'transit_duration_minutes': transitDurationMinutes,
        'ventilated': ventilated,
        'gps_active': gpsActive,
        'departure_time': departureTime,
        'available': available,
      };

  @override
  List<Object?> get props => [id, providerName, vehicleType, costPerQuintal];
}

// ─── StorageOption model ──────────────────────────────────────────────────────
class StorageOption extends Equatable {
  const StorageOption({
    required this.id,
    required this.providerName,
    required this.location,
    required this.capacityQuintal,
    required this.costPerQuintalDay,
    required this.available,
    this.district,
    this.state,
    this.availableCapacityQuintal,
    this.distanceKm,
    this.storageType = 'Cold Storage',
    this.isCertified = true,
    this.enwrLoanEligible = true,
    this.loanAdvancePct = 70.0,
  });

  final int id;
  final String providerName;
  final String location;
  final String? district;
  final String? state;
  final double capacityQuintal;
  final double? availableCapacityQuintal;
  final double costPerQuintalDay;
  final double? distanceKm;
  final String storageType;
  final bool isCertified;
  final bool enwrLoanEligible;
  final double loanAdvancePct;
  final bool available;

  factory StorageOption.fromJson(Map<String, dynamic> json) => StorageOption(
        id: json['id'] as int,
        providerName: json['provider_name'] as String,
        location: json['location'] as String,
        district: json['district'] as String?,
        state: json['state'] as String?,
        capacityQuintal: (json['capacity_quintal'] as num).toDouble(),
        availableCapacityQuintal: (json['available_capacity_quintal'] as num?)?.toDouble(),
        costPerQuintalDay: (json['cost_per_quintal_day'] as num).toDouble(),
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        storageType: json['storage_type'] as String? ?? 'Cold Storage',
        isCertified: json['is_certified'] as bool? ?? true,
        enwrLoanEligible: json['enwr_loan_eligible'] as bool? ?? true,
        loanAdvancePct: (json['loan_advance_pct'] as num?)?.toDouble() ?? 70.0,
        available: json['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider_name': providerName,
        'location': location,
        'district': district,
        'state': state,
        'capacity_quintal': capacityQuintal,
        'available_capacity_quintal': availableCapacityQuintal,
        'cost_per_quintal_day': costPerQuintalDay,
        'distance_km': distanceKm,
        'storage_type': storageType,
        'is_certified': isCertified,
        'enwr_loan_eligible': enwrLoanEligible,
        'loan_advance_pct': loanAdvancePct,
        'available': available,
      };

  @override
  List<Object?> get props => [id, providerName, location, costPerQuintalDay];
}

// ─── NetRealization model (from intelligence endpoint) ────────────────────────
class NetRealizationResult extends Equatable {
  const NetRealizationResult({
    required this.market,
    required this.modalPrice,
    required this.quantity,
    required this.grossRealization,
    required this.transportCost,
    required this.storageCost,
    required this.estimatedNetRealization,
    required this.governmentDataDate,
    required this.source,
    this.district,
    this.state,
    this.variety,
    this.minPrice,
    this.maxPrice,
    this.commodity = '',
    this.distanceKm = 0,
    this.rank,
    this.isLiveGovData = true,
  });

  final String market;
  final String? district;
  final String? state;
  final String? variety;
  final String commodity;
  final double modalPrice; // Government-reported price
  final double? minPrice;
  final double? maxPrice;
  final double quantity;
  final double grossRealization;
  final double transportCost;
  final double storageCost;
  final double estimatedNetRealization; // Gross - Transport - Storage
  final String governmentDataDate;
  final String source;
  final double distanceKm;
  final int? rank;
  final bool isLiveGovData;

  // Compatibility getters for legacy callers
  double get netTotal => estimatedNetRealization;
  double get grossTotal => grossRealization;
  double get netPerQuintal => quantity > 0 ? (estimatedNetRealization / quantity) : 0;

  factory NetRealizationResult.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toDouble() ??
        (json['quantity_quintal'] as num?)?.toDouble() ??
        20.0;
    final modal = (json['modal_price'] as num?)?.toDouble() ?? 0.0;
    final gross = (json['gross_realization'] as num?)?.toDouble() ??
        (json['gross_total'] as num?)?.toDouble() ??
        (modal * qty);
    final transport = (json['transport_cost'] as num?)?.toDouble() ?? 0.0;
    final storage = (json['storage_cost'] as num?)?.toDouble() ?? 0.0;
    final net = (json['estimated_net_realization'] as num?)?.toDouble() ??
        (json['net_total'] as num?)?.toDouble() ??
        (gross - transport - storage);
    final govDate = (json['government_data_date'] as String?) ??
        (json['arrival_date'] as String?) ??
        '';
    final src = (json['source'] as String?) ??
        'Government Market Data (AGMARKNET / data.gov.in)';

    return NetRealizationResult(
      market: json['market'] as String? ?? 'Unknown Mandi',
      district: json['district'] as String?,
      state: json['state'] as String?,
      variety: json['variety'] as String?,
      commodity: (json['commodity'] as String?) ?? '',
      modalPrice: modal,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      quantity: qty,
      grossRealization: gross,
      transportCost: transport,
      storageCost: storage,
      estimatedNetRealization: net,
      governmentDataDate: govDate,
      source: src,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int?,
      isLiveGovData: (json['is_live_gov_data'] as bool?) ?? (src != 'DEMO_SEED'),
    );
  }

  Map<String, dynamic> toJson() => {
        'market': market,
        'district': district,
        'state': state,
        'variety': variety,
        'commodity': commodity,
        'modal_price': modalPrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'quantity': quantity,
        'gross_realization': grossRealization,
        'transport_cost': transportCost,
        'storage_cost': storageCost,
        'estimated_net_realization': estimatedNetRealization,
        'government_data_date': governmentDataDate,
        'source': source,
        'is_live_gov_data': isLiveGovData,
      };

  @override
  List<Object?> get props => [
        market,
        modalPrice,
        quantity,
        grossRealization,
        transportCost,
        storageCost,
        estimatedNetRealization,
        governmentDataDate,
        source,
      ];
}

// ─── SaleRecommendation response model ───────────────────────────────────────
class SaleRecommendationResponse extends Equatable {
  const SaleRecommendationResponse({
    required this.commodity,
    required this.quantity,
    required this.options,
    required this.disclaimer,
    required this.note,
  });

  final String commodity;
  final double quantity;
  final List<NetRealizationResult> options;
  final String disclaimer;
  final String note;

  factory SaleRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    final commodityName = (json['commodity'] as String?) ?? 'Onion';
    final qty = (json['quantity'] as num?)?.toDouble() ??
        (json['quantity_quintal'] as num?)?.toDouble() ??
        20.0;

    final parsedOptions = rawOptions
        .whereType<Map<String, dynamic>>()
        .map((opt) {
          final optMap = Map<String, dynamic>.from(opt);
          optMap.putIfAbsent('commodity', () => commodityName);
          optMap.putIfAbsent('quantity', () => qty);
          return NetRealizationResult.fromJson(optMap);
        })
        .toList();

    return SaleRecommendationResponse(
      commodity: commodityName,
      quantity: qty,
      options: parsedOptions,
      disclaimer: (json['disclaimer'] as String?) ??
          'Calculated values are KrishiChakra estimates based on government mandi prices and cost assumptions; not a guaranteed future price.',
      note: (json['note'] as String?) ??
          'Calculated values are KrishiChakra estimates based on government mandi prices and cost assumptions; not a guaranteed future price.',
    );
  }

  @override
  List<Object?> get props => [commodity, quantity, options, disclaimer];
}

// ─── FPO models ───────────────────────────────────────────────────────────────
class Fpo extends Equatable {
  const Fpo({
    required this.id,
    required this.name,
    required this.district,
    required this.state,
    required this.verified,
    this.memberCount,
    this.registrationNumber,
    this.hubName,
  });

  final int id;
  final String name;
  final String district;
  final String state;
  final bool verified;
  final int? memberCount;
  final String? registrationNumber;
  final String? hubName;

  factory Fpo.fromJson(Map<String, dynamic> json) => Fpo(
        id: json['id'] as int,
        name: json['name'] as String,
        district: json['district'] as String? ?? '',
        state: json['state'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
        memberCount: json['total_members_count'] as int? ??
            json['member_count'] as int?,
        registrationNumber: json['registration_number'] as String?,
        hubName: json['hub_name'] as String?,
      );

  @override
  List<Object?> get props => [id, name, verified, registrationNumber];
}

class FpoMember extends Equatable {
  const FpoMember({
    required this.id,
    required this.fpoId,
    required this.farmerId,
    this.farmerName,
    this.farmerPhone,
    this.farmerVillage,
    this.farmerDistrict,
    this.memberCode,
    this.role = 'member',
    this.createdAt,
  });

  final int id;
  final int fpoId;
  final int farmerId;
  final String? farmerName;
  final String? farmerPhone;
  final String? farmerVillage;
  final String? farmerDistrict;
  final String? memberCode;
  final String role;
  final String? createdAt;

  factory FpoMember.fromJson(Map<String, dynamic> json) => FpoMember(
        id: json['id'] as int,
        fpoId: json['fpo_id'] as int,
        farmerId: json['farmer_id'] as int,
        farmerName: json['farmer_name'] as String?,
        farmerPhone: json['farmer_phone'] as String?,
        farmerVillage: json['farmer_village'] as String?,
        farmerDistrict: json['farmer_district'] as String?,
        memberCode: json['member_code'] as String?,
        role: json['role'] as String? ?? 'member',
        createdAt: json['created_at'] as String?,
      );

  @override
  List<Object?> get props => [id, fpoId, farmerId, memberCode];
}

class FpoBatchLot extends Equatable {
  const FpoBatchLot({
    required this.id,
    required this.batchId,
    this.farmerId,
    required this.farmerName,
    this.memberCode,
    this.lotId,
    required this.quantityQuintal,
    required this.grade,
    this.bulbSpec,
    this.moisturePct,
    this.foreignRotPct,
    this.cratesCount = 0,
    this.qrTagRange,
    required this.status,
    this.diversionRoute,
    this.gatekeeperNote,
  });

  final int id;
  final int batchId;
  final int? farmerId;
  final String farmerName;
  final String? memberCode;
  final int? lotId;
  final double quantityQuintal;
  final String grade;
  final String? bulbSpec;
  final double? moisturePct;
  final double? foreignRotPct;
  final int cratesCount;
  final String? qrTagRange;
  final String status; // 'staged' or 'diverted'
  final String? diversionRoute;
  final String? gatekeeperNote;

  bool get isStaged => status == 'staged';
  bool get isDiverted => status == 'diverted';

  factory FpoBatchLot.fromJson(Map<String, dynamic> json) => FpoBatchLot(
        id: json['id'] as int,
        batchId: json['batch_id'] as int,
        farmerId: json['farmer_id'] as int?,
        farmerName: json['farmer_name'] as String? ?? 'Farmer Member',
        memberCode: json['member_code'] as String?,
        lotId: json['lot_id'] as int?,
        quantityQuintal: (json['quantity_quintal'] as num).toDouble(),
        grade: json['grade'] as String? ?? 'Grade A',
        bulbSpec: json['bulb_spec'] as String?,
        moisturePct: (json['moisture_pct'] as num?)?.toDouble(),
        foreignRotPct: (json['foreign_rot_pct'] as num?)?.toDouble(),
        cratesCount: json['crates_count'] as int? ?? 0,
        qrTagRange: json['qr_tag_range'] as String?,
        status: json['status'] as String? ?? 'staged',
        diversionRoute: json['diversion_route'] as String?,
        gatekeeperNote: json['gatekeeper_note'] as String?,
      );

  @override
  List<Object?> get props => [id, batchId, farmerName, quantityQuintal, status];
}

class FpoFinancialLedger extends Equatable {
  const FpoFinancialLedger({
    required this.commercialValue,
    required this.farmerPayout,
    required this.fpoMargin,
    required this.freightSurcharge,
    this.currency = 'INR',
  });

  final double commercialValue;
  final double farmerPayout;
  final double fpoMargin;
  final double freightSurcharge;
  final String currency;

  factory FpoFinancialLedger.fromJson(Map<String, dynamic> json) =>
      FpoFinancialLedger(
        commercialValue: (json['commercial_value'] as num).toDouble(),
        farmerPayout: (json['farmer_payout'] as num).toDouble(),
        fpoMargin: (json['fpo_margin'] as num).toDouble(),
        freightSurcharge: (json['freight_surcharge'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'INR',
      );

  @override
  List<Object?> get props =>
      [commercialValue, farmerPayout, fpoMargin, freightSurcharge];
}

class FpoBatchAggregation extends Equatable {
  const FpoBatchAggregation({
    required this.id,
    required this.batchCode,
    required this.fpoId,
    required this.fpoName,
    required this.fpoVerified,
    this.fpoRegistrationNumber,
    this.fpoHubName,
    this.totalRegisteredFarmers = 0,
    required this.commodity,
    required this.targetGrade,
    required this.targetQuantityQuintal,
    required this.stagedQuantityQuintal,
    required this.divertedQuantityQuintal,
    required this.remainingQuantityQuintal,
    required this.remainingCrates,
    required this.fillPercentage,
    required this.status,
    this.buyerName,
    this.buyerContractPrice,
    this.benchmarkMandiPrice,
    this.institutionalBonusPerQ,
    this.bonusExplanation,
    this.stagingBayInfo,
    this.totalCratesChecked = 0,
    this.dockBay,
    this.transporterVehicle,
    this.transporterNumber,
    this.transporterDriver,
    this.destination,
    this.lots = const [],
    required this.ledger,
    this.ewayBillNumber,
  });

  final int id;
  final String batchCode;
  final int fpoId;
  final String fpoName;
  final bool fpoVerified;
  final String? fpoRegistrationNumber;
  final String? fpoHubName;
  final int totalRegisteredFarmers;
  final String commodity;
  final String targetGrade;
  final double targetQuantityQuintal;
  final double stagedQuantityQuintal;
  final double divertedQuantityQuintal;
  final double remainingQuantityQuintal;
  final int remainingCrates;
  final double fillPercentage;
  final String status;
  final String? buyerName;
  final double? buyerContractPrice;
  final double? benchmarkMandiPrice;
  final double? institutionalBonusPerQ;
  final String? bonusExplanation;
  final String? stagingBayInfo;
  final int totalCratesChecked;
  final String? dockBay;
  final String? transporterVehicle;
  final String? transporterNumber;
  final String? transporterDriver;
  final String? destination;
  final List<FpoBatchLot> lots;
  final FpoFinancialLedger ledger;
  final String? ewayBillNumber;

  factory FpoBatchAggregation.fromJson(Map<String, dynamic> json) =>
      FpoBatchAggregation(
        id: json['id'] as int,
        batchCode: json['batch_code'] as String? ?? '#BATCH',
        fpoId: json['fpo_id'] as int,
        fpoName: json['fpo_name'] as String? ?? 'FPO Hub',
        fpoVerified: json['fpo_verified'] as bool? ?? false,
        fpoRegistrationNumber: json['fpo_registration_number'] as String?,
        fpoHubName: json['fpo_hub_name'] as String?,
        totalRegisteredFarmers: json['total_registered_farmers'] as int? ?? 0,
        commodity: json['commodity'] as String? ?? 'Produce',
        targetGrade: json['target_grade'] as String? ?? 'Grade A',
        targetQuantityQuintal:
            (json['target_quantity_quintal'] as num).toDouble(),
        stagedQuantityQuintal:
            (json['staged_quantity_quintal'] as num).toDouble(),
        divertedQuantityQuintal:
            (json['diverted_quantity_quintal'] as num).toDouble(),
        remainingQuantityQuintal:
            (json['remaining_quantity_quintal'] as num).toDouble(),
        remainingCrates: json['remaining_crates'] as int? ?? 0,
        fillPercentage: (json['fill_percentage'] as num).toDouble(),
        status: json['status'] as String? ?? 'pooling',
        buyerName: json['buyer_name'] as String?,
        buyerContractPrice: (json['buyer_contract_price'] as num?)?.toDouble(),
        benchmarkMandiPrice:
            (json['benchmark_mandi_price'] as num?)?.toDouble(),
        institutionalBonusPerQ:
            (json['institutional_premium_per_q'] as num?)?.toDouble(),
        bonusExplanation: json['bonus_explanation'] as String?,
        stagingBayInfo: json['staging_bay_info'] as String?,
        totalCratesChecked: json['total_crates_checked'] as int? ?? 0,
        dockBay: json['dock_bay'] as String?,
        transporterVehicle: json['transporter_vehicle'] as String?,
        transporterNumber: json['transporter_number'] as String?,
        transporterDriver: json['transporter_driver'] as String?,
        destination: json['destination'] as String?,
        lots: (json['lots'] as List<dynamic>?)
                ?.map((e) => FpoBatchLot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        ledger: FpoFinancialLedger.fromJson(
            json['ledger'] as Map<String, dynamic>),
        ewayBillNumber: json['eway_bill_number'] as String?,
      );

  @override
  List<Object?> get props => [id, batchCode, fpoId, status, fillPercentage];
}

// ─── MandiSyncStatus model ────────────────────────────────────────────────────
class MandiSyncStatus extends Equatable {
  const MandiSyncStatus({
    required this.configured,
    required this.lastSync,
    required this.status,
    required this.totalRecords,
    this.sourceUrl,
    this.error,
  });

  final bool configured;
  final String? lastSync;
  final String status;
  final int totalRecords;
  final String? sourceUrl;
  final String? error;

  factory MandiSyncStatus.fromJson(Map<String, dynamic> json) =>
      MandiSyncStatus(
        configured: json['configured'] as bool? ?? false,
        lastSync: json['last_sync'] as String?,
        status: json['status'] as String? ?? 'unknown',
        totalRecords: json['total_records'] as int? ?? 0,
        sourceUrl: json['source_url'] as String?,
        error: json['error'] as String?,
      );

  @override
  List<Object?> get props => [configured, lastSync, totalRecords];
}

// ─── Transaction & Settlement models ──────────────────────────────────────────

class SettlementMilestone extends Equatable {
  const SettlementMilestone({
    required this.step,
    required this.title,
    required this.timestamp,
    required this.description,
    this.badge,
    this.amount,
    this.amountLabel,
    this.isCompleted = true,
    this.isCurrent = false,
  });

  final int step;
  final String title;
  final String timestamp;
  final String description;
  final String? badge;
  final double? amount;
  final String? amountLabel;
  final bool isCompleted;
  final bool isCurrent;

  factory SettlementMilestone.fromJson(Map<String, dynamic> json) =>
      SettlementMilestone(
        step: json['step'] as int? ?? 1,
        title: json['title'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        description: json['description'] as String? ?? '',
        badge: json['badge'] as String?,
        amount: (json['amount'] as num?)?.toDouble(),
        amountLabel: json['amount_label'] as String?,
        isCompleted: json['is_completed'] as bool? ?? true,
        isCurrent: json['is_current'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'timestamp': timestamp,
        'description': description,
        'badge': badge,
        'amount': amount,
        'amount_label': amountLabel,
        'is_completed': isCompleted,
        'is_current': isCurrent,
      };

  @override
  List<Object?> get props => [step, title, isCompleted, isCurrent];
}

class IsolatedCrate extends Equatable {
  const IsolatedCrate({
    required this.crateId,
    required this.issue,
    required this.weightKg,
    required this.deductionAmount,
  });

  final String crateId;
  final String issue;
  final double weightKg;
  final double deductionAmount;

  factory IsolatedCrate.fromJson(Map<String, dynamic> json) => IsolatedCrate(
        crateId: json['crate_id'] as String? ?? '',
        issue: json['issue'] as String? ?? '',
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 50.0,
        deductionAmount:
            (json['deduction_amount'] as num?)?.toDouble() ?? 600.0,
      );

  Map<String, dynamic> toJson() => {
        'crate_id': crateId,
        'issue': issue,
        'weight_kg': weightKg,
        'deduction_amount': deductionAmount,
      };

  @override
  List<Object?> get props => [crateId, issue, deductionAmount];
}

class MemberPayoutSplit extends Equatable {
  const MemberPayoutSplit({
    required this.name,
    required this.quantityQuintal,
    required this.grade,
    required this.grossAmount,
    required this.deductionAmount,
    required this.netPayout,
    required this.status,
    this.note,
  });

  final String name;
  final double quantityQuintal;
  final String grade;
  final double grossAmount;
  final double deductionAmount;
  final double netPayout;
  final String status;
  final String? note;

  factory MemberPayoutSplit.fromJson(Map<String, dynamic> json) =>
      MemberPayoutSplit(
        name: json['name'] as String? ?? '',
        quantityQuintal: (json['quantity_quintal'] as num?)?.toDouble() ?? 0.0,
        grade: json['grade'] as String? ?? 'Grade A',
        grossAmount: (json['gross_amount'] as num?)?.toDouble() ?? 0.0,
        deductionAmount:
            (json['deduction_amount'] as num?)?.toDouble() ?? 0.0,
        netPayout: (json['net_payout'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'Pending',
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity_quintal': quantityQuintal,
        'grade': grade,
        'gross_amount': grossAmount,
        'deduction_amount': deductionAmount,
        'net_payout': netPayout,
        'status': status,
        'note': note,
      };

  @override
  List<Object?> get props => [name, netPayout, status];
}

class SettlementLedger extends Equatable {
  const SettlementLedger({
    required this.grossValue,
    required this.freightDeduction,
    required this.damagedCratesDeduction,
    required this.apmcFee,
    required this.netDisbursed,
    this.currency = 'INR',
    this.utrReference,
    this.bankInfo,
    this.paymentMode = 'Direct DBT',
  });

  final double grossValue;
  final double freightDeduction;
  final double damagedCratesDeduction;
  final double apmcFee;
  final double netDisbursed;
  final String currency;
  final String? utrReference;
  final String? bankInfo;
  final String paymentMode;

  factory SettlementLedger.fromJson(Map<String, dynamic> json) =>
      SettlementLedger(
        grossValue: (json['gross_value'] as num?)?.toDouble() ?? 0.0,
        freightDeduction:
            (json['freight_deduction'] as num?)?.toDouble() ?? 0.0,
        damagedCratesDeduction:
            (json['damaged_crates_deduction'] as num?)?.toDouble() ?? 0.0,
        apmcFee: (json['apmc_fee'] as num?)?.toDouble() ?? 0.0,
        netDisbursed: (json['net_disbursed'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'INR',
        utrReference: json['utr_reference'] as String?,
        bankInfo: json['bank_info'] as String?,
        paymentMode: json['payment_mode'] as String? ?? 'Direct DBT',
      );

  Map<String, dynamic> toJson() => {
        'gross_value': grossValue,
        'freight_deduction': freightDeduction,
        'damaged_crates_deduction': damagedCratesDeduction,
        'apmc_fee': apmcFee,
        'net_disbursed': netDisbursed,
        'currency': currency,
        'utr_reference': utrReference,
        'bank_info': bankInfo,
        'payment_mode': paymentMode,
      };

  @override
  List<Object?> get props => [grossValue, netDisbursed, utrReference];
}

class DisputeRecord extends Equatable {
  const DisputeRecord({
    required this.id,
    required this.transactionId,
    required this.raisedBy,
    required this.reason,
    required this.status,
    this.crateIds,
    this.disputeType,
    this.resolution,
    this.createdAt,
  });

  final int id;
  final int transactionId;
  final String raisedBy;
  final String reason;
  final String status;
  final String? crateIds;
  final String? disputeType;
  final String? resolution;
  final DateTime? createdAt;

  factory DisputeRecord.fromJson(Map<String, dynamic> json) => DisputeRecord(
        id: json['id'] as int,
        transactionId: json['transaction_id'] as int,
        raisedBy: json['raised_by'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        crateIds: json['crate_ids'] as String?,
        disputeType: json['dispute_type'] as String?,
        resolution: json['resolution'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'raised_by': raisedBy,
        'reason': reason,
        'status': status,
        'crate_ids': crateIds,
        'dispute_type': disputeType,
        'resolution': resolution,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, transactionId, status, reason];
}

class TransactionRecord extends Equatable {
  const TransactionRecord({
    required this.id,
    required this.lotId,
    required this.buyerId,
    required this.agreedPrice,
    required this.quantityQuintal,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.utrNumber,
    this.weighbridgeQuantity,
    this.freightDeduction = 0.0,
    this.crateDamageDeduction = 0.0,
    this.flaggedCratesCount = 0,
    this.invoiceNumber,
    this.batchCode,
    this.sellerName,
    this.buyerName,
    this.commodity,
    this.createdAt,
    this.milestones = const [],
    this.isolatedCrates = const [],
    this.ledger,
    this.memberSplits = const [],
    this.disputes = const [],
  });

  final int id;
  final int lotId;
  final int buyerId;
  final double agreedPrice;
  final double quantityQuintal;
  final double totalAmount;
  final String status;
  final String paymentStatus; // pending, paid, failed, disputed
  final String? utrNumber;
  final double? weighbridgeQuantity;
  final double freightDeduction;
  final double crateDamageDeduction;
  final int flaggedCratesCount;
  final String? invoiceNumber;
  final String? batchCode;
  final String? sellerName;
  final String? buyerName;
  final String? commodity;
  final DateTime? createdAt;
  final List<SettlementMilestone> milestones;
  final List<IsolatedCrate> isolatedCrates;
  final SettlementLedger? ledger;
  final List<MemberPayoutSplit> memberSplits;
  final List<DisputeRecord> disputes;

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get isPending => paymentStatus.toLowerCase() == 'pending';
  bool get isFailed => paymentStatus.toLowerCase() == 'failed';
  bool get isDisputed => paymentStatus.toLowerCase() == 'disputed';

  factory TransactionRecord.fromJson(Map<String, dynamic> json) =>
      TransactionRecord(
        id: json['id'] as int,
        lotId: json['lot_id'] as int,
        buyerId: json['buyer_id'] as int,
        agreedPrice: (json['agreed_price'] as num?)?.toDouble() ?? 0.0,
        quantityQuintal:
            (json['quantity_quintal'] as num?)?.toDouble() ?? 0.0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'created',
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        utrNumber: json['utr_number'] as String?,
        weighbridgeQuantity:
            (json['weighbridge_quantity'] as num?)?.toDouble(),
        freightDeduction:
            (json['freight_deduction'] as num?)?.toDouble() ?? 0.0,
        crateDamageDeduction:
            (json['crate_damage_deduction'] as num?)?.toDouble() ?? 0.0,
        flaggedCratesCount:
            (json['flagged_crates_count'] as num?)?.toInt() ?? 0,
        invoiceNumber: json['invoice_number'] as String?,
        batchCode: json['batch_code'] as String?,
        sellerName: json['seller_name'] as String?,
        buyerName: json['buyer_name'] as String?,
        commodity: json['commodity'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((e) =>
                    SettlementMilestone.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        isolatedCrates: (json['isolated_crates'] as List<dynamic>?)
                ?.map((e) =>
                    IsolatedCrate.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        ledger: json['ledger'] != null
            ? SettlementLedger.fromJson(json['ledger'] as Map<String, dynamic>)
            : null,
        memberSplits: (json['member_splits'] as List<dynamic>?)
                ?.map((e) =>
                    MemberPayoutSplit.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        disputes: (json['disputes'] as List<dynamic>?)
                ?.map((e) =>
                    DisputeRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lot_id': lotId,
        'buyer_id': buyerId,
        'agreed_price': agreedPrice,
        'quantity_quintal': quantityQuintal,
        'total_amount': totalAmount,
        'status': status,
        'payment_status': paymentStatus,
        'utr_number': utrNumber,
        'weighbridge_quantity': weighbridgeQuantity,
        'freight_deduction': freightDeduction,
        'crate_damage_deduction': crateDamageDeduction,
        'flagged_crates_count': flaggedCratesCount,
        'invoice_number': invoiceNumber,
        'batch_code': batchCode,
        'seller_name': sellerName,
        'buyer_name': buyerName,
        'commodity': commodity,
        'created_at': createdAt?.toIso8601String(),
        'milestones': milestones.map((e) => e.toJson()).toList(),
        'isolated_crates': isolatedCrates.map((e) => e.toJson()).toList(),
        'ledger': ledger?.toJson(),
        'member_splits': memberSplits.map((e) => e.toJson()).toList(),
        'disputes': disputes.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, lotId, buyerId, paymentStatus, totalAmount];
}

// ─── Chatbot models ──────────────────────────────────────────────────────────
class ChatResponseModel extends Equatable {
  const ChatResponseModel({
    required this.reply,
    this.mode = 'rule_based_prototype',
    this.isLlm = false,
    this.intent = 'general',
    this.suggestions = const [],
    this.disclaimer =
        'Krishi Assistant is running in Rule-Based Prototype mode. LLM integration architecture ready.',
  });

  final String reply;
  final String mode;
  final bool isLlm;
  final String intent;
  final List<String> suggestions;
  final String disclaimer;

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) =>
      ChatResponseModel(
        reply: json['reply'] as String? ?? '',
        mode: json['mode'] as String? ?? 'rule_based_prototype',
        isLlm: json['is_llm'] as bool? ?? false,
        intent: json['intent'] as String? ?? 'general',
        suggestions: (json['suggestions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        disclaimer: json['disclaimer'] as String? ??
            'Krishi Assistant is running in Rule-Based Prototype mode. LLM integration architecture ready.',
      );

  Map<String, dynamic> toJson() => {
        'reply': reply,
        'mode': mode,
        'is_llm': isLlm,
        'intent': intent,
        'suggestions': suggestions,
        'disclaimer': disclaimer,
      };

  @override
  List<Object?> get props => [reply, mode, isLlm, intent, suggestions];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.intent,
    this.mode = 'rule_based_prototype',
    this.isLlm = false,
    this.suggestions = const [],
    this.disclaimer,
  });

  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? intent;
  final String mode;
  final bool isLlm;
  final List<String> suggestions;
  final String? disclaimer;

  factory ChatMessage.fromResponse(ChatResponseModel res) => ChatMessage(
        text: res.reply,
        isBot: true,
        timestamp: DateTime.now(),
        intent: res.intent,
        mode: res.mode,
        isLlm: res.isLlm,
        suggestions: res.suggestions,
        disclaimer: res.disclaimer,
      );

  factory ChatMessage.user(String text) => ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      );

  @override
  List<Object?> get props => [text, isBot, timestamp, intent, mode, isLlm];
}

