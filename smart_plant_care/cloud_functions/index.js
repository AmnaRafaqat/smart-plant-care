/*
  Smart Plant Care System - Cloud Functions (FINAL PHASE)
  -----------------------------------------------------------
  Implements the backend/cloud layer from Design Document Section 4.2:
    - addReading        : ESP32 POSTs sensor data here -> stored in Firestore (FR-01, FR-02)
    - onReadingCreated   : Firestore trigger -> checks thresholds -> sends FCM push (FR-06)
    - triggerPump        : called from the Flutter app when user taps "Water Now" (FR-09)
    - getPumpCommand     : ESP32 polls this to see if a pump command is pending (FR-09)
    - ackPumpCommand     : ESP32 calls this after running the pump, to clear the flag
    - getPrediction      : proxies a request to the Python ML service (FR-07, FR-08)

  Firestore structure:
    plants/{plantId}                -> { name, type, ownerId, minMoisture, maxMoisture,
                                          minTemp, maxTemp, minLight, maxLight,
                                          pumpEnabled, pumpCommand, pumpOn }
    plants/{plantId}/readings/{id}  -> { soilMoisture, light, temperature, humidity, timestamp }
    plants/{plantId}/alerts/{id}    -> { message, level, timestamp }
    users/{uid}                     -> { fcmToken, selectedPlantId }

  Deploy: from this folder run `firebase deploy --only functions`
*/

const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const axios = require("axios");

initializeApp();
const db = getFirestore();

// URL of the Python ML prediction service (see ml_service/ folder).
// Local emulator: FUNCTIONS_EMULATOR is set automatically; override with ML_SERVICE_URL if needed.
// Production: set ML_SERVICE_URL to the deployed service, e.g. Cloud Run .../predict
const ML_SERVICE_URL =
  process.env.ML_SERVICE_URL ||
  (process.env.FUNCTIONS_EMULATOR
    ? "http://127.0.0.1:8080/predict"
    : "https://YOUR-ML-SERVICE-URL/predict");

// ---------------- FR-01 / FR-02: receive readings from ESP32 ----------------
exports.addReading = onRequest({ cors: true }, async (req, res) => {
  try {
    const { plantId, soilMoisture, light, temperature, humidity } = req.body;

    if (!plantId || soilMoisture === undefined || temperature === undefined) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    await db
      .collection("plants")
      .doc(plantId)
      .collection("readings")
      .add({
        soilMoisture,
        light,
        temperature,
        humidity,
        timestamp: FieldValue.serverTimestamp(),
      });

    // Keep a quick "latest reading" copy on the plant doc for a fast dashboard read
    await db.collection("plants").doc(plantId).set(
      {
        latestReading: {
          soilMoisture,
          light,
          temperature,
          humidity,
          timestamp: FieldValue.serverTimestamp(),
        },
      },
      { merge: true }
    );

    return res.status(200).json({ status: "ok" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal error" });
  }
});

// ---------------- FR-06: threshold check + push notification ----------------
exports.onReadingCreated = onDocumentCreated(
  "plants/{plantId}/readings/{readingId}",
  async (event) => {
    const reading = event.data.data();
    const plantId = event.params.plantId;

    const plantSnap = await db.collection("plants").doc(plantId).get();
    if (!plantSnap.exists) return;
    const plant = plantSnap.data();

    const alerts = [];
    const minMoist = plant.minMoisture ?? 20;
    const maxMoist = plant.maxMoisture ?? 80;
    if (reading.soilMoisture < minMoist) {
      const level = reading.soilMoisture < minMoist * 0.5 ? "critical" : "warning";
      alerts.push({
        message: `Soil moisture low (${reading.soilMoisture}%) for ${plant.name || plantId}`,
        level,
      });
    }
    if (reading.soilMoisture > maxMoist) {
      alerts.push({
        message: `Soil moisture too high (${reading.soilMoisture}%) for ${plant.name || plantId}`,
        level: "critical",
      });
    }
    if (plant.minTemp !== undefined && reading.temperature < plant.minTemp) {
      alerts.push({
        message: `Temperature too low (${reading.temperature}°C) for ${plant.name || plantId}`,
        level: "critical",
      });
    }
    if (plant.maxTemp !== undefined && reading.temperature > plant.maxTemp) {
      alerts.push({
        message: `Temperature too high (${reading.temperature}°C) for ${plant.name || plantId}`,
        level: "critical",
      });
    }
    if (plant.minLight !== undefined && reading.light < plant.minLight) {
      alerts.push({
        message: `Light too low (${reading.light}%) for ${plant.name || plantId}`,
        level: "warning",
      });
    }
    if (plant.maxLight !== undefined && reading.light > plant.maxLight) {
      alerts.push({
        message: `Light too high (${reading.light}%) for ${plant.name || plantId}`,
        level: "warning",
      });
    }

    if (alerts.length === 0) return;

    for (const alert of alerts) {
      await db.collection("plants").doc(plantId).collection("alerts").add({
        message: alert.message,
        level: alert.level,
        timestamp: FieldValue.serverTimestamp(),
      });
    }

    // Send FCM push if the owner has a registered device token
    if (plant.ownerId) {
      const userSnap = await db.collection("users").doc(plant.ownerId).get();
      const fcmToken = userSnap.exists ? userSnap.data().fcmToken : null;
      if (fcmToken) {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: "Plant Alert",
            body: alerts[0].message,
          },
        });
      }
    }
  }
);

