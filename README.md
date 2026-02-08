# Stress Monitor App

## Engineering Thesis: "Personal Stress Monitoring: An Adaptive Mobile-Cloud System"

A Flutter (Android) application demonstrating adaptive edge-cloud processing for real-time stress monitoring using HRV analysis from BLE heart rate monitors and camera-based PPG.

---

## Key Features

### 1. Dual Sensor Acquisition
- **BLE Heart Rate Monitor**: Connects to standard Bluetooth LE heart rate devices (Polar, Garmin, Wahoo, Xiaomi)
- **Camera PPG**: Measures heart rate through smartphone camera photoplethysmography
- **Simulator**: Demo mode with configurable sensor data for testing

### 2. HRV-Based Stress Classification
Seven HRV features analyzed in real-time:
- RMSSD, SDNN, pNN50 (time-domain)
- LF/HF Ratio, HF Power (frequency-domain)
- Baevsky Stress Index
- Mean Heart Rate

Threshold-based classification into four stress levels: Relaxed, Normal, Elevated, High.

### 3. Adaptive Offloading Manager
Intelligent routing between Edge and Cloud processing:

```
IF Battery < 20%        → EDGE (on-device processing)
IF Battery ≥ 20% + WiFi → CLOUD (Firebase)
IF No WiFi              → EDGE (avoid mobile data)
```

### 4. Android 14 Compliant
- Kotlin ForegroundService with `foregroundServiceType="health"`
- POST_NOTIFICATIONS permission handling
- Minimum SDK 26 (Android 8.0)

### 5. Privacy Controls
- Local data storage with Hive
- Cloud sync to Firebase Firestore
- Data export and deletion options

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.16+ |
| State Management | Riverpod |
| Charts | fl_chart, syncfusion_gauges |
| Local Storage | Hive |
| Cloud | Firebase Firestore |
| Sensors | flutter_blue_plus, camera |
| Native | Kotlin (Foreground Service) |

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Routing & theme
├── core/                        # Constants, utils, theme
├── domain/entities/             # Business entities
├── features/
│   ├── dashboard/               # Main screen with gauge & chart
│   ├── breathing/               # Guided breathing exercises
│   ├── device/                  # BLE/Camera sensor connection
│   ├── history/                 # Stress history view
│   ├── simulation/              # Demo control panel
│   └── settings/                # Privacy & offloading settings
├── services/
│   ├── sensor/                  # BLE, Camera PPG, Simulator sources
│   ├── hrv_computation_service.dart
│   ├── threshold_stress_engine.dart
│   ├── offloading_manager.dart
│   ├── edge_inference_service.dart
│   └── cloud_inference_service.dart
└── di/                          # Dependency injection

android/app/src/main/kotlin/
└── com/stressmonitor/stress_monitor_app/
    ├── MainActivity.kt
    └── services/
        └── SensorForegroundService.kt
```

---

## Getting Started

### Prerequisites
- Flutter 3.16+
- Android Studio / VS Code
- Android device or emulator (API 26+)

### Installation

```bash
# Clone the repo
git clone https://github.com/Leo-devv/Stress-Monitoring-App.git
cd Stress-Monitoring-App

# Install Flutter dependencies
flutter pub get

# Run on Android device/emulator
flutter run
```

### Firebase Setup (Optional)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init

# Select Firestore when prompted
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                             │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐    ┌─────────────────┐    ┌────────────┐  │
│   │   Sensor    │───▶│   Offloading    │───▶│  Stress    │  │
│   │   Manager   │    │    Manager      │    │  Engine    │  │
│   └─────────────┘    └─────────────────┘    └─────┬──────┘  │
│         │                    │                    │         │
│   ┌─────┴─────┐    ┌────────┴────────┐          │         │
│   │           │    │                  │          │         │
│   ▼           ▼    ▼                  ▼          │         │
│ ┌─────┐  ┌──────┐ ┌──────────┐ ┌──────────┐     │         │
│ │ BLE │  │Camera│ │Battery<20│ │Battery≥20│     │         │
│ │ HR  │  │ PPG  │ │ No WiFi  │ │ + WiFi   │     │         │
│ └─────┘  └──────┘ └────┬─────┘ └────┬─────┘     │         │
│                        │            │           │         │
│                        ▼            ▼           │         │
│                  ┌──────────┐ ┌──────────┐      │         │
│                  │   EDGE   │ │  CLOUD   │◀─────┘         │
│                  │(On-Device│ │(Firebase)│                │
│                  └──────────┘ └──────────┘                │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

---

## Screens

| Dashboard | History | Settings |
|-----------|---------|----------|
| Stress gauge, HRV metrics, live chart | Historical stress trends | Offloading strategy, privacy controls |

---

## License

This project is created for academic purposes as part of an Engineering Thesis.

---

## Author

Built for thesis demonstration.
