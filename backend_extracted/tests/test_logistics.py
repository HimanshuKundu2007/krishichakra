import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import get_db, Base
from app.models import MandiPrice, LogisticsOption, StorageOption

@pytest.fixture()
def engine_and_session(tmp_path):
    db_path = tmp_path / "test_logistics.db"
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
def client(engine_and_session):
    eng, session = engine_and_session
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=eng)

    def override_get_db():
        db = SessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.pop(get_db, None)

def test_get_logistics_options_seeded(client: TestClient):
    """Verify that logistics options endpoint returns seeded baseline options with full fields."""
    response = client.get("/api/logistics/options")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1

    # Verify fields on the baseline option
    first = data[0]
    assert "provider_name" in first
    assert "vehicle_type" in first
    assert "cost_per_quintal" in first
    assert "capacity_quintal" in first
    assert "driver_name" in first
    assert "is_empty_return" in first
    assert "discount_percentage" in first
    assert "available" in first
    assert first["available"] is True

def test_logistics_filter_origin_destination(client: TestClient):
    """Test filtering transport options by origin and destination."""
    response = client.get("/api/logistics/options?origin=Junnar&destination=Vashi")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert "Junnar" in data[0]["origin"]
    assert "Vashi" in data[0]["destination"]

def test_create_and_fetch_logistics_option(client: TestClient):
    """Test creating a custom logistics provider and retrieving it."""
    payload = {
        "provider_name": "Kisan Express Line",
        "vehicle_type": "Mahindra Bolero Maxi Truck",
        "vehicle_number": "MH-14-GH-9090",
        "driver_name": "Ramesh Pawar",
        "driver_phone": "+91 98220 54321",
        "driver_rating": 4.9,
        "verified_trips": 85,
        "origin": "Khed APMC",
        "destination": "Pune Gultekdi Mandi",
        "cost_per_quintal": 140.0,
        "capacity_quintal": 30.0,
        "is_empty_return": True,
        "discount_percentage": 25.0,
        "distance_km": 42.0,
        "transit_duration_minutes": 75,
        "ventilated": True,
        "gps_active": True,
        "departure_time": "04:30 AM",
        "available": True,
    }
    create_res = client.post("/api/logistics/options", json=payload)
    assert create_res.status_code == 200
    created = create_res.json()
    assert created["id"] is not None
    assert created["provider_name"] == "Kisan Express Line"
    assert created["cost_per_quintal"] == 140.0
    assert created["is_empty_return"] is True

    # Check search
    list_res = client.get("/api/logistics/options?destination=Gultekdi")
    assert list_res.status_code == 200
    results = list_res.json()
    assert any(item["provider_name"] == "Kisan Express Line" for item in results)

def test_get_storage_options_seeded(client: TestClient):
    """Verify that storage endpoint returns seeded baseline storage with full fields."""
    response = client.get("/api/logistics/storage")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1

    first = data[0]
    assert "provider_name" in first
    assert "location" in first
    assert "capacity_quintal" in first
    assert "available_capacity_quintal" in first
    assert "cost_per_quintal_day" in first
    assert "is_certified" in first
    assert "enwr_loan_eligible" in first
    assert "loan_advance_pct" in first
    assert first["cost_per_quintal_day"] > 0
    assert first["enwr_loan_eligible"] is True

def test_create_and_filter_storage_option(client: TestClient):
    """Test creating a storage facility and filtering it."""
    payload = {
        "provider_name": "Maharashtra State Agro Warehouse",
        "location": "Lasalgaon Mandi Hub",
        "district": "Nashik",
        "state": "Maharashtra",
        "capacity_quintal": 3000.0,
        "available_capacity_quintal": 1200.0,
        "cost_per_quintal_day": 1.20,
        "distance_km": 4.5,
        "storage_type": "Ventilated Onion Godown",
        "is_certified": True,
        "enwr_loan_eligible": True,
        "loan_advance_pct": 70.0,
        "available": True,
    }
    create_res = client.post("/api/logistics/storage", json=payload)
    assert create_res.status_code == 200
    created = create_res.json()
    assert created["id"] is not None
    assert created["provider_name"] == "Maharashtra State Agro Warehouse"
    assert created["cost_per_quintal_day"] == 1.20

    # Filter by location
    list_res = client.get("/api/logistics/storage?location=Lasalgaon")
    assert list_res.status_code == 200
    results = list_res.json()
    assert len(results) >= 1
    assert results[0]["location"] == "Lasalgaon Mandi Hub"

def test_market_intelligence_uses_logistics_and_storage(client: TestClient, engine_and_session):
    """Test that recommend-sale incorporates live logistics and storage costs when fallback is needed."""
    eng, session = engine_and_session
    # Seed a MandiPrice and logistics/storage in this session
    import datetime
    price = MandiPrice(
        market="Vashi (Mumbai)",
        commodity="Onion",
        modal_price=2400.0,
        arrival_date=datetime.date(2026, 3, 30),
        source="Agmarknet",
    )
    session.add(price)
    session.commit()

    # Trigger logistics options endpoint to ensure seeded
    client.get("/api/logistics/options")
    client.get("/api/logistics/storage")

    rec_res = client.post("/api/intelligence/recommend-sale", json={
        "commodity": "Onion",
        "quantity": 25.0,
        "holding_days": 10,
    })
    assert rec_res.status_code == 200
    data = rec_res.json()
    assert "options" in data
    assert len(data["options"]) > 0
    first_opt = data["options"][0]

    # Transport and storage costs should be calculated (> 0) due to live logistics / storage fallbacks
    assert first_opt["transport_cost"] > 0
    assert first_opt["storage_cost"] > 0
    assert first_opt["estimated_net_realization"] == round(
        first_opt["gross_realization"] - first_opt["transport_cost"] - first_opt["storage_cost"], 2
    )
