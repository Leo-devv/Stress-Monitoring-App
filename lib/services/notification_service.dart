import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling push notifications (stress alerts)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Show a stress alert notification
  Future<void> showStressAlert({
    required int stressLevel,
    String? message,
  }) async {
    if (!_isInitialized) await initialize();

    final String title = _getAlertTitle(stressLevel);
    final String body = message ?? _getAlertBody(stressLevel);

    final androidDetails = AndroidNotificationDetails(
      'stress_alerts',
      'Stress Alerts',
      channelDescription: 'Notifications for high stress levels',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFFF6B6B),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
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
  }

  /// Show a reminder notification
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

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  String _getAlertTitle(int stressLevel) {
    if (stressLevel >= 85) {
      return 'Critical Stress Alert';
    } else if (stressLevel >= 70) {
      return 'High Stress Detected';
    } else {
      return 'Stress Level Elevated';
    }
  }

  String _getAlertBody(int stressLevel) {
    if (stressLevel >= 85) {
      return 'Your stress level is $stressLevel%. Please take immediate action to relax.';
    } else if (stressLevel >= 70) {
      return 'Your stress is at $stressLevel%. Consider taking a short break.';
    } else {
      return 'Your stress level is $stressLevel%. Try some deep breathing.';
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation to dashboard when notification is tapped
    // This would typically use a navigation service or callback
  }
}

/// Extension for easy access
extension NotificationServiceExtension on NotificationService {
  /// Check if should show alert based on stress level
  bool shouldShowAlert(int stressLevel, {int threshold = 70}) {
    return stressLevel >= threshold;
  }
}
