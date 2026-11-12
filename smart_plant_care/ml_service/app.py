"""
Smart Plant Care System - AI Watering Prediction Service (FINAL PHASE)
------------------------------------------------------------------------
Implements FR-07 (AI-Based Recommendation System) and FR-08 (Watering Prediction).

Approach (matches Design Document Section 3.2 justification):
A lightweight scikit-learn Linear Regression model is trained ON THE FLY for each
request, on that plant's own recent soil-moisture-over-time history. This is a
deliberately simple, low-latency model appropriate for a single-plant, single-user
dataset (per the literature review comparison in the Design Document), rather than
an LSTM/RL pipeline meant for large-scale farms.

The model learns the rate at which soil moisture drops over time, then predicts
the timestamp at which moisture will cross the plant's minimum safe threshold.

Run locally:
    pip install -r requirements.txt
    python app.py

Deploy (recommended): Google Cloud Run (containerize with a simple Dockerfile) or
any host that can run a Flask app; then set ML_SERVICE_URL in cloud_functions/index.js
to the deployed URL + "/predict".
"""

from flask import Flask, request, jsonify
import numpy as np
from sklearn.linear_model import LinearRegression
from datetime import datetime, timedelta

app = Flask(__name__)

DEFAULT_MIN_MOISTURE = 30  # % - overridden by the plant's own profile if provided


@app.route("/predict", methods=["POST"])
def predict():
    payload = request.get_json(force=True)
    readings = payload.get("readings", [])
    min_moisture = payload.get("minMoisture", DEFAULT_MIN_MOISTURE)

    if len(readings) < 5:
        return jsonify({
            "prediction": None,
            "message": "Not enough data points to predict yet."
        }), 200

    # readings come newest-first from Firestore; sort oldest-first for regression
    readings = sorted(readings, key=lambda r: r["timestamp"])

    timestamps = np.array([r["timestamp"] for r in readings]).reshape(-1, 1)
    moisture = np.array([r["soilMoisture"] for r in readings])

    # Normalize timestamps to hours since first reading, for numerical stability
    t0 = timestamps[0][0]
    hours = (timestamps - t0) / (1000 * 60 * 60)

    model = LinearRegression()
    model.fit(hours, moisture)

    slope = model.coef_[0]       # % moisture change per hour
    intercept = model.intercept_

    latest_hour = hours[-1][0]
    latest_moisture = moisture[-1]

    if slope >= 0:
        # Moisture is stable or rising (e.g. was just watered) -> no urgent prediction
        return jsonify({
            "prediction": None,
            "trend": "stable_or_rising",
            "message": "Soil moisture is stable or increasing. No watering needed soon.",
            "currentMoisture": float(latest_moisture),
        }), 200

    # Solve for the hour at which moisture == min_moisture
    hours_to_threshold = (min_moisture - latest_moisture) / slope

    if hours_to_threshold < 0:
        # Already below threshold right now
        predicted_time = datetime.utcnow()
        message = "Soil moisture is already at or below the safe threshold. Water now."
    else:
        predicted_time = datetime.utcnow() + timedelta(hours=float(hours_to_threshold))
        message = f"Plant is predicted to need water in approximately {round(hours_to_threshold, 1)} hours."

    return jsonify({
        "prediction": predicted_time.isoformat() + "Z",
        "hoursUntilWatering": round(float(hours_to_threshold), 1) if hours_to_threshold > 0 else 0,
        "trend": "declining",
        "currentMoisture": float(latest_moisture),
        "dropRatePerHour": round(float(-slope), 3),
        "message": message,
    }), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
