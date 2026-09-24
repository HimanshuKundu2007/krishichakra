from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_chatbot_mandi_prices():
    response = client.post("/api/chatbot/chat", json={"message": "What is the tomato price in Vashi mandi today?"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "mandi_prices"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Mandi" in data["reply"] or "Rate" in data["reply"] or "₹" in data["reply"]
    assert len(data["suggestions"]) > 0


def test_chatbot_market_comparison():
    response = client.post("/api/chatbot/chat", json={"message": "Compare Vashi vs Pune mandi prices"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "market_comparison"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Vashi APMC" in data["reply"]
    assert "Pune APMC" in data["reply"]


def test_chatbot_buyers():
    response = client.post("/api/chatbot/chat", json={"message": "Who are verified institutional buyers?"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "buyers"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Reliability" in data["reply"]
    assert "Buyer" in data["reply"] or "Agro" in data["reply"]


def test_chatbot_transport():
    response = client.post("/api/chatbot/chat", json={"message": "How do I book return truck transport?"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "transport"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Tata 407" in data["reply"] or "Freight" in data["reply"]


def test_chatbot_storage():
    response = client.post("/api/chatbot/chat", json={"message": "Tell me about cold storage and e-NWR loan advance"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "storage"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "e-NWR" in data["reply"] or "MSWC" in data["reply"]


def test_chatbot_produce_quality():
    response = client.post("/api/chatbot/chat", json={"message": "What is the quality grade A standard for tomatoes?"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "produce_quality"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Grade A" in data["reply"]
    assert "Zero Whole-Batch Rejection" in data["reply"]


def test_chatbot_selling_decisions():
    response = client.post("/api/chatbot/chat", json={"message": "Should I sell now or hold my produce?"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "selling_decisions"
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Net Realization" in data["reply"]


def test_chatbot_multilingual_greeting():
    # Hindi
    res_hi = client.post("/api/chatbot/chat", json={"message": "नमस्ते", "language": "hi"})
    assert res_hi.status_code == 200
    data_hi = res_hi.json()
    assert data_hi["mode"] == "rule_based_prototype"
    assert data_hi["is_llm"] is False
    assert "नमस्ते" in data_hi["reply"] or "KrishiBot" in data_hi["reply"]

    # Marathi
    res_mr = client.post("/api/chatbot/chat", json={"message": "नमस्कार", "language": "mr"})
    assert res_mr.status_code == 200
    data_mr = res_mr.json()
    assert data_mr["mode"] == "rule_based_prototype"
    assert data_mr["is_llm"] is False
    assert "नमस्कार" in data_mr["reply"] or "KrishiBot" in data_mr["reply"]


def test_chatbot_empty_message():
    res = client.post("/api/chatbot/chat", json={"message": "   "})
    assert res.status_code == 200
    data = res.json()
    assert data["mode"] == "rule_based_prototype"
    assert data["is_llm"] is False
    assert "Please enter a question" in data["reply"]
