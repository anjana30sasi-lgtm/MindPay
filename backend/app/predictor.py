
"""
MindPay ML Predictor Engine.

Loads the trained scikit-learn model pipeline, performs feature engineering
on incoming transactions, generates prediction probabilities, and produces
plain-language explainable reasons for the PauseDialog.
"""

import os
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import joblib
import pandas as pd

from app.schemas import (
    TransactionPredictionRequest,
    TransactionPredictionResponse,
)


DEFAULT_CATEGORY_AVERAGES: Dict[str, float] = {
    "Food": 450.0,
    "Shopping": 1250.0,
    "Travel": 250.0,
    "Groceries": 800.0,
    "Entertainment": 650.0,
    "Others": 400.0,
}

TEMPTATION_MAP: Dict[str, str] = {
    "Food delivery": "Food",
    "Online shopping": "Shopping",
    "Rides & travel": "Travel",
    "Entertainment": "Entertainment",
}


def _ordinal(n: int) -> str:
    if n == 1:
        return "1st"
    elif n == 2:
        return "2nd"
    elif n == 3:
        return "3rd"
    return f"{n}th"


class ImpulsePredictor:
    """Inference service for impulse spending prediction."""

    def __init__(self, model_path: Optional[str] = None):
        if model_path is None:
            base_dir = os.path.dirname(
                os.path.dirname(os.path.abspath(__file__))
            )
            model_path = os.path.join(
                base_dir, "models", "model.joblib"
            )

        self.model_path = model_path
        self.model = None
        self.model_version = "1.0.0-synthetic-rf"
        self._load_model()

    def _load_model(self):
        if os.path.exists(self.model_path):
            self.model = joblib.load(self.model_path)
            print(f"Loaded ML model pipeline from {self.model_path}")
        else:
            print(
                f"Warning: Model file not found at {self.model_path}. "
                "Train model first."
            )

    def is_loaded(self) -> bool:
        return self.model is not None

    def _extract_features(
        self, req: TransactionPredictionRequest
    ) -> Tuple[pd.DataFrame, Dict]:
        """Extract numerical and categorical features matching training."""

        tx_time = req.time or datetime.now()
        hour = tx_time.hour
        day_of_week = tx_time.weekday()
        is_weekend = 1 if day_of_week in [5, 6] else 0

        cat_avg = (
            req.historical_category_avg
            or DEFAULT_CATEGORY_AVERAGES.get(req.category, 500.0)
        )
        spend_ratio = req.amount / max(cat_avg, 1.0)

        daily_limit = req.daily_limit or 5000.0
        amount_to_limit_ratio = req.amount / max(daily_limit, 1.0)

        target_temptation_cat = TEMPTATION_MAP.get(
            req.main_temptation or ""
        )
        is_temptation_category = (
            1 if target_temptation_cat == req.category else 0
        )

        feature_dict = {
            "amount": float(req.amount),
            "hour": int(hour),
            "day_of_week": int(day_of_week),
            "is_weekend": int(is_weekend),
            "same_day_category_count": int(
                req.same_day_category_count or 1
            ),
            "daily_limit": float(daily_limit),
            "monthly_budget": float(req.monthly_budget or 40000.0),
            "amount_to_limit_ratio": float(
                round(amount_to_limit_ratio, 4)
            ),
            "spend_ratio_to_category_avg": float(
                round(spend_ratio, 4)
            ),
            "is_temptation_category": int(is_temptation_category),
            "category": str(req.category),
            "spending_style": str(
                req.spending_style or "I go with the flow"
            ),
        }

        metadata_context = {
            "hour": hour,
            "tx_time": tx_time,
            "cat_avg": cat_avg,
            "spend_ratio": spend_ratio,
            "daily_limit": daily_limit,
            "amount_to_limit_ratio": amount_to_limit_ratio,
            "is_temptation_category": is_temptation_category,
        }

        return pd.DataFrame([feature_dict]), metadata_context

    def _generate_explainable_reasons(
        self,
        req: TransactionPredictionRequest,
        prob: float,
        ctx: Dict,
    ) -> List[str]:
        """Generate plain-language explanations for the pause dialog."""

        reasons = []

        # 1. Frequency spike
        same_day = req.same_day_category_count or 1
        if same_day >= 3:
            reasons.append(
                f"This is your {_ordinal(same_day)} "
                f"{req.category.lower()} order today"
            )
        elif same_day == 2 and prob >= 0.50:
            reasons.append(
                f"2nd {req.category.lower()} transaction "
                "within a short window"
            )

        # 2. Late-night or early-morning spending
        hour = ctx["hour"]
        if hour >= 23 or hour <= 4:
            formatted_time = ctx["tx_time"].strftime("%I:%M %p")
            reasons.append(
                f"Late night spend at {formatted_time} "
                "outside your usual hours"
            )

        # 3. Category amount deviation
        spend_ratio = ctx["spend_ratio"]
        if spend_ratio >= 1.8:
            reasons.append(
                f"Amount is {spend_ratio:.1f}x higher than your "
                f"usual {req.category.lower()} spend"
            )

        # 4. Daily limit usage
        amount_ratio = ctx["amount_to_limit_ratio"]
        if amount_ratio >= 0.8:
            reasons.append(
                f"This single purchase uses "
                f"{int(amount_ratio * 100)}% of your "
                f"₹{int(ctx['daily_limit'])} daily limit"
            )

        # 5. User-declared temptation trigger
        if ctx["is_temptation_category"]:
            reasons.append(
                f"Matches your self-declared trigger: "
                f"{req.main_temptation}"
            )

        # 6. ML model assessment
        if prob >= 0.70:
            reasons.append(
                f"High impulse confidence score "
                f"({int(prob * 100)}%) detected by ML model"
            )
        elif not reasons and prob >= 0.50:
            reasons.append(
                f"Unusual spending behavior flagged by ML model "
                f"({int(prob * 100)}% risk)"
            )

        return reasons

    def predict(
        self, req: TransactionPredictionRequest
    ) -> TransactionPredictionResponse:
        """Execute prediction and format the API response."""

        if self.model is None:
            self._load_model()
            if self.model is None:
                raise RuntimeError(
                    "ML model is not loaded. "
                    "Ensure models/model.joblib is trained."
                )

        features_df, ctx = self._extract_features(req)

        # Calculate the model's impulse probability.
        probabilities = self.model.predict_proba(features_df)[0]
        impulse_prob = float(probabilities[1])

        # Generate explanations before deciding whether to pause.
        reasons = self._generate_explainable_reasons(
            req, impulse_prob, ctx
        )

        # Pause if the model probability is high enough, or if
        # multiple independent risk signals have been identified.
        should_pause = impulse_prob >= 0.50 or len(reasons) >= 3

        if should_pause:
            risk_level = (
                "HIGH" if impulse_prob >= 0.70 else "MEDIUM"
            )
        else:
            risk_level = "LOW"

        return TransactionPredictionResponse(
            should_pause=should_pause,
            is_impulsive=should_pause,
            impulse_probability=round(impulse_prob, 4),
            risk_level=risk_level,
            reasons=reasons,
            model_version=self.model_version,
            disclaimer=(
                "Trained on synthetic demonstration data. "
                "Designed for MindPay mindful spending simulation."
            ),
        )
