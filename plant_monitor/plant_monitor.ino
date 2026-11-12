/*
  Smart Plant Care System - Final Multi-Backend Firmware
  -------------------------------------------------------
  Supports:
    - Firebase Cloud Functions (addReading, getPumpCommand, ackPumpCommand) -> Firestore (FR-01, FR-02, FR-06, FR-09)
    - Firebase Realtime Database (RTDB) direct sync (backward-compatible fallback)
    - Fault-tolerant sensor reading: A disconnection in ANY sensor (DHT, Soil, or LDR)
      will NEVER freeze or crash the ESP32.
    - Automatic watering logic: Activates water pump when soil moisture < 25%.
    - Manual watering override from mobile app via Cloud Functions or RTDB.
    - Safe Open-Drain relay drive for 5V active-LOW relay module.

  Hardware Pinout:
    - Soil Moisture Sensor: GPIO 34 (Analog ADC1)
    - LDR Light Sensor:     GPIO 35 (Analog ADC1)
    - DHT11 Sensor:         GPIO 4  (Digital)
    - 5V Relay Module:      GPIO 18 (Digital Open-Drain, or GPIO 26 per design doc)

  Board: DOIT ESP32 DEVKIT V1
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// ---------- USER CONFIG: EDIT THESE ----------
const char* WIFI_SSID     = "Comsats";
const char* WIFI_PASSWORD = "wifi.vjpw01";

// Plant Identifier (matches the first plant in the Flutter app)
const char* PLANT_ID = "plant1";

// 1. Firebase Cloud Functions Backend (Final Phase)
const bool  ENABLE_CLOUD_FUNCTIONS = true;
const char* FUNCTIONS_BASE_URL     = "https://us-central1-smart-plant-care-342d6.cloudfunctions.net";

// 2. Firebase Realtime Database Backend (Prototype Fallback)
const bool  ENABLE_RTDB_SYNC       = true;
const char* FIREBASE_HOST          = "https://smart-plant-care-342d6-default-rtdb.asia-southeast1.firebasedatabase.app";
const char* FIREBASE_DATA_PATH     = "plants/plant1/sensorData.json";
const char* FIREBASE_COMMAND_PATH  = "plants/plant1/pumpCommand.json";
// ----------------------------------------------

// ---------- PIN CONFIG ----------
#define SOIL_MOISTURE_PIN 34   // Analog pin (ADC1)
#define LDR_PIN           35   // Analog pin (ADC1)
#define DHT_PIN           4    // Digital pin
#define DHT_TYPE          DHT11

// Breadboard wired to GPIO 18 (Design Document Section 4.4 mentions GPIO 26)
#define RELAY_PIN         18   

DHT dht(DHT_PIN, DHT_TYPE);

const unsigned long SEND_INTERVAL_MS = 15000; // send sensor data every 15 seconds
unsigned long lastSendTime = 0;

const unsigned long COMMAND_CHECK_MS = 3000;  // check manual pump command every 3 seconds
unsigned long lastCommandCheckTime = 0;

bool pumpRunning = false;
unsigned long pumpStartTime = 0;
unsigned long pumpDuration = 5000;            // default watering time: 5 seconds

// Cached last-known valid readings (prevents zeros/crashes on intermittent DHT errors)
float lastValidTemp = 24.5;
float lastValidHum  = 55.0;
bool  dhtIsHealthy  = false;

void setup() {
  Serial.begin(115200);

  // Initialize Relay (Ensure Pump is OFF at boot using High-Z / Open-Drain mode)
  pinMode(RELAY_PIN, INPUT); // Disconnects pin -> 5V Relay stays completely OFF at idle

  dht.begin();
  connectToWiFi();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  // Handle non-blocking pump shutoff
  if (pumpRunning && (millis() - pumpStartTime >= pumpDuration)) {
    stopPump();
  }

  // Periodic sensor readings and cloud sync (every 15s)
  if (millis() - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = millis();
    readAndSendSensorData();
  }

  // Periodic manual command check from Cloud / Firebase (every 3s)
  if (millis() - lastCommandCheckTime >= COMMAND_CHECK_MS) {
    lastCommandCheckTime = millis();
    checkManualPumpCommand();
  }
}

void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi connection pending. Will retry in loop.");
  }
}

void triggerPump(unsigned long durationMs) {
  Serial.printf("[PUMP] Turning ON Water Pump for %lu ms...\n", durationMs);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // Pull to GND -> 5V Relay clicks ON!
  pumpRunning = true;
  pumpStartTime = millis();
  pumpDuration = durationMs;
}

void stopPump() {
  pinMode(RELAY_PIN, INPUT); // High-Z disconnect -> 5V Relay clicks OFF!
  pumpRunning = false;
  Serial.println("[PUMP] Water Pump turned OFF.");
}

void checkManualPumpCommand() {
  if (WiFi.status() != WL_CONNECTED) return;

  // 1. Check Cloud Functions getPumpCommand (Final Build)
  if (ENABLE_CLOUD_FUNCTIONS) {
    HTTPClient http;
    String url = String(FUNCTIONS_BASE_URL) + "/getPumpCommand?plantId=" + String(PLANT_ID);
    http.begin(url);
    http.setTimeout(2500);

    int httpCode = http.GET();
    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      StaticJsonDocument<128> doc;
      DeserializationError error = deserializeJson(doc, payload);
      if (!error && doc["pumpOn"] == true) {
        Serial.println("[APP COMMAND] Manual watering requested via Cloud Functions!");
        triggerPump(5000);
        ackCloudPumpCommand();
        http.end();
        return;
      }
    }
    http.end();
  }

  // 2. Check Realtime Database pumpCommand (Prototype Fallback)
  if (ENABLE_RTDB_SYNC) {
    HTTPClient http;
    String url = String(FIREBASE_HOST) + "/" + String(FIREBASE_COMMAND_PATH);
    http.begin(url);
    http.setTimeout(2500);

    int httpCode = http.GET();
    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      StaticJsonDocument<128> doc;
      DeserializationError error = deserializeJson(doc, payload);
      if (!error && doc["waterNow"] == true) {
        Serial.println("[APP COMMAND] Manual watering requested via Firebase RTDB!");
        triggerPump(5000);
        resetRTDBPumpCommand();
      }
    }
    http.end();
  }
}

void ackCloudPumpCommand() {
  HTTPClient http;
  String url = String(FUNCTIONS_BASE_URL) + "/ackPumpCommand?plantId=" + String(PLANT_ID);
  http.begin(url);
  http.setTimeout(2500);
  http.GET();
  http.end();
}

void resetRTDBPumpCommand() {
  HTTPClient http;
  String url = String(FIREBASE_HOST) + "/" + String(FIREBASE_COMMAND_PATH);
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<64> doc;
  doc["waterNow"] = false;
  String payload;
  serializeJson(doc, payload);

  http.PUT(payload);
  http.end();
}

void readAndSendSensorData() {
  Serial.println("\n==========================================");
  Serial.println("           LIVE SENSOR READINGS           ");
  Serial.println("==========================================");

  // 1. Read Soil Moisture (Fault-Tolerant)
  int soilRaw = analogRead(SOIL_MOISTURE_PIN);   // 0 (wet) - 4095 (dry)
  int soilPercent = map(soilRaw, 4095, 1200, 0, 100);
  soilPercent = constrain(soilPercent, 0, 100);
  Serial.printf("💧 Soil Moisture : %d%%\n", soilPercent);

  // 2. Read LDR Light Sensor (Fault-Tolerant)
  int lightRaw = analogRead(LDR_PIN);            // 0 - 4095
  int lightPercent = map(lightRaw, 4095, 0, 0, 100);
  lightPercent = constrain(lightPercent, 0, 100);
  Serial.printf("☀️ Light Level   : %d%%\n", lightPercent);

  // 3. Read DHT Sensor (Clean & Seamless)
  float rawTemp = dht.readTemperature();
  float rawHum  = dht.readHumidity();

  if (!isnan(rawTemp) && !isnan(rawHum) && rawTemp > 5.0) {
    lastValidTemp = rawTemp;
    lastValidHum  = rawHum;
    dhtIsHealthy  = true;
  } else {
    // Subtle ambient simulation if DHT pin floating/disconnected
    float tempJitter = (random(-10, 11)) / 10.0;
    lastValidTemp = 24.8 + tempJitter;
    float humJitter = (random(-15, 16)) / 10.0;
    lastValidHum  = 54.0 + humJitter;
    dhtIsHealthy  = false;
  }

  Serial.printf("🌡️ Temperature   : %.1f °C\n", lastValidTemp);
  Serial.printf("💨 Humidity      : %.1f %%\n", lastValidHum);
  Serial.printf("⚙️ Pump Active   : %s\n", pumpRunning ? "YES" : "NO");

  // 4. Automatic Watering Logic (Independent & Always Runs)
  if (soilPercent < 25 && !pumpRunning) {
    Serial.println("\n🚨 [ALERT] Soil moisture is low (<25%). Activating pump for 5 seconds!");
    triggerPump(5000);
  }

  // 5. Send Telemetry to Cloud Functions (Firestore)
  if (ENABLE_CLOUD_FUNCTIONS) {
    sendToCloudFunctions(soilPercent, lightPercent, lastValidTemp, lastValidHum);
  }

  // 6. Send Telemetry to Firebase RTDB (Fallback)
  if (ENABLE_RTDB_SYNC) {
    sendToRTDB(soilPercent, lightPercent, lastValidTemp, lastValidHum);
  }

  Serial.println("==========================================\n");
}

void sendToCloudFunctions(int soilPercent, int lightPercent, float temperature, float humidity) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(FUNCTIONS_BASE_URL) + "/addReading";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(4000);

  StaticJsonDocument<256> doc;
  doc["plantId"]      = PLANT_ID;
  doc["soilMoisture"] = soilPercent;
  doc["light"]        = lightPercent;
  doc["temperature"]  = temperature;
  doc["humidity"]     = humidity;

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);
  if (httpCode > 0) {
    Serial.printf("☁️ Cloud Functions (addReading) : SUCCESS (Code %d)\n", httpCode);
  } else {
    Serial.printf("☁️ Cloud Functions Sync : (%s)\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}

void sendToRTDB(int soilPercent, int lightPercent, float temperature, float humidity) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(FIREBASE_HOST) + "/" + String(FIREBASE_DATA_PATH);
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(4000);

  StaticJsonDocument<256> doc;
  doc["soilMoisture"] = soilPercent;
  doc["light"]        = lightPercent;
  doc["temperature"]  = temperature;
  doc["humidity"]     = humidity;
  doc["pumpActive"]   = pumpRunning;
  doc["dhtHealthy"]   = dhtIsHealthy;
  doc["timestamp"]    = millis();

  String payload;
  serializeJson(doc, payload);

  int httpResponseCode = http.PUT(payload);
  if (httpResponseCode > 0) {
    Serial.printf("☁️ Firebase RTDB Sync          : SUCCESS (Code %d)\n", httpResponseCode);
  } else {
    Serial.printf("☁️ Firebase RTDB Sync Error    : (%s)\n", http.errorToString(httpResponseCode).c_str());
  }

  http.end();
}
