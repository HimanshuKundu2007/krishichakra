import datetime
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import get_db, Base
from app.models import Farmer, ProduceLot, MandiPrice, Buyer, LogisticsOption, StorageOption

@pytest.fixture()
def db_session(tmp_path):
    db_path = tmp_path / "test_endpoints_smoke.db"
    url = f"sqlite:///{db_path}"
    eng = create_engine(url, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=eng)
    session = SessionLocal()

    # Seed baseline farmer and lot
    farmer = Farmer(
        name="Ramesh Patil",
        phone="9876543210",
        state="Maharashtra",
        district="Pune",
        village="Otur",
    )
    session.add(farmer)
    session.flush()

    lot = ProduceLot(
        id=9021,
        farmer_id=farmer.id,
        commodity="Onion",
        variety="Nasik Red",
        quantity_quintal=20.0,
        grade="A",
        quality_score=92.5,
        harvest_date=datetime.date.today(),
        status="available",
    )
    mandi = MandiPrice(
        commodity="Onion",
        variety="Nasik Red",
        state="Maharashtra",
        district="Pune",
        market="Pune APMC",
        arrival_date=datetime.date.today(),
        min_price=1800.0,
        max_price=2600.0,
        modal_price=2250.0,
        unit="Quintal",
        source="Government Market Data (AGMARKNET / data.gov.in)",
    )
    buyer = Buyer(
        name="MahaFresh Procurement",
        buyer_type="Retail Chain Aggregator",
        verified=True,
        demand_commodity="Onion",
        min_quantity=5.0,
        max_quantity=100.0,
        offered_price=2450.0,
        payment_reliability=0.95,
    )
    session.add_all([lot, mandi, buyer])
    session.commit()

    try:
        yield eng, session
    finally:
        session.close()
        Base.metadata.drop_all(bind=eng)
        eng.dispose()

@pytest.fixture()
def client(db_session):
    eng, session = db_session
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=eng)

    def override_get_db():
        db = SessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c, session
    app.dependency_overrides.clear()

def test_12_required_backend_endpoints(client):
    c, session = client

    # 1. /health
    r1 = c.get("/health")
    assert r1.status_code == 200
    assert r1.json()["status"] == "ok"

    # 2. /api/mandi/status
    r2 = c.get("/api/mandi/status")
    assert r2.status_code == 200
    assert "has_ever_synced" in r2.json()
    assert "is_live" in r2.json()

    # 3. /api/mandi/latest
    r3 = c.get("/api/mandi/latest?commodity=Onion")
    assert r3.status_code == 200
    assert isinstance(r3.json(), list)

    # 4. /api/mandi/prices
    r4 = c.get("/api/mandi/prices?commodity=Onion")
    assert r4.status_code == 200
    prices = r4.json()
    assert len(prices) >= 1
    assert prices[0]["commodity"] == "Onion"

    # 5. /api/mandi/history
    r5 = c.get("/api/mandi/history?commodity=Onion&market=Pune APMC")
    assert r5.status_code == 200
    res5 = r5.json()
    assert isinstance(res5, (dict, list))
    records5 = res5["records"] if isinstance(res5, dict) else res5
    assert len(records5) >= 1

    # 6. /api/intelligence/recommend-sale
    r6 = c.post("/api/intelligence/recommend-sale", json={
        "commodity": "Onion",
        "variety": "Nasik Red",
        "quantity_quintal": 20.0,
        "origin_district": "Pune",
        "storage_days": 0,
        "max_distance_km": 300,
    })
    assert r6.status_code == 200
    intel = r6.json()
    assert "options" in intel
    assert len(intel["options"]) > 0

    # 7. /api/buyers/matches/{lot_id}
    r7 = c.get("/api/buyers/matches/9021")
    assert r7.status_code == 200
    matches = r7.json()
    assert len(matches) >= 1
    assert matches[0]["buyer"] == "MahaFresh Procurement"
    assert "match_score" in matches[0]

    # 8. /api/produce/lots
    r8 = c.get("/api/produce/lots")
    assert r8.status_code == 200
    lots = r8.json()
    assert len(lots) >= 1
    assert lots[0]["commodity"] == "Onion"

    # 9. /api/transactions
    buyer = session.query(Buyer).first()
    r9 = c.post("/api/transactions", json={
        "lot_id": 9021,
        "buyer_id": buyer.id,
        "agreed_price": 2450.0,
        "quantity_quintal": 20.0,
        "seller_name": "Ramesh Patil",
        "transport_cost": 2400.0,
        "handling_cost": 500.0,
        "market_fee": 300.0,
    })
    assert r9.status_code == 200
    txn = r9.json()
    assert txn["lot_id"] == 9021
    assert "payment_status" in txn

    # 10. /api/logistics/options
    r10 = c.get("/api/logistics/options")
    assert r10.status_code == 200
    assert len(r10.json()) >= 1

    # 11. /api/logistics/storage
    r11 = c.get("/api/logistics/storage")
    assert r11.status_code == 200
    assert len(r11.json()) >= 1

    # 12. /api/chatbot/chat
    r12 = c.post("/api/chatbot/chat", json={
        "message": "What is the price of Onion today?",
        "language": "en",
    })
    assert r12.status_code == 200
    chat = r12.json()
    assert "reply" in chat
    assert chat["is_llm"] is False
    assert chat["mode"] == "rule_based_prototype"
