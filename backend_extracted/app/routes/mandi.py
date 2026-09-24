from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ..database import get_db
from ..models import MandiPrice, SyncLog
from ..schemas import MandiPriceOut, SyncResult
from ..services.price_ingestion import sync_government_prices

router = APIRouter(prefix="/mandi", tags=["Mandi"])

@router.get("/prices", response_model=list[MandiPriceOut])
def prices(commodity: str | None = None, state: str | None = None, district: str | None = None,
           market: str | None = None, date_: date | None = None, limit: int = 100, db: Session = Depends(get_db)):
    q = db.query(MandiPrice).filter(MandiPrice.source != "DEMO_SEED")
    if commodity: q = q.filter(MandiPrice.commodity.ilike(f"%{commodity}%"))
    if state: q = q.filter(MandiPrice.state.ilike(f"%{state}%"))
    if district: q = q.filter(MandiPrice.district.ilike(f"%{district}%"))
    if market: q = q.filter(MandiPrice.market.ilike(f"%{market}%"))
    if date_: q = q.filter(MandiPrice.arrival_date == date_)
    return q.order_by(desc(MandiPrice.arrival_date)).limit(min(limit, 500)).all()

@router.get("/latest", response_model=list[MandiPriceOut])
def latest(commodity: str | None = None, state: str | None = None, district: str | None = None,
           market: str | None = None, limit: int = 100, db: Session = Depends(get_db)):
    q = db.query(MandiPrice).filter(MandiPrice.source != "DEMO_SEED")
    if commodity: q = q.filter(MandiPrice.commodity.ilike(f"%{commodity}%"))
    if state: q = q.filter(MandiPrice.state.ilike(f"%{state}%"))
    if district: q = q.filter(MandiPrice.district.ilike(f"%{district}%"))
    if market: q = q.filter(MandiPrice.market.ilike(f"%{market}%"))
    return q.order_by(desc(MandiPrice.arrival_date), desc(MandiPrice.ingested_at)).limit(min(limit, 500)).all()

@router.get("/history", response_model=list[MandiPriceOut])
def history(commodity: str, market: str | None = None, limit: int = 200, db: Session = Depends(get_db)):
    q = db.query(MandiPrice).filter(MandiPrice.source != "DEMO_SEED").filter(MandiPrice.commodity.ilike(f"%{commodity}%"))
    if market: q = q.filter(MandiPrice.market.ilike(f"%{market}%"))
    return q.order_by(desc(MandiPrice.arrival_date)).limit(min(limit, 500)).all()

@router.get("/status")
def status(db: Session = Depends(get_db)):
    last = db.query(SyncLog).order_by(desc(SyncLog.started_at)).first()
    last_success = db.query(SyncLog).filter(SyncLog.status == "success").order_by(desc(SyncLog.finished_at)).first()
    count = db.query(MandiPrice).count()
    gov_count = db.query(MandiPrice).filter(MandiPrice.source != "DEMO_SEED").count()
    latest_date = db.query(MandiPrice.arrival_date).filter(MandiPrice.source != "DEMO_SEED").order_by(desc(MandiPrice.arrival_date)).first()
    if not latest_date:
        latest_date = db.query(MandiPrice.arrival_date).order_by(desc(MandiPrice.arrival_date)).first()
    
    today_date = date.today()
    is_live = bool(
        last
        and last.status == "success"
        and gov_count > 0
        and (
            (latest_date and latest_date[0] == today_date)
            or (last.finished_at and last.finished_at.date() == today_date)
        )
    )
    is_stale = bool(gov_count > 0 and not is_live)
    has_ever_synced = bool(gov_count > 0 and last_success is not None)

    msg = "No government market data is currently available."
    if gov_count > 0:
        if is_stale or (last and last.status == "failed"):
            msg = f"Showing last available government data from {latest_date[0] if latest_date else 'archive'}."
        else:
            msg = "Official live government market data (AGMARKNET / data.gov.in)."

    return {
        "source": last.source if last else "Government Market Data (AGMARKNET / data.gov.in)",
        "last_sync": last.finished_at if last else None,
        "last_sync_status": last.status if last else "never",
        "last_successful_sync": last_success.finished_at if last_success else None,
        "has_ever_synced": has_ever_synced,
        "records": count,
        "gov_records": gov_count,
        "latest_data_date": latest_date[0] if latest_date else None,
        "is_live": is_live,
        "is_stale": is_stale,
        "message": msg,
    }

@router.post("/sync", response_model=SyncResult)
async def sync(db: Session = Depends(get_db)):
    try:
        log = await sync_government_prices(db)
        return SyncResult(
            status=log.status, source=log.source, records_fetched=log.fetched,
            records_inserted=log.inserted, records_updated=log.updated,
            records_skipped=log.skipped, last_updated=log.finished_at
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))

@router.post("/seed-demo")
def seed_demo(db: Session = Depends(get_db)):
    from datetime import date
    if db.query(MandiPrice).count():
        return {"status": "already_seeded", "message": "Database already contains mandi records."}
    demo = [
        MandiPrice(commodity="Tomato", variety="Hybrid", state="Maharashtra", district="Pune", market="Pune", arrival_date=date.today(), min_price=2200, max_price=3100, modal_price=2850, unit="Quintal", source="DEMO_SEED"),
        MandiPrice(commodity="Tomato", variety="Hybrid", state="Maharashtra", district="Nashik", market="Nashik", arrival_date=date.today(), min_price=2400, max_price=3400, modal_price=3120, unit="Quintal", source="DEMO_SEED"),
    ]
    db.add_all(demo); db.commit()
    return {"status": "seeded", "warning": "Development-only data. Not government data."}
