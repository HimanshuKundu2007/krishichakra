from datetime import date, datetime
from pydantic import BaseModel, Field
from typing import Any

class FarmerCreate(BaseModel):
    name: str
    phone: str
    village: str | None = None
    district: str | None = None
    state: str | None = None
    land_acres: float | None = None
    vulnerability_score: float = 0.5
    liquidity_need: float = 0.5

class FarmerOut(FarmerCreate):
    id: int
    class Config: from_attributes = True

class MandiPriceOut(BaseModel):
    id: int
    commodity: str
    variety: str | None
    state: str | None
    district: str | None
    market: str
    arrival_date: date
    min_price: float | None
    max_price: float | None
    modal_price: float | None
    unit: str
    arrival_quantity: float | None
    source: str
    source_updated_at: datetime | None
    ingested_at: datetime
    class Config: from_attributes = True

class ProduceLotCreate(BaseModel):
    farmer_id: int
    commodity: str
    variety: str | None = None
    quantity_quintal: float = Field(gt=0)
    grade: str | None = None
    quality_score: float | None = None
    latitude: float | None = None
    longitude: float | None = None
    harvest_date: date | None = None
    image_path: str | None = None

class BuyerCreate(BaseModel):
    name: str
    buyer_type: str
    district: str | None = None
    state: str | None = None
    verified: bool = False
    payment_reliability: float = 0.5
    demand_commodity: str
    min_quantity: float = 0
    max_quantity: float = 1e9
    quality_requirements: str | None = None
    offered_price: float | None = None

class OfferCreate(BaseModel):
    lot_id: int
    buyer_id: int
    offered_price: float
    quantity_quintal: float

class OfferOut(BaseModel):
    id: int
    lot_id: int
    buyer_id: int
    offered_price: float
    quantity_quintal: float
    class Config: from_attributes = True

class BuyerMatchScoreBreakdown(BaseModel):
    quantity_fit: float
    quality_fit: float
    verified_score: float
    payment_score: float

class MatchedBuyerOut(BaseModel):
    """
    Response item for GET /api/buyers/matches/{lot_id}.
    All scoring weights are transparent and documented here:
      match_score = 0.30*quantity_fit + 0.25*quality_fit
                  + 0.25*verified_score + 0.20*payment_score
    """
    buyer_id: int
    buyer: str
    buyer_type: str
    verified: bool
    payment_reliability: float
    offered_price: float | None
    match_score: float
    reason: str
    score_breakdown: BuyerMatchScoreBreakdown

class SettlementMilestoneOut(BaseModel):
    step: int
    title: str
    timestamp: str
    description: str
    badge: str | None = None
    amount: float | None = None
    amount_label: str | None = None
    is_completed: bool = True
    is_current: bool = False

class IsolatedCrateOut(BaseModel):
    crate_id: str
    issue: str
    weight_kg: float
    deduction_amount: float

class MemberSplitOut(BaseModel):
    name: str
    quantity_quintal: float
    grade: str
    gross_amount: float
    deduction_amount: float = 0.0
    net_payout: float
    status: str
    note: str | None = None

class SettlementLedgerOut(BaseModel):
    gross_value: float
    freight_deduction: float
    damaged_crates_deduction: float
    apmc_fee: float = 0.0
    net_disbursed: float
    currency: str = "INR"
    utr_reference: str | None = None
    bank_info: str | None = None
    payment_mode: str = "Direct DBT"

class DisputeCreate(BaseModel):
    transaction_id: int
    raised_by: str
    reason: str
    crate_ids: str | None = None
    dispute_type: str | None = "quality_mismatch"

class DisputeOut(BaseModel):
    id: int
    transaction_id: int
    raised_by: str
    reason: str
    status: str
    crate_ids: str | None = None
    dispute_type: str | None = None
    resolution: str | None = None
    created_at: datetime | None = None

    class Config:
        from_attributes = True

class TransactionCreate(BaseModel):
    lot_id: int
    buyer_id: int
    agreed_price: float
    quantity_quintal: float
    batch_code: str | None = None
    seller_name: str | None = None
    buyer_name: str | None = None
    commodity: str | None = None

