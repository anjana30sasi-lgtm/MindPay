"""
MindPay FastAPI Application.

Provides /health and /predict endpoints for conscious spending impulse detection.
"""

from contextlib import asynccontextmanager
from datetime import datetime
import os
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from app.predictor import ImpulsePredictor
from app.schemas import (
    HealthResponse,
    TransactionPredictionRequest,
    TransactionPredictionResponse,
)

# Global predictor instance
_predictor: ImpulsePredictor = None


def get_predictor() -> ImpulsePredictor:
    global _predictor
    if _predictor is None:
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        model_path = os.path.join(base_dir, "models", "model.joblib")
        _predictor = ImpulsePredictor(model_path=model_path)
    return _predictor


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting MindPay ML Service...")
    pred = get_predictor()
    if pred.is_loaded():
        print(f"ML Model ready from {pred.model_path}")
    else:
        print("Note: Model file not yet trained. Run training/train.py to generate model.joblib.")
    yield
    print("Shutting down MindPay ML Service...")



app = FastAPI(
    title="MindPay ML Engine",
    description=(
        "Conscious spending prediction service for MindPay. Uses scikit-learn "
        "to evaluate impulse risk and returns explainable pause reasons."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS configuration to allow Flutter and local development connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", summary="Root index")
async def root():
    return {
        "service": "MindPay ML Engine",
        "status": "online",
        "docs": "/docs",
        "health": "/health",
        "predict": "/predict",
    }


@app.get("/health", response_model=HealthResponse, summary="Health Check")
async def health_check():
    """
    Check if the API is active and whether the scikit-learn model is loaded into memory.
    """
    pred = get_predictor()
    is_loaded = pred is not None and pred.is_loaded()
    version = pred.model_version if pred else "unknown"
    return HealthResponse(
        status="healthy" if is_loaded else "degraded (model not trained/loaded)",
        model_loaded=is_loaded,
        model_version=version,
        timestamp=datetime.now(),
    )


@app.post(
    "/predict",
    response_model=TransactionPredictionResponse,
    status_code=status.HTTP_200_OK,
    summary="Predict Impulse Spending",
)
async def predict_impulse(request: TransactionPredictionRequest):
    """
    Evaluate a candidate transaction against user context and behavioral history.
    Returns whether to pause, impulse probability, and plain-language explanation reasons.
    """
    pred = get_predictor()
    if pred is None or not pred.is_loaded():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="ML Model is not loaded. Ensure training/train.py has been run.",
        )

    try:
        response = pred.predict(request)
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Inference error: {str(e)}",
        )

