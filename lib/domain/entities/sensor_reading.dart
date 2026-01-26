import 'package:equatable/equatable.dart';

/// Represents a single sensor reading from the wearable device (or simulation)
class SensorReading extends Equatable {
  final DateTime timestamp;
  final double bvp; // Blood Volume Pulse (related to heart rate)
  final double eda; // Electrodermal Activity (skin conductance)
  final double temperature; // Skin temperature in Celsius

  const SensorReading({
    required this.timestamp,
    required this.bvp,
    required this.eda,
    required this.temperature,
  });

  /// Calculates approximate heart rate from BVP
  /// In real implementation, this would use peak detection algorithms
  double get heartRate => bvp.clamp(40.0, 200.0);

  /// Creates a copy with modified values
  SensorReading copyWith({
    DateTime? timestamp,
    double? bvp,
    double? eda,
    double? temperature,
  }) {
    return SensorReading(
      timestamp: timestamp ?? this.timestamp,
      bvp: bvp ?? this.bvp,
      eda: eda ?? this.eda,
      temperature: temperature ?? this.temperature,
    );
  }

  /// Creates a normalized input array for ML model
  List<double> toModelInput() {
    return [
      bvp / 200.0, // Normalize HR to 0-1
      eda / 10.0, // Normalize EDA to 0-1
      (temperature - 30.0) / 10.0, // Normalize temp to 0-1
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'bvp': bvp,
      'eda': eda,
      'temperature': temperature,
    };
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      bvp: (json['bvp'] as num).toDouble(),
      eda: (json['eda'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [timestamp, bvp, eda, temperature];
}
