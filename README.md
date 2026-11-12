# Smart Plant Care System with AI-Based Monitoring and Mobile App

**Virtual University CS619 Final Year Project**  
**Student:** Amna Rafaqat | **Group ID:** BC220401947  
**Supervisor:** Waqas Ahmad (`waqas.ahmad@vu.edu.pk`)  
**Repository:** [AmnaRafaqat/smart-plant-care](https://github.com/AmnaRafaqat/smart-plant-care)

---

## 🌿 System Overview
An intelligent IoT and AI-driven plant monitoring system that continuously tracks soil moisture, temperature, humidity, and light intensity, stores telemetry securely in Cloud Firestore, predicts watering requirements using machine learning, and alerts the user through push notifications and an intuitive mobile dashboard.

### 🌟 Key Deliverables
- **Hardware Layer:** ESP32 main station (GPIO 34 Soil, GPIO 35 LDR, GPIO 4 DHT11, GPIO 18 Relay) + ESP32-CAM live streamer.
- **Backend Layer:** Firebase Cloud Functions (Node.js v2) + Cloud Firestore with role-based security rules.
- **AI / ML Layer:** Python Flask service with Scikit-learn Linear Regression for predictive watering curves.
- **Mobile Front-End:** Flutter mobile application with real-time Firestore synchronization, FCM push notifications, interactive `fl_chart` trend graphs, and remote pump control.
- **Deliverables & Report Template:** Official VU CS619 Final Project Report template (`FRTemplate.txt`) and LMS submission guide.

---

## 📁 Repository Structure

* **[`smart_plant_care/`](./smart_plant_care/)** - Complete source code package:
  * **[`esp32_firmware/`](./smart_plant_care/esp32_firmware/)** - ESP32 firmware supporting Cloud Functions (`addReading`) and RTDB fallback.
  * **[`esp32_cam_firmware/`](./smart_plant_care/esp32_cam_firmware/)** - ESP32-CAM video streaming server.
  * **[`cloud_functions/`](./smart_plant_care/cloud_functions/)** - Node.js Firebase functions (`addReading`, `onReadingCreated`, `triggerPump`, `getPumpCommand`, `getPrediction`).
  * **[`ml_service/`](./smart_plant_care/ml_service/)** - Python/Scikit-learn AI watering prediction microservice with Dockerfile.
  * **[`flutter_app/`](./smart_plant_care/flutter_app/)** - Upgraded Flutter mobile application implementing all 10 Functional Requirements.
  * **[`deliverables/`](./smart_plant_care/deliverables/)** - VU CS619 Final Report template and submission documents.
* **[`plant_monitor/`](./plant_monitor/)** - Standalone Arduino sketch folder for the main ESP32 station.
* **[`esp32_cam_streamer/`](./esp32_cam_streamer/)** - Standalone Arduino sketch folder for ESP32-CAM streaming.
* **[`client_hardware_setup_guide.md`](./client_hardware_setup_guide.md)** - Step-by-step breadboard assembly and wiring guide.
* **[`install_arduino_dependencies.ps1`](./install_arduino_dependencies.ps1)** - Automated PowerShell script to install ESP32 Arduino cores and libraries.

---

## ⚡ Quick Start

### Hardware
1. Connect ESP32 DevKit to PC via Micro-USB.
2. Open [`plant_monitor/plant_monitor.ino`](./plant_monitor/plant_monitor.ino) in Arduino IDE.
3. Select board `DOIT ESP32 DEVKIT V1` and the active COM port, then click **Upload**.

### Backend & Cloud Functions
```bash
cd smart_plant_care/cloud_functions
npm install
firebase deploy --only functions
```

### ML Microservice
```bash
cd smart_plant_care/ml_service
pip install -r requirements.txt
python app.py
```

### Mobile Application
```bash
cd smart_plant_care/flutter_app
flutter pub get
flutter run
```

---

## 📋 Academic Compliance (CS619 Deliverables)
All 10 Functional Requirements (FR-01 to FR-10) and 4 Non-Functional Requirements (NFR-01 to NFR-04) specified in the approved SRS and Design Document are fully implemented and verified.
