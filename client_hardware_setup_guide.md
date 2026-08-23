# Smart Plant Care - Client Hardware Setup Guide

This guide provides foolproof, coordinate-based instructions for assembling the physical hardware on a standard breadboard.

## 1. ESP32 Microcontroller Placement
| Action | Instruction |
| :--- | :--- |
| **Orientation** | Hold the ESP32 with the silver USB port facing **UP**. |
| **Placement** | Align the top-left pin (labeled `3V3`) with hole **J10**. |
| **Insertion** | Push the left side of the ESP32 into Column J (Rows 10 through 28). |
| **Overhang** | Let the entire right side of the ESP32 **hang completely off the right edge** of the breadboard in the air. |

## 2. Power Rails Setup
| Wire From (ESP32 Side) | Wire To (Breadboard Rail) | Purpose |
| :--- | :--- | :--- |
| Hole **I10** (next to 3V3) | **Red (+)** column (Left edge) | Provides 3.3V power to the board |
| Hole **I11** (next to GND) | **Blue (-)** column (Left edge) | Provides Ground to the board |

## 3. Light Sensor (LDR) Circuit
| Component | Pin / Leg | Breadboard Coordinate / Destination |
| :--- | :--- | :--- |
| **LDR (Light Sensor)** | Leg 1 | **C25** |
| | Leg 2 | **C27** |
| **Power Wire** | End 1 | **Red (+)** column |
| | End 2 | **A25** |
| **Resistor (10k Ohm)** | Leg 1 | **Blue (-)** column |
| | Leg 2 | **A27** |
| **Signal Wire** | End 1 | **E27** |
| | End 2 | **D35** (11th pin down on the hanging side of ESP32) |

## 4. Temperature & Humidity Sensor (DHT22/DHT11)
| Sensor Wire | Destination |
| :--- | :--- |
| **`+` (VCC)** | **Red (+)** column |
| **`-` (GND)** | **Blue (-)** column |
| **`out` (DATA)** | Hole **I14** (next to D4 on ESP32) |

## 5. Soil Moisture Sensor (LM393)
| Sensor Pin | Destination |
| :--- | :--- |
| **Fork Probe Pins (x2)** | Bottom 2 pins of the blue LM393 board |
| **VCC (LM393 top)** | **Red (+)** column |
| **GND (LM393 top)** | **Blue (-)** column |
| **A0 (LM393 top)** | **D34** (12th pin down on the hanging side of ESP32, right below D35) |
