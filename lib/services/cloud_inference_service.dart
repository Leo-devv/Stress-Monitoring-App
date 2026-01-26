import '../domain/entities/sensor_reading.dart';
import '../domain/entities/stress_assessment.dart';

/// Service for performing cloud-based stress inference
/// Calls Firebase Cloud Functions for "heavy" AI processing
/// For the prototype, this simulates cloud processing with a delay
class CloudInferenceService {
  bool _isAvailable = true;

  /// Whether the cloud service is available
  bool get isAvailable => _isAvailable;

  /// Analyzes stress level using cloud processing
  /// In production, this would call Firebase Cloud Functions
  Future<StressAssessment> analyzeStress(SensorReading reading) async {
    // Simulate network latency for cloud processing
    await Future.delayed(const Duration(milliseconds: 200));

    // Use the same algorithm as edge but mark as cloud processed
    // In production, this would call the Firebase Cloud Function

    final normalizedHr = _normalizeHeartRate(reading.bvp);
    final normalizedEda = _normalizeEda(reading.eda);
    final normalizedTemp = _normalizeTemperature(reading.temperature);

    // Weighted stress calculation with slightly different weights
    // Cloud model could use different/more sophisticated algorithm
    final rawStress = (normalizedHr * 0.45) +
        (normalizedEda * 0.40) +
        (normalizedTemp * 0.15);

    final smoothedStress = _sigmoidSmooth(rawStress);
    final stressLevel = (smoothedStress * 100).round().clamp(0, 100);

    return StressAssessment(
      level: stressLevel,
      timestamp: DateTime.now(),
      processedBy: ProcessingMode.cloud,
      confidence: 0.95, // Cloud typically has higher confidence
      rawScores: {
        'hr_contribution': normalizedHr * 0.45,
        'eda_contribution': normalizedEda * 0.40,
        'temp_contribution': normalizedTemp * 0.15,
        'cloud_model_version': 1.0,
      },
    );
  }

  double _normalizeHeartRate(double hr) {
    const minHr = 50.0;
    const maxHr = 140.0;
    return ((hr - minHr) / (maxHr - minHr)).clamp(0.0, 1.0);
  }

  double _normalizeEda(double eda) {
    const minEda = 0.0;
    const maxEda = 10.0;
    return ((eda - minEda) / (maxEda - minEda)).clamp(0.0, 1.0);
  }

  double _normalizeTemperature(double temp) {
    const minTemp = 31.0;
    const maxTemp = 38.0;
    return ((temp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
  }

  double _sigmoidSmooth(double x) {
    return 1 / (1 + _exp(-6 * (x - 0.5)));
  }

  double _exp(double x) {
    if (x < -10) return 0.0;
    if (x > 10) return 22026.0;
    double sum = 1.0;
    double term = 1.0;
    for (int i = 1; i < 20; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }

  /// Stores result to Firestore
  /// In production, this would write to Cloud Firestore
  Future<void> storeResult(StressAssessment assessment, String userId) async {
    // Simulated Firestore write
    await Future.delayed(const Duration(milliseconds: 50));
    // In production:
    // await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(userId)
    //     .collection('stress_readings')
    //     .add(assessment.toJson());
  }

  /// Sets availability status (for testing offline scenarios)
  void setAvailability(bool available) {
    _isAvailable = available;
  }
}
