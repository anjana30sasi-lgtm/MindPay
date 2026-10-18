"""
Model Training Script for MindPay Impulse Spending Prediction.

Trains a scikit-learn pipeline (preprocessing + RandomForestClassifier)
using the synthetic transactions dataset and exports the artifact to
backend/models/model.joblib.
"""

import json
import os
import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score, accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from generate_dataset import generate_synthetic_transactions


NUMERICAL_FEATURES = [
    "amount",
    "hour",
    "day_of_week",
    "is_weekend",
    "same_day_category_count",
    "daily_limit",
    "monthly_budget",
    "amount_to_limit_ratio",
    "spend_ratio_to_category_avg",
    "is_temptation_category",
]

CATEGORICAL_FEATURES = [
    "category",
    "spending_style",
]


def train_and_save_model(data_path: str = None, model_dir: str = "models"):
    """
    Train a scikit-learn pipeline and save the model.
    """
    os.makedirs(model_dir, exist_ok=True)

    # 1. Load or generate data
    if data_path and os.path.exists(data_path):
        print(f"Loading data from {data_path}...")
        df = pd.read_csv(data_path)
    else:
        print("Generating fresh synthetic dataset...")
        df = generate_synthetic_transactions(num_samples=7500, random_seed=42)
        os.makedirs("data", exist_ok=True)
        df.to_csv(os.path.join("data", "synthetic_transactions.csv"), index=False)

    feature_cols = NUMERICAL_FEATURES + CATEGORICAL_FEATURES
    X = df[feature_cols]
    y = df["is_impulsive"]

    # 2. Train-test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    print(f"Dataset size: {len(df)} (Train: {len(X_train)}, Test: {len(X_test)})")

    # 3. Build Preprocessor Pipeline
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), NUMERICAL_FEATURES),
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL_FEATURES),
        ]
    )

    # 4. Model Pipeline
    classifier = RandomForestClassifier(
        n_estimators=120,
        max_depth=10,
        min_samples_split=5,
        random_state=42,
        class_weight="balanced",
    )

    pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("classifier", classifier),
        ]
    )

    # 5. Fit Pipeline
    print("Training Random Forest model pipeline...")
    pipeline.fit(X_train, y_train)

    # 6. Evaluate Model
    y_pred = pipeline.predict(X_test)
    y_prob = pipeline.predict_proba(X_test)[:, 1]

    accuracy = accuracy_score(y_test, y_pred)
    roc_auc = roc_auc_score(y_test, y_prob)
    report = classification_report(y_test, y_pred, output_dict=True)

    print(f"\nModel Evaluation:")
    print(f"Accuracy: {accuracy:.4f}")
    print(f"ROC-AUC:  {roc_auc:.4f}")
    print(classification_report(y_test, y_pred))

    # 7. Save Model & Metadata
    model_path = os.path.join(model_dir, "model.joblib")
    joblib.dump(pipeline, model_path)
    print(f"Model successfully saved to {model_path}")

    metadata = {
        "model_type": "RandomForestClassifier",
        "num_samples": len(df),
        "numerical_features": NUMERICAL_FEATURES,
        "categorical_features": CATEGORICAL_FEATURES,
        "metrics": {
            "accuracy": round(accuracy, 4),
            "roc_auc": round(roc_auc, 4),
            "precision_class_1": round(report["1"]["precision"], 4),
            "recall_class_1": round(report["1"]["recall"], 4),
            "f1_class_1": round(report["1"]["f1-score"], 4),
        },
        "disclaimer": (
            "This model is trained on synthetic behavioral spending data for "
            "MindPay demonstration. It is not an empirically validated psychological "
            "impulse diagnostic tool."
        ),
    }

    metadata_path = os.path.join(model_dir, "model_metadata.json")
    with open(metadata_path, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"Metadata saved to {metadata_path}")

    return pipeline, metadata


if __name__ == "__main__":
    train_and_save_model()
