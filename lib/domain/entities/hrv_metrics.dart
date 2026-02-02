import 'package:equatable/equatable.dart';

/// Heart Rate Variability metrics computed from a window of RR intervals.
///
/// These metrics follow clinical standards:
/// - RMSSD: short-term (parasympathetic) variability
/// - SDNN: total variability
/// - pNN50: percentage of successive intervals differing >50ms
/// - Baevsky Stress Index: sympathetic/parasympathetic balance
class HRVMetrics extends Equatable {
  final double rmssd;
  final double sdnn;
  final double pnn50;
  final double stressIndex;
  final int meanHeartRate;
  final int sampleCount;
  final DateTime timestamp;
  final Duration windowDuration;

  const HRVMetrics({
    required this.rmssd,
    required this.sdnn,
    required this.pnn50,
    required this.stressIndex,
    required this.meanHeartRate,
    required this.sampleCount,
    required this.timestamp,
    this.windowDuration = const Duration(minutes: 2),
  });

  bool get hasSufficientData => sampleCount >= 10;

  double get parasympatheticTone => rmssd;

  /// Confidence estimate based on sample count and artifact ratio.
  /// At least 30 clean intervals in a 2-minute window is ideal.
  double get confidence {
    if (sampleCount < 10) return 0.3;
    if (sampleCount < 20) return 0.6;
    if (sampleCount < 30) return 0.8;
    return 0.95;
  }

  Map<String, dynamic> toJson() => {
        'rmssd': rmssd,
        'sdnn': sdnn,
        'pnn50': pnn50,
        'stressIndex': stressIndex,
        'meanHeartRate': meanHeartRate,
        'sampleCount': sampleCount,
        'timestamp': timestamp.toIso8601String(),
        'windowMs': windowDuration.inMilliseconds,
      };

  factory HRVMetrics.fromJson(Map<String, dynamic> json) {
    return HRVMetrics(
      rmssd: (json['rmssd'] as num).toDouble(),
      sdnn: (json['sdnn'] as num).toDouble(),
      pnn50: (json['pnn50'] as num).toDouble(),
      stressIndex: (json['stressIndex'] as num).toDouble(),
      meanHeartRate: json['meanHeartRate'] as int,
      sampleCount: json['sampleCount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      windowDuration: Duration(
        milliseconds: json['windowMs'] as int? ?? 120000,
      ),
    );
  }

  static HRVMetrics placeholder() {
    return HRVMetrics(
      rmssd: 0,
      sdnn: 0,
      pnn50: 0,
      stressIndex: 0,
      meanHeartRate: 0,
      sampleCount: 0,
      timestamp: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        rmssd,
        sdnn,
        pnn50,
        stressIndex,
        meanHeartRate,
        sampleCount,
        timestamp,
      ];
}
