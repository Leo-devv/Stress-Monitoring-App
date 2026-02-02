import 'package:equatable/equatable.dart';

/// Processing mode for stress analysis
enum ProcessingMode {
  edge, // On-device threshold-based processing
  cloud, // Cloud processing with Firestore persistence
}

/// Represents the result of a stress analysis
class StressAssessment extends Equatable {
  final int level; // 0-100 stress level
  final DateTime timestamp;
  final ProcessingMode processedBy;
  final double confidence; // Model confidence 0-1
  final Map<String, double>? rawScores; // Optional detailed scores
  final int? latencyMs; // Inference latency in milliseconds
  final int? subjectiveRating; // User self-reported stress 1-10

  /// Acquisition metadata
  final String? acquisitionSource; // "ble" / "camera" / "simulator"
  final double? acquisitionDuration; // seconds

  /// Named HRV feature map (sdnn, rmssd, pnn50, lfPower, hfPower, lfHfRatio)
  final Map<String, double>? features;

  const StressAssessment({
    required this.level,
    required this.timestamp,
    required this.processedBy,
    this.confidence = 1.0,
    this.rawScores,
    this.latencyMs,
    this.subjectiveRating,
    this.acquisitionSource,
    this.acquisitionDuration,
    this.features,
  });

  /// Returns true if this is a high stress reading
  bool get isHighStress => level >= 75;

  /// Returns true if this is an elevated stress reading
  bool get isElevatedStress => level >= 50;

  /// Returns the processing mode as a string
  String get processingModeLabel =>
      processedBy == ProcessingMode.edge ? 'EDGE' : 'CLOUD';

  /// Categorical stress label required by the Firestore schema.
  String get stressLevelLabel => level >= 50 ? 'stressed' : 'not_stressed';

  StressAssessment copyWith({
    int? level,
    DateTime? timestamp,
    ProcessingMode? processedBy,
    double? confidence,
    Map<String, double>? rawScores,
    int? latencyMs,
    int? subjectiveRating,
    String? acquisitionSource,
    double? acquisitionDuration,
    Map<String, double>? features,
  }) {
    return StressAssessment(
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      processedBy: processedBy ?? this.processedBy,
      confidence: confidence ?? this.confidence,
      rawScores: rawScores ?? this.rawScores,
      latencyMs: latencyMs ?? this.latencyMs,
      subjectiveRating: subjectiveRating ?? this.subjectiveRating,
      acquisitionSource: acquisitionSource ?? this.acquisitionSource,
      acquisitionDuration: acquisitionDuration ?? this.acquisitionDuration,
      features: features ?? this.features,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'stressLevel': stressLevelLabel,
      'timestamp': timestamp.toIso8601String(),
      'processedBy': processedBy.name,
      'confidence': confidence,
      'rawScores': rawScores,
      'latencyMs': latencyMs,
      'subjectiveRating': subjectiveRating,
      if (acquisitionSource != null) 'acquisitionSource': acquisitionSource,
      if (acquisitionDuration != null)
        'acquisitionDuration': acquisitionDuration,
      if (features != null) 'features': features,
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
      latencyMs: json['latencyMs'] as int?,
      subjectiveRating: json['subjectiveRating'] as int?,
      acquisitionSource: json['acquisitionSource'] as String?,
      acquisitionDuration:
          (json['acquisitionDuration'] as num?)?.toDouble(),
      features: json['features'] != null
          ? Map<String, double>.from(json['features'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        level,
        timestamp,
        processedBy,
        confidence,
        rawScores,
        latencyMs,
        subjectiveRating,
        acquisitionSource,
        acquisitionDuration,
        features,
      ];
}
