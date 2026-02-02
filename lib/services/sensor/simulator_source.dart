import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../domain/entities/rr_interval.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../core/utils/csv_parser.dart';
import 'heart_rate_source.dart';

/// Generates simulated sensor data from WESAD CSV or synthetic patterns.
/// Produces both HeartRateReadings and realistic RR intervals for HRV testing.
class SimulatorSource implements HeartRateSource {
  final _hrController = StreamController<HeartRateReading>.broadcast();
  final _rrController = StreamController<RRInterval>.broadcast();
  final _sensorController = StreamController<SensorReading>.broadcast();

  Timer? _emissionTimer;
  List<SensorReading> _wesadData = [];
  int _currentIndex = 0;
  bool _running = false;
  final _rng = Random(42);

  double? _manualBvp;
  double? _manualEda;
  double? _manualTemperature;

  @override
  Stream<HeartRateReading> get heartRateStream => _hrController.stream;

  @override
  Stream<RRInterval> get rrIntervalStream => _rrController.stream;

  /// Full sensor reading stream (includes EDA, temperature for simulation UI)
  Stream<SensorReading> get sensorStream => _sensorController.stream;

  @override
  bool get isActive => _running;

  @override
  String get sourceName => 'Simulator (WESAD)';

  @override
  SensorSourceType get sourceType => SensorSourceType.simulator;

  int get currentIndex => _currentIndex;
  int get totalDataPoints => _wesadData.length;

  Future<void> loadWesadData() async {
    try {
      final csvString =
          await rootBundle.loadString('assets/data/wesad_sample.csv');
      _wesadData = CsvParser.parseWesadData(csvString);
    } catch (e) {
      _wesadData = CsvParser.generateSyntheticData(count: 300);
    }
  }

  @override
  Future<void> start() async {
    startSimulation();
  }

  void startSimulation({Duration interval = const Duration(seconds: 1)}) {
    if (_running) return;
    if (_wesadData.isEmpty) {
      _wesadData = CsvParser.generateSyntheticData(count: 300);
    }
    _running = true;
    _emissionTimer = Timer.periodic(interval, (_) => _emitReading());
  }

  @override
  Future<void> stop() async {
    stopSimulation();
  }

  void stopSimulation() {
    _emissionTimer?.cancel();
    _emissionTimer = null;
    _running = false;
  }

  void resetSimulation() {
    _currentIndex = 0;
  }

  void setManualValues({double? bvp, double? eda, double? temperature}) {
    _manualBvp = bvp;
    _manualEda = eda;
    _manualTemperature = temperature;
  }

  void clearManualValues() {
    _manualBvp = null;
    _manualEda = null;
    _manualTemperature = null;
  }

  void injectManualReading({
    required double bvp,
    required double eda,
    required double temperature,
  }) {
    final reading = SensorReading(
      timestamp: DateTime.now(),
      bvp: bvp,
      eda: eda,
      temperature: temperature,
    );
    _sensorController.add(reading);
    _emitHrAndRrFromBvp(bvp);
  }

  void _emitReading() {
    if (_wesadData.isEmpty) return;

    final baseReading = _wesadData[_currentIndex % _wesadData.length];
    final reading = SensorReading(
      timestamp: DateTime.now(),
      bvp: _manualBvp ?? baseReading.bvp,
      eda: _manualEda ?? baseReading.eda,
      temperature: _manualTemperature ?? baseReading.temperature,
    );

    _sensorController.add(reading);
    _emitHrAndRrFromBvp(reading.bvp);
    _currentIndex++;
  }

  /// Generates a realistic RR interval from a target heart rate.
  /// Adds physiological variability: healthy hearts have ~5-10% beat-to-beat variation.
  void _emitHrAndRrFromBvp(double bvp) {
    final hr = bvp.clamp(40.0, 200.0);
    final now = DateTime.now();

    _hrController.add(HeartRateReading(
      bpm: hr.round(),
      timestamp: now,
      source: SensorSourceType.simulator,
    ));

    // Derive a synthetic RR interval with realistic variability
    final nominalRr = (60000 / hr).round();
    final variability = (nominalRr * 0.06 * (_rng.nextDouble() - 0.5)).round();
    final rrMs = (nominalRr + variability).clamp(300, 2000);

    _rrController.add(RRInterval(timestamp: now, milliseconds: rrMs));
  }

  void dispose() {
    stopSimulation();
    _hrController.close();
    _rrController.close();
    _sensorController.close();
  }
}
