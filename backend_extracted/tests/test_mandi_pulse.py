"""
Tests for /api/mandi/pulse endpoint ensuring authentic government data,
accurate price movement calculation, and presence of target commodities.
"""
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

TARGET_COMMODITIES = {
    "Wheat",
    "Paddy",
    "Sponge Gourd",
    "Garlic",
    "Chilli",
    "Onion",
    "Tomato",
    "Potato",
    "Soybean",
}

def test_mandi_pulse_endpoint():
    response = client.get("/api/mandi/pulse?limit=50")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0

    commodities_returned = {
        item.get("normalized_name") or item["commodity"] for item in data
    }

    # Verify target commodities are returned
    for target in TARGET_COMMODITIES:
        assert target in commodities_returned, f"Expected {target} to be present in pulse commodities"

    for item in data:
        # Every card requires commodity, modal_price, unit, market, source, and price_change_pct (or None)
        assert "commodity" in item
        assert "modal_price" in item
        assert item["modal_price"] > 0
        assert "unit" in item
        assert "market" in item
        assert len(item["market"]) > 0
        assert "source" in item
        assert "price_change_pct" in item

        # Verify price_change_pct formula when previous_modal_price is present
        if item.get("previous_modal_price") is not None and item.get("price_change_pct") is not None:
            expected_change = round(((item["modal_price"] - item["previous_modal_price"]) / item["previous_modal_price"]) * 100, 1)
            assert item["price_change_pct"] == expected_change
        elif item.get("previous_modal_price") is None:
            # If previous record did not exist in the same market, movement must be None (not fake 0.0)
            assert item.get("price_change_pct") is None
