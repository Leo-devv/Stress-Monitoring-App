import 'package:equatable/equatable.dart';

/// Heart Rate Variability metrics computed from a window of RR intervals.
///
/// These metrics follow clinical standards:
/// - RMSSD: short-term (parasympathetic) variability
/// - SDNN: total variability
/// - pNN50: percentage of successive intervals differing >50ms
/// - Baevsky Stress Index: sympathetic/parasympathetic balance
/// - LF Power: low-frequency band (0.04–0.15 Hz) – sympathetic + parasympathetic
/// - HF Power: high-frequency band (0.15–0.4 Hz) – parasympathetic
/// - LF/HF Ratio: sympatho-vagal balance index
class HRVMetrics extends Equatable {
  final double rmssd;
  final double sdnn;
  final double pnn50;
  final double stressIndex;
  final int meanHeartRate;
  final int sampleCount;
  final DateTime timestamp;
  final Duration windowDuration;

  // Frequency-domain metrics (from Lomb-Scargle periodogram)
  final double lfPower;
  final double hfPower;
  final double lfHfRatio;

  const HRVMetrics({
    required this.rmssd,
    required this.sdnn,
    required this.pnn50,
    required this.stressIndex,
    required this.meanHeartRate,
    required this.sampleCount,
    required this.timestamp,
    this.windowDuration = const Duration(seconds: 60),
    this.lfPower = 0.0,
    this.hfPower = 0.0,
    this.lfHfRatio = 0.0,
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

  HRVMetrics copyWith({
    double? rmssd,
    double? sdnn,
    double? pnn50,
    double? stressIndex,
    int? meanHeartRate,
    int? sampleCount,
    DateTime? timestamp,
    Duration? windowDuration,
    double? lfPower,
    double? hfPower,
    double? lfHfRatio,
  }) {
    return HRVMetrics(
      rmssd: rmssd ?? this.rmssd,
      sdnn: sdnn ?? this.sdnn,
      pnn50: pnn50 ?? this.pnn50,
      stressIndex: stressIndex ?? this.stressIndex,
      meanHeartRate: meanHeartRate ?? this.meanHeartRate,
      sampleCount: sampleCount ?? this.sampleCount,
      timestamp: timestamp ?? this.timestamp,
      windowDuration: windowDuration ?? this.windowDuration,
      lfPower: lfPower ?? this.lfPower,
      hfPower: hfPower ?? this.hfPower,
      lfHfRatio: lfHfRatio ?? this.lfHfRatio,
    );
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
        'lfPower': lfPower,
        'hfPower': hfPower,
        'lfHfRatio': lfHfRatio,
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
        milliseconds: json['windowMs'] as int? ?? 60000,
      ),
      lfPower: (json['lfPower'] as num?)?.toDouble() ?? 0.0,
      hfPower: (json['hfPower'] as num?)?.toDouble() ?? 0.0,
      lfHfRatio: (json['lfHfRatio'] as num?)?.toDouble() ?? 0.0,
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
        lfPower,
        hfPower,
        lfHfRatio,
      ];
}
