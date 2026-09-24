from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime

from ..database import get_db
from ..models import FPO, FPOMember, Farmer, FPOBatch, FPOBatchLot
from ..schemas import (
    FPOCreate, FPOOut,
    FPOMemberCreate, FPOMemberOut,
    FPOBatchCreate, FPOBatchLotCreate,
    FPOBatchAggregationOut
)
from ..services.fpo_aggregation import (
    evaluate_gatekeeper_quality,
    calculate_batch_aggregation
)

router = APIRouter(prefix="/fpo", tags=["FPO"])


def _seed_stitch_fpo_if_empty(db: Session) -> FPO:
    """Helper to ensure baseline Stitch FPO and batch exist for prototype."""
    fpo = db.query(FPO).filter(FPO.id == 1).first()
    if not fpo:
        fpo = FPO(
            id=1,
            name="Junnar Farmer Producer Co. Ltd.",
            district="Pune",
            state="Maharashtra",
            registration_number="Reg #MH-JNR-092",
            hub_name="Junnar FPC Hub",
            total_members_count=412,
            verified=True,
            created_at=datetime.utcnow()
        )
        db.add(fpo)
        db.commit()
        db.refresh(fpo)

    batch = db.query(FPOBatch).filter(FPOBatch.id == 1).first()
    if not batch:
        batch = FPOBatch(
            id=1,
            batch_code="#ON-BATCH-402",
            fpo_id=fpo.id,
            commodity="Nashik Red Onion",
            target_grade="Grade A",
            target_quantity_quintal=200.0,
            current_quantity_quintal=185.0,
            status="pooling",
            buyer_name="Sahyadri Processing",
            buyer_contract_price=2650.0,
            benchmark_mandi_price=2470.0,
            institutional_premium_per_q=180.0,
            destination="Sahyadri Agro Processing Plant, Dindori",
            transporter_vehicle="10-Tonne Eicher Pro",
            transporter_number="MH-14-AZ-8821",
            transporter_driver="Kailash Jadhav • Verified Ventilated Reefer",
            dock_bay="Dock Bay #2",
            staging_bay_info="Junnar Staging Bay: 70 Crates Checked • Live Camera Gate 2",
            created_at=datetime.utcnow()
        )
        db.add(batch)
        db.commit()
        db.refresh(batch)

        # Seed member lots matching Stitch reference
        lots = [
            FPOBatchLot(
                batch_id=batch.id,
                farmer_name="Ramesh Patil",
                member_code="Member ID #FPO-084",
                quantity_quintal=20.0,
                grade="Grade A",
                bulb_spec="52–58mm bulb",
                moisture_pct=11.8,
                foreign_rot_pct=0.0,
                crates_count=40,
                qr_tag_range="#QR-01 to #QR-40",
                status="staged",
                diversion_route=None,
                gatekeeper_note=None,
                created_at=datetime.utcnow()
            ),
            FPOBatchLot(
                batch_id=batch.id,
                farmer_name="Suresh Deshmukh",
                member_code="Member ID #FPO-119",
                quantity_quintal=15.0,
                grade="Grade A",
                bulb_spec="50–56mm bulb",
                moisture_pct=12.1,
                foreign_rot_pct=0.0,
                crates_count=30,
                qr_tag_range="#QR-41 to #QR-70",
                status="staged",
                diversion_route=None,
                gatekeeper_note=None,
                created_at=datetime.utcnow()
            ),
            FPOBatchLot(
                batch_id=batch.id,
                farmer_name="Vilas Shinde",
                member_code="Member ID #FPO-203",
                quantity_quintal=8.0,
                grade="Grade B",
                bulb_spec="<45mm Uniformity",
                moisture_pct=14.0,
                foreign_rot_pct=2.0,
                crates_count=0,
                qr_tag_range=None,
                status="diverted",
                diversion_route="Junnar APMC Yard • Spot Auction Slip #92",
                gatekeeper_note="Not eligible for Grade A bulk processing contract. Auto-rerouted to local mandi spot auction to safeguard FPO grade purity bonus.",
                created_at=datetime.utcnow()
            ),
        ]
        db.add_all(lots)
        db.commit()

    return fpo


