import 'dart:async';
import '../core/network/network_info.dart';
import '../core/utils/battery_utils.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/stress_assessment.dart';

/// The "Brain" of the application - decides whether to process on Edge or Cloud
class OffloadingManager {
  final NetworkInfo _networkInfo;
  final BatteryUtils _batteryUtils;

  // Simulation overrides for demo
  double? _simulatedBatteryLevel;
  bool? _simulatedWifiConnected;
  OffloadingStrategy _strategy = OffloadingStrategy.auto;

  // Stream controller for mode changes
  final _modeController = StreamController<ProcessingMode>.broadcast();

  OffloadingManager({
    required NetworkInfo networkInfo,
    required BatteryUtils batteryUtils,
  })  : _networkInfo = networkInfo,
        _batteryUtils = batteryUtils;

  /// Stream of processing mode changes
  Stream<ProcessingMode> get modeStream => _modeController.stream;

  /// Current offloading strategy
  OffloadingStrategy get strategy => _strategy;

  /// Sets the offloading strategy
  set strategy(OffloadingStrategy value) {
    _strategy = value;
    // Recalculate and emit new mode
    determineProcessingMode().then(_modeController.add);
  }

  /// Sets simulated battery level for demo (0.0 - 1.0)
  void setSimulatedBatteryLevel(double? level) {
    _simulatedBatteryLevel = level;
    determineProcessingMode().then(_modeController.add);
  }

  /// Sets simulated WiFi connection status for demo
  void setSimulatedWifiStatus(bool? connected) {
    _simulatedWifiConnected = connected;
    determineProcessingMode().then(_modeController.add);
  }

  /// Gets current battery level (simulated or real)
  Future<double> getCurrentBatteryLevel() async {
    return _simulatedBatteryLevel ?? await _batteryUtils.getBatteryLevel();
  }

  /// Gets current WiFi status (simulated or real)
  Future<bool> getCurrentWifiStatus() async {
    return _simulatedWifiConnected ?? await _networkInfo.isConnectedToWifi;
  }

  /// Determines the appropriate processing mode based on current conditions
  ///
  /// Decision Logic:
  /// 1. If strategy is FORCE_EDGE: always return EDGE
  /// 2. If strategy is FORCE_CLOUD: always return CLOUD
  /// 3. If AUTO:
  ///    - Battery < 20%: EDGE (preserve battery)
  ///    - Battery >= 20% AND WiFi: CLOUD (offload to server)
  ///    - Battery >= 20% AND no WiFi: EDGE (avoid mobile data costs)
  Future<ProcessingMode> determineProcessingMode() async {
    // Handle forced modes
    if (_strategy == OffloadingStrategy.forceEdge) {
      return ProcessingMode.edge;
    }
    if (_strategy == OffloadingStrategy.forceCloud) {
      return ProcessingMode.cloud;
    }

    // Auto mode decision logic
    final batteryLevel = await getCurrentBatteryLevel();
    final hasWifi = await getCurrentWifiStatus();

    // Battery critical - force edge to preserve battery
    if (batteryLevel < AppConstants.batteryThresholdLow) {
      return ProcessingMode.edge;
    }

    // Good battery and WiFi available - use cloud
    if (hasWifi) {
      return ProcessingMode.cloud;
    }

    // No WiFi - stay on edge to avoid mobile data
    return ProcessingMode.edge;
  }

  /// Returns a detailed status report for UI display
  Future<OffloadingStatus> getStatus() async {
    final mode = await determineProcessingMode();
    final battery = await getCurrentBatteryLevel();
    final wifi = await getCurrentWifiStatus();

    return OffloadingStatus(
      currentMode: mode,
      batteryLevel: battery,
      isWifiConnected: wifi,
      strategy: _strategy,
      reason: _getDecisionReason(mode, battery, wifi),
    );
  }

  String _getDecisionReason(ProcessingMode mode, double battery, bool wifi) {
    if (_strategy == OffloadingStrategy.forceEdge) {
      return 'Forced to Edge mode by user';
    }
    if (_strategy == OffloadingStrategy.forceCloud) {
      return 'Forced to Cloud mode by user';
    }

    if (battery < AppConstants.batteryThresholdLow) {
      return 'Low battery (${(battery * 100).toInt()}%) - using local processing';
    }
    if (mode == ProcessingMode.cloud) {
      return 'WiFi connected - offloading to cloud';
    }
    return 'No WiFi - using local processing';
  }

  void dispose() {
    _modeController.close();
  }
}

/// Offloading strategy enum
enum OffloadingStrategy {
  auto, // Automatic decision based on battery/network
  forceEdge, // Always use on-device processing
  forceCloud, // Always use cloud processing
}

/// Status report for the offloading manager
class OffloadingStatus {
  final ProcessingMode currentMode;
  final double batteryLevel;
  final bool isWifiConnected;
  final OffloadingStrategy strategy;
  final String reason;

  const OffloadingStatus({
    required this.currentMode,
    required this.batteryLevel,
    required this.isWifiConnected,
    required this.strategy,
    required this.reason,
  });

  int get batteryPercentage => (batteryLevel * 100).toInt();
}
