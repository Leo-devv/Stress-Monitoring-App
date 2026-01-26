import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/sensor_reading.dart';
import '../../../../domain/entities/stress_assessment.dart';
import '../../../../services/sensor_simulator_service.dart';
import '../../../../services/offloading_manager.dart';
import '../../../../services/stress_analysis_service.dart';
import '../../../../di/injection_container.dart';

// Dashboard state
class DashboardState {
  final List<SensorReading> sensorHistory;
  final List<StressAssessment> stressHistory;
  final StressAssessment? currentStress;
  final SensorReading? currentReading;
  final ProcessingMode processingMode;
  final bool isSimulationRunning;
  final OffloadingStatus? offloadingStatus;
  final bool isLoading;

  const DashboardState({
    this.sensorHistory = const [],
    this.stressHistory = const [],
    this.currentStress,
    this.currentReading,
    this.processingMode = ProcessingMode.edge,
    this.isSimulationRunning = false,
    this.offloadingStatus,
    this.isLoading = false,
  });

  DashboardState copyWith({
    List<SensorReading>? sensorHistory,
    List<StressAssessment>? stressHistory,
    StressAssessment? currentStress,
    SensorReading? currentReading,
    ProcessingMode? processingMode,
    bool? isSimulationRunning,
    OffloadingStatus? offloadingStatus,
    bool? isLoading,
  }) {
    return DashboardState(
      sensorHistory: sensorHistory ?? this.sensorHistory,
      stressHistory: stressHistory ?? this.stressHistory,
      currentStress: currentStress ?? this.currentStress,
      currentReading: currentReading ?? this.currentReading,
      processingMode: processingMode ?? this.processingMode,
      isSimulationRunning: isSimulationRunning ?? this.isSimulationRunning,
      offloadingStatus: offloadingStatus ?? this.offloadingStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Dashboard notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final SensorSimulatorService _sensorService;
  final StressAnalysisService _analysisService;
  final OffloadingManager _offloadingManager;

  StreamSubscription<SensorReading>? _sensorSubscription;
  StreamSubscription<ProcessingMode>? _modeSubscription;

  static const int maxHistorySize = 60;

  DashboardNotifier({
    required SensorSimulatorService sensorService,
    required StressAnalysisService analysisService,
    required OffloadingManager offloadingManager,
  })  : _sensorService = sensorService,
        _analysisService = analysisService,
        _offloadingManager = offloadingManager,
        super(const DashboardState()) {
    _initializeSubscriptions();
    _updateOffloadingStatus();
  }

  void _initializeSubscriptions() {
    // Listen to sensor readings
    _sensorSubscription = _sensorService.sensorStream.listen(_onSensorReading);

    // Listen to processing mode changes
    _modeSubscription = _offloadingManager.modeStream.listen((mode) {
      state = state.copyWith(processingMode: mode);
      _updateOffloadingStatus();
    });
  }

  Future<void> _onSensorReading(SensorReading reading) async {
    // Update sensor history
    final newSensorHistory = [...state.sensorHistory, reading];
    if (newSensorHistory.length > maxHistorySize) {
      newSensorHistory.removeAt(0);
    }

    // Analyze stress
    final assessment = await _analysisService.analyze(reading);

    // Update stress history
    final newStressHistory = [...state.stressHistory, assessment];
    if (newStressHistory.length > maxHistorySize) {
      newStressHistory.removeAt(0);
    }

    state = state.copyWith(
      sensorHistory: newSensorHistory,
      stressHistory: newStressHistory,
      currentReading: reading,
      currentStress: assessment,
      processingMode: assessment.processedBy,
    );
  }

  Future<void> _updateOffloadingStatus() async {
    final status = await _offloadingManager.getStatus();
    state = state.copyWith(offloadingStatus: status);
  }

  void startSimulation() {
    _sensorService.startSimulation();
    state = state.copyWith(isSimulationRunning: true);
  }

  void stopSimulation() {
    _sensorService.stopSimulation();
    state = state.copyWith(isSimulationRunning: false);
  }

  void toggleSimulation() {
    if (state.isSimulationRunning) {
      stopSimulation();
    } else {
      startSimulation();
    }
  }

  void resetData() {
    _sensorService.resetSimulation();
    _analysisService.clearHistory();
    state = const DashboardState();
    _updateOffloadingStatus();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _modeSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    sensorService: sl<SensorSimulatorService>(),
    analysisService: sl<StressAnalysisService>(),
    offloadingManager: sl<OffloadingManager>(),
  );
});