# ─── FPO Creation & Inspection ────────────────────────────────────────────────
@router.post("", response_model=FPOOut)
def create_fpo(data: FPOCreate, db: Session = Depends(get_db)):
    """Create a new FPO organization."""
    obj = FPO(
        name=data.name,
        district=data.district,
        state=data.state,
        registration_number=data.registration_number,
        hub_name=data.hub_name or f"{data.name} Hub",
        verified=data.verified,
        total_members_count=0,
        created_at=datetime.utcnow()
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("", response_model=list[FPOOut])
def list_fpos(db: Session = Depends(get_db)):
    """List all registered FPOs. Seeds baseline if empty."""
    fpos = db.query(FPO).all()
    if not fpos:
        _seed_stitch_fpo_if_empty(db)
        fpos = db.query(FPO).all()
    return fpos


@router.get("/{fpo_id}", response_model=FPOOut)
def get_fpo(fpo_id: int, db: Session = Depends(get_db)):
    """Retrieve FPO details and verification status."""
    fpo = db.query(FPO).filter(FPO.id == fpo_id).first()
    if not fpo and fpo_id == 1:
        fpo = _seed_stitch_fpo_if_empty(db)
    if not fpo:
        raise HTTPException(status_code=404, detail=f"FPO {fpo_id} not found")
    return fpo


@router.patch("/{fpo_id}/verify", response_model=FPOOut)
def verify_fpo(fpo_id: int, verified: bool = True, db: Session = Depends(get_db)):
    """Update FPO verification status."""
    fpo = db.query(FPO).filter(FPO.id == fpo_id).first()
    if not fpo:
        raise HTTPException(status_code=404, detail=f"FPO {fpo_id} not found")
    fpo.verified = verified
    db.commit()
    db.refresh(fpo)
    return fpo


# ─── Farmer Membership & Directory ───────────────────────────────────────────
@router.post("/members", response_model=FPOMemberOut)
def add_member(data: FPOMemberCreate, db: Session = Depends(get_db)):
    """Enrol a farmer into an FPO."""
    fpo = db.query(FPO).filter(FPO.id == data.fpo_id).first()
    if not fpo and data.fpo_id == 1:
        fpo = _seed_stitch_fpo_if_empty(db)
    if not fpo:
        raise HTTPException(status_code=404, detail=f"FPO {data.fpo_id} not found")

    farmer = db.query(Farmer).filter(Farmer.id == data.farmer_id).first()
    member_code = data.member_code or f"Member ID #FPO-{data.farmer_id:03d}"

    obj = FPOMember(
        fpo_id=data.fpo_id,
        farmer_id=data.farmer_id,
        member_code=member_code,
        role=data.role or "member",
        created_at=datetime.utcnow()
    )
    db.add(obj)
    fpo.total_members_count = (fpo.total_members_count or 0) + 1
    db.commit()
    db.refresh(obj)

    return FPOMemberOut(
        id=obj.id,
        fpo_id=obj.fpo_id,
        farmer_id=obj.farmer_id,
        farmer_name=farmer.name if farmer else None,
        farmer_phone=farmer.phone if farmer else None,
        farmer_village=farmer.village if farmer else None,
        farmer_district=farmer.district if farmer else None,
        member_code=obj.member_code,
        role=obj.role or "member",
        created_at=obj.created_at
    )


@router.get("/{fpo_id}/members", response_model=list[FPOMemberOut])
def list_members(fpo_id: int, db: Session = Depends(get_db)):
    """List members of an FPO with farmer directory details."""
    fpo = db.query(FPO).filter(FPO.id == fpo_id).first()
    if not fpo and fpo_id == 1:
        fpo = _seed_stitch_fpo_if_empty(db)

    members = db.query(FPOMember).filter(FPOMember.fpo_id == fpo_id).all()
    out = []
    for m in members:
        farmer = db.query(Farmer).filter(Farmer.id == m.farmer_id).first()
        out.append(FPOMemberOut(
            id=m.id,
            fpo_id=m.fpo_id,
            farmer_id=m.farmer_id,
            farmer_name=farmer.name if farmer else None,
            farmer_phone=farmer.phone if farmer else None,
            farmer_village=farmer.village if farmer else None,
            farmer_district=farmer.district if farmer else None,
            member_code=m.member_code,
            role=m.role or "member",
            created_at=m.created_at
        ))
    return out


# ─── Aggregated Produce Workflow & Backend Aggregation ────────────────────────
@router.post("/batches", response_model=FPOBatchAggregationOut)
def create_batch(data: FPOBatchCreate, db: Session = Depends(get_db)):
    """Create a new master aggregation batch for an FPO."""
    fpo = db.query(FPO).filter(FPO.id == data.fpo_id).first()
    if not fpo and data.fpo_id == 1:
        fpo = _seed_stitch_fpo_if_empty(db)
    if not fpo:
        raise HTTPException(status_code=404, detail=f"FPO {data.fpo_id} not found")

    batch_code = data.batch_code or f"#BATCH-{int(datetime.utcnow().timestamp()) % 10000:04d}"
    batch = FPOBatch(
        batch_code=batch_code,
        fpo_id=data.fpo_id,
        commodity=data.commodity,
        target_grade=data.target_grade,
        target_quantity_quintal=data.target_quantity_quintal,
        current_quantity_quintal=0.0,
        status="pooling",
        buyer_name=data.buyer_name or "Sahyadri Processing",
        buyer_contract_price=data.buyer_contract_price or 2650.0,
        benchmark_mandi_price=data.benchmark_mandi_price or 2470.0,
        institutional_premium_per_q=round((data.buyer_contract_price or 2650.0) - (data.benchmark_mandi_price or 2470.0), 2),
        destination=data.destination or "Sahyadri Agro Processing Plant, Dindori",
        transporter_vehicle=data.transporter_vehicle or "10-Tonne Eicher Pro",
        transporter_number=data.transporter_number or "MH-14-AZ-8821",
        transporter_driver=data.transporter_driver or "Kailash Jadhav • Verified Ventilated Reefer",
        dock_bay=data.dock_bay or "Dock Bay #2",
        staging_bay_info="Staging Bay Active",
        created_at=datetime.utcnow()
    )
    db.add(batch)
    db.commit()
    db.refresh(batch)

    agg = calculate_batch_aggregation(batch, [], fpo)
    return FPOBatchAggregationOut(**agg)


@router.get("/batches", response_model=list[FPOBatchAggregationOut])
def list_batches(fpo_id: int | None = None, db: Session = Depends(get_db)):
    """List batches with calculated aggregation summaries."""
    q = db.query(FPOBatch)
    if fpo_id:
        q = q.filter(FPOBatch.fpo_id == fpo_id)
    batches = q.all()
    if not batches:
        _seed_stitch_fpo_if_empty(db)
        batches = db.query(FPOBatch).all()

    out = []
    for b in batches:
        lots = db.query(FPOBatchLot).filter(FPOBatchLot.batch_id == b.id).all()
        fpo = db.query(FPO).filter(FPO.id == b.fpo_id).first()
        agg = calculate_batch_aggregation(b, lots, fpo)
        out.append(FPOBatchAggregationOut(**agg))
    return out


@router.get("/batches/{batch_id}", response_model=FPOBatchAggregationOut)
def get_batch_aggregation(batch_id: int, db: Session = Depends(get_db)):
    """
    Get aggregated batch details with pure backend computation.
    Calculates volumes, gatekeeper quality routing, crate counts,
    and financial realization ledger.
    """
    batch = db.query(FPOBatch).filter(FPOBatch.id == batch_id).first()
    if not batch and batch_id == 1:
        _seed_stitch_fpo_if_empty(db)
        batch = db.query(FPOBatch).filter(FPOBatch.id == 1).first()
    if not batch:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    lots = db.query(FPOBatchLot).filter(FPOBatchLot.batch_id == batch.id).all()
    fpo = db.query(FPO).filter(FPO.id == batch.fpo_id).first()
    agg = calculate_batch_aggregation(batch, lots, fpo)
    return FPOBatchAggregationOut(**agg)


@router.post("/batches/{batch_id}/lots", response_model=FPOBatchAggregationOut)
def add_lot_to_batch(batch_id: int, data: FPOBatchLotCreate, db: Session = Depends(get_db)):
    """
    Contribute a farmer's produce lot to the aggregation batch.
    Applies backend gatekeeper quality evaluation:
      - If lot grade meets target grade -> staged at hub
      - If lot grade is sub-standard -> auto-diverted to APMC spot auction to protect purity bonus
    """
    batch = db.query(FPOBatch).filter(FPOBatch.id == batch_id).first()
    if not batch and batch_id == 1:
        _seed_stitch_fpo_if_empty(db)
        batch = db.query(FPOBatch).filter(FPOBatch.id == 1).first()
    if not batch:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    # Backend Gatekeeper quality decision
    status, diversion_route, gatekeeper_note = evaluate_gatekeeper_quality(
        batch.target_grade, data.grade
    )

    crates = data.crates_count if data.crates_count > 0 else int(round(data.quantity_quintal * 2))

    lot = FPOBatchLot(
        batch_id=batch.id,
        farmer_id=data.farmer_id,
        farmer_name=data.farmer_name,
        member_code=data.member_code or f"Member #{data.farmer_name[:2].upper()}",
        lot_id=data.lot_id,
        quantity_quintal=data.quantity_quintal,
        grade=data.grade,
        bulb_spec=data.bulb_spec or "Standard spec",
        moisture_pct=data.moisture_pct or 12.0,
        foreign_rot_pct=data.foreign_rot_pct or 0.0,
        crates_count=crates if status == "staged" else 0,
        qr_tag_range=data.qr_tag_range or (f"#QR-{crates:02d}" if status == "staged" else None),
        status=status,
        diversion_route=diversion_route,
        gatekeeper_note=gatekeeper_note,
        created_at=datetime.utcnow()
    )
    db.add(lot)
    db.commit()

    # Re-calculate aggregation and update batch current quantity
    lots = db.query(FPOBatchLot).filter(FPOBatchLot.batch_id == batch.id).all()
    staged_total = sum(l.quantity_quintal for l in lots if l.status == "staged")
    batch.current_quantity_quintal = staged_total
    db.commit()

    fpo = db.query(FPO).filter(FPO.id == batch.fpo_id).first()
    agg = calculate_batch_aggregation(batch, lots, fpo)
    return FPOBatchAggregationOut(**agg)


@router.post("/batches/{batch_id}/dispatch", response_model=FPOBatchAggregationOut)
def dispatch_batch(batch_id: int, db: Session = Depends(get_db)):
    """
    Seal master batch and dispatch order.
    Transitions status to 'dispatched' and generates official e-Way bill manifest.
    """
    batch = db.query(FPOBatch).filter(FPOBatch.id == batch_id).first()
    if not batch and batch_id == 1:
        _seed_stitch_fpo_if_empty(db)
        batch = db.query(FPOBatch).filter(FPOBatch.id == 1).first()
    if not batch:
        raise HTTPException(status_code=404, detail=f"Batch {batch_id} not found")

    batch.status = "dispatched"
    db.commit()
    db.refresh(batch)

    lots = db.query(FPOBatchLot).filter(FPOBatchLot.batch_id == batch.id).all()
    fpo = db.query(FPO).filter(FPO.id == batch.fpo_id).first()
    agg = calculate_batch_aggregation(batch, lots, fpo)
    return FPOBatchAggregationOut(**agg)
