import 'dart:async';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';
import '../domain/entities/hrv_metrics.dart';
import 'offloading_manager.dart';
import 'edge_inference_service.dart';
import 'cloud_inference_service.dart';

/// Unified stress analysis service that routes to Edge or Cloud
/// based on the OffloadingManager's decision.
///
/// Supports both HRV-based analysis (preferred when HRV data is available)
/// and raw sensor reading fallback (for simulation mode).
class StressAnalysisService {
  final OffloadingManager _offloadingManager;
  final EdgeInferenceService _edgeService;
  final CloudInferenceService _cloudService;

  final _assessmentController =
      StreamController<StressAssessment>.broadcast();
  final List<StressAssessment> _history = [];

  static const int maxHistorySize = 100;

  StressAnalysisService({
    required OffloadingManager offloadingManager,
    required EdgeInferenceService edgeService,
    required CloudInferenceService cloudService,
  })  : _offloadingManager = offloadingManager,
        _edgeService = edgeService,
        _cloudService = cloudService;

  Stream<StressAssessment> get assessmentStream =>
      _assessmentController.stream;

  List<StressAssessment> get history => List.unmodifiable(_history);

  StressAssessment? get latestAssessment =>
      _history.isNotEmpty ? _history.last : null;

  /// Analyzes stress from HRV metrics (preferred path).
  Future<StressAssessment> analyzeHRV(
    HRVMetrics metrics, {
    double? baselineRmssd,
  }) async {
    final mode = await _offloadingManager.determineProcessingMode();

    StressAssessment assessment;
    if (mode == ProcessingMode.edge) {
      assessment = await _edgeService.analyzeWithHRV(
        metrics,
        baselineRmssd: baselineRmssd,
      );
    } else {
      try {
        assessment = await _cloudService.analyzeWithHRV(
          metrics,
          baselineRmssd: baselineRmssd,
        );
      } catch (_) {
        assessment = await _edgeService.analyzeWithHRV(
          metrics,
          baselineRmssd: baselineRmssd,
        );
      }
    }

    _record(assessment);
    return assessment;
  }

  /// Analyzes stress from a raw sensor reading (simulation fallback).
  Future<StressAssessment> analyze(SensorReading reading) async {
    final mode = await _offloadingManager.determineProcessingMode();

    StressAssessment assessment;
    if (mode == ProcessingMode.edge) {
      assessment = await _edgeService.analyzeStress(reading);
    } else {
      try {
        assessment = await _cloudService.analyzeStress(reading);
      } catch (_) {
        assessment = await _edgeService.analyzeStress(reading);
      }
    }

    _record(assessment);
    return assessment;
  }

  void _record(StressAssessment assessment) {
    _history.add(assessment);
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    _assessmentController.add(assessment);
  }

  void clearHistory() {
    _history.clear();
  }

  double getAverageStress({int lastN = 10}) {
    if (_history.isEmpty) return 0;

    final recentReadings = _history.length >= lastN
        ? _history.sublist(_history.length - lastN)
        : _history;

    final sum = recentReadings.fold<int>(0, (sum, a) => sum + a.level);
    return sum / recentReadings.length;
  }

  double getStressTrend({int windowSize = 5}) {
    if (_history.length < windowSize * 2) return 0;

    final recent = _history.sublist(_history.length - windowSize);
    final previous = _history.sublist(
        _history.length - windowSize * 2, _history.length - windowSize);

    final recentAvg =
        recent.fold<int>(0, (sum, a) => sum + a.level) / windowSize;
    final previousAvg =
        previous.fold<int>(0, (sum, a) => sum + a.level) / windowSize;

    return recentAvg - previousAvg;
  }

  void dispose() {
    _assessmentController.close();
  }
}
