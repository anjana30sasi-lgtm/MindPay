# MindPay ML Backend

FastAPI and scikit-learn machine-learning service for predicting impulse spending in MindPay.

> **Disclaimer:**
> This service uses a model trained on synthetic behavioral transaction data to demonstrate conscious spending interventions and explainable pause nudges for the MindPay prototype. It is not an empirically validated psychological or clinical diagnostic tool.

---

## Architecture Overview

```
backend/
├── requirements.txt           # Dependencies (FastAPI, uvicorn, scikit-learn, etc.)
├── test_api.py                # Automated API test suite
├── app/
│   ├── __init__.py
│   ├── main.py                # FastAPI application exposing /health & /predict
│   ├── predictor.py           # Feature engineering, ML inference & reason generation
│   └── schemas.py             # Pydantic request/response schemas
├── training/
│   ├── __init__.py
│   ├── generate_dataset.py    # Synthetic dataset generator with behavioral heuristics
│   └── train.py               # Preprocessing pipeline & RandomForestClassifier training
├── data/
│   └── synthetic_transactions.csv
└── models/
    ├── model.joblib           # Trained scikit-learn pipeline artifact
    └── model_metadata.json    # Model evaluation metrics and parameters
```

---

## How to Run

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. (Optional) Re-train the model
```bash
python training/train.py
```

### 3. Start the FastAPI server
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Once started, the API documentation is available at:
* Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
* Health Check: [http://localhost:8000/health](http://localhost:8000/health)

### 4. Run tests
```bash
python test_api.py
```
