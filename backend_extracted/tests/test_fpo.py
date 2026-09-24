"""
Tests for FPO aggregation functionality and backend endpoints.

Covers:
  - FPO creation
  - FPO verification status
  - Farmer membership enrolment
  - Member directory listing
  - Aggregated produce batch workflow & pure backend aggregation logic
  - Gatekeeper quality routing (Grade A staged vs Grade B diverted to APMC)
  - Master batch seal & dispatch with e-Way bill manifest
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base, get_db
from app.main import app
from app.models import FPO, Farmer


@pytest.fixture
def test_db(tmp_path):
    db_file = tmp_path / "test_fpo.db"
    engine = create_engine(
        f"sqlite:///{db_file}",
        connect_args={"check_same_thread": False}
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        session = TestingSessionLocal()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestingSessionLocal()
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client(test_db):
    return TestClient(app)


def test_create_fpo(client):
    res = client.post("/api/fpo", json={
        "name": "Sahyadri Farmers Producer Co.",
        "district": "Nashik",
        "state": "Maharashtra",
        "registration_number": "Reg #MH-NSK-2024-01",
        "hub_name": "Sahyadri Nashik Hub",
        "verified": False
    })
    assert res.status_code == 200
    data = res.json()
    assert data["name"] == "Sahyadri Farmers Producer Co."
    assert data["district"] == "Nashik"
    assert data["registration_number"] == "Reg #MH-NSK-2024-01"
    assert data["verified"] is False
    assert data["id"] > 0


def test_fpo_verification_status(client):
    create_res = client.post("/api/fpo", json={
        "name": "Khed Agro FPC",
        "district": "Pune",
        "state": "Maharashtra",
        "registration_number": "Reg #MH-KHD-005"
    })
    fpo_id = create_res.json()["id"]

    # Check unverified initial status
    get_res = client.get(f"/api/fpo/{fpo_id}")
    assert get_res.status_code == 200
    assert get_res.json()["verified"] is False

    # Verify FPO
    patch_res = client.patch(f"/api/fpo/{fpo_id}/verify?verified=true")
    assert patch_res.status_code == 200
    assert patch_res.json()["verified"] is True

    # Re-check via GET
    get_res2 = client.get(f"/api/fpo/{fpo_id}")
    assert get_res2.json()["verified"] is True


def test_farmer_membership_and_listing(client, test_db):
    # Setup FPO & Farmer
    fpo_res = client.post("/api/fpo", json={
        "name": "Junnar FPC",
        "district": "Pune",
        "state": "Maharashtra"
    })
    fpo_id = fpo_res.json()["id"]

    farmer = Farmer(
        name="Santosh Jadhav",
        phone="9876543210",
        village="Narayangaon",
        district="Pune",
        state="Maharashtra"
    )
    test_db.add(farmer)
    test_db.commit()
    test_db.refresh(farmer)

    # Add member
    mem_res = client.post("/api/fpo/members", json={
        "fpo_id": fpo_id,
        "farmer_id": farmer.id,
        "member_code": "Member ID #FPO-099",
        "role": "core_member"
    })
    assert mem_res.status_code == 200
    mem_data = mem_res.json()
    assert mem_data["farmer_name"] == "Santosh Jadhav"
    assert mem_data["farmer_phone"] == "9876543210"
    assert mem_data["member_code"] == "Member ID #FPO-099"

    # List members
    list_res = client.get(f"/api/fpo/{fpo_id}/members")
    assert list_res.status_code == 200
    members = list_res.json()
    assert len(members) == 1
    assert members[0]["farmer_village"] == "Narayangaon"


def test_batch_creation_and_aggregation_math(client):
    fpo_res = client.post("/api/fpo", json={
        "name": "Baramati FPC",
        "district": "Pune",
        "state": "Maharashtra",
        "verified": True
    })
    fpo_id = fpo_res.json()["id"]

    # Create batch
    batch_res = client.post("/api/fpo/batches", json={
        "fpo_id": fpo_id,
        "batch_code": "#ON-BATCH-501",
        "commodity": "Nashik Red Onion",
        "target_grade": "Grade A",
        "target_quantity_quintal": 200.0,
        "buyer_name": "Sahyadri Processing",
        "buyer_contract_price": 2650.0,
        "benchmark_mandi_price": 2470.0
    })
    assert batch_res.status_code == 200
    b_data = batch_res.json()
    assert b_data["target_quantity_quintal"] == 200.0
    assert b_data["staged_quantity_quintal"] == 0.0
    assert b_data["fill_percentage"] == 0.0
    assert b_data["institutional_premium_per_q"] == 180.0
    assert b_data["remaining_crates"] == 400


def test_gatekeeper_quality_routing(client):
    fpo_res = client.post("/api/fpo", json={"name": "Otur FPC", "district": "Pune"})
    fpo_id = fpo_res.json()["id"]

    batch_res = client.post("/api/fpo/batches", json={
        "fpo_id": fpo_id,
        "batch_code": "#ON-BATCH-777",
        "commodity": "Nashik Red Onion",
        "target_grade": "Grade A",
        "target_quantity_quintal": 100.0,
        "buyer_contract_price": 2600.0,
        "benchmark_mandi_price": 2450.0
    })
    batch_id = batch_res.json()["id"]

    # Add Grade A lot -> Staged
    res1 = client.post(f"/api/fpo/batches/{batch_id}/lots", json={
        "farmer_name": "Ramesh Patil",
        "member_code": "Member ID #FPO-084",
        "quantity_quintal": 20.0,
        "grade": "Grade A",
        "bulb_spec": "52–58mm bulb",
        "moisture_pct": 11.8,
        "crates_count": 40
    })
    assert res1.status_code == 200
    d1 = res1.json()
    assert d1["staged_quantity_quintal"] == 20.0
    assert d1["diverted_quantity_quintal"] == 0.0
    assert d1["fill_percentage"] == 20.0
    assert len(d1["lots"]) == 1
    assert d1["lots"][0]["status"] == "staged"

    # Add Grade B lot -> Gatekeeper auto-diverts to APMC!
    res2 = client.post(f"/api/fpo/batches/{batch_id}/lots", json={
        "farmer_name": "Vilas Shinde",
        "member_code": "Member ID #FPO-203",
        "quantity_quintal": 10.0,
        "grade": "Grade B",
        "bulb_spec": "<45mm Uniformity"
    })
    assert res2.status_code == 200
    d2 = res2.json()
    # Staged quantity remains 20.0 to protect Grade A purity!
    assert d2["staged_quantity_quintal"] == 20.0
    assert d2["diverted_quantity_quintal"] == 10.0
    assert d2["fill_percentage"] == 20.0
    assert len(d2["lots"]) == 2

    # Check diverted lot
    diverted_lot = [l for l in d2["lots"] if l["farmer_name"] == "Vilas Shinde"][0]
    assert diverted_lot["status"] == "diverted"
    assert "APMC" in diverted_lot["diversion_route"]
    assert "safeguard FPO grade purity bonus" in diverted_lot["gatekeeper_note"]

    # Verify Financial Ledger Realization
    # commercial_value = 20 * 2600 = 52,000
    # fpo_margin = 52,000 * 0.02 = 1,040
    # freight = 20 * 95.68 = 1,913.6
    # farmer_payout = 52000 - 1040 - 1913.6 = 49,046.4
    ledger = d2["ledger"]
    assert ledger["commercial_value"] == 52000.0
    assert ledger["fpo_margin"] == 1040.0
    assert ledger["freight_surcharge"] == 1913.6
    assert ledger["farmer_payout"] == 49046.4


def test_batch_dispatch_and_eway_bill(client):
    fpo_res = client.post("/api/fpo", json={"name": "Dindori FPC", "district": "Nashik"})
    batch_res = client.post("/api/fpo/batches", json={
        "fpo_id": fpo_res.json()["id"],
        "batch_code": "#ON-BATCH-DISPATCH",
        "commodity": "Nashik Red Onion",
        "target_quantity_quintal": 50.0
    })
    batch_id = batch_res.json()["id"]

    # Dispatch
    dispatch_res = client.post(f"/api/fpo/batches/{batch_id}/dispatch")
    assert dispatch_res.status_code == 200
    data = dispatch_res.json()
    assert data["status"] == "dispatched"
    assert data["eway_bill_number"] is not None
    assert "EWB" in data["eway_bill_number"]
