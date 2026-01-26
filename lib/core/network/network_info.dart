import 'package:connectivity_plus/connectivity_plus.dart';

/// Provides network connectivity information
class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Returns true if device is connected to WiFi
  Future<bool> get isConnectedToWifi async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.wifi;
  }

  /// Returns true if device has any internet connection
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Returns current connectivity type
  Future<ConnectivityResult> get connectivityStatus =>
      _connectivity.checkConnectivity();

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
