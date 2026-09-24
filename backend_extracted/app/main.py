from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import Base, engine
from . import models
from .config import settings
from .services.scheduler import start_scheduler, stop_scheduler
from .routes import mandi, farmers, produce, buyers, intelligence, chatbot, transactions, logistics, fpo

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    start_scheduler()
    yield
    stop_scheduler()

app = FastAPI(title=settings.app_name, version="2.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

@app.get("/health")
def health():
    return {"status": "ok", "service": settings.app_name, "version": "2.0.0"}

app.include_router(mandi.router, prefix=settings.api_prefix)
app.include_router(farmers.router, prefix=settings.api_prefix)
app.include_router(produce.router, prefix=settings.api_prefix)
app.include_router(buyers.router, prefix=settings.api_prefix)
app.include_router(intelligence.router, prefix=settings.api_prefix)
app.include_router(chatbot.router, prefix=settings.api_prefix)
app.include_router(transactions.router, prefix=settings.api_prefix)
app.include_router(logistics.router, prefix=settings.api_prefix)
app.include_router(fpo.router, prefix=settings.api_prefix)
