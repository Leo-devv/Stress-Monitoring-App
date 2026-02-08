import 'dart:math';
import '../core/constants/stress_thresholds.dart';
import '../domain/entities/hrv_metrics.dart';

/// Result of the threshold-based stress classification.
///
/// Contains the composite score plus per-feature subscores and
/// confidence so callers can inspect the reasoning.
class StressResult {
  /// Composite stress score (0-100).
  final int score;

  /// Per-feature subscores (each 0-100).
  final Map<String, double> subscores;

  /// Confidence in the composite result (0.0–1.0).
  final double confidence;

  const StressResult({
    required this.score,
    required this.subscores,
    required this.confidence,
  });
}

/// Baseline values for baseline-relative scoring.
class BaselineValues {
  final double rmssd;
  final double sdnn;
  final int meanHr;

  const BaselineValues({
    required this.rmssd,
    required this.sdnn,
    required this.meanHr,
  });
}

/// Clinically-informed, threshold-based stress classification engine.
///
/// Uses a transparent, deterministic scoring system based on clinical
/// HRV reference ranges.  Each feature is mapped
/// to a 0-100 stress subscale via piecewise-linear interpolation across
/// four zones (relaxed / normal / elevated / high), then combined using
/// evidence-based weights from [StressThresholds].
///
/// When a personal baseline is available the engine blends absolute
/// thresholds (population norms) with baseline-relative deviations,
/// producing an individualised score.
class ThresholdStressEngine {
  const ThresholdStressEngine._();

  // ────────────────────────────────────────────────────────
  //  Public API
  // ────────────────────────────────────────────────────────

  /// Scores [metrics] against clinical thresholds and an optional
  /// personal [baseline].
  ///
  /// Returns [StressResult] with composite score, per-feature
  /// breakdown, and confidence.
  static StressResult evaluate(
    HRVMetrics metrics, {
    BaselineValues? baseline,
  }) {
    if (!metrics.hasSufficientData) {
      return const StressResult(
        score: 0,
        subscores: {},
        confidence: 0.0,
      );
    }

    // 1. Score each feature on an absolute 0-100 scale.
    final absRmssd = _scoreRmssd(metrics.rmssd);
    final absSdnn = _scoreSdnn(metrics.sdnn);
    final absPnn50 = _scorePnn50(metrics.pnn50);
    final absSi = _scoreBaevskySi(metrics.stressIndex);
    final absLfHf = _scoreLfHfRatio(metrics.lfHfRatio);
    final absHf = _scoreHfPower(metrics.hfPower);
    final absHr = _scoreMeanHr(metrics.meanHeartRate.toDouble());

    // 2. If we have a personal baseline, compute baseline-relative
    //    scores and blend them in.
    double rmssdScore = absRmssd;
    double sdnnScore = absSdnn;
    double hrScore = absHr;

    if (baseline != null) {
      const bw = StressThresholds.baselineBlendWeight;
      rmssdScore = _blend(absRmssd, _baselineRelative(
        current: metrics.rmssd,
        baseline: baseline.rmssd,
        lowerIsBetter: false,
      ), bw);
      sdnnScore = _blend(absSdnn, _baselineRelative(
        current: metrics.sdnn,
        baseline: baseline.sdnn,
        lowerIsBetter: false,
      ), bw);
      hrScore = _blend(absHr, _baselineRelative(
        current: metrics.meanHeartRate.toDouble(),
        baseline: baseline.meanHr.toDouble(),
        lowerIsBetter: true,
      ), bw);
    }

    // 3. Build subscores map.
    final subscores = <String, double>{
      'rmssd': rmssdScore,
      'sdnn': sdnnScore,
      'pnn50': absPnn50,
      'baevskySi': absSi,
      'lfHfRatio': absLfHf,
      'hfPower': absHf,
      'meanHr': hrScore,
    };

    // 4. Weighted composite.
    final composite = rmssdScore * StressThresholds.weightRmssd +
        sdnnScore * StressThresholds.weightSdnn +
        absPnn50 * StressThresholds.weightPnn50 +
        absSi * StressThresholds.weightBaevskySi +
        absLfHf * StressThresholds.weightLfHfRatio +
        absHf * StressThresholds.weightHfPower +
        hrScore * StressThresholds.weightMeanHr;

    // 5. Confidence based on data quality + feature agreement.
    final confidence = _computeConfidence(metrics, subscores);

    return StressResult(
      score: composite.round().clamp(0, 100),
      subscores: subscores,
      confidence: confidence,
    );
  }

