import datetime
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import get_db, Base
from app.models import MandiPrice, SyncLog

@pytest.fixture()
def db_session(tmp_path):
    db_path = tmp_path / "test_mandi_reliability.db"
    url = f"sqlite:///{db_path}"
    eng = create_engine(url, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=eng)
    session = SessionLocal()

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

def test_no_government_data_status(client):
    """
    Requirement:
    If no government data has ever been synchronized:
    show "No government market data is currently available."
    Do not substitute demo prices.
    """
    c, session = client

    # Even if demo seed prices exist in DB, they MUST NOT count as government data
    demo_p = MandiPrice(
        commodity="Onion",
        variety="Local",
        state="Maharashtra",
        district="Nashik",
        market="Lasalgaon",
        arrival_date=datetime.date(2026, 3, 20),
        min_price=1000.0,
        max_price=2000.0,
        modal_price=1500.0,
        unit="Quintal",
        source="DEMO_SEED",
    )
    session.add(demo_p)
    session.commit()

    # 1. Verify /status endpoint
    res = c.get("/api/mandi/status")
    assert res.status_code == 200
    data = res.json()
    assert data["has_ever_synced"] is False
    assert data["gov_records"] == 0
    assert "No government market data is currently available." in data["message"]

    # 2. Verify /prices endpoint excludes demo data
    res_prices = c.get("/api/mandi/prices?commodity=Onion")
    assert res_prices.status_code == 200
    prices = res_prices.json()
    assert len(prices) == 0

def test_official_government_data_status_and_filtering(client):
    """
    Requirement:
    Show the latest successfully synchronized government data and clearly indicate its date.
    """
    c, session = client

    # Seed 1 demo seed and 1 real government data record
    today = datetime.date.today()
    demo_p = MandiPrice(
        commodity="Tomato",
        variety="Local",
        state="Maharashtra",
        district="Pune",
        market="Pune APMC",
        arrival_date=today - datetime.timedelta(days=1),
        min_price=500.0,
        max_price=800.0,
        modal_price=650.0,
        unit="Quintal",
        source="DEMO_SEED",
    )
    gov_p = MandiPrice(
        commodity="Tomato",
        variety="Hybrid",
        state="Maharashtra",
        district="Pune",
        market="Pune APMC",
        arrival_date=today,
        min_price=2200.0,
        max_price=3100.0,
        modal_price=2800.0,
        unit="Quintal",
        source="Government Market Data (AGMARKNET / data.gov.in)",
    )
    sync_success = SyncLog(
        source="data.gov.in / Agmarknet API",
        status="success",
        fetched=1,
        started_at=datetime.datetime.now() - datetime.timedelta(minutes=5),
        finished_at=datetime.datetime.now(),
    )
    session.add_all([demo_p, gov_p, sync_success])
    session.commit()

    # 1. Verify status endpoint
    res = c.get("/api/mandi/status")
    assert res.status_code == 200
    data = res.json()
    assert data["has_ever_synced"] is True
    assert data["gov_records"] == 1
    assert data["latest_data_date"] == today.isoformat()
    assert data["is_live"] is True
    assert data["is_stale"] is False

    # 2. Verify prices endpoint returns ONLY government record
    res_prices = c.get("/api/mandi/prices?commodity=Tomato")
    assert res_prices.status_code == 200
    prices = res_prices.json()
    assert len(prices) == 1
    assert prices[0]["modal_price"] == 2800.0
    assert prices[0]["source"] == "Government Market Data (AGMARKNET / data.gov.in)"

def test_stale_government_data_handling(client):
    """
    Requirement:
    If government mandi source fails:
    DO NOT show fake prices.
    Show the latest successfully synchronized government data and clearly indicate its date.
    """
    c, session = client

    past_date = datetime.date.today() - datetime.timedelta(days=3)
    gov_p = MandiPrice(
        commodity="Onion",
        variety="Nasik Red",
        state="Maharashtra",
        district="Nashik",
        market="Lasalgaon",
        arrival_date=past_date,
        min_price=1800.0,
        max_price=2400.0,
        modal_price=2100.0,
        unit="Quintal",
        source="Government Market Data (AGMARKNET / data.gov.in)",
    )
    sync_success = SyncLog(
        source="data.gov.in / Agmarknet API",
        status="success",
        fetched=1,
        started_at=datetime.datetime.now() - datetime.timedelta(days=3, hours=1),
        finished_at=datetime.datetime.now() - datetime.timedelta(days=3),
    )
    # Then subsequent sync fails (e.g., API timeout or server down)
    sync_failed = SyncLog(
        source="data.gov.in / Agmarknet API",
        status="failed",
        fetched=0,
        error="Gov API timeout 504 Gateway Timeout",
        started_at=datetime.datetime.now() - datetime.timedelta(hours=2),
        finished_at=datetime.datetime.now() - datetime.timedelta(hours=2),
    )
    session.add_all([gov_p, sync_success, sync_failed])
    session.commit()

    res = c.get("/api/mandi/status")
    assert res.status_code == 200
    data = res.json()
    assert data["has_ever_synced"] is True
    assert data["is_stale"] is True
    assert data["latest_data_date"] == past_date.isoformat()
    assert "Showing last available government data" in data["message"]
    assert past_date.isoformat() in data["message"]

    # Verify prices still serve real past_date data and NEVER fake prices
    res_prices = c.get("/api/mandi/prices?commodity=Onion")
    assert res_prices.status_code == 200
    prices = res_prices.json()
    assert len(prices) == 1
    assert prices[0]["arrival_date"] == past_date.isoformat()
    assert prices[0]["modal_price"] == 2100.0

