"""
Synthetic Dataset Generator for MindPay Impulse Spending Prediction.

IMPORTANT NOTICE:
This dataset is generated synthetically for demonstration, educational, and
prototyping purposes in MindPay. The labels are generated using probabilistic
behavioral heuristics (e.g. night-time purchases, frequency spikes, temptation category
alignment, and budget ratio anomalies) to simulate realistic spending patterns.
These predictions are for demonstration and are NOT clinically or empirically
validated real-world impulse detection models.
"""

import random
from datetime import datetime, timedelta
import numpy as np
import pandas as pd


def generate_synthetic_transactions(num_samples: int = 5000, random_seed: int = 42) -> pd.DataFrame:
    """
    Generate synthetic transactions with behavioural features and an impulse label.
    """
    random.seed(random_seed)
    np.random.seed(random_seed)

    categories = ["Food", "Shopping", "Travel", "Groceries", "Entertainment", "Others"]
    merchants_by_category = {
        "Food": ["Zomato", "Swiggy", "Domino's", "McDonald's", "Starbucks", "Chai Point"],
        "Shopping": ["Amazon", "Myntra", "Flipkart", "Zara", "Nykaa", "Ajio"],
        "Travel": ["Uber", "Ola", "IRCTC", "Rapido", "MakeMyTrip"],
        "Groceries": ["BigBasket", "Blinkit", "Zepto", "Instamart"],
        "Entertainment": ["BookMyShow", "Steam", "PlayStation Store", "PVR Cinemas"],
        "Others": ["Local Store", "Pharmacy", "Utility Bill", "Courier"],
    }

    spending_styles = ["I plan ahead", "I go with the flow", "A bit of both"]
    temptations = ["Food delivery", "Online shopping", "Rides & travel", "Entertainment"]

    temptation_to_category = {
        "Food delivery": "Food",
        "Online shopping": "Shopping",
        "Rides & travel": "Travel",
        "Entertainment": "Entertainment",
    }

    records = []

    for i in range(num_samples):
        # User profile context
        monthly_budget = float(random.choice([20000, 30000, 40000, 50000, 60000, 80000]))
        daily_limit = float(round(monthly_budget / random.uniform(15, 25), -2))
        spending_style = random.choice(spending_styles)
        main_temptation = random.choice(temptations)

        category = random.choices(
            categories,
            weights=[0.30, 0.25, 0.15, 0.20, 0.07, 0.03],
            k=1
        )[0]
        merchant = random.choice(merchants_by_category[category])

        # Temporal features
        hour = int(random.choices(
            list(range(24)),
            weights=[
                2, 1, 1, 1, 1, 2, 3, 5, 6, 7, 8, 9,
                10, 9, 7, 6, 7, 8, 9, 10, 9, 7, 5, 3
            ],
            k=1
        )[0])
        day_of_week = random.randint(0, 6)
        is_weekend = 1 if day_of_week in [5, 6] else 0

        # Frequency today in this category (0 to 4 prior orders)
        same_day_count = int(np.random.poisson(lam=0.8)) + 1

        # Baseline amount by category
        baseline_amounts = {
            "Food": random.uniform(150, 900),
            "Shopping": random.uniform(400, 3500),
            "Travel": random.uniform(80, 750),
            "Groceries": random.uniform(250, 2000),
            "Entertainment": random.uniform(300, 2500),
            "Others": random.uniform(100, 1500),
        }
        base_amount = baseline_amounts[category]

        # Sometimes inject an intentional high spike or impulsive scenario
        is_anomaly_candidate = random.random() < 0.25
        if is_anomaly_candidate:
            amount = round(base_amount * random.uniform(1.8, 3.8), 2)
        else:
            amount = round(base_amount * random.uniform(0.7, 1.3), 2)

        # Behavioral ratios
        amount_to_limit_ratio = round(amount / daily_limit, 4)
        category_avg_amount = base_amount
        spend_ratio_to_category_avg = round(amount / category_avg_amount, 4)

        # Check alignment with stated temptation
        is_temptation_category = 1 if temptation_to_category.get(main_temptation) == category else 0

        # Impulse risk scoring calculation (ground truth label generation)
        # We calculate an impulse probability using latent behavioral weights:
        risk_score = 0.0

        # 1. Late night/early morning hours (11 PM - 4:59 AM)
        if hour >= 23 or hour <= 4:
            risk_score += 0.30

        # 2. Frequency spike in same day
        if same_day_count >= 3:
            risk_score += 0.25
        elif same_day_count == 2:
            risk_score += 0.10

        # 3. High amount compared to category average
        if spend_ratio_to_category_avg > 2.0:
            risk_score += 0.30
        elif spend_ratio_to_category_avg > 1.5:
            risk_score += 0.15

        # 4. Exceeds daily limit
        if amount_to_limit_ratio > 0.8:
            risk_score += 0.25
        elif amount_to_limit_ratio > 0.5:
            risk_score += 0.10

        # 5. Stated temptation matching category
        if is_temptation_category:
            risk_score += 0.15

        # 6. User personality effect
        if spending_style == "I go with the flow":
            risk_score += 0.10
        elif spending_style == "I plan ahead":
            risk_score -= 0.10

        # Add Gaussian noise
        noise = np.random.normal(0, 0.08)
        total_probability = 1 / (1 + np.exp(-3 * (risk_score - 0.45 + noise)))

        is_impulsive = 1 if total_probability >= 0.50 else 0

        records.append({
            "amount": amount,
            "category": category,
            "merchant": merchant,
            "hour": hour,
            "day_of_week": day_of_week,
            "is_weekend": is_weekend,
            "same_day_category_count": same_day_count,
            "daily_limit": daily_limit,
            "monthly_budget": monthly_budget,
            "amount_to_limit_ratio": amount_to_limit_ratio,
            "spend_ratio_to_category_avg": spend_ratio_to_category_avg,
            "spending_style": spending_style,
            "main_temptation": main_temptation,
            "is_temptation_category": is_temptation_category,
            "is_impulsive": is_impulsive,
        })

    return pd.DataFrame(records)


if __name__ == "__main__":
    import os
    os.makedirs("data", exist_ok=True)
    output_path = os.path.join("data", "synthetic_transactions.csv")
    df = generate_synthetic_transactions(num_samples=6000)
    df.to_csv(output_path, index=False)
    print(f"Generated {len(df)} synthetic records saved to {output_path}")
    print("Class balance:")
    print(df["is_impulsive"].value_counts(normalize=True))