  // ────────────────────────────────────────────────────────
  //  Per-feature scorers (piecewise-linear, 0-100 output)
  //
  //  Convention: 0 = fully relaxed, 100 = maximum stress.
  // ────────────────────────────────────────────────────────

  /// RMSSD: higher value → lower stress (inverted).
  static double _scoreRmssd(double rmssd) {
    return _invertedPiecewise(
      rmssd,
      relaxed: StressThresholds.rmssdRelaxed,
      normal: StressThresholds.rmssdNormal,
      elevated: StressThresholds.rmssdElevated,
    );
  }

  /// SDNN: higher value → lower stress (inverted).
  static double _scoreSdnn(double sdnn) {
    return _invertedPiecewise(
      sdnn,
      relaxed: StressThresholds.sdnnRelaxed,
      normal: StressThresholds.sdnnNormal,
      elevated: StressThresholds.sdnnElevated,
    );
  }

  /// pNN50: higher value → lower stress (inverted).
  static double _scorePnn50(double pnn50) {
    return _invertedPiecewise(
      pnn50,
      relaxed: StressThresholds.pnn50Relaxed,
      normal: StressThresholds.pnn50Normal,
      elevated: StressThresholds.pnn50Elevated,
    );
  }

  /// Baevsky SI: higher value → higher stress (direct).
  static double _scoreBaevskySi(double si) {
    return _directPiecewise(
      si,
      relaxed: StressThresholds.siRelaxed,
      normal: StressThresholds.siNormal,
      elevated: StressThresholds.siElevated,
    );
  }

  /// LF/HF Ratio: higher value → higher stress (direct).
  static double _scoreLfHfRatio(double ratio) {
    return _directPiecewise(
      ratio,
      relaxed: StressThresholds.lfHfRelaxed,
      normal: StressThresholds.lfHfNormal,
      elevated: StressThresholds.lfHfElevated,
    );
  }

  /// HF Power: higher value → lower stress (inverted).
  static double _scoreHfPower(double hf) {
    return _invertedPiecewise(
      hf,
      relaxed: StressThresholds.hfPowerRelaxed,
      normal: StressThresholds.hfPowerNormal,
      elevated: StressThresholds.hfPowerElevated,
    );
  }

  /// Mean HR: higher value → higher stress (direct).
  static double _scoreMeanHr(double hr) {
    return _directPiecewise(
      hr,
      relaxed: StressThresholds.hrRelaxed,
      normal: StressThresholds.hrNormal,
      elevated: StressThresholds.hrElevated,
    );
  }

  // ────────────────────────────────────────────────────────
  //  Piecewise-linear interpolation helpers
  // ────────────────────────────────────────────────────────

  /// For metrics where a **lower** raw value means **more** stress
  /// (e.g. RMSSD, SDNN, pNN50, HF power).
  ///
  /// Zone mapping (value → stress):
  ///   value ≥ relaxed  →  0–12  (relaxed)
  ///   normal–relaxed   → 13–37  (normal)
  ///   elevated–normal  → 38–62  (elevated)
  ///   0–elevated       → 63–100 (high)
  static double _invertedPiecewise(
    double value, {
    required double relaxed,
    required double normal,
    required double elevated,
  }) {
    if (value >= relaxed) {
      // Relaxed zone: score 0–12
      return (12.0 * (1 - ((value - relaxed) / relaxed).clamp(0.0, 1.0)))
          .clamp(0, 12);
    } else if (value >= normal) {
      // Normal zone: 13–37
      final t = (relaxed - value) / (relaxed - normal);
      return 13.0 + t * 24.0;
    } else if (value >= elevated) {
      // Elevated zone: 38–62
      final t = (normal - value) / (normal - elevated);
      return 38.0 + t * 24.0;
    } else {
      // High zone: 63–100
      final t = (elevated - value) / elevated;
      return 63.0 + t.clamp(0.0, 1.0) * 37.0;
    }
  }

