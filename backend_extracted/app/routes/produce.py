from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import ProduceLot
from ..schemas import ProduceLotCreate, GradeRequest, GradeResponse
from ..services.ai_service import grade_produce

router = APIRouter(prefix="/produce", tags=["Produce"])

@router.post("/lots")
def create_lot(data: ProduceLotCreate, db: Session = Depends(get_db)):
    obj = ProduceLot(**data.model_dump()); db.add(obj); db.commit(); db.refresh(obj); return obj

@router.get("/lots")
def all_lots(db: Session = Depends(get_db)):
    return db.query(ProduceLot).all()

@router.get("/lots/{farmer_id}")
def farmer_lots(farmer_id: int, db: Session = Depends(get_db)):
    return db.query(ProduceLot).filter(ProduceLot.farmer_id == farmer_id).all()

@router.get("/lot/{lot_id}")
def single_lot(lot_id: int, db: Session = Depends(get_db)):
    lot = db.get(ProduceLot, lot_id)
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found")
    return lot

@router.post("/grade", response_model=GradeResponse)
def grade(data: GradeRequest):
    result = grade_produce(data.crop, data.image_path, data.image_bytes_base64)
    # Coerce detected_markers list to typed dicts for schema validation
    return result
