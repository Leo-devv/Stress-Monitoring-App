import 'dart:math';
import 'package:flutter/foundation.dart';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';
import '../domain/entities/hrv_metrics.dart';
import 'threshold_stress_engine.dart';

/// Service for performing on-device (Edge) stress inference.
///
/// Uses the [ThresholdStressEngine] — a clinically-informed, rule-based
/// classifier that scores all available HRV features against population
/// norms and optional personal baselines.
///
/// Two analysis paths:
///  1. HRV-based (preferred): feeds all time-domain and frequency-domain
///     HRV features into the threshold engine.
///  2. Sensor reading fallback: weighted HR/EDA/Temp for simulation mode.
class EdgeInferenceService {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
    debugPrint('EdgeInferenceService: threshold engine ready');
  }

  /// Primary path: stress analysis from HRV metrics + personal baseline.
  Future<StressAssessment> analyzeWithHRV(
    HRVMetrics metrics, {
    double? baselineRmssd,
    double? baselineSdnn,
    int? baselineHr,
  }) async {
    if (!_isInitialized) await initialize();

    final stopwatch = Stopwatch()..start();

    // Build baseline if available
    BaselineValues? baseline;
    if (baselineRmssd != null) {
      baseline = BaselineValues(
        rmssd: baselineRmssd,
        sdnn: baselineSdnn ?? 50.0,
        meanHr: baselineHr ?? 72,
      );
    }

    // Run the threshold engine over all features
    final result = ThresholdStressEngine.evaluate(
      metrics,
      baseline: baseline,
    );

    stopwatch.stop();

    return StressAssessment(
      level: result.score,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.edge,
      confidence: result.confidence,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawScores: {
        for (final e in result.subscores.entries) e.key: e.value,
        'baseline_rmssd': baselineRmssd ?? 42.0,
      },
      features: {
        'sdnn': metrics.sdnn,
        'rmssd': metrics.rmssd,
        'pnn50': metrics.pnn50,
        'lfPower': metrics.lfPower,
        'hfPower': metrics.hfPower,
        'lfHfRatio': metrics.lfHfRatio,
      },
    );
  }

  /// Fallback path: stress analysis from raw sensor reading (simulation).
  Future<StressAssessment> analyzeStress(SensorReading reading) async {
    if (!_isInitialized) await initialize();

    final stopwatch = Stopwatch()..start();

    final normalizedHr = _normalizeHeartRate(reading.bvp);
    final normalizedEda = _normalizeEda(reading.eda);
    final normalizedTemp = _normalizeTemperature(reading.temperature);

    // Weighted: HR 50%, EDA 35%, Temp 15%
    final rawStress = (normalizedHr * 0.50) +
        (normalizedEda * 0.35) +
        (normalizedTemp * 0.15);

    final smoothedStress = _sigmoidSmooth(rawStress);
    final confidence = _calculateConfidence(reading);
    final stressLevel = (smoothedStress * 100).round().clamp(0, 100);

    stopwatch.stop();

    return StressAssessment(
      level: stressLevel,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.edge,
      confidence: confidence,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawScores: {
        'hr_contribution': normalizedHr * 0.50,
        'eda_contribution': normalizedEda * 0.35,
        'temp_contribution': normalizedTemp * 0.15,
      },
    );
  }

  double _normalizeHeartRate(double hr) {
    const minHr = 50.0;
    const maxHr = 140.0;
    return ((hr - minHr) / (maxHr - minHr)).clamp(0.0, 1.0);
  }

  double _normalizeEda(double eda) {
    const minEda = 0.0;
    const maxEda = 10.0;
    return ((eda - minEda) / (maxEda - minEda)).clamp(0.0, 1.0);
  }

  double _normalizeTemperature(double temp) {
    const minTemp = 31.0;
    const maxTemp = 38.0;
    return ((temp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
  }

  double _sigmoidSmooth(double x) {
    return 1 / (1 + exp(-6 * (x - 0.5)));
  }

  double _calculateConfidence(SensorReading reading) {
    double confidence = 1.0;
    if (reading.bvp < 40 || reading.bvp > 200) confidence -= 0.2;
    if (reading.eda < 0 || reading.eda > 20) confidence -= 0.2;
    if (reading.temperature < 28 || reading.temperature > 40) confidence -= 0.2;
    return confidence.clamp(0.0, 1.0);
  }

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
