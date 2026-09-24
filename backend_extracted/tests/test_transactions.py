"""
Unit tests for the Transaction & Settlement workflow.
Covers:
- POST /api/transactions
- GET /api/transactions/{transaction_id}
- PATCH /api/transactions/{transaction_id}/payment (pending, paid, failed, disputed)
- Invalid payment status rejection (HTTP 400)
- POST /api/transactions/disputes (with automatic transaction payment_status -> disputed)
- Auto-seeding of Stitch baseline consignment #9021
- Financial audit ledger calculations
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

from app.main import app
from app.database import get_db, Base
from app.models import Farmer, ProduceLot, Buyer, Transaction, Dispute


@pytest.fixture()
def engine_and_session(tmp_path):
    db_path = tmp_path / "test_transactions.db"
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
def client_and_db(engine_and_session):
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
        yield c, session
    app.dependency_overrides.pop(get_db, None)


def _seed_lot_and_buyer(db: Session):
    farmer = Farmer(
        name="Test Farmer",
        phone="9876543210",
        village="Test Village",
        district="Pune",
        state="Maharashtra",
    )
    db.add(farmer)
    db.commit()

    lot = ProduceLot(
        farmer_id=farmer.id,
        commodity="Tomato",
        quantity_quintal=50.0,
        grade="Grade A",
        quality_score=90.0,
    )
    db.add(lot)

    buyer = Buyer(
        name="Reliable Retail Corp",
        buyer_type="Retailer",
        district="Pune",
        state="Maharashtra",
        verified=True,
        payment_reliability=0.95,
        demand_commodity="Tomato",
        offered_price=2500.0,
    )
    db.add(buyer)
    db.commit()
    return lot, buyer


def test_create_transaction(client_and_db):
    client, db = client_and_db
    lot, buyer = _seed_lot_and_buyer(db)

    payload = {
        "lot_id": lot.id,
        "buyer_id": buyer.id,
        "agreed_price": 2500.0,
        "quantity_quintal": 50.0,
        "seller_name": "Kisan FPO",
    }
    res = client.post("/api/transactions", json=payload)
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["lot_id"] == lot.id
    assert data["buyer_id"] == buyer.id
    assert data["agreed_price"] == 2500.0
    assert data["quantity_quintal"] == 50.0
    assert data["payment_status"] == "pending"
    assert data["status"] == "escrow_locked"
    assert data["total_amount"] == 125000.0
    assert data["ledger"]["gross_value"] == 125000.0
    assert data["buyer_name"] == "Reliable Retail Corp"
    assert len(data["milestones"]) == 3


def test_create_transaction_validation_errors(client_and_db):
    client, db = client_and_db
    lot, buyer = _seed_lot_and_buyer(db)

    # Invalid price <= 0
    res = client.post("/api/transactions", json={
        "lot_id": lot.id,
        "buyer_id": buyer.id,
        "agreed_price": -100.0,
        "quantity_quintal": 20.0,
    })
    assert res.status_code == 400

    # Invalid qty <= 0
    res = client.post("/api/transactions", json={
        "lot_id": lot.id,
        "buyer_id": buyer.id,
        "agreed_price": 2000.0,
        "quantity_quintal": 0.0,
    })
    assert res.status_code == 400


def test_get_baseline_seeded_consignment(client_and_db):
    client, db = client_and_db
    res = client.get("/api/transactions/9021")
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["id"] == 9021
    assert data["batch_code"] == "LOT-9021"
    assert data["agreed_price"] == 2400.0
    assert data["payment_status"] == "paid"
    assert data["utr_number"] == "SBIN0049281726"
    assert data["ledger"]["net_disbursed"] == 456700.0
    assert len(data["isolated_crates"]) == 2
    assert len(data["member_splits"]) == 3


def test_patch_payment_status_valid_transitions(client_and_db):
    client, db = client_and_db
    lot, buyer = _seed_lot_and_buyer(db)

    # Create transaction
    create_res = client.post("/api/transactions", json={
        "lot_id": lot.id,
        "buyer_id": buyer.id,
        "agreed_price": 2000.0,
        "quantity_quintal": 10.0,
    })
    assert create_res.status_code == 200
    txn_id = create_res.json()["id"]

    # Transition to paid
    res_paid = client.patch(f"/api/transactions/{txn_id}/payment?status=paid")
    assert res_paid.status_code == 200
    data_paid = res_paid.json()
    assert data_paid["payment_status"] == "paid"
    assert data_paid["status"] == "settled"
    assert data_paid["utr_number"] is not None

    # Transition to failed
    res_failed = client.patch(f"/api/transactions/{txn_id}/payment?status=failed")
    assert res_failed.status_code == 200
    data_failed = res_failed.json()
    assert data_failed["payment_status"] == "failed"
    assert data_failed["status"] == "payment_failed"

    # Transition to disputed
    res_disputed = client.patch(f"/api/transactions/{txn_id}/payment?status=disputed")
    assert res_disputed.status_code == 200
    data_disputed = res_disputed.json()
    assert data_disputed["payment_status"] == "disputed"
    assert data_disputed["status"] == "disputed"

    # Transition back to pending
    res_pending = client.patch(f"/api/transactions/{txn_id}/payment?status=pending")
    assert res_pending.status_code == 200
    data_pending = res_pending.json()
    assert data_pending["payment_status"] == "pending"
    assert data_pending["status"] == "escrow_locked"


def test_patch_payment_status_invalid_raises_400(client_and_db):
    client, db = client_and_db
    res = client.patch("/api/transactions/9021/payment?status=completed_fake")
    assert res.status_code == 400
    assert "Invalid payment status" in res.json()["detail"]


def test_post_dispute_updates_transaction(client_and_db):
    client, db = client_and_db
    lot, buyer = _seed_lot_and_buyer(db)

    create_res = client.post("/api/transactions", json={
        "lot_id": lot.id,
        "buyer_id": buyer.id,
        "agreed_price": 2400.0,
        "quantity_quintal": 20.0,
    })
    txn_id = create_res.json()["id"]

    dispute_payload = {
        "transaction_id": txn_id,
        "raised_by": "Buyer QC Inspector",
        "reason": "Bruised crates detected during dock unloading",
        "crate_ids": "QR-38, QR-39",
        "dispute_type": "quality_bruising",
    }
    disp_res = client.post("/api/transactions/disputes", json=dispute_payload)
    assert disp_res.status_code == 200, disp_res.text
    disp_data = disp_res.json()
    assert disp_data["transaction_id"] == txn_id
    assert disp_data["status"] == "open"

    # Verify transaction payment_status is updated to 'disputed'
    txn_res = client.get(f"/api/transactions/{txn_id}")
    assert txn_res.status_code == 200
    txn_data = txn_res.json()
    assert txn_data["payment_status"] == "disputed"
    assert txn_data["flagged_crates_count"] == 2
    assert len(txn_data["disputes"]) == 1
    assert txn_data["disputes"][0]["reason"] == "Bruised crates detected during dock unloading"
