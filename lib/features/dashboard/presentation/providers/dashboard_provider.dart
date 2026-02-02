import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/sensor_reading.dart';
import '../../../../domain/entities/stress_assessment.dart';
import '../../../../domain/entities/hrv_metrics.dart';
import '../../../../services/sensor_simulator_service.dart';
import '../../../../services/sensor/sensor_manager.dart';
import '../../../../services/sensor/heart_rate_source.dart';
import '../../../../services/hrv_computation_service.dart';
import '../../../../services/baseline_service.dart';
import '../../../../services/notification_service.dart';
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

  // HRV-aware fields
  final HRVMetrics? currentHRV;
  final SensorSourceType? activeSourceType;
  final double? baselineDeviation;

  const DashboardState({
    this.sensorHistory = const [],
    this.stressHistory = const [],
    this.currentStress,
    this.currentReading,
    this.processingMode = ProcessingMode.edge,
    this.isSimulationRunning = false,
    this.offloadingStatus,
    this.isLoading = false,
    this.currentHRV,
    this.activeSourceType,
    this.baselineDeviation,
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
    HRVMetrics? currentHRV,
    SensorSourceType? activeSourceType,
    double? baselineDeviation,
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
      currentHRV: currentHRV ?? this.currentHRV,
      activeSourceType: activeSourceType ?? this.activeSourceType,
      baselineDeviation: baselineDeviation ?? this.baselineDeviation,
    );
  }
}

// Dashboard notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final SensorSimulatorService _sensorService;
  final StressAnalysisService _analysisService;
  final OffloadingManager _offloadingManager;
  final SensorManager _sensorManager;
  final HRVComputationService _hrvService;
  final BaselineService _baselineService;
  final NotificationService _notificationService;

  StreamSubscription<SensorReading>? _sensorSubscription;
  StreamSubscription<ProcessingMode>? _modeSubscription;
  StreamSubscription<HRVMetrics>? _hrvSubscription;
  StreamSubscription<SensorSourceType>? _sourceSubscription;

  static const int maxHistorySize = 60;

  DashboardNotifier({
    required SensorSimulatorService sensorService,
    required StressAnalysisService analysisService,
    required OffloadingManager offloadingManager,
    required SensorManager sensorManager,
    required HRVComputationService hrvService,
    required BaselineService baselineService,
    required NotificationService notificationService,
  })  : _sensorService = sensorService,
        _analysisService = analysisService,
        _offloadingManager = offloadingManager,
        _sensorManager = sensorManager,
        _hrvService = hrvService,
        _baselineService = baselineService,
        _notificationService = notificationService,
        super(const DashboardState()) {
    _initializeSubscriptions();
    _updateOffloadingStatus();
  }

  void _initializeSubscriptions() {
    // Listen to legacy sensor readings (BVP/EDA/temp from simulator)
    _sensorSubscription =
        _sensorService.sensorStream.listen(_onSensorReading);

    // Listen to processing mode changes
    _modeSubscription = _offloadingManager.modeStream.listen((mode) {
      state = state.copyWith(processingMode: mode);
      _updateOffloadingStatus();
    });

    // Feed RR intervals from SensorManager into HRV computation
    _sensorManager.rrIntervalStream.listen((rr) {
      _hrvService.addInterval(rr);
    });

    // Listen to computed HRV metrics
    _hrvSubscription =
        _hrvService.metricsStream.listen(_onHRVMetrics);

    // Listen to source changes
    _sourceSubscription =
        _sensorManager.sourceChangeStream.listen((sourceType) {
      state = state.copyWith(activeSourceType: sourceType);
    });

    // Start periodic HRV computation
    _hrvService.startPeriodicComputation();
  }

  Future<void> _onSensorReading(SensorReading reading) async {
    // Update sensor history
    final newSensorHistory = [...state.sensorHistory, reading];
    if (newSensorHistory.length > maxHistorySize) {
      newSensorHistory.removeAt(0);
    }

    // Analyze stress with the traditional algorithm
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

    // Evaluate whether to fire a notification
    await _notificationService.evaluateStressReading(assessment.level);
  }

  /// Maps the active sensor source type to a short acquisition label.
  String _acquisitionSourceLabel() {
    switch (state.activeSourceType) {
      case SensorSourceType.ble:
        return 'ble';
      case SensorSourceType.cameraPpg:
        return 'camera';
      case SensorSourceType.simulator:
      case null:
        return 'simulator';
    }
  }

  Future<void> _onHRVMetrics(HRVMetrics metrics) async {
    // Compute baseline deviation and record for learning
    final deviation = _baselineService.deviationPercent(metrics);
    _baselineService.recordMeasurement(metrics);

    // Route through the analysis service so the edge/cloud decision,
    // Firestore persistence, and sync-queue fallback all work correctly.
    final assessment = await _analysisService.analyzeHRV(
      metrics,
      baselineRmssd: _baselineService.baselineRmssd,
      baselineSdnn: _baselineService.baselineSdnn,
      baselineHr: _baselineService.baselineHr,
      acquisitionSource: _acquisitionSourceLabel(),
      acquisitionDuration: _hrvService.windowDuration.inSeconds.toDouble(),
    );

    final newStressHistory = [...state.stressHistory, assessment];
    if (newStressHistory.length > maxHistorySize) {
      newStressHistory.removeAt(0);
    }

    state = state.copyWith(
      currentHRV: metrics,
      baselineDeviation: deviation,
      currentStress: assessment,
      stressHistory: newStressHistory,
    );

    // Evaluate notification with HRV-based score
    _notificationService.evaluateStressReading(assessment.level);
  }

  Future<void> _updateOffloadingStatus() async {
    final status = await _offloadingManager.getStatus();
    state = state.copyWith(offloadingStatus: status);
  }

  void startSimulation() {
    _sensorService.startSimulation();
    // Also activate SimulatorSource in SensorManager for RR intervals
    _sensorManager.useSimulator();
    state = state.copyWith(isSimulationRunning: true);
  }

  void stopSimulation() {
    _sensorService.stopSimulation();
    _sensorManager.stopActiveSource();
    state = state.copyWith(isSimulationRunning: false);
  }

  void toggleSimulation() {
    if (state.isSimulationRunning) {
      stopSimulation();
    } else {
      startSimulation();
    }
  }

  /// Attaches a subjective stress rating to the most recent assessment
  /// and updates the current stress with the rating included.
  void recordSubjectiveRating(int rating) {
    final current = state.currentStress;
    if (current == null) return;

    final updated = current.copyWith(subjectiveRating: rating);
    state = state.copyWith(currentStress: updated);
  }

  void resetData() {
    _sensorService.resetSimulation();
    _analysisService.clearHistory();
    _hrvService.clearBuffer();
    _notificationService.resetAlertState();
    state = const DashboardState();
    _updateOffloadingStatus();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _modeSubscription?.cancel();
    _hrvSubscription?.cancel();
    _sourceSubscription?.cancel();
    _hrvService.stopPeriodicComputation();
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
    sensorManager: sl<SensorManager>(),
    hrvService: sl<HRVComputationService>(),
    baselineService: sl<BaselineService>(),
    notificationService: sl<NotificationService>(),
  );
});
