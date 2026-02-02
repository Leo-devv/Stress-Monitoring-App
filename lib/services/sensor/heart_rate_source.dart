import 'dart:async';
import '../../domain/entities/rr_interval.dart';

enum SensorSourceType { ble, cameraPpg, simulator }

class HeartRateReading {
  final int bpm;
  final DateTime timestamp;
  final SensorSourceType source;

  const HeartRateReading({
    required this.bpm,
    required this.timestamp,
    required this.source,
  });
}

/// Abstraction over any heart rate data source.
///
/// Implemented by:
///  - [BleHeartRateSource] for Bluetooth LE chest straps / wristbands
///  - [CameraPpgSource]    for smartphone camera photoplethysmography
///  - [SimulatorSource]    for WESAD-format demo data
abstract class HeartRateSource {
  Stream<HeartRateReading> get heartRateStream;
  Stream<RRInterval> get rrIntervalStream;

  Future<void> start();
  Future<void> stop();

  bool get isActive;
  String get sourceName;
  SensorSourceType get sourceType;
}
