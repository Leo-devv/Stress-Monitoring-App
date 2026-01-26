import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/entities/sensor_reading.dart';
import '../core/utils/csv_parser.dart';

/// Service that simulates sensor data from a wearable device
/// Reads from WESAD-format CSV or generates synthetic data for demos
class SensorSimulatorService {
  final StreamController<SensorReading> _controller =
      StreamController<SensorReading>.broadcast();

  Timer? _emissionTimer;
  List<SensorReading> _wesadData = [];
  int _currentIndex = 0;
  bool _isRunning = false;

  // Manual override values for demo
  double? _manualBvp;
  double? _manualEda;
  double? _manualTemperature;

  /// Stream of sensor readings
  Stream<SensorReading> get sensorStream => _controller.stream;

  /// Whether the simulator is currently running
  bool get isRunning => _isRunning;

  /// Current data index
  int get currentIndex => _currentIndex;

  /// Total data points available
  int get totalDataPoints => _wesadData.length;

  /// Loads WESAD data from assets
  Future<void> loadWesadData() async {
    try {
      final csvString = await rootBundle.loadString('assets/data/wesad_sample.csv');
      _wesadData = CsvParser.parseWesadData(csvString);
    } catch (e) {
      // If CSV not found, generate synthetic data
      _wesadData = CsvParser.generateSyntheticData(count: 300);
    }
  }

  /// Starts emitting sensor data at the specified interval
  void startSimulation({Duration interval = const Duration(seconds: 1)}) {
    if (_isRunning) return;
    if (_wesadData.isEmpty) {
      // Generate data if not loaded
      _wesadData = CsvParser.generateSyntheticData(count: 300);
    }

    _isRunning = true;
    _emissionTimer = Timer.periodic(interval, (_) => _emitReading());
  }

  /// Stops the simulation
  void stopSimulation() {
    _emissionTimer?.cancel();
    _emissionTimer = null;
    _isRunning = false;
  }

  /// Resets the simulation to the beginning
  void resetSimulation() {
    _currentIndex = 0;
  }

  /// Sets manual override values for demo purposes
  void setManualValues({
    double? bvp,
    double? eda,
    double? temperature,
  }) {
    _manualBvp = bvp;
    _manualEda = eda;
    _manualTemperature = temperature;
  }

  /// Clears manual override values
  void clearManualValues() {
    _manualBvp = null;
    _manualEda = null;
    _manualTemperature = null;
  }

  /// Injects a single reading manually (for UI slider demo)
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
    _controller.add(reading);
  }

  void _emitReading() {
    if (_wesadData.isEmpty) return;

    final baseReading = _wesadData[_currentIndex % _wesadData.length];

    // Apply manual overrides if set
    final reading = SensorReading(
      timestamp: DateTime.now(),
      bvp: _manualBvp ?? baseReading.bvp,
      eda: _manualEda ?? baseReading.eda,
      temperature: _manualTemperature ?? baseReading.temperature,
    );

    _controller.add(reading);
    _currentIndex++;
  }

  /// Disposes of resources
  void dispose() {
    stopSimulation();
    _controller.close();
  }
}
