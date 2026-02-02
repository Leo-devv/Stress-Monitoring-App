import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';
import '../domain/entities/hrv_metrics.dart';
import 'hrv_computation_service.dart';

/// Service for performing on-device (Edge) stress inference using TensorFlow Lite.
///
/// Loads a quantized stress classification model and runs inference on the
/// device GPU (via delegate) with automatic CPU fallback.
///
/// Two analysis paths:
///  1. HRV-based (preferred): feeds RMSSD, SDNN, pNN50, Baevsky SI, mean HR
///     into the TFLite model. Falls back to rule-based scoring if the model
///     is unavailable.
///  2. Sensor reading fallback: weighted HR/EDA/Temp for simulation mode.
class EdgeInferenceService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _modelLoaded = false;

  bool get isInitialized => _isInitialized;
  bool get isModelLoaded => _modelLoaded;

  Future<void> initialize() async {
    // Attempt to load TFLite model with GPU delegate, then CPU fallback
    try {
      final gpuOptions = InterpreterOptions()..addDelegate(GpuDelegateV2());
      _interpreter = await Interpreter.fromAsset(
        'models/stress_classifier.tflite',
        options: gpuOptions,
      );
      _modelLoaded = true;
      debugPrint('TFLite model loaded with GPU delegate');
    } catch (gpuError) {
      debugPrint('GPU delegate unavailable ($gpuError), trying CPU...');
      try {
        _interpreter = await Interpreter.fromAsset(
          'models/stress_classifier.tflite',
        );
        _modelLoaded = true;
        debugPrint('TFLite model loaded (CPU)');
      } catch (cpuError) {
        debugPrint('TFLite model not found, using rule-based fallback: $cpuError');
        _modelLoaded = false;
      }
    }
    _isInitialized = true;
  }

  /// Primary path: stress analysis from HRV metrics + personal baseline.
  ///
  /// When the TFLite model is available, feeds normalized HRV features into
  /// the neural network. Otherwise falls back to the rule-based algorithm.
  Future<StressAssessment> analyzeWithHRV(
    HRVMetrics metrics, {
    double? baselineRmssd,
  }) async {
    if (!_isInitialized) await initialize();

    final stopwatch = Stopwatch()..start();

    int score;
    if (_modelLoaded && _interpreter != null) {
      score = _runTFLiteInference(metrics);
    } else {
      score = HRVComputationService.computeStressScore(
        metrics,
        baselineRmssd: baselineRmssd,
      );
    }

    stopwatch.stop();

    return StressAssessment(
      level: score,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.edge,
      confidence: metrics.confidence,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawScores: {
        'rmssd': metrics.rmssd,
        'sdnn': metrics.sdnn,
        'stress_index': metrics.stressIndex,
        'baseline_rmssd': baselineRmssd ?? 42.0,
        'model_used': _modelLoaded ? 1.0 : 0.0,
      },
    );
  }

  /// Runs the TFLite stress classifier on normalized HRV features.
  ///
  /// Input tensor: [1, 5] — RMSSD, SDNN, pNN50, Baevsky SI, mean HR
  /// Output tensor: [1, 1] — stress probability (0.0 = relaxed, 1.0 = stressed)
  int _runTFLiteInference(HRVMetrics metrics) {
    // Normalize features to [0, 1] ranges matching training distribution
    final input = [
      [
        (metrics.rmssd / 100.0).clamp(0.0, 1.0),
        (metrics.sdnn / 100.0).clamp(0.0, 1.0),
        (metrics.pnn50 / 100.0).clamp(0.0, 1.0),
        (metrics.stressIndex / 500.0).clamp(0.0, 1.0),
        (metrics.meanHeartRate / 200.0).clamp(0.0, 1.0),
      ]
    ];

    final output = [List<double>.filled(1, 0.0)];
    _interpreter!.run(input, output);

    // Model outputs stress probability [0, 1] → scale to 0-100
    return (output[0][0] * 100).round().clamp(0, 100);
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
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _modelLoaded = false;
  }
}
