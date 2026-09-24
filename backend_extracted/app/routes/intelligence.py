from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Farmer, ProduceLot
from ..schemas import RecommendRequest, RecommendResponseOut
from ..services.market_intelligence import recommend_sale

router = APIRouter(prefix="/intelligence", tags=["Market Intelligence"])

@router.post("/recommend-sale", response_model=RecommendResponseOut)
def recommend(data: RecommendRequest, db: Session = Depends(get_db)):
    lot = None
    if data.lot_id is not None:
        lot = db.get(ProduceLot, data.lot_id)
        if not lot and data.farmer_id is not None and not db.get(Farmer, data.farmer_id) and not data.commodity:
            raise HTTPException(404, "Farmer or lot not found")

    return recommend_sale(
        db=db,
        lot=lot,
        transport=data.transport_cost_per_quintal,
        storage=data.storage_cost_per_quintal,
        holding_days=data.holding_days,
        commodity=data.commodity,
        quantity=data.quantity_quintal,
        transport_cost_per_quintal=data.transport_cost_per_quintal,
        storage_cost_per_quintal=data.storage_cost_per_quintal,
        explicit_transport_cost=data.transport_cost,
        explicit_storage_cost=data.storage_cost,
    )
