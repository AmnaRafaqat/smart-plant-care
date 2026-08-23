# Smart Plant Care System - Prototype Phase

An end-to-end IoT and Mobile Application solution designed to remotely monitor plant health in real-time. This repository contains the 70% Prototype Phase deliverables, including the ESP32 microcontroller firmware and the Flutter mobile application front-end.

## 📁 Repository Structure

*   **`/smart_plant_care/esp32_firmware/plant_monitor.ino`** - The core C++ firmware for the ESP32 that reads sensors and streams data to Firebase.
*   **`/smart_plant_care/flutter_app/`** - The complete Flutter mobile application featuring User Authentication, Plant Profiles, and a Live Data Dashboard.
*   **`client_hardware_setup_guide.md`** - A foolproof, coordinate-based guide for assembling the physical sensors on a breadboard.
*   **`install_arduino_dependencies.ps1`** - A fully automated setup script to configure the Arduino development environment for the ESP32.

---

## 🛠️ Part 1: Hardware Assembly
Before uploading any code, the physical IoT device must be assembled. 
Please refer strictly to the **[client_hardware_setup_guide.md](./client_hardware_setup_guide.md)** included in this repository for exact breadboard coordinates to connect the DHT22, Soil Moisture Sensor, and Light Sensor (LDR).

---

## 💻 Part 2: ESP32 Firmware Setup

### Automated Setup (Recommended for Windows)
If you are setting this up on a new PC, you can completely automate the installation of the required ESP32 core and libraries:
1. Download and install the standard [Arduino IDE](https://www.arduino.cc/en/software).
2. Right-click **`install_arduino_dependencies.ps1`** and select **Run with PowerShell**.
3. The script will automatically download and configure the heavy ESP32 packages and required libraries (`DHT sensor library`, `Adafruit Unified Sensor`, `ArduinoJson`).

### Configuration & Upload
1. Open `plant_monitor.ino` in the Arduino IDE.
2. Edit **Line 21 & 22** with your local WiFi credentials:
   ```cpp
   const char* WIFI_SSID     = "YOUR_WIFI_NAME";
   const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
   ```
3. Connect the ESP32 via Micro-USB, select **DOIT ESP32 DEVKIT V1** under `Tools -> Board -> esp32`, and select your COM port.
4. Click **Upload**. (Open the Serial Monitor at `115200` baud to verify it connects to WiFi).

---

## 🔥 Part 3: Firebase Configuration
This project utilizes Firebase for seamless cloud communication between the ESP32 and the Flutter app.
1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Enable **Authentication** (Sign-in method -> Email/Password).
3. Create a **Realtime Database** (Start in Test Mode for the prototype).
4. Update the `FIREBASE_HOST` variable in the Arduino code with your database URL.

---

## 📱 Part 4: Flutter Mobile App
The mobile application allows users to view live sensor readings fetched securely from Firebase.

1. Ensure the [Flutter SDK](https://docs.flutter.dev/get-started/install) is installed on your machine.
2. Open a terminal in the `smart_plant_care/flutter_app/` directory and fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application on your connected Android/iOS device or emulator:
   ```bash
   flutter run
   ```

---

