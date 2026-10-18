"""
Pydantic schemas for MindPay ML prediction API.
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class TransactionPredictionRequest(BaseModel):
    """
    Input transaction and user context sent for impulse prediction.
    """
    user_id: Optional[str] = Field(default="demo_user", description="ID of the user")
    amount: float = Field(..., gt=0, description="Transaction amount in INR")
    category: str = Field(..., description="Category: Food, Shopping, Travel, Groceries, Entertainment, Others")
    merchant: str = Field(..., description="Merchant name (e.g. Zomato, Amazon, Uber)")
    time: Optional[datetime] = Field(default_factory=datetime.now, description="Transaction timestamp (ISO format)")
    
    # User Profile / Behavioral Context
    daily_limit: Optional[float] = Field(default=5000.0, gt=0, description="User's daily spending limit")
    monthly_budget: Optional[float] = Field(default=40000.0, gt=0, description="User's monthly budget")
    spending_style: Optional[str] = Field(default="I go with the flow", description="User spending style from onboarding")
    main_temptation: Optional[str] = Field(default=None, description="Primary temptation identified during onboarding")
    
    # History Context (can be passed from client/firestore)
    same_day_category_count: Optional[int] = Field(default=1, ge=1, description="Number of orders in this category today")
    historical_category_avg: Optional[float] = Field(default=None, gt=0, description="Average spend in this category")


class TransactionPredictionResponse(BaseModel):
    """
    ML prediction response matching MindPay's PauseDecision format.
    """
    should_pause: bool = Field(..., description="Whether MindPay should trigger the 10-second pause")
    is_impulsive: bool = Field(..., description="Binary classification (1 = impulsive, 0 = normal)")
    impulse_probability: float = Field(..., description="Predicted impulse risk probability (0.0 to 1.0)")
    risk_level: str = Field(..., description="Risk tier: LOW, MEDIUM, HIGH")
    reasons: List[str] = Field(default_factory=list, description="Explainable reasons for the nudge")
    model_version: str = Field(default="1.0.0-synthetic-rf", description="Version of the loaded ML model")
    disclaimer: str = Field(
        default="Trained on synthetic demonstration data. Not an empirical clinical spending diagnostic.",
        description="Dataset and model disclaimer"
    )


class HealthResponse(BaseModel):
    """
    Health check status response.
    """
    status: str
    model_loaded: bool
    model_version: str
    timestamp: datetime
