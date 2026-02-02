import 'package:csv/csv.dart';
import '../../domain/entities/sensor_reading.dart';

/// Utility class for parsing WESAD-format CSV data
class CsvParser {
  CsvParser._();

  /// Parses WESAD CSV data into a list of SensorReadings
  /// Expected columns: timestamp, bvp, eda, temperature
  static List<SensorReading> parseWesadData(String csvString) {
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(csvString, eol: '\n');

    if (rows.isEmpty) return [];

    // Skip header row if present
    final startIndex = rows[0][0].toString().toLowerCase().contains('time') ? 1 : 0;
    final readings = <SensorReading>[];
    final baseTime = DateTime.now();

    for (int i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 4) {
        try {
          readings.add(SensorReading(
            timestamp: baseTime.add(Duration(seconds: i - startIndex)),
            bvp: _parseDouble(row[1]),
            eda: _parseDouble(row[2]),
            temperature: _parseDouble(row[3]),
          ));
        } catch (e) {
          // Skip malformed rows
          continue;
        }
      }
    }

    return readings;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Cannot parse $value as double');
  }

  /// Generates synthetic WESAD-like data for testing/demo
  static List<SensorReading> generateSyntheticData({
    int count = 300,
    double baseHr = 72,
    double baseEda = 2.0,
    double baseTemp = 33.0,
  }) {
    final readings = <SensorReading>[];
    final baseTime = DateTime.now();

    for (int i = 0; i < count; i++) {
      // Generate stress wave pattern for realistic data variation
      final stressWave = _generateStressWave(i, count);

      readings.add(SensorReading(
        timestamp: baseTime.add(Duration(seconds: i)),
        bvp: baseHr + (stressWave * 30) + (_pseudoRandom(i) * 5 - 2.5),
        eda: baseEda + (stressWave * 3) + (_pseudoRandom(i + 1) * 0.5),
        temperature: baseTemp + (stressWave * 1.5) + (_pseudoRandom(i + 2) * 0.3 - 0.15),
      ));
    }

    return readings;
  }

  /// Generates a stress wave pattern (0-1) over the dataset
  static double _generateStressWave(int index, int total) {
    // Create multiple stress "episodes" throughout the data
    final progress = index / total;

    // Episode 1: around 20%
    final ep1 = _gaussianPeak(progress, 0.2, 0.05);
    // Episode 2: around 50%
    final ep2 = _gaussianPeak(progress, 0.5, 0.08);
    // Episode 3: around 80%
    final ep3 = _gaussianPeak(progress, 0.8, 0.06);

    return (ep1 + ep2 + ep3).clamp(0.0, 1.0);
  }

  static double _gaussianPeak(double x, double center, double width) {
    final diff = x - center;
    return (0.8 * (-(diff * diff) / (2 * width * width)).clamp(-10, 0)).exp();
  }

  // Simple pseudo-random for reproducible variation
  static double _pseudoRandom(int seed) {
    return ((seed * 1103515245 + 12345) % (1 << 16)) / (1 << 16);
  }
}

extension on double {
  double exp() => this > -10 ?
    _taylorExp(this) : 0.0;

  static double _taylorExp(double x) {
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
}
