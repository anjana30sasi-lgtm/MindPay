"""
Comprehensive integration test for MindPay ML Backend.

Tests:
1. /health endpoint and model loading.
2. /predict endpoint across normal, frequency spike, and high-risk spending scenarios.
3. Reason generation and schema validation.
"""

import json
from datetime import datetime
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    print("\n--- Testing GET /health ---")
    response = client.get("/health")
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Health response:", json.dumps(data, indent=2))
    assert data["status"] == "healthy"
    assert data["model_loaded"] is True
    assert data["model_version"] == "1.0.0-synthetic-rf"
    print("[PASS] Health check passed!")


def test_normal_transaction():
    print("\n--- Testing Scenario 1: Normal Everyday Transaction ---")
    payload = {
        "user_id": "user_demo",
        "merchant": "BigBasket",
        "category": "Groceries",
        "amount": 550.0,
        "time": datetime(2026, 10, 18, 13, 0).isoformat(),
        "daily_limit": 5000.0,
        "monthly_budget": 40000.0,
        "spending_style": "I plan ahead",
        "main_temptation": "Online shopping",
        "same_day_category_count": 1,
        "historical_category_avg": 700.0,
    }

    response = client.post("/predict", json=payload)
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
    result = response.json()
    print("Prediction Result:")
    print(json.dumps(result, indent=2))

    assert result["should_pause"] is False, "Expected normal transaction NOT to pause"
    assert result["risk_level"] == "LOW"
    assert result["impulse_probability"] < 0.50
    print("[PASS] Normal transaction correctly identified (no pause)!")


def test_frequency_trigger():
    print("\n--- Testing Scenario 2: Frequency Spike (3rd Food Order) ---")
    payload = {
        "user_id": "user_demo",
        "merchant": "Zomato",
        "category": "Food",
        "amount": 420.0,
        "time": datetime(2026, 10, 18, 22, 10).isoformat(),
        "daily_limit": 5000.0,
        "monthly_budget": 40000.0,
        "spending_style": "I go with the flow",
        "main_temptation": "Food delivery",
        "same_day_category_count": 3,  # 3rd order today
        "historical_category_avg": 400.0,
    }

    response = client.post("/predict", json=payload)
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
    result = response.json()
    print("Prediction Result:")
    print(json.dumps(result, indent=2))

    assert result["should_pause"] is True, "Expected frequency spike to pause"
    assert len(result["reasons"]) > 0
    assert any("3rd" in r or "food" in r.lower() for r in result["reasons"])
    print("[PASS] Frequency spike correctly triggered pause with explainable reason!")


def test_high_risk_late_night():
    print("\n--- Testing Scenario 3: High Risk Late-Night Impulse Spend ---")
    payload = {
        "user_id": "user_demo",
        "merchant": "Myntra",
        "category": "Shopping",
        "amount": 3400.0,  # High amount
        "time": datetime(2026, 10, 18, 1, 15).isoformat(),  # 1:15 AM
        "daily_limit": 3000.0,  # Crosses daily limit
        "monthly_budget": 40000.0,
        "spending_style": "I go with the flow",
        "main_temptation": "Online shopping",
        "same_day_category_count": 2,
        "historical_category_avg": 1100.0,
    }

    response = client.post("/predict", json=payload)
    assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
    result = response.json()
    print("Prediction Result:")
    print(json.dumps(result, indent=2))

    assert result["should_pause"] is True, "Expected high-risk spend to pause"
    assert result["risk_level"] == "HIGH"
    assert result["impulse_probability"] >= 0.70
    assert len(result["reasons"]) >= 2
    print("[PASS] High-risk impulse spend correctly identified with high confidence and multiple reasons!")



if __name__ == "__main__":
    test_health()
    test_normal_transaction()
    test_frequency_trigger()
    test_high_risk_late_night()
    print("\n==========================================")
    print("ALL ML BACKEND TESTS PASSED SUCCESSFULLY!")
    print("==========================================")