class TransactionOut(BaseModel):
    id: int
    lot_id: int
    buyer_id: int
    agreed_price: float
    quantity_quintal: float
    total_amount: float
    status: str
    payment_status: str  # pending, paid, failed, disputed
    utr_number: str | None = None
    weighbridge_quantity: float | None = None
    freight_deduction: float = 0.0
    crate_damage_deduction: float = 0.0
    flagged_crates_count: int = 0
    invoice_number: str | None = None
    batch_code: str | None = None
    seller_name: str | None = None
    buyer_name: str | None = None
    commodity: str | None = None
    created_at: datetime | None = None
    milestones: list[SettlementMilestoneOut] = []
    isolated_crates: list[IsolatedCrateOut] = []
    ledger: SettlementLedgerOut | None = None
    member_splits: list[MemberSplitOut] = []
    disputes: list[DisputeOut] = []

    class Config:
        from_attributes = True

class LogisticsCreate(BaseModel):
    provider_name: str
    vehicle_type: str | None = None
    vehicle_number: str | None = None
    driver_name: str | None = None
    driver_phone: str | None = None
    driver_rating: float | None = 4.8
    verified_trips: int | None = 50
    origin: str | None = None
    destination: str | None = None
    cost_per_quintal: float
    capacity_quintal: float
    is_empty_return: bool = False
    discount_percentage: float | None = 0.0
    distance_km: float | None = None
    transit_duration_minutes: int | None = None
    ventilated: bool = True
    gps_active: bool = True
    departure_time: str | None = None
    available: bool = True

class LogisticsOut(BaseModel):
    id: int
    provider_name: str
    vehicle_type: str | None = None
    vehicle_number: str | None = None
    driver_name: str | None = None
    driver_phone: str | None = None
    driver_rating: float | None = 4.8
    verified_trips: int | None = 50
    origin: str | None = None
    destination: str | None = None
    cost_per_quintal: float
    capacity_quintal: float
    is_empty_return: bool = False
    discount_percentage: float | None = 0.0
    distance_km: float | None = None
    transit_duration_minutes: int | None = None
    ventilated: bool = True
    gps_active: bool = True
    departure_time: str | None = None
    available: bool = True

    class Config:
        from_attributes = True

class StorageCreate(BaseModel):
    provider_name: str
    location: str
    district: str | None = None
    state: str | None = None
    capacity_quintal: float
    available_capacity_quintal: float | None = None
    cost_per_quintal_day: float
    distance_km: float | None = None
    storage_type: str | None = "Cold Storage"
    is_certified: bool = True
    enwr_loan_eligible: bool = True
    loan_advance_pct: float = 70.0
    available: bool = True

class StorageOut(BaseModel):
    id: int
    provider_name: str
    location: str
    district: str | None = None
    state: str | None = None
    capacity_quintal: float
    available_capacity_quintal: float | None = None
    cost_per_quintal_day: float
    distance_km: float | None = None
    storage_type: str | None = "Cold Storage"
    is_certified: bool = True
    enwr_loan_eligible: bool = True
    loan_advance_pct: float = 70.0
    available: bool = True

    class Config:
        from_attributes = True

class ChatRequest(BaseModel):
    farmer_id: int | None = None
    message: str
    language: str = "en"

class ChatResponse(BaseModel):
    reply: str
    mode: str = "rule_based_prototype"
    is_llm: bool = False
    intent: str
    suggestions: list[str] = []
    disclaimer: str = "Krishi Assistant is running in Rule-Based Prototype mode. LLM integration architecture ready."

    class Config:
        from_attributes = True

class RecommendRequest(BaseModel):
    farmer_id: int | None = None
    lot_id: int | None = None
    commodity: str | None = None
    quantity_quintal: float | None = None
    transport_cost_per_quintal: float = 0.0
    storage_cost_per_quintal: float = 0.0
    holding_days: int = 0
    transport_cost: float | None = None
    storage_cost: float | None = None

class RecommendOptionOut(BaseModel):
    market: str
    district: str | None = None
    state: str | None = None
    arrival_date: str | None = None
    government_data_date: str
    modal_price: float
    quantity: float
    gross_realization: float
    transport_cost: float
    storage_cost: float
    estimated_net_realization: float
    source: str
    is_live_gov_data: bool = True
    variety: str | None = None
    min_price: float | None = None
    max_price: float | None = None

class RecommendResponseOut(BaseModel):
    commodity: str
    quantity: float
    quantity_quintal: float
    options: list[RecommendOptionOut]
    disclaimer: str
    note: str

class GradeRequest(BaseModel):
    crop: str
    lot_id: int | None = None
    image_path: str | None = None
    image_bytes_base64: str | None = None

class BoundingMarker(BaseModel):
    label: str
    conf: float
    x: float
    y: float

