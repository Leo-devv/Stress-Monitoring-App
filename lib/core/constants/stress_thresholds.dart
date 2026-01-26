import 'package:flutter/material.dart';

class StressThresholds {
  StressThresholds._();

  // Stress level boundaries (0-100 scale)
  static const int relaxed = 25;
  static const int normal = 50;
  static const int elevated = 75;
  static const int high = 100;

  // Heart rate boundaries (BPM)
  static const double hrRestingLow = 60;
  static const double hrRestingHigh = 80;
  static const double hrElevated = 100;
  static const double hrHigh = 120;

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
    if (level <= relaxed) return 'Relaxed';
    if (level <= normal) return 'Normal';
    if (level <= elevated) return 'Elevated';
    return 'High';
  }

  static Color getStressColor(int level) {
    if (level <= relaxed) return const Color(0xFF22C55E); // Green
    if (level <= normal) return const Color(0xFF3B82F6); // Blue
    if (level <= elevated) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  static Color getStressColorGradientStart(int level) {
    if (level <= relaxed) return const Color(0xFF22C55E);
    if (level <= normal) return const Color(0xFF3B82F6);
    if (level <= elevated) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static Color getStressColorGradientEnd(int level) {
    if (level <= relaxed) return const Color(0xFF16A34A);
    if (level <= normal) return const Color(0xFF2563EB);
    if (level <= elevated) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }
}
