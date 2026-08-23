/*
  Smart Plant Care System - ESP32 Firmware (Prototype Phase)
  ------------------------------------------------------------
  Reads: Soil Moisture (analog), DHT22 Temperature & Humidity, LDR (light)
  Sends readings to Firebase Realtime Database every 15 seconds.

  Required Libraries (install via Arduino IDE -> Sketch -> Include Library -> Manage Libraries):
    1. DHT sensor library (by Adafruit)
    2. Adafruit Unified Sensor (dependency of DHT library)
    3. ArduinoJson (by Benoit Blanchon)

  Board setup: Tools -> Board -> ESP32 Arduino -> "ESP32 Dev Module"
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// ---------- USER CONFIG: EDIT THESE ----------
const char* WIFI_SSID     = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase Realtime Database URL (from Firebase Console -> Realtime Database)
// Example: https://smartplantcare-default-rtdb.firebaseio.com
const char* FIREBASE_HOST = "https://smart-plant-care-342d6-default-rtdb.asia-southeast1.firebasedatabase.app";

// Path where sensor data will be stored, e.g. plants/plant1/sensorData
const char* FIREBASE_PATH = "plants/plant1/sensorData.json";
// ----------------------------------------------

// ---------- PIN CONFIG ----------
#define SOIL_MOISTURE_PIN 34   // Analog pin (ADC1)
#define LDR_PIN           35   // Analog pin (ADC1)
#define DHT_PIN           4    // Digital pin
#define DHT_TYPE          DHT22

DHT dht(DHT_PIN, DHT_TYPE);

const unsigned long SEND_INTERVAL_MS = 15000; // send every 15 seconds
unsigned long lastSendTime = 0;

void setup() {
  Serial.begin(115200);
  dht.begin();
  connectToWiFi();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  if (millis() - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = millis();
    readAndSendSensorData();
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
    Serial.println("\nWiFi connection failed. Will retry in loop.");
  }
}

void readAndSendSensorData() {
  // --- Read raw sensor values ---
  int soilRaw = analogRead(SOIL_MOISTURE_PIN);   // 0 (wet) - 4095 (dry) on ESP32 ADC
  int lightRaw = analogRead(LDR_PIN);            // 0 (bright) - 4095 (dark) depending on wiring
  float temperature = dht.readTemperature();     // Celsius
  float humidity = dht.readHumidity();           // %

  // Convert soil raw value to percentage (calibrate these min/max after testing your sensor in dry/wet soil)
  int soilPercent = map(soilRaw, 4095, 1200, 0, 100);
  soilPercent = constrain(soilPercent, 0, 100);

  // Convert light raw value to percentage (0% dark - 100% bright); calibrate as needed
  int lightPercent = map(lightRaw, 4095, 0, 0, 100);
  lightPercent = constrain(lightPercent, 0, 100);

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read from DHT sensor! Skipping this cycle.");
    return;
  }

  Serial.println("---- Sensor Readings ----");
  Serial.printf("Soil Moisture: %d%%\n", soilPercent);
  Serial.printf("Light: %d%%\n", lightPercent);
  Serial.printf("Temperature: %.1f C\n", temperature);
  Serial.printf("Humidity: %.1f %%\n", humidity);

  sendToFirebase(soilPercent, lightPercent, temperature, humidity);
}

void sendToFirebase(int soilPercent, int lightPercent, float temperature, float humidity) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("No WiFi connection, cannot send data.");
    return;
  }

  HTTPClient http;
  String url = String(FIREBASE_HOST) + "/" + String(FIREBASE_PATH);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Build JSON payload
  StaticJsonDocument<256> doc;
  doc["soilMoisture"] = soilPercent;
  doc["light"] = lightPercent;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["timestamp"] = millis();

  String payload;
  serializeJson(doc, payload);

  // PUT overwrites the data at this path with the latest reading (simplest for prototype)
  int httpResponseCode = http.PUT(payload);

  if (httpResponseCode > 0) {
    Serial.printf("Firebase response code: %d\n", httpResponseCode);
  } else {
    Serial.printf("Error sending data: %s\n", http.errorToString(httpResponseCode).c_str());
  }

  http.end();
}
