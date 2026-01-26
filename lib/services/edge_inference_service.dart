import 'dart:math';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';

/// Service for performing on-device (Edge) stress inference
/// Uses a simplified stress calculation algorithm for the prototype
/// In production, this would use TensorFlow Lite
class EdgeInferenceService {
  bool _isInitialized = false;

  /// Initializes the inference service
  /// In production, this would load the TFLite model
  Future<void> initialize() async {
    // Simulate model loading delay
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
  }

  /// Whether the service is ready for inference
  bool get isInitialized => _isInitialized;

  /// Analyzes stress level from sensor reading
  ///
  /// The stress calculation considers:
  /// - Heart rate (BVP): Higher HR indicates more stress
  /// - EDA: Higher skin conductance indicates stress response
  /// - Temperature: Elevated skin temp can indicate stress
  Future<StressAssessment> analyzeStress(SensorReading reading) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Normalize inputs
    final normalizedHr = _normalizeHeartRate(reading.bvp);
    final normalizedEda = _normalizeEda(reading.eda);
    final normalizedTemp = _normalizeTemperature(reading.temperature);

    // Weighted stress calculation
    // HR contributes 50%, EDA contributes 35%, Temp contributes 15%
    final rawStress = (normalizedHr * 0.50) +
        (normalizedEda * 0.35) +
        (normalizedTemp * 0.15);

    // Apply sigmoid-like smoothing for more natural values
    final smoothedStress = _sigmoidSmooth(rawStress);

    // Calculate confidence based on input validity
    final confidence = _calculateConfidence(reading);

    // Convert to 0-100 scale
    final stressLevel = (smoothedStress * 100).round().clamp(0, 100);

    return StressAssessment(
      level: stressLevel,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.edge,
      confidence: confidence,
      rawScores: {
        'hr_contribution': normalizedHr * 0.50,
        'eda_contribution': normalizedEda * 0.35,
        'temp_contribution': normalizedTemp * 0.15,
      },
    );
  }

  /// Normalizes heart rate to 0-1 scale
  /// Resting: 60-80 BPM = 0-0.3
  /// Elevated: 80-100 BPM = 0.3-0.6
  /// High: 100-120+ BPM = 0.6-1.0
  double _normalizeHeartRate(double hr) {
    const minHr = 50.0;
    const maxHr = 140.0;
    return ((hr - minHr) / (maxHr - minHr)).clamp(0.0, 1.0);
  }

  /// Normalizes EDA to 0-1 scale
  /// Low: 0-2 µS = 0-0.3
  /// Normal: 2-5 µS = 0.3-0.6
  /// High: 5-10+ µS = 0.6-1.0
  double _normalizeEda(double eda) {
    const minEda = 0.0;
    const maxEda = 10.0;
    return ((eda - minEda) / (maxEda - minEda)).clamp(0.0, 1.0);
  }

  /// Normalizes temperature to 0-1 scale
  /// Normal: 32-34°C = 0-0.4
  /// Elevated: 34-36°C = 0.4-0.8
  /// High: 36-38°C = 0.8-1.0
  double _normalizeTemperature(double temp) {
    const minTemp = 31.0;
    const maxTemp = 38.0;
    return ((temp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
  }

  /// Applies sigmoid smoothing for more natural stress curve
  double _sigmoidSmooth(double x) {
    // Modified sigmoid for 0-1 range
    return 1 / (1 + exp(-6 * (x - 0.5)));
  }

  /// Calculates confidence based on input validity
  double _calculateConfidence(SensorReading reading) {
    double confidence = 1.0;

    // Reduce confidence for out-of-range values
    if (reading.bvp < 40 || reading.bvp > 200) confidence -= 0.2;
    if (reading.eda < 0 || reading.eda > 20) confidence -= 0.2;
    if (reading.temperature < 28 || reading.temperature > 40) confidence -= 0.2;

    return confidence.clamp(0.0, 1.0);
  }

  /// Batch analysis for multiple readings
  Future<List<StressAssessment>> analyzeStressBatch(
      List<SensorReading> readings) async {
    final results = <StressAssessment>[];
    for (final reading in readings) {
      results.add(await analyzeStress(reading));
    }
    return results;
  }

  void dispose() {
    _isInitialized = false;
  }
}
