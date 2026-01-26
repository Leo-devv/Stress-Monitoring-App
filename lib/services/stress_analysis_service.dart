import 'dart:async';
import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';
import 'offloading_manager.dart';
import 'edge_inference_service.dart';
import 'cloud_inference_service.dart';

/// Unified stress analysis service that routes to Edge or Cloud
/// based on the OffloadingManager's decision
class StressAnalysisService {
  final OffloadingManager _offloadingManager;
  final EdgeInferenceService _edgeService;
  final CloudInferenceService _cloudService;

  final _assessmentController = StreamController<StressAssessment>.broadcast();
  final List<StressAssessment> _history = [];

  static const int maxHistorySize = 100;

  StressAnalysisService({
    required OffloadingManager offloadingManager,
    required EdgeInferenceService edgeService,
    required CloudInferenceService cloudService,
  })  : _offloadingManager = offloadingManager,
        _edgeService = edgeService,
        _cloudService = cloudService;

  /// Stream of stress assessments
  Stream<StressAssessment> get assessmentStream => _assessmentController.stream;

  /// History of recent assessments
  List<StressAssessment> get history => List.unmodifiable(_history);

  /// Latest assessment
  StressAssessment? get latestAssessment =>
      _history.isNotEmpty ? _history.last : null;

  /// Analyzes a sensor reading and emits the result
  Future<StressAssessment> analyze(SensorReading reading) async {
    // Determine processing mode
    final mode = await _offloadingManager.determineProcessingMode();

    // Route to appropriate service
    StressAssessment assessment;
    if (mode == ProcessingMode.edge) {
      assessment = await _edgeService.analyzeStress(reading);
    } else {
      try {
        assessment = await _cloudService.analyzeStress(reading);
      } catch (e) {
        // Fallback to edge if cloud fails
        assessment = await _edgeService.analyzeStress(reading);
      }
    }

    // Store in history
    _history.add(assessment);
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }

    // Emit to stream
    _assessmentController.add(assessment);

    return assessment;
  }

  /// Clears analysis history
  void clearHistory() {
    _history.clear();
  }

  /// Gets average stress level from recent history
  double getAverageStress({int lastN = 10}) {
    if (_history.isEmpty) return 0;

    final recentReadings = _history.length >= lastN
        ? _history.sublist(_history.length - lastN)
        : _history;

    final sum = recentReadings.fold<int>(0, (sum, a) => sum + a.level);
    return sum / recentReadings.length;
  }

  /// Gets stress trend (positive = increasing, negative = decreasing)
  double getStressTrend({int windowSize = 5}) {
    if (_history.length < windowSize * 2) return 0;

    final recent = _history.sublist(_history.length - windowSize);
    final previous = _history.sublist(
        _history.length - windowSize * 2, _history.length - windowSize);

    final recentAvg = recent.fold<int>(0, (sum, a) => sum + a.level) / windowSize;
    final previousAvg =
        previous.fold<int>(0, (sum, a) => sum + a.level) / windowSize;

    return recentAvg - previousAvg;
  }

  void dispose() {
    _assessmentController.close();
  }
}
