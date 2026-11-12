# Smart Plant Care System with AI-Based Monitoring and Mobile App

**Virtual University CS619 Final Year Project**  
**Student:** Amna Rafaqat | **Group ID:** BC220401947  
**Supervisor:** Waqas Ahmad (`waqas.ahmad@vu.edu.pk`)

---

## 📌 Project Overview
The **Smart Plant Care System** is an end-to-end IoT, Cloud, Mobile, and Machine Learning solution designed to automate indoor plant monitoring, predict watering needs, and provide remote care assistance.

### Implemented Functional Requirements (FR-01 to FR-10)
| ID | Requirement | Implementation | Status |
|:---|:---|:---|:---:|
| **FR-01** | Sensor Data Collection | ESP32 reading Soil Moisture, LDR Light, DHT11 Temp/Humidity | ✅ Completed |
| **FR-02** | Real-Time Data Transmission | HTTPS telemetry upload to Firebase backend every 15s | ✅ Completed |
| **FR-03** | User Registration & Login | Firebase Authentication (Email/Password) | ✅ Completed |
| **FR-04** | Plant Profile Management | Firestore database per-plant customization (name, species, safe thresholds) | ✅ Completed |
| **FR-05** | Live Dashboard | Auto-refreshing sensor readings colour-coded by safe/warning/critical | ✅ Completed |
| **FR-06** | Automated Alerts & Push Notifications | Firebase Cloud Function (`onReadingCreated`) + Firebase Cloud Messaging (FCM) | ✅ Completed |
| **FR-07** | AI Recommendation System | Scikit-learn Linear Regression model analysing soil moisture decay curves | ✅ Completed |
| **FR-08** | Watering Time Prediction | Flask ML Service computing exact predicted hours/time to next watering threshold | ✅ Completed |
| **FR-09** | Remote Pump Control / Manual Override | 5V Relay module + Submersible pump with in-app "Water Now" override | ✅ Completed |
| **FR-10** | Historical Trends & Charts | Flutter interactive graphs (`fl_chart`) over 7-day and 30-day time ranges | ✅ Completed |

---

## 📁 System Architecture & Directory Structure

```
smart_plant_care/
├── esp32_firmware/
│   └── plant_monitor.ino         # Multi-backend firmware (Cloud Functions + RTDB fallback)
├── esp32_cam_firmware/
│   └── esp32_cam_firmware.ino    # ESP32-CAM MJPEG video streaming server
├── cloud_functions/              # Node.js Firebase Cloud Functions (v2)
│   ├── index.js                  # addReading, onReadingCreated, triggerPump, getPumpCommand, getPrediction
│   ├── package.json
│   └── package-lock.json
├── ml_service/                   # Python / Scikit-learn AI Prediction Microservice
│   ├── app.py                    # Flask REST endpoint (/predict)
│   ├── requirements.txt          # flask, scikit-learn, numpy, gunicorn
│   └── Dockerfile                # Production container deployment for Google Cloud Run
├── flutter_app/                  # Flutter 3.x Cross-Platform Mobile Application
│   ├── lib/
│   │   ├── main.dart             # App entry, routing, and Firebase initialisation
│   │   ├── app_config.dart       # Cloud Functions base URL configuration
│   │   ├── firebase_options.dart # Firebase credentials for smart-plant-care-342d6
│   │   ├── plant_controller.dart # Multi-plant state management and Firestore synchronisation
│   │   ├── plant_status.dart     # Threshold calculation and safe/warning/critical level helpers
│   │   └── screens/
│   │       ├── home_screen.dart          # Live dashboard and main navigation hub
│   │       ├── login_screen.dart         # User authentication
│   │       ├── signup_screen.dart        # New account registration
│   │       ├── plant_profile_screen.dart # Thresholds, plant species, and pump enablement
│   │       ├── history_screen.dart       # fl_chart historical trend lines (FR-10)
│   │       ├── alerts_screen.dart        # FCM push alert log and breach history (FR-06)
│   │       ├── pump_control_screen.dart  # Relay toggle and manual "Water Now" pulse (FR-09)
│   │       └── ai_prediction_screen.dart # AI next-watering time and recommendations (FR-07/08)
│   └── pubspec.yaml
├── deliverables/                 # VU CS619 Academic Documentation
│   ├── FRTemplate.txt            # Virtual University Final Project Report Template
│   ├── Application.txt           # LMS Final Submission Guidelines
│   ├── _srs_extract.txt          # Approved Software Requirements Specification
│   └── _design_extract.txt       # Approved System Design Document
├── firestore.rules               # Firestore per-user security rules (NFR-03)
├── firebase.json                 # Firebase deployment configuration
└── .firebaserc                   # Firebase project binding
```

---

## 🚀 Step-by-Step Deployment Guide

### 1. Firebase Cloud Setup
1. Open the [Firebase Console](https://console.firebase.google.com) and navigate to project `smart-plant-care-342d6`.
2. Ensure **Authentication** (Email/Password provider) is enabled.
3. In **Firestore Database**, navigate to **Rules** and deploy the security rules from `firestore.rules`.
4. Ensure **Firebase Cloud Messaging (FCM)** API is enabled in Project Settings for push notifications.

### 2. Deploy Cloud Functions
From the `smart_plant_care/cloud_functions` directory:
```bash
npm install
firebase deploy --only functions
```
The deployed endpoint URL will be:
`https://us-central1-smart-plant-care-342d6.cloudfunctions.net`

### 3. Deploy Python ML Microservice
The prediction service runs a lightweight Scikit-learn Linear Regression model trained on recent soil moisture readings.
- **Local Testing:**
  ```bash
  cd ml_service
  pip install -r requirements.txt
  python app.py
  ```
- **Cloud Run Deployment:**
  ```bash
  cd ml_service
  gcloud run deploy plant-ml-service --source . --region us-central1 --allow-unauthenticated
  ```
  Set the resulting URL in Cloud Functions environment or `cloud_functions/index.js` (`ML_SERVICE_URL`).

### 4. ESP32 Microcontroller Setup
1. Open `esp32_firmware/plant_monitor.ino` in Arduino IDE or PlatformIO.
2. Verify WiFi credentials:
   ```cpp
   const char* WIFI_SSID     = "Comsats";
   const char* WIFI_PASSWORD = "wifi.vjpw01";
   ```
3. Hardware Wiring (Breadboard verified):
   - **Soil Moisture Sensor (AO):** GPIO 34
   - **LDR Light Sensor (AO):** GPIO 35
   - **DHT11 Sensor (Data):** GPIO 4
   - **5V Relay Module (IN):** GPIO 18 (Open-Drain drive mode)
4. Upload to **DOIT ESP32 DEVKIT V1**. Open Serial Monitor at **115200 baud**.

### 5. Flutter Mobile Application Setup
```bash
cd flutter_app
flutter pub get
flutter run
```
Log in or sign up, then configure your plant profile in **Plant Profile** to begin monitoring.
