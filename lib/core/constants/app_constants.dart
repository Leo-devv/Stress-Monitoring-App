class AppConstants {
  AppConstants._();

  static const String appName = 'Stress Monitor';
  static const String appVersion = '1.0.0';

  // Sensor simulation intervals
  static const Duration sensorEmissionInterval = Duration(seconds: 1);
  static const int maxChartDataPoints = 60;

  // Battery thresholds
  static const double batteryThresholdLow = 0.20; // 20%
  static const double batteryThresholdCritical = 0.10; // 10%

  // Hive box names
  static const String sensorReadingsBox = 'sensor_readings';
  static const String userSettingsBox = 'user_settings';
  static const String stressHistoryBox = 'stress_history';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String stressReadingsCollection = 'stress_readings';

  // Method channel
  static const String methodChannelName = 'com.stressmonitor.app/foreground_service';
}