  /// For metrics where a **higher** raw value means **more** stress
  /// (e.g. Baevsky SI, LF/HF ratio, mean HR).
  static double _directPiecewise(
    double value, {
    required double relaxed,
    required double normal,
    required double elevated,
  }) {
    if (value <= relaxed) {
      // Relaxed zone: 0–12
      return (value / relaxed * 12.0).clamp(0, 12);
    } else if (value <= normal) {
      // Normal zone: 13–37
      final t = (value - relaxed) / (normal - relaxed);
      return 13.0 + t * 24.0;
    } else if (value <= elevated) {
      // Elevated zone: 38–62
      final t = (value - normal) / (elevated - normal);
      return 38.0 + t * 24.0;
    } else {
      // High zone: 63–100
      final overshoot = (value - elevated) / elevated;
      return (63.0 + overshoot.clamp(0.0, 1.0) * 37.0).clamp(63, 100);
    }
  }

  // ────────────────────────────────────────────────────────
  //  Baseline-relative scoring
  // ────────────────────────────────────────────────────────

  /// Produces a 0-100 score based on how far [current] deviates
  /// from the user's personal [baseline].
  ///
  /// [lowerIsBetter] flips the direction for HR (where lower is
  /// more relaxed) vs. RMSSD/SDNN (where higher is more relaxed).
  static double _baselineRelative({
    required double current,
    required double baseline,
    required bool lowerIsBetter,
  }) {
    if (baseline <= 0) return 50.0; // No useful baseline → neutral

    final ratio = current / baseline;

    // For "lower is better" metrics (HR): ratio > 1 = stressed
    // For "higher is better" metrics (RMSSD, SDNN): ratio < 1 = stressed
    double deviation;
    if (lowerIsBetter) {
      deviation = ratio - 1.0; // positive = stressed
    } else {
      deviation = 1.0 - ratio; // positive = stressed
    }

    // Map deviation to 0-100:
    //   deviation  0.0 → 25 (personal normal)
    //   deviation +0.3 → 62 (mildly above normal)
    //   deviation +0.6 → 87 (well above normal)
    //   deviation -0.3 → 12 (below normal = relaxed)
    return (25.0 + deviation * 120.0).clamp(0, 100);
  }

  /// Blends absolute and baseline-relative scores.
  static double _blend(double absolute, double relative, double relWeight) {
    return absolute * (1 - relWeight) + relative * relWeight;
  }

  // ────────────────────────────────────────────────────────
  //  Confidence estimation
  // ────────────────────────────────────────────────────────

  /// Confidence reflects:
  ///  - Data sufficiency (sample count)
  ///  - Feature agreement (low SD among subscores)
  static double _computeConfidence(
    HRVMetrics metrics,
    Map<String, double> subscores,
  ) {
    // Data sufficiency component (0.3–1.0)
    double dataSufficiency;
    if (metrics.sampleCount < 10) {
      dataSufficiency = 0.3;
    } else if (metrics.sampleCount < 20) {
      dataSufficiency = 0.5;
    } else if (metrics.sampleCount < 30) {
      dataSufficiency = 0.7;
    } else if (metrics.sampleCount < 50) {
      dataSufficiency = 0.85;
    } else {
      dataSufficiency = 0.95;
    }

    // Feature agreement component (0.5–1.0)
    // If all features agree the confidence is higher.
    if (subscores.isEmpty) return dataSufficiency * 0.5;
    final values = subscores.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final stdDev = sqrt(variance);
    // SD of 0 → perfect agreement (1.0), SD of 40+ → poor agreement (0.5)
    final agreement = (1.0 - (stdDev / 80.0)).clamp(0.5, 1.0);

    return (dataSufficiency * 0.6 + agreement * 0.4).clamp(0.0, 1.0);
  }
}
