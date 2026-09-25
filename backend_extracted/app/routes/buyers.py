from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Buyer, ProduceLot, Offer
from ..schemas import BuyerCreate, OfferCreate, OfferOut, MatchedBuyerOut, BuyerOut
from ..services.buyer_matching import match_buyers

router = APIRouter(prefix="/buyers", tags=["Buyers"])


@router.get("", response_model=list[BuyerOut])
def list_buyers(
    commodity: str | None = None,
    location: str | None = None,
    grade: str | None = None,
    min_qty: float | None = None,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """
    Returns synthetic demo buyers for prototype exploration and market linkage matching.
    Supports filtering by commodity, district/city location, grade, and required quantity.
    """
    q = db.query(Buyer)
    if commodity and commodity.strip():
        c = commodity.strip().lower()
        from ..services.buyer_matching import _normalize_commodity_token
        norm = _normalize_commodity_token(c)
        q = q.filter(
            (Buyer.demand_commodity.ilike(f"%{norm}%")) | (Buyer.demand_commodity.ilike(f"%{c}%"))
        )
    if location and location.strip():
        loc = location.strip()
        q = q.filter((Buyer.district.ilike(f"%{loc}%")) | (Buyer.state.ilike(f"%{loc}%")))
    if grade and grade.strip():
        g = grade.strip()
        q = q.filter((Buyer.quality_requirements.ilike(f"%{g}%")))
    if min_qty is not None:
        q = q.filter(Buyer.max_quantity >= min_qty)

    buyers = q.limit(limit).all()
    out = []
    for b in buyers:
        out.append(
            BuyerOut(
                id=b.id,
                name=b.name,
                buyer_type=b.buyer_type,
                district=b.district,
                state=b.state,
                city=getattr(b, "city", None) or b.district or "Pune",
                verified=b.verified,
                payment_reliability=b.payment_reliability or 0.8,
                demand_commodity=b.demand_commodity,
                commodities=[b.demand_commodity],
                varieties=getattr(b, "varieties", None),
                min_quantity=b.min_quantity or 10.0,
                max_quantity=b.max_quantity or 500.0,
                accepted_grade=getattr(b, "accepted_grade", None) or "Grade A",
                quality_requirements=b.quality_requirements or "Grade A, Grade B",
                indicative_price_min=getattr(b, "indicative_price_min", None) or (b.offered_price * 0.95 if b.offered_price else 2000.0),
                indicative_price_max=getattr(b, "indicative_price_max", None) or (b.offered_price * 1.05 if b.offered_price else 2500.0),
                offered_price=b.offered_price,
                pickup_available=getattr(b, "pickup_available", True),
                delivery_available=getattr(b, "delivery_available", True),
                payment_terms=getattr(b, "payment_terms", "T+1 (24 hrs via KrishiChakra Escrow)"),
                verification_status=getattr(b, "verification_status", "Demo Verified Buyer"),
                contact_available=getattr(b, "contact_available", True),
                is_demo=getattr(b, "is_demo", True),
            )
        )
    return out


@router.get("/{buyer_id}", response_model=BuyerOut)
def get_buyer(buyer_id: int, db: Session = Depends(get_db)):
    """Returns single buyer profile by ID."""
    b = db.get(Buyer, buyer_id)
    if not b:
        raise HTTPException(status_code=404, detail="Buyer not found")
    return BuyerOut(
        id=b.id,
        name=b.name,
        buyer_type=b.buyer_type,
        district=b.district,
        state=b.state,
        city=getattr(b, "city", None) or b.district or "Pune",
        verified=b.verified,
        payment_reliability=b.payment_reliability or 0.8,
        demand_commodity=b.demand_commodity,
        commodities=[b.demand_commodity],
        varieties=getattr(b, "varieties", None),
        min_quantity=b.min_quantity or 10.0,
        max_quantity=b.max_quantity or 500.0,
        accepted_grade=getattr(b, "accepted_grade", None) or "Grade A",
        quality_requirements=b.quality_requirements or "Grade A, Grade B",
        indicative_price_min=getattr(b, "indicative_price_min", None) or (b.offered_price * 0.95 if b.offered_price else 2000.0),
        indicative_price_max=getattr(b, "indicative_price_max", None) or (b.offered_price * 1.05 if b.offered_price else 2500.0),
        offered_price=b.offered_price,
        pickup_available=getattr(b, "pickup_available", True),
        delivery_available=getattr(b, "delivery_available", True),
        payment_terms=getattr(b, "payment_terms", "T+1 (24 hrs via KrishiChakra Escrow)"),
        verification_status=getattr(b, "verification_status", "Demo Verified Buyer"),
        contact_available=getattr(b, "contact_available", True),
        is_demo=getattr(b, "is_demo", True),
    )


@router.post("", response_model=BuyerCreate)
def create_buyer(data: BuyerCreate, db: Session = Depends(get_db)):
    obj = Buyer(**data.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/matches/{lot_id}", response_model=list[MatchedBuyerOut])
def matches(lot_id: int, db: Session = Depends(get_db)):
    """
    Returns buyers matched to the given produce lot, ranked by transparent match score.
    Score formula: 30% quantity fit + 25% quality fit + 25% verified + 20% payment reliability.
    Full score_breakdown is included per item so the farmer can see why each buyer ranked.
    """
    lot = db.get(ProduceLot, lot_id)
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found")
    return match_buyers(db, lot)


@router.post("/offers", response_model=OfferOut)
def create_offer(data: OfferCreate, db: Session = Depends(get_db)):
    """Creates a buyer offer (Escrow Lock intent) for a produce lot."""
    lot = db.get(ProduceLot, data.lot_id)
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found")
    buyer = db.get(Buyer, data.buyer_id)
    if not buyer:
        raise HTTPException(status_code=404, detail="Buyer not found")
    obj = Offer(**data.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj
