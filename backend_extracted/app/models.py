from datetime import datetime, date
from sqlalchemy import String, Float, Integer, DateTime, Date, Text, Boolean, ForeignKey, UniqueConstraint, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base

class Farmer(Base):
    __tablename__ = "farmers"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    village: Mapped[str | None] = mapped_column(String(120), nullable=True)
    district: Mapped[str | None] = mapped_column(String(120), nullable=True)
    state: Mapped[str | None] = mapped_column(String(120), nullable=True)
    land_acres: Mapped[float | None] = mapped_column(Float, nullable=True)
    vulnerability_score: Mapped[float] = mapped_column(Float, default=0.5)
    liquidity_need: Mapped[float] = mapped_column(Float, default=0.5)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class MandiPrice(Base):
    __tablename__ = "mandi_prices"
    id: Mapped[int] = mapped_column(primary_key=True)
    commodity: Mapped[str] = mapped_column(String(120), index=True)
    variety: Mapped[str | None] = mapped_column(String(120), nullable=True)
    state: Mapped[str | None] = mapped_column(String(120), index=True, nullable=True)
    district: Mapped[str | None] = mapped_column(String(120), index=True, nullable=True)
    market: Mapped[str] = mapped_column(String(160), index=True)
    arrival_date: Mapped[date] = mapped_column(Date, index=True)
    min_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    max_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    modal_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    unit: Mapped[str] = mapped_column(String(30), default="Quintal")
    arrival_quantity: Mapped[float | None] = mapped_column(Float, nullable=True)
    source: Mapped[str] = mapped_column(String(120))
    source_record_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    source_updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    ingested_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    raw_record: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    __table_args__ = (UniqueConstraint("source", "source_record_id", name="uq_mandi_source_record"),)

