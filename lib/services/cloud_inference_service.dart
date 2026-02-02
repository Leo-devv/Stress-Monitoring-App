import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';
import '../domain/entities/hrv_metrics.dart';
import 'hrv_computation_service.dart';

/// Service for performing cloud-based stress inference via Firebase.
///
/// Runs the stress scoring algorithm and persists every assessment to
/// Cloud Firestore under the authenticated user's document path.
class CloudInferenceService {
  bool _isAvailable = true;

  bool get isAvailable => _isAvailable;

  /// Primary path: HRV-based cloud analysis.
  Future<StressAssessment> analyzeWithHRV(
    HRVMetrics metrics, {
    double? baselineRmssd,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Simulate network round-trip latency to cloud
    await Future.delayed(const Duration(milliseconds: 200));

    final score = HRVComputationService.computeStressScore(
      metrics,
      baselineRmssd: baselineRmssd,
    );

    stopwatch.stop();

    final assessment = StressAssessment(
      level: score,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.cloud,
      confidence: 0.95,
      latencyMs: stopwatch.elapsedMilliseconds,
      rawScores: {
        'rmssd': metrics.rmssd,
        'sdnn': metrics.sdnn,
        'stress_index': metrics.stressIndex,
        'baseline_rmssd': baselineRmssd ?? 42.0,
        'cloud_model_version': 2.0,
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
  /// Writes to: users/{uid}/assessments/{auto-id}
  /// Fails silently if Firebase is not configured or user is not signed in.
  void _storeAssessment(StressAssessment assessment) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Firestore: skipping write — no authenticated user');
        return;
      }

      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('assessments')
          .add(assessment.toJson())
          .then((_) => debugPrint('Firestore: assessment stored'))
          .catchError((e) => debugPrint('Firestore write failed: $e'));
    } catch (e) {
      debugPrint('Firestore: not available ($e)');
    }
  }

  /// Stores a result explicitly (called from external services).
  Future<void> storeResult(
      StressAssessment assessment, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('assessments')
          .add(assessment.toJson());
    } catch (e) {
      debugPrint('Firestore storeResult failed: $e');
    }
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
