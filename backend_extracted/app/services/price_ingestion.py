from datetime import datetime, timezone
import logging
from sqlalchemy.orm import Session
from ..models import MandiPrice, SyncLog
from .gov_price_source import GovernmentPriceSource, MaharashtraPriceSource, MsambPriceSource
from ..config import settings

logger = logging.getLogger(__name__)

async def sync_government_prices(db: Session) -> SyncLog:
    """
    Ingests and synchronizes official mandi market data from:
    1. National Government Price Source (data.gov.in / AGMARKNET)
    2. Dedicated Maharashtra APMC Source (OGD / AGMARKNET Maharashtra)
    3. Maharashtra State Agricultural Marketing Board (MSAMB / APMC Maharashtra)
    Normalizes, deduplicates, and preserves all existing national and Maharashtra markets.
    """
    log = SyncLog(source="Government Market Data (AGMARKNET & MSAMB / National & Maharashtra)", status="running")
    db.add(log)
    db.commit()
    db.refresh(log)

    national_source = GovernmentPriceSource()
    mh_source = MaharashtraPriceSource()
    msamb_source = MsambPriceSource()

    total_fetched = 0
    total_inserted = 0
    total_updated = 0
    total_skipped = 0

    sources_to_run = [
        ("National Mandi Data", national_source, lambda s: s.fetch_records(max_records=100)),
        ("Maharashtra APMC Data", mh_source, lambda s: s.fetch_maharashtra_records(max_records=250)),
        ("Maharashtra MSAMB Data", msamb_source, lambda s: s.fetch_msamb_records(max_records=150)),
    ]

    for label, src, fetch_fn in sources_to_run:
        try:
            logger.info(f"Synchronizing {label}...")
            raw_records = await fetch_fn(src)
            total_fetched += len(raw_records)

            for raw in raw_records:
                try:
                    item = src.normalize(raw)
                    if not item["commodity"] or not item["market"] or not item["arrival_date"]:
                        total_skipped += 1
                        continue

                    # Deduplication check across market, commodity, variety, arrival_date, and state
                    query = db.query(MandiPrice).filter(
                        MandiPrice.commodity.ilike(item["commodity"].strip()),
                        MandiPrice.market.ilike(item["market"].strip()),
                        MandiPrice.arrival_date == item["arrival_date"],
                    )
                    if item.get("variety"):
                        query = query.filter(MandiPrice.variety.ilike(item["variety"].strip()))
                    if item.get("state"):
                        query = query.filter(MandiPrice.state.ilike(item["state"].strip()))

                    existing = query.first()

                    now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
                    if existing:
                        for k, v in item.items():
                            if k != "raw_record":
                                setattr(existing, k, v)
                        existing.raw_record = item["raw_record"]
                        existing.ingested_at = now_utc
                        total_updated += 1
                    else:
                        db.add(MandiPrice(
                            **item,
                            source=src.source_name,
                            ingested_at=now_utc
                        ))
                        total_inserted += 1
                except Exception as rec_err:
                    logger.warning(f"Error processing {label} record: {rec_err}")
                    total_skipped += 1

            db.commit()
        except Exception as src_err:
            logger.error(f"Failed to fetch {label}: {src_err}")
            # Do NOT wipe existing records on failure; log and continue to preserve available data

    now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
    log.fetched = total_fetched
    log.inserted = total_inserted
    log.updated = total_updated
    log.skipped = total_skipped
    log.status = "success" if (total_inserted > 0 or total_updated > 0 or total_fetched > 0) else "partial"
    log.finished_at = now_utc
    db.commit()
    return log
