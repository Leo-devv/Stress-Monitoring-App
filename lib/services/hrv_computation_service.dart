import 'dart:async';
import 'dart:math';
import '../domain/entities/rr_interval.dart';
import '../domain/entities/hrv_metrics.dart';

/// Computes Heart Rate Variability metrics from a stream of RR intervals.
///
/// Implements the standard time-domain HRV analysis methods:
///  - RMSSD  (short-term parasympathetic variability)
///  - SDNN   (total variability)
///  - pNN50  (parasympathetic index)
///  - Baevsky Stress Index (sympatho-vagal balance)
///
/// Computation follows the Task Force of the European Society of Cardiology
/// guidelines and matches the approach used by Kubios HRV software.
class HRVComputationService {
  final Duration windowDuration;
  final Duration computeInterval;

  final List<RRInterval> _buffer = [];
  final _metricsController = StreamController<HRVMetrics>.broadcast();
  Timer? _computeTimer;

  HRVComputationService({
    this.windowDuration = const Duration(minutes: 2),
    this.computeInterval = const Duration(seconds: 5),
  });

  Stream<HRVMetrics> get metricsStream => _metricsController.stream;

  void addInterval(RRInterval rr) {
    if (!rr.isPhysiologicallyValid) return;

    // Artifact rejection: reject if the interval deviates more than 20%
    // from the previous interval (ectopic beat detection)
    if (_buffer.isNotEmpty) {
      final prev = _buffer.last.milliseconds;
      final deviation = (rr.milliseconds - prev).abs() / prev;
      if (deviation > 0.20) return;
    }

    _buffer.add(rr);
    _pruneBuffer();
  }

  void startPeriodicComputation() {
    _computeTimer?.cancel();
    _computeTimer = Timer.periodic(computeInterval, (_) {
      final metrics = computeFromBuffer();
      if (metrics != null) {
        _metricsController.add(metrics);
      }
    });
  }

  void stopPeriodicComputation() {
    _computeTimer?.cancel();
    _computeTimer = null;
  }

  /// Computes HRV metrics from the current buffer contents.
  HRVMetrics? computeFromBuffer() {
    _pruneBuffer();
    if (_buffer.length < 10) return null;

    final intervals = _buffer.map((r) => r.milliseconds.toDouble()).toList();
    return computeMetrics(intervals);
  }

  /// Core computation from a list of RR interval durations (ms).
  HRVMetrics computeMetrics(List<double> intervals) {
    final n = intervals.length;
    if (n < 5) return HRVMetrics.placeholder();

    // Mean RR
    final meanRR = intervals.reduce((a, b) => a + b) / n;

    // SDNN: standard deviation of all NN intervals
    final sdnn = _standardDeviation(intervals, meanRR);

    // Successive differences
    final diffs = <double>[];
    for (int i = 1; i < n; i++) {
      diffs.add(intervals[i] - intervals[i - 1]);
    }

    // RMSSD: root mean square of successive differences
    final squaredDiffs = diffs.map((d) => d * d);
    final rmssd = sqrt(squaredDiffs.reduce((a, b) => a + b) / diffs.length);

    // pNN50: percentage of successive intervals differing by more than 50ms
    final nn50Count = diffs.where((d) => d.abs() > 50).length;
    final pnn50 = (nn50Count / diffs.length) * 100.0;

    // Baevsky Stress Index: SI = AMo / (2 * VR * Mo)
    final stressIndex = _computeBaevskyIndex(intervals);

    final meanHr = (60000 / meanRR).round();

    return HRVMetrics(
      rmssd: rmssd,
      sdnn: sdnn,
      pnn50: pnn50,
      stressIndex: stressIndex,
      meanHeartRate: meanHr,
      sampleCount: n,
      timestamp: DateTime.now(),
      windowDuration: windowDuration,
    );
  }

  /// Converts HRV metrics to a 0-100 stress score.
  ///
  /// Uses an inverse mapping of RMSSD to stress:
  ///   RMSSD >= 60ms   -> ~10-20 (relaxed)
  ///   RMSSD ~40ms     -> ~35-45 (normal)
  ///   RMSSD ~25ms     -> ~55-65 (elevated)
  ///   RMSSD <= 15ms   -> ~80-95 (high stress)
  ///
  /// The Baevsky SI provides a secondary input.
  static int computeStressScore(HRVMetrics metrics, {double? baselineRmssd}) {
    if (!metrics.hasSufficientData) return 0;

    final baseline = baselineRmssd ?? 42.0;

    // RMSSD-based score (primary, 70% weight)
    // Lower RMSSD = higher stress
    final rmssdRatio = metrics.rmssd / baseline;
    double rmssdScore;
    if (rmssdRatio >= 1.4) {
      rmssdScore = 10;
    } else if (rmssdRatio >= 1.0) {
      rmssdScore = 10 + (1.4 - rmssdRatio) * 75;
    } else if (rmssdRatio >= 0.5) {
      rmssdScore = 40 + (1.0 - rmssdRatio) * 80;
    } else {
      rmssdScore = 80 + (0.5 - rmssdRatio) * 40;
    }

    // Baevsky SI-based score (secondary, 30% weight)
    // SI < 100 is relaxed, SI > 500 is highly stressed
    final si = metrics.stressIndex.clamp(0, 1000);
    double siScore;
    if (si < 100) {
      siScore = si / 100 * 25;
    } else if (si < 250) {
      siScore = 25 + (si - 100) / 150 * 25;
    } else if (si < 500) {
      siScore = 50 + (si - 250) / 250 * 25;
    } else {
      siScore = 75 + (si - 500) / 500 * 25;
    }

    final combined = rmssdScore * 0.7 + siScore * 0.3;
    return combined.round().clamp(0, 100);
  }

  /// Baevsky Stress Index:  SI = AMo / (2 * VR * Mo)
  ///
  ///   Mo    = mode of RR intervals (most frequent value, binned to 50ms)
  ///   AMo   = amplitude of the mode (% of intervals in the modal bin)
  ///   VR    = variation range = max(RR) - min(RR)
  double _computeBaevskyIndex(List<double> intervals) {
    if (intervals.length < 5) return 0;

    // Bin intervals to 50ms resolution
    const binWidth = 50.0;
    final bins = <int, int>{};
    for (final rr in intervals) {
      final bin = (rr / binWidth).round();
      bins[bin] = (bins[bin] ?? 0) + 1;
    }

    // Find mode (most frequent bin)
    int modeBin = 0;
    int modeCount = 0;
    bins.forEach((bin, count) {
      if (count > modeCount) {
        modeBin = bin;
        modeCount = count;
      }
    });

    final mo = modeBin * binWidth; // Mode in ms
    final amo = (modeCount / intervals.length) * 100; // Amplitude of mode (%)
    final vr = intervals.reduce(max) - intervals.reduce(min); // Variation range

    if (mo <= 0 || vr <= 0) return 0;
    return amo / (2 * vr / 1000 * mo / 1000);
  }

  double _standardDeviation(List<double> values, double mean) {
    final squaredDiffs =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return sqrt(squaredDiffs / (values.length - 1));
  }

  void _pruneBuffer() {
    final cutoff = DateTime.now().subtract(windowDuration);
    _buffer.removeWhere((rr) => rr.timestamp.isBefore(cutoff));
  }

  void clearBuffer() {
    _buffer.clear();
  }

  void dispose() {
    stopPeriodicComputation();
    _metricsController.close();
  }
}
