import datetime
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import get_db, Base
from app.models import MandiPrice

@pytest.fixture()
def engine_and_session(tmp_path):
    db_path = tmp_path / "test_intel.db"
    url = f"sqlite:///{db_path}"
    eng = create_engine(url, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=eng)
    session = SessionLocal()

    # Seed baseline MandiPrice rows for Onion and Tomato
    p1 = MandiPrice(
        commodity="Onion",
        variety="Nasik Red",
        state="Maharashtra",
        district="Nashik",
        market="Lasalgaon",
        arrival_date=datetime.date(2026, 3, 20),
        min_price=1800.0,
        max_price=2600.0,
        modal_price=2250.0,
        unit="Quintal",
        source="Government Market Data (AGMARKNET / data.gov.in)",
    )
    p2 = MandiPrice(
        commodity="Tomato",
        variety="Hybrid",
        state="Maharashtra",
        district="Pune",
        market="Pune APMC",
        arrival_date=datetime.date(2026, 3, 20),
        min_price=2100.0,
        max_price=3100.0,
        modal_price=2800.0,
        unit="Quintal",
        source="Government Market Data (AGMARKNET / data.gov.in)",
    )
    session.add_all([p1, p2])
    session.commit()

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

def test_recommend_sale_calculations_and_provenance(client: TestClient):
    payload = {
        "commodity": "Onion",
        "quantity_quintal": 20.0,
        "transport_cost_per_quintal": 160.0,
        "storage_cost_per_quintal": 10.0,
        "holding_days": 2,
    }
    res = client.post("/api/intelligence/recommend-sale", json=payload)
    assert res.status_code == 200
    data = res.json()

    assert data["commodity"] == "Onion"
    assert data["quantity"] == 20.0
    assert "not guaranteed future price" in data["disclaimer"].lower()
    assert len(data["options"]) > 0

    for opt in data["options"]:
        # Required fields check
        assert "market" in opt and len(opt["market"]) > 0
        assert "modal_price" in opt and opt["modal_price"] > 0
        assert "quantity" in opt and opt["quantity"] == 20.0
        assert "gross_realization" in opt
        assert "transport_cost" in opt
        assert "storage_cost" in opt
        assert "estimated_net_realization" in opt
        assert "government_data_date" in opt and len(opt["government_data_date"]) > 0
        assert "source" in opt and len(opt["source"]) > 0

        # Calculation verification:
        # Gross Realization = modal_price * quantity
        expected_gross = round(opt["modal_price"] * opt["quantity"], 2)
        assert opt["gross_realization"] == expected_gross

        # Transport Cost = 160 * 20 = 3200
        expected_transport = round(160.0 * 20.0, 2)
        assert opt["transport_cost"] == expected_transport

        # Storage Cost = 10 * 2 * 20 = 400
        expected_storage = round(10.0 * 2 * 20.0, 2)
        assert opt["storage_cost"] == expected_storage

        # Formula: Estimated Net Realization = Gross Realization - Transport Cost - Storage Cost
        expected_net = round(expected_gross - expected_transport - expected_storage, 2)
        assert opt["estimated_net_realization"] == expected_net

        # Provenance: verified government data
        assert opt["source"] == "Government Market Data (AGMARKNET / data.gov.in)"
        assert opt["is_live_gov_data"] is True

def test_recommend_sale_explicit_costs(client: TestClient):
    payload = {
        "commodity": "Tomato",
        "quantity_quintal": 15.0,
        "transport_cost": 2500.0,
        "storage_cost": 300.0,
    }
    res = client.post("/api/intelligence/recommend-sale", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert len(data["options"]) > 0

    first = data["options"][0]
    assert first["transport_cost"] == 2500.0
    assert first["storage_cost"] == 300.0
    assert first["estimated_net_realization"] == round(first["gross_realization"] - 2500.0 - 300.0, 2)
