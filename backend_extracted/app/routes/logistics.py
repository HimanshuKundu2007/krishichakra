from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import LogisticsOption, StorageOption
from ..schemas import LogisticsCreate, LogisticsOut, StorageCreate, StorageOut

router = APIRouter(prefix="/logistics", tags=["Logistics"])


def _seed_logistics_if_empty(db: Session):
    """Seed baseline transport deals matching Stitch reference if table is empty."""
    if not db.query(LogisticsOption).first():
        options = [
            LogisticsOption(
                provider_name="Maha AgriHaul",
                vehicle_type="Tata 407 LCV",
                vehicle_number="MH-14-AZ-4921",
                driver_name="Suresh Shinde",
                driver_phone="18001801551",
                driver_rating=4.9,
                verified_trips=142,
                origin="Junnar",
                destination="Vashi APMC",
                cost_per_quintal=160.0,
                capacity_quintal=40.0,
                is_empty_return=True,
                discount_percentage=35.0,
                distance_km=124.0,
                transit_duration_minutes=220,
                ventilated=True,
                gps_active=True,
                departure_time="Today • 05:00 PM",
                available=True,
            ),
            LogisticsOption(
                provider_name="Kisan Carrier Co.",
                vehicle_type="7-Ton Container",
                vehicle_number="MH-12-CT-8091",
                driver_name="Baburao Gade",
                driver_phone="18001801551",
                driver_rating=4.7,
                verified_trips=98,
                origin="Junnar",
                destination="Pune APMC",
                cost_per_quintal=185.0,
                capacity_quintal=70.0,
                is_empty_return=False,
                discount_percentage=0.0,
                distance_km=85.0,
                transit_duration_minutes=150,
                ventilated=True,
                gps_active=True,
                departure_time="Tomorrow • 08:00 AM",
                available=True,
            ),
            LogisticsOption(
                provider_name="Sahyadri Cold Haulage",
                vehicle_type="10-Tonne Eicher Pro",
                vehicle_number="MH-14-AZ-8821",
                driver_name="Kailash Jadhav",
                driver_phone="18001801551",
                driver_rating=4.9,
                verified_trips=210,
                origin="Junnar",
                destination="Dindori",
                cost_per_quintal=145.0,
                capacity_quintal=100.0,
                is_empty_return=False,
                discount_percentage=0.0,
                distance_km=160.0,
                transit_duration_minutes=270,
                ventilated=True,
                gps_active=True,
                departure_time="Today • 06:00 PM",
                available=True,
            ),
        ]
        db.add_all(options)
        db.commit()


def _seed_storage_if_empty(db: Session):
    """Seed baseline cold storage and warehouse facilities matching Stitch reference."""
    if not db.query(StorageOption).first():
        storages = [
            StorageOption(
                provider_name="MSWC Nashik Cold Storage",
                location="Nashik",
                district="Nashik",
                state="Maharashtra",
                capacity_quintal=5000.0,
                available_capacity_quintal=1200.0,
                cost_per_quintal_day=1.5,
                distance_km=45.0,
                storage_type="Cold Storage",
                is_certified=True,
                enwr_loan_eligible=True,
                loan_advance_pct=70.0,
                available=True,
            ),
            StorageOption(
                provider_name="Agri Frost Junnar",
                location="Junnar",
                district="Pune",
                state="Maharashtra",
                capacity_quintal=800.0,
                available_capacity_quintal=200.0,
                cost_per_quintal_day=2.0,
                distance_km=8.0,
                storage_type="Cold Storage",
                is_certified=True,
                enwr_loan_eligible=True,
                loan_advance_pct=70.0,
                available=True,
            ),
            StorageOption(
                provider_name="Pune District Warehousing Corp",
                location="Pune",
                district="Pune",
                state="Maharashtra",
                capacity_quintal=10000.0,
                available_capacity_quintal=3500.0,
                cost_per_quintal_day=1.2,
                distance_km=60.0,
                storage_type="Ventilated Warehouse",
                is_certified=True,
                enwr_loan_eligible=True,
                loan_advance_pct=70.0,
                available=True,
            ),
        ]
        db.add_all(storages)
        db.commit()


# ─── Logistics Endpoints ───────────────────────────────────────────────────────
@router.post("/options", response_model=LogisticsOut)
def create_logistics(data: LogisticsCreate, db: Session = Depends(get_db)):
    """Add a new commercial or returning vehicle logistics option."""
    obj = LogisticsOption(**data.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/options", response_model=list[LogisticsOut])
def list_logistics(
    origin: str | None = None,
    destination: str | None = None,
    vehicle_type: str | None = None,
    db: Session = Depends(get_db)
):
    """
    List available freight transport options.
    Supports empty-return truck discounts and live corridor rates.
    """
    _seed_logistics_if_empty(db)
    q = db.query(LogisticsOption).filter(LogisticsOption.available == True)
    if origin:
        q = q.filter(LogisticsOption.origin.ilike(f"%{origin}%"))
    if destination:
        q = q.filter(LogisticsOption.destination.ilike(f"%{destination}%"))
    if vehicle_type:
        q = q.filter(LogisticsOption.vehicle_type.ilike(f"%{vehicle_type}%"))
    return q.all()


# ─── Storage Endpoints ────────────────────────────────────────────────────────
@router.post("/storage", response_model=StorageOut)
def create_storage(data: StorageCreate, db: Session = Depends(get_db)):
    """Register a cold storage or warehouse storage facility."""
    obj = StorageOption(**data.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/storage", response_model=list[StorageOut])
def list_storage(
    location: str | None = None,
    storage_type: str | None = None,
    enwr_eligible: bool | None = None,
    db: Session = Depends(get_db)
):
    """
    List available storage and cold warehouse facilities with daily rates
    and e-NWR instant loan eligibility.
    """
    _seed_storage_if_empty(db)
    q = db.query(StorageOption).filter(StorageOption.available == True)
    if location:
        q = q.filter(StorageOption.location.ilike(f"%{location}%"))
    if storage_type:
        q = q.filter(StorageOption.storage_type.ilike(f"%{storage_type}%"))
    if enwr_eligible is not None:
        q = q.filter(StorageOption.enwr_loan_eligible == enwr_eligible)
    return q.all()