class GradeResponse(BaseModel):
    """
    Structured response for POST /api/produce/grade.
    IMPORTANT: is_certified is always False for the integration boundary prototype.
    The trained YOLO/PyTorch/OpenCV pipeline should replace ai_service.py when ready.
    """
    status: str
    crop: str
    grade: str | None = None
    quality_score: float | None = None
    uniformity_pct: float | None = None
    moisture_pct: float | None = None
    pest_damage_pct: float | None = None
    detected_markers: list[BoundingMarker] = []
    has_image: bool = False
    is_certified: bool = False
    assessment_type: str
    disclaimer: str
    message: str

class FPOCreate(BaseModel):
    name: str
    district: str | None = None
    state: str | None = None
    registration_number: str | None = None
    hub_name: str | None = None
    verified: bool = False

class FPOOut(BaseModel):
    id: int
    name: str
    district: str | None = None
    state: str | None = None
    registration_number: str | None = None
    hub_name: str | None = None
    total_members_count: int = 0
    verified: bool = False
    created_at: datetime | None = None

    class Config:
        from_attributes = True

class FPOMemberCreate(BaseModel):
    fpo_id: int
    farmer_id: int
    member_code: str | None = None
    role: str | None = "member"

class FPOMemberOut(BaseModel):
    id: int
    fpo_id: int
    farmer_id: int
    farmer_name: str | None = None
    farmer_phone: str | None = None
    farmer_village: str | None = None
    farmer_district: str | None = None
    member_code: str | None = None
    role: str = "member"
    created_at: datetime | None = None

    class Config:
        from_attributes = True

class FPOBatchLotCreate(BaseModel):
    farmer_id: int | None = None
    farmer_name: str
    member_code: str | None = None
    lot_id: int | None = None
    quantity_quintal: float
    grade: str
    bulb_spec: str | None = None
    moisture_pct: float | None = None
    foreign_rot_pct: float | None = None
    crates_count: int = 0
    qr_tag_range: str | None = None

class FPOBatchLotOut(BaseModel):
    id: int
    batch_id: int
    farmer_id: int | None = None
    farmer_name: str
    member_code: str | None = None
    lot_id: int | None = None
    quantity_quintal: float
    grade: str
    bulb_spec: str | None = None
    moisture_pct: float | None = None
    foreign_rot_pct: float | None = None
    crates_count: int = 0
    qr_tag_range: str | None = None
    status: str
    diversion_route: str | None = None
    gatekeeper_note: str | None = None

    class Config:
        from_attributes = True

class FPOBatchCreate(BaseModel):
    fpo_id: int
    batch_code: str | None = None
    commodity: str
    target_grade: str = "Grade A"
    target_quantity_quintal: float = 200.0
    buyer_name: str | None = None
    buyer_contract_price: float | None = None
    benchmark_mandi_price: float | None = None
    destination: str | None = None
    transporter_vehicle: str | None = None
    transporter_number: str | None = None
    transporter_driver: str | None = None
    dock_bay: str | None = None

class FPOFinancialLedgerOut(BaseModel):
    commercial_value: float
    farmer_payout: float
    fpo_margin: float
    freight_surcharge: float
    currency: str = "INR"

class FPOBatchAggregationOut(BaseModel):
    id: int
    batch_code: str
    fpo_id: int
    fpo_name: str
    fpo_verified: bool
    fpo_registration_number: str | None = None
    fpo_hub_name: str | None = None
    total_registered_farmers: int = 0
    commodity: str
    target_grade: str
    target_quantity_quintal: float
    staged_quantity_quintal: float
    diverted_quantity_quintal: float
    remaining_quantity_quintal: float
    remaining_crates: int
    fill_percentage: float
    status: str
    buyer_name: str | None = None
    buyer_contract_price: float | None = None
    benchmark_mandi_price: float | None = None
    institutional_premium_per_q: float | None = None
    bonus_explanation: str | None = None
    staging_bay_info: str | None = None
    total_crates_checked: int = 0
    dock_bay: str | None = None
    transporter_vehicle: str | None = None
    transporter_number: str | None = None
    transporter_driver: str | None = None
    destination: str | None = None
    lots: list[FPOBatchLotOut] = []
    ledger: FPOFinancialLedgerOut
    eway_bill_number: str | None = None

class SyncResult(BaseModel):
    status: str
    source: str
    records_fetched: int
    records_inserted: int
    records_updated: int
    records_skipped: int
    last_updated: datetime | None = None
    error: str | None = None
