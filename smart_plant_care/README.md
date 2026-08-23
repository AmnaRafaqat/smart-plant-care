# Smart Plant Care System — Prototype Software

Ye package do parts par mabni hai:

1. **esp32_firmware/plant_monitor.ino** — ESP32 ka code jo sensors se data lekar Firebase mein bhejta hai.
2. **flutter_app/** — Mobile app (Flutter) jo Firebase se live data dikhata hai aur plant profile set karne deta hai.

---

## Part 1: ESP32 Firmware Setup

1. Arduino IDE khol kar `plant_monitor.ino` file open karein.
2. **Board Manager** se ESP32 support add karein (File > Preferences > Additional Board URLs mein ye add karein: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`), phir Tools > Board > Boards Manager se "esp32" install karein.
3. Ye libraries install karein (Sketch > Include Library > Manage Libraries):
   - `DHT sensor library` (by Adafruit)
   - `Adafruit Unified Sensor`
   - `ArduinoJson`
4. Code ke top mein ye values apne hisab se edit karein:
   - `WIFI_SSID`, `WIFI_PASSWORD`
   - `FIREBASE_HOST` (apna Firebase Realtime Database URL)
5. Wiring:
   - Soil Moisture sensor AO pin → GPIO 34
   - LDR module AO pin → GPIO 35
   - DHT22 data pin → GPIO 4
6. Board select karein: Tools > Board > "ESP32 Dev Module", correct COM port select karein.
7. Upload karein aur Serial Monitor (115200 baud) khol kar readings check karein.

## Part 2: Firebase Setup (dono parts ke liye zaroori)

1. [Firebase Console](https://console.firebase.google.com) par project banayein.
2. **Authentication** enable karein → Sign-in method → Email/Password ON karein.
3. **Realtime Database** banayein → Start in **test mode** (prototype ke liye).
4. Database URL copy karein — ye ESP32 code mein `FIREBASE_HOST` mein aur Flutter app config mein use hoga.

## Part 3: Flutter App Setup

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) install karein agar pehle se nahi hai.
2. `flutter_app` folder mein terminal khol kar:
   ```
   flutter pub get
   ```
3. **FlutterFire CLI se Firebase connect karein** (ye zaroori hai, warna app chalega nahi):
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Ye command aap ke Firebase project ko select karne ke baad automatically `firebase_options.dart` file bana degi, aur `main.dart` mein import karna hoga:
   ```dart
   import 'firebase_options.dart';
   ...
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
4. App run karein:
   ```
   flutter run
   ```

## Notes

- Ye prototype-phase code hai — final phase mein AI-based watering prediction, camera module, aur relay/pump control add hoga (abhi include nahi kiya).
- Soil moisture aur light sensor ki `map()` values calibration ke baad adjust karni hongi — apne sensor ko dry/wet soil aur light/dark mein test kar ke min/max values note karein.
- Realtime Database "test mode" security rules sirf development ke liye hain — submission se pehle rules tighten karne ka mention apni report mein karein.
