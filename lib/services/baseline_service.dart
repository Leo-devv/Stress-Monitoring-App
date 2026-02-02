import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/entities/hrv_metrics.dart';

/// Manages the user's personal HRV baseline.
///
/// Stress thresholds are individual -- a marathon runner's resting RMSSD of
/// 80ms is very different from a sedentary person's 30ms. This service learns
/// the user's normal range over a rolling 7-day window and stores it in Hive.
///
/// On first use, population defaults are used until enough personal data
/// accumulates (at least 5 sessions).
class BaselineService {
  static const String _boxName = 'hrv_baseline';
  static const String _samplesKey = 'rmssd_samples';
  static const String _baselineRmssdKey = 'baseline_rmssd';
  static const String _baselineSdnnKey = 'baseline_sdnn';
  static const String _baselineHrKey = 'baseline_hr';
  static const String _lastUpdateKey = 'last_update';

  // Population defaults for adults (Task Force 1996, adjusted for wrist PPG)
  static const double defaultRmssd = 42.0;
  static const double defaultSdnn = 50.0;
  static const int defaultRestingHr = 72;
  static const int minSamplesForBaseline = 5;
  static const int maxStoredSamples = 200;

  Box? _box;

  double _baselineRmssd = defaultRmssd;
  double _baselineSdnn = defaultSdnn;
  int _baselineHr = defaultRestingHr;

  double get baselineRmssd => _baselineRmssd;
  double get baselineSdnn => _baselineSdnn;
  int get baselineHr => _baselineHr;
  bool get hasPersonalBaseline => _sampleCount >= minSamplesForBaseline;

  int get _sampleCount {
    final samples = _box?.get(_samplesKey);
    if (samples is List) return samples.length;
    return 0;
  }

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    _baselineRmssd = _box!.get(_baselineRmssdKey, defaultValue: defaultRmssd);
    _baselineSdnn = _box!.get(_baselineSdnnKey, defaultValue: defaultSdnn);
    _baselineHr = _box!.get(_baselineHrKey, defaultValue: defaultRestingHr);
    debugPrint(
        'Baseline loaded: RMSSD=$_baselineRmssd, SDNN=$_baselineSdnn, HR=$_baselineHr');
  }

  /// Records a new HRV measurement and recalculates the baseline.
  /// Should be called with data from resting or low-activity periods.
  Future<void> recordMeasurement(HRVMetrics metrics) async {
    if (_box == null) await initialize();
    if (!metrics.hasSufficientData) return;

    // Store RMSSD sample with timestamp for 7-day windowing
    final samples = List<Map<dynamic, dynamic>>.from(
      _box!.get(_samplesKey, defaultValue: <Map<dynamic, dynamic>>[]),
    );

    samples.add({
      'rmssd': metrics.rmssd,
      'sdnn': metrics.sdnn,
      'hr': metrics.meanHeartRate,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    // Keep only the last 7 days of data
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    samples.removeWhere((s) => (s['ts'] as int) < sevenDaysAgo);

    // Cap total stored samples
    while (samples.length > maxStoredSamples) {
      samples.removeAt(0);
    }

    await _box!.put(_samplesKey, samples);

    if (samples.length >= minSamplesForBaseline) {
      _recalculateBaseline(samples);
    }
  }

  void _recalculateBaseline(List<Map<dynamic, dynamic>> samples) {
    double rmssdSum = 0;
    double sdnnSum = 0;
    int hrSum = 0;

    for (final s in samples) {
      rmssdSum += (s['rmssd'] as num).toDouble();
      sdnnSum += (s['sdnn'] as num).toDouble();
      hrSum += (s['hr'] as num).toInt();
    }

    _baselineRmssd = rmssdSum / samples.length;
    _baselineSdnn = sdnnSum / samples.length;
    _baselineHr = (hrSum / samples.length).round();

    _box!.put(_baselineRmssdKey, _baselineRmssd);
    _box!.put(_baselineSdnnKey, _baselineSdnn);
    _box!.put(_baselineHrKey, _baselineHr);
    _box!.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

    debugPrint('Baseline updated: RMSSD=$_baselineRmssd '
        '(${samples.length} samples)');
  }

  /// Returns the deviation from baseline as a percentage.
  /// Positive = more stressed than normal, negative = more relaxed.
  double deviationPercent(HRVMetrics current) {
    if (!current.hasSufficientData) return 0;
    if (_baselineRmssd <= 0) return 0;
    // RMSSD is inverted: lower = more stress
    return ((1 - current.rmssd / _baselineRmssd) * 100).clamp(-100, 200);
  }

  Future<void> reset() async {
    if (_box == null) return;
    await _box!.clear();
    _baselineRmssd = defaultRmssd;
    _baselineSdnn = defaultSdnn;
    _baselineHr = defaultRestingHr;
  }
}