class ProduceLot(Base):
    __tablename__ = "produce_lots"
    id: Mapped[int] = mapped_column(primary_key=True)
    farmer_id: Mapped[int] = mapped_column(ForeignKey("farmers.id"), index=True)
    commodity: Mapped[str] = mapped_column(String(120))
    variety: Mapped[str | None] = mapped_column(String(120), nullable=True)
    quantity_quintal: Mapped[float] = mapped_column(Float)
    grade: Mapped[str | None] = mapped_column(String(50), nullable=True)
    quality_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    harvest_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(String(40), default="available")
    image_path: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class Buyer(Base):
    __tablename__ = "buyers"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(160))
    buyer_type: Mapped[str] = mapped_column(String(80))
    district: Mapped[str | None] = mapped_column(String(120), nullable=True)
    state: Mapped[str | None] = mapped_column(String(120), nullable=True)
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    payment_reliability: Mapped[float] = mapped_column(Float, default=0.5)
    demand_commodity: Mapped[str] = mapped_column(String(120))
    min_quantity: Mapped[float] = mapped_column(Float, default=0)
    max_quantity: Mapped[float] = mapped_column(Float, default=1e9)
    quality_requirements: Mapped[str | None] = mapped_column(Text, nullable=True)
    offered_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class Offer(Base):
    __tablename__ = "offers"
    id: Mapped[int] = mapped_column(primary_key=True)
    lot_id: Mapped[int] = mapped_column(ForeignKey("produce_lots.id"), index=True)
    buyer_id: Mapped[int] = mapped_column(ForeignKey("buyers.id"), index=True)
    offered_price: Mapped[float] = mapped_column(Float)
    quantity_quintal: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(40), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class FPO(Base):
    __tablename__ = "fpos"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(160))
    district: Mapped[str | None] = mapped_column(String(120), nullable=True)
    state: Mapped[str | None] = mapped_column(String(120), nullable=True)
    registration_number: Mapped[str | None] = mapped_column(String(80), nullable=True)
    hub_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    total_members_count: Mapped[int] = mapped_column(Integer, default=0)
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class FPOMember(Base):
    __tablename__ = "fpo_members"
    id: Mapped[int] = mapped_column(primary_key=True)
    fpo_id: Mapped[int] = mapped_column(ForeignKey("fpos.id"), index=True)
    farmer_id: Mapped[int] = mapped_column(ForeignKey("farmers.id"), index=True)
    member_code: Mapped[str | None] = mapped_column(String(60), nullable=True)
    role: Mapped[str | None] = mapped_column(String(60), default="member")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class FPOBatch(Base):
    __tablename__ = "fpo_batches"
    id: Mapped[int] = mapped_column(primary_key=True)
    batch_code: Mapped[str] = mapped_column(String(60), unique=True, index=True)
    fpo_id: Mapped[int] = mapped_column(ForeignKey("fpos.id"), index=True)
    commodity: Mapped[str] = mapped_column(String(120))
    target_grade: Mapped[str] = mapped_column(String(50), default="Grade A")
    target_quantity_quintal: Mapped[float] = mapped_column(Float, default=200.0)
    current_quantity_quintal: Mapped[float] = mapped_column(Float, default=0.0)
    status: Mapped[str] = mapped_column(String(50), default="pooling")  # pooling, sealed, dispatched
    buyer_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    buyer_contract_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    benchmark_mandi_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    institutional_premium_per_q: Mapped[float | None] = mapped_column(Float, nullable=True)
    destination: Mapped[str | None] = mapped_column(String(200), nullable=True)
    transporter_vehicle: Mapped[str | None] = mapped_column(String(120), nullable=True)
    transporter_number: Mapped[str | None] = mapped_column(String(60), nullable=True)
    transporter_driver: Mapped[str | None] = mapped_column(String(120), nullable=True)
    dock_bay: Mapped[str | None] = mapped_column(String(60), nullable=True)
    staging_bay_info: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class FPOBatchLot(Base):
    __tablename__ = "fpo_batch_lots"
    id: Mapped[int] = mapped_column(primary_key=True)
    batch_id: Mapped[int] = mapped_column(ForeignKey("fpo_batches.id"), index=True)
    farmer_id: Mapped[int | None] = mapped_column(ForeignKey("farmers.id"), nullable=True)
    farmer_name: Mapped[str] = mapped_column(String(120))
    member_code: Mapped[str | None] = mapped_column(String(60), nullable=True)
    lot_id: Mapped[int | None] = mapped_column(ForeignKey("produce_lots.id"), nullable=True)
    quantity_quintal: Mapped[float] = mapped_column(Float)
    grade: Mapped[str] = mapped_column(String(50))
    bulb_spec: Mapped[str | None] = mapped_column(String(80), nullable=True)
    moisture_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    foreign_rot_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    crates_count: Mapped[int] = mapped_column(Integer, default=0)
    qr_tag_range: Mapped[str | None] = mapped_column(String(100), nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="staged")  # staged, diverted
    diversion_route: Mapped[str | None] = mapped_column(String(160), nullable=True)
    gatekeeper_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class LogisticsOption(Base):
    __tablename__ = "logistics_options"
    id: Mapped[int] = mapped_column(primary_key=True)
    provider_name: Mapped[str] = mapped_column(String(160))
    vehicle_type: Mapped[str | None] = mapped_column(String(80), nullable=True)
    vehicle_number: Mapped[str | None] = mapped_column(String(60), nullable=True)
    driver_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    driver_phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    driver_rating: Mapped[float | None] = mapped_column(Float, default=4.8)
    verified_trips: Mapped[int | None] = mapped_column(Integer, default=50)
    origin: Mapped[str | None] = mapped_column(String(160), nullable=True)
    destination: Mapped[str | None] = mapped_column(String(160), nullable=True)
    cost_per_quintal: Mapped[float] = mapped_column(Float)
    capacity_quintal: Mapped[float] = mapped_column(Float)
    is_empty_return: Mapped[bool] = mapped_column(Boolean, default=False)
    discount_percentage: Mapped[float | None] = mapped_column(Float, default=0.0)
    distance_km: Mapped[float | None] = mapped_column(Float, nullable=True)
    transit_duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    ventilated: Mapped[bool] = mapped_column(Boolean, default=True)
    gps_active: Mapped[bool] = mapped_column(Boolean, default=True)
    departure_time: Mapped[str | None] = mapped_column(String(60), nullable=True)
    available: Mapped[bool] = mapped_column(Boolean, default=True)

