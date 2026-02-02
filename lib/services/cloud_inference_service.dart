import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';
import '../domain/entities/hrv_metrics.dart';
import 'threshold_stress_engine.dart';
import 'sync_queue_service.dart';

/// Service for performing cloud-based stress inference via Firebase.
///
/// Runs the stress scoring algorithm and persists every assessment to
/// Cloud Firestore under the authenticated user's document path.
class CloudInferenceService {
  bool _isAvailable = true;
  SyncQueueService? _syncQueue;

  bool get isAvailable => _isAvailable;

  /// Injects the sync queue so failed writes can be retried later.
  void setSyncQueue(SyncQueueService queue) {
    _syncQueue = queue;
  }

  /// Primary path: HRV-based cloud analysis via [ThresholdStressEngine].
  Future<StressAssessment> analyzeWithHRV(
    HRVMetrics metrics, {
    double? baselineRmssd,
    double? baselineSdnn,
    int? baselineHr,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Simulate network round-trip latency to cloud
    await Future.delayed(const Duration(milliseconds: 200));

    // Build baseline if available
    BaselineValues? baseline;
    if (baselineRmssd != null) {
      baseline = BaselineValues(
        rmssd: baselineRmssd,
        sdnn: baselineSdnn ?? 50.0,
        meanHr: baselineHr ?? 72,
      );
    }

    final result = ThresholdStressEngine.evaluate(
      metrics,
      baseline: baseline,
    );

    stopwatch.stop();

    final assessment = StressAssessment(
      level: result.score,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.cloud,
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

    // Persist to Firestore in background (non-blocking)
    _storeAssessment(assessment);

    return assessment;
  }

  /// Fallback path: raw sensor reading analysis.
  Future<StressAssessment> analyzeStress(SensorReading reading) async {
    final stopwatch = Stopwatch()..start();

    await Future.delayed(const Duration(milliseconds: 200));

    final normalizedHr = _normalizeHeartRate(reading.bvp);
    final normalizedEda = _normalizeEda(reading.eda);
    final normalizedTemp = _normalizeTemperature(reading.temperature);

    // Cloud weights differ slightly from edge
    final rawStress = (normalizedHr * 0.45) +
        (normalizedEda * 0.40) +
        (normalizedTemp * 0.15);

    final smoothedStress = _sigmoidSmooth(rawStress);
    final stressLevel = (smoothedStress * 100).round().clamp(0, 100);

    stopwatch.stop();

    final assessment = StressAssessment(
      level: stressLevel,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.cloud,
      confidence: 0.95,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawScores: {
        'hr_contribution': normalizedHr * 0.45,
        'eda_contribution': normalizedEda * 0.40,
        'temp_contribution': normalizedTemp * 0.15,
        'cloud_model_version': 1.0,
      },
    );

    _storeAssessment(assessment);

    return assessment;
  }

  /// Persists a stress assessment to Cloud Firestore.
  ///
  /// Writes to: users/{uid}/stress_assessments/{auto-id}
  /// Throws on failure so callers (e.g. sync queue) can catch and retry.
  Future<void> storeAssessment(StressAssessment assessment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Firestore: skipping write — no authenticated user');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stress_assessments')
        .add(assessment.toJson());
    debugPrint('Firestore: assessment stored');
  }

  /// Fire-and-forget wrapper used internally after inference.
  /// Falls back to the offline sync queue when the write fails.
  void _storeAssessment(StressAssessment assessment) {
    storeAssessment(assessment).catchError((e) {
      debugPrint('Firestore write failed, queueing for sync: $e');
      _syncQueue?.enqueue(assessment);
    });
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
    if (x < -10) return 0.0;
    if (x > 10) return 1.0;
    double sum = 1.0;
    double term = 1.0;
    final exponent = -6 * (x - 0.5);
    for (int i = 1; i < 20; i++) {
      term *= exponent / i;
      sum += term;
    }
    return 1 / (1 + sum);
  }

  void setAvailability(bool available) {
    _isAvailable = available;
  }
}
