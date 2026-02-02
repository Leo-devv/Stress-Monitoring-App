import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages stress alert notifications with pattern detection and cooldown.
///
/// Prevents alert fatigue using three mechanisms:
///  1. Sustained threshold – alert only if stress stays high for N consecutive readings
///  2. Cooldown period – minimum gap between successive alerts
///  3. Recovery gate – after an alert, stress must drop below a recovery
///     threshold before a new alert cycle can begin
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // --- Alert state machine ---
  DateTime? _lastAlertTime;
  int _consecutiveHighCount = 0;
  bool _recoveredSinceLastAlert = true;

  // Configurable parameters
  int alertThreshold = 75;
  int recoveryThreshold = 55;
  int sustainedReadingsRequired = 3;
  Duration cooldownDuration = const Duration(minutes: 20);

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Evaluates whether a stress reading should trigger an alert.
  ///
  /// Call this every time a new stress score is computed. The method
  /// internally tracks the sustained-threshold, cooldown, and recovery
  /// state so callers don't need to manage any of that logic.
  Future<void> evaluateStressReading(int stressLevel) async {
    // Track recovery: stress must dip below recovery threshold
    // before we consider alerting again
    if (stressLevel < recoveryThreshold) {
      _recoveredSinceLastAlert = true;
      _consecutiveHighCount = 0;
      return;
    }

    // Count consecutive high readings
    if (stressLevel >= alertThreshold) {
      _consecutiveHighCount++;
    } else {
      _consecutiveHighCount = 0;
      return;
    }

    // All three conditions must be met to fire an alert:
    // 1. Sustained high stress
    if (_consecutiveHighCount < sustainedReadingsRequired) return;

    // 2. Recovered since last alert
    if (!_recoveredSinceLastAlert) return;

    // 3. Cooldown elapsed
    if (_lastAlertTime != null) {
      final elapsed = DateTime.now().difference(_lastAlertTime!);
      if (elapsed < cooldownDuration) return;
    }

    // Fire alert
    await showStressAlert(stressLevel: stressLevel);
    _lastAlertTime = DateTime.now();
    _recoveredSinceLastAlert = false;
    _consecutiveHighCount = 0;
  }

  Future<void> showStressAlert({
    required int stressLevel,
    String? message,
  }) async {
    if (!_isInitialized) await initialize();

    final title = _getAlertTitle(stressLevel);
    final body = message ?? _getAlertBody(stressLevel);

    final androidDetails = AndroidNotificationDetails(
      'stress_alerts',
      'Stress Alerts',
      channelDescription: 'Notifications for high stress levels',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFEF4444),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: 'stress_alert_$stressLevel',
    );

    debugPrint('Stress alert fired: level=$stressLevel');
  }

  Future<void> showReminder({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Wellness reminders and tips',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  String _getAlertTitle(int stressLevel) {
    if (stressLevel >= 85) return 'Critical Stress Alert';
    if (stressLevel >= 75) return 'High Stress Detected';
    return 'Stress Level Elevated';
  }

  String _getAlertBody(int stressLevel) {
    if (stressLevel >= 85) {
      return 'Your stress level is $stressLevel%. '
          'Please take a moment to breathe and relax.';
    }
    if (stressLevel >= 75) {
      return 'Your stress is at $stressLevel%. '
          'Consider taking a short break.';
    }
    return 'Your stress level is $stressLevel%. Try some deep breathing.';
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void resetAlertState() {
    _lastAlertTime = null;
    _consecutiveHighCount = 0;
    _recoveredSinceLastAlert = true;
  }
}
