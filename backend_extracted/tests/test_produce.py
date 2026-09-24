"""
Tests for POST /api/produce/grade and POST /api/produce/lots endpoints.
"""
import random
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestProduceGrade:
    """Tests for POST /api/produce/grade — integration boundary prototype."""

    def test_grade_supported_crop_returns_prototype_status(self):
        resp = client.post("/api/produce/grade", json={"crop": "tomato"})
        assert resp.status_code == 200
        data = resp.json()
        # Must clearly mark as prototype — never AI certified
        assert data["status"] == "integration_boundary_prototype"
        assert data["is_certified"] is False
        assert "prototype" in data["disclaimer"].lower() or \
               "integration" in data["disclaimer"].lower()

    def test_grade_returns_required_diagnostic_metrics(self):
        resp = client.post("/api/produce/grade", json={"crop": "onion"})
        assert resp.status_code == 200
        data = resp.json()
        # Must return all expected diagnostic fields
        assert "grade" in data
        assert "quality_score" in data
        assert "uniformity_pct" in data
        assert "moisture_pct" in data
        assert "pest_damage_pct" in data
        assert "detected_markers" in data
        assert isinstance(data["detected_markers"], list)

    def test_grade_markers_have_correct_structure(self):
        resp = client.post("/api/produce/grade", json={"crop": "potato"})
        assert resp.status_code == 200
        markers = resp.json()["detected_markers"]
        for marker in markers:
            assert "label" in marker
            assert "conf" in marker
            assert "x" in marker
            assert "y" in marker

    def test_grade_unsupported_crop_returns_not_available(self):
        resp = client.post("/api/produce/grade", json={"crop": "jackfruit"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "model_not_available"
        assert data["is_certified"] is False
        assert data["grade"] is None

    def test_grade_with_image_base64_sets_has_image_true(self):
        resp = client.post("/api/produce/grade", json={
            "crop": "wheat",
            "image_bytes_base64": "dGVzdA==",  # base64 "test"
        })
        assert resp.status_code == 200
        data = resp.json()
        assert data["has_image"] is True

    def test_grade_without_image_sets_has_image_false(self):
        resp = client.post("/api/produce/grade", json={"crop": "tomato"})
        assert resp.status_code == 200
        assert resp.json()["has_image"] is False

    def test_grade_never_claims_ai_certified(self):
        for crop in ["tomato", "onion", "potato", "wheat"]:
            resp = client.post("/api/produce/grade", json={"crop": crop})
            assert resp.status_code == 200
            data = resp.json()
            # Strict: is_certified MUST be False for integration boundary
            assert data["is_certified"] is False, (
                f"Crop '{crop}' returned is_certified=True — "
                "this violates the integration boundary contract."
            )


class TestProduceLots:
    """Tests for POST /api/produce/lots and GET /api/produce/lots/{farmer_id}."""

    def _create_farmer(self) -> int:
        phone = f"98{random.randint(10000000, 99999999)}"
        resp = client.post("/api/farmers", json={
            "name": "Test Farmer",
            "phone": phone,
            "village": "Junnar",
            "district": "Pune",
            "state": "Maharashtra",
        })
        assert resp.status_code == 200
        return resp.json()["id"]

    def test_create_lot_persists_grade_and_quality_score(self):
        farmer_id = self._create_farmer()
        resp = client.post("/api/produce/lots", json={
            "farmer_id": farmer_id,
            "commodity": "Onion",
            "variety": "Nasik Red",
            "quantity_quintal": 20.0,
            "grade": "A",
            "quality_score": 0.88,
        })
        assert resp.status_code == 200
        data = resp.json()
        assert data["grade"] == "A"
        assert data["quality_score"] == pytest.approx(0.88)
        assert data["commodity"] == "Onion"
        assert data["farmer_id"] == farmer_id

    def test_create_lot_persists_image_path(self):
        farmer_id = self._create_farmer()
        resp = client.post("/api/produce/lots", json={
            "farmer_id": farmer_id,
            "commodity": "Tomato",
            "quantity_quintal": 10.0,
            "image_path": "/uploads/farmer_1_lot_tomato.jpg",
        })
        assert resp.status_code == 200
        data = resp.json()
        assert data["image_path"] == "/uploads/farmer_1_lot_tomato.jpg"

    def test_get_farmer_lots_returns_created_lot(self):
        farmer_id = self._create_farmer()
        create_resp = client.post("/api/produce/lots", json={
            "farmer_id": farmer_id,
            "commodity": "Soybean",
            "quantity_quintal": 50.0,
        })
        assert create_resp.status_code == 200
        lot_id = create_resp.json()["id"]

        lots_resp = client.get(f"/api/produce/lots/{farmer_id}")
        assert lots_resp.status_code == 200
        lot_ids = [l["id"] for l in lots_resp.json()]
        assert lot_id in lot_ids

    def test_create_lot_requires_positive_quantity(self):
        farmer_id = self._create_farmer()
        resp = client.post("/api/produce/lots", json={
            "farmer_id": farmer_id,
            "commodity": "Onion",
            "quantity_quintal": 0.0,  # Invalid: must be > 0
        })
        assert resp.status_code == 422
