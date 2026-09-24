from datetime import datetime
from sqlalchemy.orm import Session
from ..models import MandiPrice, SyncLog
from .gov_price_source import GovernmentPriceSource
from ..config import settings

async def sync_government_prices(db: Session):
    log = SyncLog(source=settings.gov_price_source_name, status="running")
    db.add(log); db.commit(); db.refresh(log)
    source = GovernmentPriceSource()
    try:
        raw_records = await source.fetch_records()
        log.fetched = len(raw_records)
        for raw in raw_records:
            try:
                item = source.normalize(raw)
                if not item["commodity"] or not item["market"] or not item["arrival_date"]:
                    log.skipped += 1
                    continue
                source_id = item["source_record_id"]
                existing = None
                if source_id:
                    existing = db.query(MandiPrice).filter(
                        MandiPrice.source == settings.gov_price_source_name,
                        MandiPrice.source_record_id == source_id
                    ).first()
                else:
                    existing = db.query(MandiPrice).filter(
                        MandiPrice.source == settings.gov_price_source_name,
                        MandiPrice.commodity == item["commodity"],
                        MandiPrice.market == item["market"],
                        MandiPrice.arrival_date == item["arrival_date"]
                    ).first()
                if existing:
                    for k, v in item.items():
                        if k != "raw_record":
                            setattr(existing, k, v)
                    existing.raw_record = item["raw_record"]
                    existing.ingested_at = datetime.utcnow()
                    log.updated += 1
                else:
                    db.add(MandiPrice(
                        **item,
                        source=settings.gov_price_source_name,
                        ingested_at=datetime.utcnow()
                    ))
                    log.inserted += 1
            except Exception:
                log.skipped += 1
        db.commit()
        log.status = "success"
        log.finished_at = datetime.utcnow()
        db.commit()
        return log
    except Exception as exc:
        db.rollback()
        log.status = "failed"
        log.error = str(exc)
        log.finished_at = datetime.utcnow()
        db.add(log)
        db.commit()
        raise
