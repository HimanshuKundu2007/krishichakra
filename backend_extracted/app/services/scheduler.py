from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from .price_ingestion import sync_government_prices
from ..database import SessionLocal
from ..config import settings

scheduler = AsyncIOScheduler()

async def scheduled_sync():
    db = SessionLocal()
    try:
        await sync_government_prices(db)
    except Exception:
        pass
    finally:
        db.close()

def start_scheduler():
    scheduler.add_job(
        scheduled_sync,
        CronTrigger(hour=settings.price_sync_hour, minute=settings.price_sync_minute, timezone=settings.price_sync_timezone),
        id="daily-government-price-sync",
        replace_existing=True,
    )
    scheduler.start()

def stop_scheduler():
    if scheduler.running:
        scheduler.shutdown(wait=False)
