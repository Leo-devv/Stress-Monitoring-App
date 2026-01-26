import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/sensor_simulator_service.dart';
import '../../../services/offloading_manager.dart';
import '../../../di/injection_container.dart';

// Simulation state for controlling demo parameters
class SimulationState {
  final double heartRate;
  final double eda;
  final double temperature;
  final double batteryLevel;
  final bool isWifiConnected;
  final bool useManualValues;
  final OffloadingStrategy strategy;

  const SimulationState({
    this.heartRate = 72.0,
    this.eda = 2.0,
    this.temperature = 33.0,
    this.batteryLevel = 0.80,
    this.isWifiConnected = true,
    this.useManualValues = false,
    this.strategy = OffloadingStrategy.auto,
  });

  SimulationState copyWith({
    double? heartRate,
    double? eda,
    double? temperature,
    double? batteryLevel,
    bool? isWifiConnected,
    bool? useManualValues,
    OffloadingStrategy? strategy,
  }) {
    return SimulationState(
      heartRate: heartRate ?? this.heartRate,
      eda: eda ?? this.eda,
      temperature: temperature ?? this.temperature,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isWifiConnected: isWifiConnected ?? this.isWifiConnected,
      useManualValues: useManualValues ?? this.useManualValues,
      strategy: strategy ?? this.strategy,
    );
  }

  int get batteryPercentage => (batteryLevel * 100).round();
}

// Simulation notifier
class SimulationNotifier extends StateNotifier<SimulationState> {
  final SensorSimulatorService _sensorService;
  final OffloadingManager _offloadingManager;

  SimulationNotifier({
    required SensorSimulatorService sensorService,
    required OffloadingManager offloadingManager,
  })  : _sensorService = sensorService,
        _offloadingManager = offloadingManager,
        super(const SimulationState());

  void setHeartRate(double value) {
    state = state.copyWith(heartRate: value);
    _updateSensorValues();
  }

  void setEda(double value) {
    state = state.copyWith(eda: value);
    _updateSensorValues();
  }

  void setTemperature(double value) {
    state = state.copyWith(temperature: value);
    _updateSensorValues();
  }

  void setBatteryLevel(double value) {
    state = state.copyWith(batteryLevel: value);
    _offloadingManager.setSimulatedBatteryLevel(value);
  }

  void setWifiConnected(bool value) {
    state = state.copyWith(isWifiConnected: value);
    _offloadingManager.setSimulatedWifiStatus(value);
  }

  void setUseManualValues(bool value) {
    state = state.copyWith(useManualValues: value);
    if (value) {
      _updateSensorValues();
    } else {
      _sensorService.clearManualValues();
    }
  }

  void setStrategy(OffloadingStrategy strategy) {
    state = state.copyWith(strategy: strategy);
    _offloadingManager.strategy = strategy;
  }

  void _updateSensorValues() {
    if (state.useManualValues) {
      _sensorService.setManualValues(
        bvp: state.heartRate,
        eda: state.eda,
        temperature: state.temperature,
      );
    }
  }

  void injectReading() {
    _sensorService.injectManualReading(
      bvp: state.heartRate,
      eda: state.eda,
      temperature: state.temperature,
    );
  }

  void resetToDefaults() {
    state = const SimulationState();
    _sensorService.clearManualValues();
    _offloadingManager.setSimulatedBatteryLevel(null);
    _offloadingManager.setSimulatedWifiStatus(null);
    _offloadingManager.strategy = OffloadingStrategy.auto;
  }

  // Preset scenarios for demo
  void applyPreset(DemoPreset preset) {
    switch (preset) {
      case DemoPreset.relaxed:
        state = state.copyWith(
          heartRate: 65,
          eda: 1.0,
          temperature: 32.5,
          batteryLevel: 0.80,
          isWifiConnected: true,
        );
        break;
      case DemoPreset.normalActivity:
        state = state.copyWith(
          heartRate: 85,
          eda: 3.0,
          temperature: 33.5,
          batteryLevel: 0.60,
          isWifiConnected: true,
        );
        break;
      case DemoPreset.stressed:
        state = state.copyWith(
          heartRate: 110,
          eda: 6.0,
          temperature: 35.0,
          batteryLevel: 0.40,
          isWifiConnected: true,
        );
        break;
      case DemoPreset.highStress:
        state = state.copyWith(
          heartRate: 130,
          eda: 8.5,
          temperature: 36.0,
          batteryLevel: 0.25,
          isWifiConnected: false,
        );
        break;
      case DemoPreset.lowBattery:
        state = state.copyWith(
          heartRate: 75,
          eda: 2.5,
          temperature: 33.0,
          batteryLevel: 0.15,
          isWifiConnected: true,
        );
        break;
    }

    // Apply all values
    _offloadingManager.setSimulatedBatteryLevel(state.batteryLevel);
    _offloadingManager.setSimulatedWifiStatus(state.isWifiConnected);
    if (state.useManualValues) {
      _updateSensorValues();
    }
  }
}

enum DemoPreset {
  relaxed,
  normalActivity,
  stressed,
  highStress,
  lowBattery,
}

// Provider
final simulationProvider =
    StateNotifierProvider<SimulationNotifier, SimulationState>((ref) {
  return SimulationNotifier(
    sensorService: sl<SensorSimulatorService>(),
    offloadingManager: sl<OffloadingManager>(),
  );
});
