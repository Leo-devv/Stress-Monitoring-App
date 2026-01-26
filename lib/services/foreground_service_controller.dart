import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

/// Controller for communicating with the native Android Foreground Service
class ForegroundServiceController {
  static const _channel = MethodChannel(AppConstants.methodChannelName);

  /// Starts the foreground service for background monitoring
  static Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to start service: ${e.message}');
      return false;
    }
  }

  /// Stops the foreground service
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop service: ${e.message}');
      return false;
    }
  }

  /// Checks if the service is currently running
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check service status: ${e.message}');
      return false;
    }
  }

  /// Requests notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to request permissions: ${e.message}');
      return false;
    }
  }
}