class StorageOption(Base):
    __tablename__ = "storage_options"
    id: Mapped[int] = mapped_column(primary_key=True)
    provider_name: Mapped[str] = mapped_column(String(160))
    location: Mapped[str] = mapped_column(String(160))
    district: Mapped[str | None] = mapped_column(String(120), nullable=True)
    state: Mapped[str | None] = mapped_column(String(120), nullable=True)
    capacity_quintal: Mapped[float] = mapped_column(Float)
    available_capacity_quintal: Mapped[float | None] = mapped_column(Float, nullable=True)
    cost_per_quintal_day: Mapped[float] = mapped_column(Float)
    distance_km: Mapped[float | None] = mapped_column(Float, nullable=True)
    storage_type: Mapped[str | None] = mapped_column(String(80), default="Cold Storage")
    is_certified: Mapped[bool] = mapped_column(Boolean, default=True)
    enwr_loan_eligible: Mapped[bool] = mapped_column(Boolean, default=True)
    loan_advance_pct: Mapped[float] = mapped_column(Float, default=70.0)
    available: Mapped[bool] = mapped_column(Boolean, default=True)

class Transaction(Base):
    __tablename__ = "transactions"
    id: Mapped[int] = mapped_column(primary_key=True)
    lot_id: Mapped[int] = mapped_column(ForeignKey("produce_lots.id"), index=True)
    buyer_id: Mapped[int] = mapped_column(ForeignKey("buyers.id"), index=True)
    agreed_price: Mapped[float] = mapped_column(Float)
    quantity_quintal: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(40), default="created")
    payment_status: Mapped[str] = mapped_column(String(40), default="pending")
    utr_number: Mapped[str | None] = mapped_column(String(80), nullable=True)
    weighbridge_quantity: Mapped[float | None] = mapped_column(Float, nullable=True)
    freight_deduction: Mapped[float | None] = mapped_column(Float, default=0.0)
    crate_damage_deduction: Mapped[float | None] = mapped_column(Float, default=0.0)
    flagged_crates_count: Mapped[int | None] = mapped_column(Integer, default=0)
    invoice_number: Mapped[str | None] = mapped_column(String(80), nullable=True)
    batch_code: Mapped[str | None] = mapped_column(String(80), nullable=True)
    seller_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    buyer_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    commodity: Mapped[str | None] = mapped_column(String(80), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class Dispute(Base):
    __tablename__ = "disputes"
    id: Mapped[int] = mapped_column(primary_key=True)
    transaction_id: Mapped[int] = mapped_column(ForeignKey("transactions.id"), index=True)
    raised_by: Mapped[str] = mapped_column(String(40))
    reason: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(40), default="open")
    crate_ids: Mapped[str | None] = mapped_column(String(120), nullable=True)
    dispute_type: Mapped[str | None] = mapped_column(String(80), default="quality_mismatch")
    resolution: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

class SyncLog(Base):
    __tablename__ = "sync_logs"
    id: Mapped[int] = mapped_column(primary_key=True)
    source: Mapped[str] = mapped_column(String(120))
    started_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    status: Mapped[str] = mapped_column(String(40))
    fetched: Mapped[int] = mapped_column(Integer, default=0)
    inserted: Mapped[int] = mapped_column(Integer, default=0)
    updated: Mapped[int] = mapped_column(Integer, default=0)
    skipped: Mapped[int] = mapped_column(Integer, default=0)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
