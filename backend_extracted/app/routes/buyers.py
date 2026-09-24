from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Buyer, ProduceLot, Offer
from ..schemas import BuyerCreate, OfferCreate, OfferOut, MatchedBuyerOut
from ..services.buyer_matching import match_buyers

router = APIRouter(prefix="/buyers", tags=["Buyers"])


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
