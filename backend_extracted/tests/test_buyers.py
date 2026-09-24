"""
Backend tests for the buyer matching workflow.

Tests:
  - GET /api/buyers/matches/{lot_id} returns correct fields and transparent scoring
  - match_score is within 0–100
  - score_breakdown components are present and individually in range
  - Reason string is non-empty and mentions the formula
  - POST /api/buyers/offers creates an offer and returns OfferOut fields
  - 404 for unknown lot_id
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

from app.main import app
from app.database import get_db, Base
from app.models import Farmer, ProduceLot, Buyer

# ─── Per-test in-memory SQLite engine ─────────────────────────────────────────
# Use a named shared-cache URI so that create_all, the test session, and the
# FastAPI dependency all see the same in-memory database within one test run.
@pytest.fixture()
def engine_and_session(tmp_path):
    """
    Each test gets a fresh SQLite file in tmp_path.
    This avoids the shared-cache pitfalls with multiple SQLAlchemy sessions
    pointing at the same in-memory :memory: database.
    """
    db_path = tmp_path / "test_buyers.db"
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


# ─── Helpers ───────────────────────────────────────────────────────────────────

def _seed_farmer(db: Session):
    f = Farmer(name="Test Farmer", phone="9000000001")
    db.add(f)
    db.commit()
    db.refresh(f)
    return f


def _seed_lot(db: Session, farmer_id: int, commodity: str = "Tomato", quantity: float = 25.0):
    lot = ProduceLot(
        farmer_id=farmer_id,
        commodity=commodity,
        quantity_quintal=quantity,
        grade="A",
    )
    db.add(lot)
    db.commit()
    db.refresh(lot)
    return lot


def _seed_buyer(
    db: Session,
    commodity: str = "Tomato",
    verified: bool = True,
    min_q: float = 10,
    max_q: float = 100,
    payment: float = 0.92,
    name: str = "FreshMart Wholesale",
):
    b = Buyer(
        name=name,
        buyer_type="Institutional Buyer",
        verified=verified,
        payment_reliability=payment,
        demand_commodity=commodity,
        min_quantity=min_q,
        max_quantity=max_q,
        offered_price=2800.0,
    )
    db.add(b)
    db.commit()
    db.refresh(b)
    return b


# ─── Tests ─────────────────────────────────────────────────────────────────────

def test_matches_returns_list_of_buyers(client_and_db):
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)
    _seed_buyer(db)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) == 1


def test_matches_required_fields_present(client_and_db):
    """All fields the Flutter UI depends on must be present."""
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)
    _seed_buyer(db)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    item = resp.json()[0]

    required = [
        "buyer_id", "buyer", "buyer_type", "verified",
        "payment_reliability", "offered_price",
        "match_score", "reason", "score_breakdown",
    ]
    for field in required:
        assert field in item, f"Missing field: {field}"


def test_score_breakdown_fields(client_and_db):
    """score_breakdown must expose all 4 transparent components."""
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)
    _seed_buyer(db)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    breakdown = resp.json()[0]["score_breakdown"]

    for key in ["quantity_fit", "quality_fit", "verified_score", "payment_score"]:
        assert key in breakdown, f"Missing breakdown key: {key}"
        assert 0 <= breakdown[key] <= 100, f"{key} out of range: {breakdown[key]}"


def test_match_score_range(client_and_db):
    """match_score must always be in [0, 100]."""
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)
    _seed_buyer(db)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    score = resp.json()[0]["match_score"]
    assert 0 <= score <= 100, f"match_score out of range: {score}"


def test_reason_is_non_empty_and_mentions_formula(client_and_db):
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)
    _seed_buyer(db)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    reason = resp.json()[0]["reason"]
    assert isinstance(reason, str) and len(reason) > 10
    assert "%" in reason


def test_high_score_for_perfect_match(client_and_db):
    """Verified buyer with lot in range should score > 70."""
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id, quantity=25.0)
    _seed_buyer(db, min_q=10, max_q=100, verified=True, payment=0.95)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    score = resp.json()[0]["match_score"]
    assert score > 70, f"Expected high score for perfect match, got {score}"


def test_no_match_for_wrong_commodity(client_and_db):
    """Buyer demanding a different commodity must not appear in matches."""
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id, commodity="Tomato")
    _seed_buyer(db, commodity="Wheat")

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    assert resp.json() == []


def test_matches_404_for_unknown_lot(client_and_db):
    client, _ = client_and_db
    resp = client.get("/api/buyers/matches/99999")
    assert resp.status_code == 404


def test_empty_matches_when_no_buyers(client_and_db):
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    assert resp.status_code == 200
    assert resp.json() == []


def test_results_sorted_by_score_descending(client_and_db):
    """Multiple buyers should be returned highest-score first."""
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id, quantity=25.0)

    b1 = Buyer(
        name="TopBuyer",
        buyer_type="Institutional Buyer",
        verified=True,
        payment_reliability=0.95,
        demand_commodity="Tomato",
        min_quantity=10,
        max_quantity=100,
        offered_price=2900.0,
    )
    b2 = Buyer(
        name="LowBuyer",
        buyer_type="Local Trader",
        verified=False,
        payment_reliability=0.40,
        demand_commodity="Tomato",
        min_quantity=200,
        max_quantity=500,
        offered_price=2200.0,
    )
    db.add_all([b1, b2])
    db.commit()

    resp = client.get(f"/api/buyers/matches/{lot.id}")
    data = resp.json()
    assert len(data) == 2
    assert data[0]["match_score"] >= data[1]["match_score"]
    assert data[0]["buyer"] == "TopBuyer"


def test_create_offer(client_and_db):
    client, db = client_and_db
    farmer = _seed_farmer(db)
    lot = _seed_lot(db, farmer.id)
    buyer = _seed_buyer(db)

    resp = client.post("/api/buyers/offers", json={
        "lot_id": lot.id,
        "buyer_id": buyer.id,
        "offered_price": 2800.0,
        "quantity_quintal": 20.0,
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["lot_id"] == lot.id
    assert data["buyer_id"] == buyer.id
    assert data["offered_price"] == 2800.0
    assert "id" in data


def test_create_offer_404_unknown_lot(client_and_db):
    client, db = client_and_db
    farmer = _seed_farmer(db)
    _seed_lot(db, farmer.id)
    buyer = _seed_buyer(db)

    resp = client.post("/api/buyers/offers", json={
        "lot_id": 99999,
        "buyer_id": buyer.id,
        "offered_price": 2800.0,
        "quantity_quintal": 20.0,
    })
    assert resp.status_code == 404
