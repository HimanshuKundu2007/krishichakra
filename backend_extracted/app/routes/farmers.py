from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Farmer
from ..schemas import FarmerCreate, FarmerOut

router = APIRouter(prefix="/farmers", tags=["Farmers"])

@router.post("", response_model=FarmerOut)
def create(data: FarmerCreate, db: Session = Depends(get_db)):
    obj = Farmer(**data.model_dump()); db.add(obj); db.commit(); db.refresh(obj); return obj

@router.get("/{farmer_id}", response_model=FarmerOut)
def get(farmer_id: int, db: Session = Depends(get_db)):
    obj = db.get(Farmer, farmer_id)
    if not obj: raise HTTPException(404, "Farmer not found")
    return obj
