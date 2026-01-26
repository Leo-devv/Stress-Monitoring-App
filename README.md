# Stress Monitor App

## Engineering Thesis: "The Role of AI in Personal Stress Monitoring: A Mobile Cloud Approach"

A Flutter (Android) prototype demonstrating intelligent hybrid Edge/Cloud processing for stress monitoring using simulated WESAD sensor data.

---

## Key Features

### 1. Virtual Sensor Simulator
- Reads WESAD-format sensor data (BVP, EDA, Temperature)
- Emits data points every second to simulate a live wearable
- Manual override sliders for thesis defense demos

### 2. Intelligent Offloading Manager
The "Brain" that decides between Edge and Cloud processing:

```
IF Battery < 20%     → EDGE MODE (TFLite on phone)
IF Battery > 20% + WiFi → CLOUD MODE (Firebase)
```

### 3. Dual AI Processing
- **Edge**: On-device stress inference (simulates TFLite)
- **Cloud**: Firebase Cloud Functions for "heavy" AI

### 4. Android 14 Compliant
- Kotlin ForegroundService with `foregroundServiceType="health"`
- POST_NOTIFICATIONS permission handling

### 5. GDPR Privacy Controls
- "Nuke Data" button to delete all user data
- Data export functionality

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.16+ |
| State Management | Riverpod |
| Charts | fl_chart, syncfusion_gauges |
| Local Storage | Hive |
| Cloud | Firebase (Firestore, Cloud Functions) |
| Native | Kotlin (Foreground Service) |

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Routing & theme
├── core/                        # Constants, utils
├── domain/entities/             # Business entities
├── features/
│   ├── dashboard/               # Main screen with gauge & chart
│   ├── simulation/              # Demo control panel
│   └── settings/                # Privacy & offloading settings
├── services/
│   ├── sensor_simulator_service.dart
│   ├── offloading_manager.dart
│   ├── edge_inference_service.dart
│   └── cloud_inference_service.dart
└── di/                          # Dependency injection

android/app/src/main/kotlin/
└── com/stressmonitor/stress_monitor_app/
    ├── MainActivity.kt          # Flutter ↔ Kotlin bridge
    └── services/
        └── SensorForegroundService.kt

firebase/functions/
├── index.js                     # Cloud Functions
└── package.json
```

---

## Getting Started

### Prerequisites
- Flutter 3.16+
- Android Studio / VS Code
- Firebase CLI (for cloud functions)

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

### Firebase Setup (Optional for full cloud features)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in the project
firebase init

# Deploy Cloud Functions
cd firebase/functions
npm install
firebase deploy --only functions
```

---

## Demo Script (Thesis Defense)

1. **Launch App** → Dashboard shows "Waiting for sensor data"
2. **Go to Simulation Panel** → Tap "Start" to begin data stream
3. **Watch the Chart** → Heart rate data fills in real-time
4. **Test Offloading Logic**:
   - Slide Battery to **15%** → Badge changes to GREEN "EDGE"
   - Slide Battery to **80%** + WiFi ON → Badge changes to BLUE "CLOUD"
5. **Test GDPR Compliance**:
   - Go to Settings → Tap "Delete All My Data"
   - Confirm deletion → All data removed

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                              │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│   ┌─────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│   │   Sensor    │───▶│   Offloading    │───▶│     AI      │ │
│   │  Simulator  │    │    Manager      │    │  Processor  │ │
│   └─────────────┘    └─────────────────┘    └──────┬──────┘ │
│                              │                      │        │
│                    ┌─────────┴─────────┐           │        │
│                    ▼                   ▼           │        │
│            ┌─────────────┐    ┌─────────────┐      │        │
│            │Battery < 20%│    │Battery ≥ 20%│      │        │
│            │  No WiFi    │    │ + WiFi      │      │        │
│            └──────┬──────┘    └──────┬──────┘      │        │
│                   │                  │             │        │
│                   ▼                  ▼             │        │
│            ┌─────────────┐    ┌─────────────┐      │        │
│            │    EDGE     │    │    CLOUD    │◀─────┘        │
│            │  (TFLite)   │    │  (Firebase) │               │
│            └─────────────┘    └─────────────┘               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Screens

| Dashboard | Simulation | Settings |
|-----------|------------|----------|
| Stress gauge, HR chart, live stats | HR/EDA/Temp sliders, battery control | Privacy, offloading strategy |

---

## License

This project is created for academic purposes as part of an Engineering Thesis.

---

## Author

Built with Claude Code for thesis demonstration.
