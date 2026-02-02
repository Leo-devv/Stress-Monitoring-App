import 'package:flutter/material.dart';

/// Clinical reference ranges and thresholds for stress classification.
///
/// Sources:
///  - Task Force of the European Society of Cardiology (1996)
///  - Shaffer & Ginsberg (2017) — An Overview of HRV Metrics and Norms
///  - Baevsky et al. (2001) — Stress Index reference values
///  - Nunan et al. (2010) — meta-analysis of short-term HRV norms
class StressThresholds {
  StressThresholds._();

  // ──────────────────────────────────────────────────────────
  //  Composite stress level UI boundaries (0-100 scale)
  // ──────────────────────────────────────────────────────────
  static const int relaxedMax = 25;
  static const int normalMax = 50;
  static const int elevatedMax = 75;

  // ──────────────────────────────────────────────────────────
  //  RMSSD (ms) — primary parasympathetic marker
  //  Higher RMSSD = more vagal tone = less stress
  //  Nunan et al. 2010: healthy adult mean ≈ 42 ms (SD ≈ 15)
  // ──────────────────────────────────────────────────────────
  static const double rmssdRelaxed = 60.0; // ≥ 60 → very relaxed
  static const double rmssdNormal = 40.0; // 40–59 → normal
  static const double rmssdElevated = 20.0; // 20–39 → elevated stress
  // < 20 → high stress

  // ──────────────────────────────────────────────────────────
  //  SDNN (ms) — total variability (sympathetic + parasympathetic)
  //  Task Force 1996: 5-min SDNN ~141 ms; short-term ~50 ms
  //  Lower SDNN = reduced overall HRV = higher stress
  // ──────────────────────────────────────────────────────────
  static const double sdnnRelaxed = 80.0; // ≥ 80 → relaxed
  static const double sdnnNormal = 50.0; // 50–79 → normal
  static const double sdnnElevated = 30.0; // 30–49 → elevated
  // < 30 → high stress

  // ──────────────────────────────────────────────────────────
  //  pNN50 (%) — percentage of successive RR diffs > 50 ms
  //  Parasympathetic index correlated with RMSSD
  //  Healthy adults at rest: ~10–25 %
  // ──────────────────────────────────────────────────────────
  static const double pnn50Relaxed = 25.0; // ≥ 25 → relaxed
  static const double pnn50Normal = 10.0; // 10–24 → normal
  static const double pnn50Elevated = 3.0; //  3–9  → elevated
  // < 3 → high stress

  // ──────────────────────────────────────────────────────────
  //  Baevsky Stress Index (SI)
  //  SI < 100   → low sympathetic activation (relaxed)
  //  SI 100–250 → moderate (normal)
  //  SI 250–500 → elevated sympathetic drive
  //  SI > 500   → high stress / overtraining
  // ──────────────────────────────────────────────────────────
  static const double siRelaxed = 100.0;
  static const double siNormal = 250.0;
  static const double siElevated = 500.0;
  // > 500 → high stress

  // ──────────────────────────────────────────────────────────
  //  LF/HF Ratio — sympatho-vagal balance
  //  Ratio > 4   → strong sympathetic dominance (high stress)
  //  Ratio 2–4   → moderate sympathetic (elevated)
  //  Ratio 0.5–2 → balanced (normal)
  //  Ratio < 0.5 → parasympathetic dominance (very relaxed)
  // ──────────────────────────────────────────────────────────
  static const double lfHfRelaxed = 0.5;
  static const double lfHfNormal = 2.0;
  static const double lfHfElevated = 4.0;
  // > 4.0 → high stress

  // ──────────────────────────────────────────────────────────
  //  HF Power (ms²) — parasympathetic activity band 0.15–0.4 Hz
  //  Higher HF = more vagal activity = less stress
  //  Short-term norms: ~975 ms² (very wide variance)
  //  Thresholds tuned for 60-second wrist-PPG windows
  // ──────────────────────────────────────────────────────────
  static const double hfPowerRelaxed = 400.0; // ≥ 400 → relaxed
  static const double hfPowerNormal = 150.0; // 150–399 → normal
  static const double hfPowerElevated = 40.0; // 40–149 → elevated
  // < 40 → high stress

  // ──────────────────────────────────────────────────────────
  //  Mean Heart Rate (BPM)
  //  Resting: 60–80 normal; >90 elevated; >100 high
  // ──────────────────────────────────────────────────────────
  static const double hrRelaxed = 65.0; // ≤ 65 → very relaxed
  static const double hrNormal = 80.0; // 66–80 → normal
  static const double hrElevated = 95.0; // 81–95 → elevated
  static const double hrHigh = 120.0; // > 120 → very high stress

  // ──────────────────────────────────────────────────────────
  //  Feature weights for composite scoring
  //
  //  RMSSD and SDNN carry the most weight as the most validated
  //  short-term HRV metrics.  LF/HF and Baevsky SI add sympatho-
  //  vagal context.  pNN50 and HF power are correlated with RMSSD
  //  so receive lower independent weight.  Mean HR is a basic
  //  autonomic indicator that provides a sanity anchor.
  // ──────────────────────────────────────────────────────────
  static const double weightRmssd = 0.25;
  static const double weightSdnn = 0.15;
  static const double weightPnn50 = 0.10;
  static const double weightBaevskySi = 0.15;
  static const double weightLfHfRatio = 0.15;
  static const double weightHfPower = 0.10;
  static const double weightMeanHr = 0.10;
  // Sum = 1.00

  // ──────────────────────────────────────────────────────────
  //  Baseline-relative scoring amplification
  //  When personal baseline is available, deviations from baseline
  //  are scaled by this factor before blending with absolute scores.
  // ──────────────────────────────────────────────────────────
  static const double baselineBlendWeight = 0.4;

  // ──────────────────────────────────────────────────────────
  //  Legacy UI helpers (kept for backward compatibility)
  // ──────────────────────────────────────────────────────────

  // Heart rate boundaries (BPM)
  static const double hrRestingLow = 60;
  static const double hrRestingHigh = 80;

  // EDA (Electrodermal Activity) boundaries (microsiemens)
  static const double edaLow = 0.5;
  static const double edaNormal = 2.0;
  static const double edaElevated = 5.0;
  static const double edaHigh = 10.0;

  // Temperature boundaries (Celsius)
  static const double tempLow = 32.0;
  static const double tempNormal = 33.5;
  static const double tempElevated = 35.0;

  static String getStressLabel(int level) {
    if (level <= relaxedMax) return 'Relaxed';
    if (level <= normalMax) return 'Normal';
    if (level <= elevatedMax) return 'Elevated';
    return 'High';
  }

  static Color getStressColor(int level) {
    if (level <= relaxedMax) return const Color(0xFF22C55E);
    if (level <= normalMax) return const Color(0xFF3B82F6);
    if (level <= elevatedMax) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static Color getStressColorGradientStart(int level) {
    if (level <= relaxedMax) return const Color(0xFF22C55E);
    if (level <= normalMax) return const Color(0xFF3B82F6);
    if (level <= elevatedMax) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static Color getStressColorGradientEnd(int level) {
    if (level <= relaxedMax) return const Color(0xFF16A34A);
    if (level <= normalMax) return const Color(0xFF2563EB);
    if (level <= elevatedMax) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }
}
