import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/rr_interval.dart';
import 'heart_rate_source.dart';
import 'ble_heart_rate_source.dart';
import 'camera_ppg_source.dart';
import 'simulator_source.dart';

/// Manages the active heart rate source and provides a unified data stream.
///
/// At any time exactly one source is active. The rest of the app consumes
/// data through [heartRateStream] and [rrIntervalStream] without caring
/// whether the data comes from a BLE strap, the camera, or the simulator.
class SensorManager {
  final BleHeartRateSource bleSource;
  final CameraPpgSource cameraPpgSource;
  final SimulatorSource simulatorSource;

  HeartRateSource? _activeSource;
  StreamSubscription<HeartRateReading>? _hrSub;
  StreamSubscription<RRInterval>? _rrSub;

  final _hrController = StreamController<HeartRateReading>.broadcast();
  final _rrController = StreamController<RRInterval>.broadcast();
  final _sourceChangeController =
      StreamController<SensorSourceType>.broadcast();

  SensorManager({
    required this.bleSource,
    required this.cameraPpgSource,
    required this.simulatorSource,
  });

  Stream<HeartRateReading> get heartRateStream => _hrController.stream;
  Stream<RRInterval> get rrIntervalStream => _rrController.stream;
  Stream<SensorSourceType> get sourceChangeStream =>
      _sourceChangeController.stream;

  HeartRateSource? get activeSource => _activeSource;
  SensorSourceType? get activeSourceType => _activeSource?.sourceType;
  bool get hasActiveSource => _activeSource != null && _activeSource!.isActive;

  /// Activates the simulator as the data source.
  Future<void> useSimulator() async {
    await _switchSource(simulatorSource);
    simulatorSource.startSimulation();
  }

  /// Activates the camera PPG as the data source.
  Future<void> useCameraPpg() async {
    await _switchSource(cameraPpgSource);
    await cameraPpgSource.start();
  }

  /// Activates BLE as the data source.
  /// If [device] is provided, connects to it first.
  Future<void> useBle([BluetoothDevice? device]) async {
    if (device != null) {
      await bleSource.connectToDevice(device);
    }
    await _switchSource(bleSource);
  }

  /// Stops whichever source is currently active.
  Future<void> stopActiveSource() async {
    await _activeSource?.stop();
    _hrSub?.cancel();
    _rrSub?.cancel();
    _activeSource = null;
  }

  Future<void> _switchSource(HeartRateSource source) async {
    if (_activeSource == source && source.isActive) return;

    await stopActiveSource();
    _activeSource = source;

    _hrSub = source.heartRateStream.listen(
      (reading) => _hrController.add(reading),
      onError: (e) => debugPrint('HR stream error: $e'),
    );
    _rrSub = source.rrIntervalStream.listen(
      (rr) => _rrController.add(rr),
      onError: (e) => debugPrint('RR stream error: $e'),
    );

    _sourceChangeController.add(source.sourceType);
    debugPrint('Sensor source switched to: ${source.sourceName}');
  }

  void dispose() {
    stopActiveSource();
    _hrController.close();
    _rrController.close();
    _sourceChangeController.close();
  }
}
