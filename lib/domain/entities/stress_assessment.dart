import 'package:equatable/equatable.dart';

/// Processing mode for stress analysis
enum ProcessingMode {
  edge, // On-device TFLite processing
  cloud, // Firebase Cloud Function processing
}

/// Represents the result of a stress analysis
class StressAssessment extends Equatable {
  final int level; // 0-100 stress level
  final DateTime timestamp;
  final ProcessingMode processedBy;
  final double confidence; // Model confidence 0-1
  final Map<String, double>? rawScores; // Optional detailed scores

  const StressAssessment({
    required this.level,
    required this.timestamp,
    required this.processedBy,
    this.confidence = 1.0,
    this.rawScores,
  });

  /// Returns true if this is a high stress reading
  bool get isHighStress => level >= 75;

  /// Returns true if this is an elevated stress reading
  bool get isElevatedStress => level >= 50;

  /// Returns the processing mode as a string
  String get processingModeLabel =>
      processedBy == ProcessingMode.edge ? 'EDGE' : 'CLOUD';

  StressAssessment copyWith({
    int? level,
    DateTime? timestamp,
    ProcessingMode? processedBy,
    double? confidence,
    Map<String, double>? rawScores,
  }) {
    return StressAssessment(
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      processedBy: processedBy ?? this.processedBy,
      confidence: confidence ?? this.confidence,
      rawScores: rawScores ?? this.rawScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'timestamp': timestamp.toIso8601String(),
      'processedBy': processedBy.name,
      'confidence': confidence,
      'rawScores': rawScores,
    };
  }

  factory StressAssessment.fromJson(Map<String, dynamic> json) {
    return StressAssessment(
      level: json['level'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      processedBy: ProcessingMode.values.byName(json['processedBy'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      rawScores: json['rawScores'] != null
          ? Map<String, double>.from(json['rawScores'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [level, timestamp, processedBy, confidence, rawScores];
}