// ---------------- FR-09: pump control ----------------
exports.triggerPump = onRequest({ cors: true }, async (req, res) => {
  try {
    const { plantId, mode } = req.body;
    if (!plantId) return res.status(400).json({ error: "plantId required" });

    if (mode === "on") {
      await db.collection("plants").doc(plantId).set(
        { pumpOn: true, pumpCommand: false },
        { merge: true }
      );
      return res.status(200).json({ status: "pump on" });
    }
    if (mode === "off") {
      await db.collection("plants").doc(plantId).set(
        { pumpOn: false, pumpCommand: false },
        { merge: true }
      );
      return res.status(200).json({ status: "pump off" });
    }

    await db.collection("plants").doc(plantId).set(
      { pumpCommand: true },
      { merge: true }
    );
    return res.status(200).json({ status: "pump command queued" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal error" });
  }
});

exports.getPumpCommand = onRequest({ cors: true }, async (req, res) => {
  try {
    const plantId = req.query.plantId;
    if (!plantId) return res.status(400).json({ error: "plantId required" });

    const snap = await db.collection("plants").doc(plantId).get();
    const data = snap.exists ? snap.data() : {};
    const holdOn = !!data.pumpOn;
    const pulse = !!data.pumpCommand;
    return res.status(200).json({
      pumpOn: holdOn || pulse,
      holdOn,
      pulse,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal error" });
  }
});

exports.ackPumpCommand = onRequest({ cors: true }, async (req, res) => {
  try {
    const plantId = req.query.plantId;
    if (!plantId) return res.status(400).json({ error: "plantId required" });

    await db.collection("plants").doc(plantId).set(
      { pumpCommand: false, lastWatered: FieldValue.serverTimestamp() },
      { merge: true }
    );
    return res.status(200).json({ status: "ack" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal error" });
  }
});

// ---------------- FR-07 / FR-08: AI watering prediction proxy ----------------
exports.getPrediction = onRequest({ cors: true }, async (req, res) => {
  try {
    const plantId = req.query.plantId;
    if (!plantId) return res.status(400).json({ error: "plantId required" });

    const plantSnap = await db.collection("plants").doc(plantId).get();
    const plant = plantSnap.exists ? plantSnap.data() : {};

    const readingsSnap = await db
      .collection("plants")
      .doc(plantId)
      .collection("readings")
      .orderBy("timestamp", "desc")
      .limit(200)
      .get();

    const readings = readingsSnap.docs.map((d) => {
      const data = d.data();
      return {
        soilMoisture: data.soilMoisture,
        timestamp: data.timestamp ? data.timestamp.toMillis() : Date.now(),
      };
    });

    if (readings.length < 5) {
      return res.status(200).json({
        available: false,
        message: "Not enough history yet. Need at least a few days of readings.",
      });
    }

    const mlResponse = await axios.post(ML_SERVICE_URL, {
      readings,
      minMoisture: plant.minMoisture ?? 30,
    });
    return res.status(200).json({ available: true, ...mlResponse.data });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Prediction service unavailable" });
  }
});