def test_commodity_catalogue_and_pulse(client):
    """
    Verify:
    1. /api/mandi/commodities returns normalized names with icons and statistics.
    2. /api/mandi/pulse returns deduplicated normalized crops with latest prices.
    3. Querying /api/mandi/prices with normalized names (e.g. 'Soybean', 'Paddy', 'Chilli')
       correctly matches government aliases ('Soyabean', 'Paddy(Common)', 'Green Chilli').
    """
    c, session = client
    today = datetime.date.today()

    records = [
        MandiPrice(commodity="Soyabean", variety="Yellow", state="Maharashtra", district="Latur", market="APMC Latur", arrival_date=today, min_price=4100, max_price=4600, modal_price=4350, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Paddy(Common)", variety="Common", state="Maharashtra", district="Gondia", market="APMC Gondia", arrival_date=today, min_price=2200, max_price=2500, modal_price=2350, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Green Chilli", variety="G4", state="Maharashtra", district="Nandurbar", market="APMC Nandurbar", arrival_date=today, min_price=3000, max_price=4000, modal_price=3500, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Chilli Red", variety="Red", state="Maharashtra", district="Nagpur", market="APMC Nagpur", arrival_date=today, min_price=8000, max_price=12000, modal_price=10500, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Tomato", variety="Hybrid", state="Maharashtra", district="Pune", market="APMC Pune", arrival_date=today, min_price=1800, max_price=2600, modal_price=2200, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Onion", variety="Red", state="Maharashtra", district="Nashik", market="APMC Lasalgaon", arrival_date=today, min_price=1600, max_price=2400, modal_price=2000, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Onion Green", variety="Local", state="Maharashtra", district="Pune", market="APMC Junnar", arrival_date=today, min_price=1200, max_price=1800, modal_price=1500, unit="Quintal", source="AGMARKNET"),
        MandiPrice(commodity="Garlic", variety="Desi", state="Gujarat", district="Rajkot", market="APMC Rajkot", arrival_date=today, min_price=7000, max_price=11000, modal_price=9500, unit="Quintal", source="AGMARKNET"),
    ]
    session.add_all(records)
    session.commit()

    # 1. Test Catalogue
    res = c.get("/api/mandi/commodities")
    assert res.status_code == 200
    cat = res.json()
    norm_names = [item["normalized_name"] for item in cat]
    assert "Soybean" in norm_names
    assert "Paddy" in norm_names
    assert "Chilli" in norm_names
    assert "Onion" in norm_names
    assert "Garlic" in norm_names

    # Test Catalogue Maharashtra Filter (Garlic is Gujarat-only in this test session)
    res_mh = c.get("/api/mandi/commodities?state=Maharashtra")
    assert res_mh.status_code == 200
    mh_norm_names = [item["normalized_name"] for item in res_mh.json()]
    assert "Soybean" in mh_norm_names
    assert "Garlic" not in mh_norm_names

    # 2. Test Live Mandi Pulse (deduplicated by normalized commodity)
    res_pulse = c.get("/api/mandi/pulse")
    assert res_pulse.status_code == 200
    pulse_items = res_pulse.json()
    pulse_norm_names = [p["normalized_name"] for p in pulse_items]
    # Ensure no duplicates: Onion should appear once, Chilli once, Soybean once
    assert len(pulse_norm_names) == len(set(pulse_norm_names))
    assert "Onion" in pulse_norm_names
    assert "Soybean" in pulse_norm_names
    assert "Chilli" in pulse_norm_names
    # Each item has commodity_name, normalized_name, price_unit
    for p in pulse_items:
        assert p["commodity_name"] is not None
        assert p["normalized_name"] is not None
        assert p["price_unit"] is not None

    # 3. Test cross-alias filtering on /prices and /history
    # Querying "Soybean" matches "Soyabean"
    res_sb = c.get("/api/mandi/prices?commodity=Soybean")
    assert res_sb.status_code == 200
    assert len(res_sb.json()) == 1
    assert res_sb.json()[0]["commodity"] == "Soyabean"
    assert res_sb.json()[0]["normalized_name"] == "Soybean"

    # Querying "Paddy" matches "Paddy(Common)"
    res_paddy = c.get("/api/mandi/prices?commodity=Paddy")
    assert res_paddy.status_code == 200
    assert len(res_paddy.json()) == 1
    assert "Paddy" in res_paddy.json()[0]["commodity"]

    # Querying "Chilli" matches both "Green Chilli" and "Chilli Red"
    res_chilli = c.get("/api/mandi/prices?commodity=Chilli")
    assert res_chilli.status_code == 200
    assert len(res_chilli.json()) == 2
