import 'package:equatable/equatable.dart';

/// A single beat-to-beat interval extracted from PPG or ECG signal.
/// This is the fundamental building block for HRV computation.
class RRInterval extends Equatable {
  final DateTime timestamp;
  final int milliseconds;

  const RRInterval({
    required this.timestamp,
    required this.milliseconds,
  });

  double get seconds => milliseconds / 1000.0;

  double get instantaneousBpm => 60000.0 / milliseconds;

  bool get isPhysiologicallyValid =>
      milliseconds >= 300 && milliseconds <= 2000;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'ms': milliseconds,
      };

  factory RRInterval.fromJson(Map<String, dynamic> json) {
    return RRInterval(
      timestamp: DateTime.parse(json['timestamp'] as String),
      milliseconds: json['ms'] as int,
    );
  }

  @override
  List<Object?> get props => [timestamp, milliseconds];
}
