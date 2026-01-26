import 'package:battery_plus/battery_plus.dart';

/// Provides battery level information
class BatteryUtils {
  final Battery _battery;

  BatteryUtils({Battery? battery}) : _battery = battery ?? Battery();

  /// Returns current battery level as a percentage (0.0 - 1.0)
  Future<double> getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    return level / 100.0;
  }

  /// Returns current battery level as integer percentage (0 - 100)
  Future<int> getBatteryPercentage() async {
    return await _battery.batteryLevel;
  }

  /// Returns battery state (charging, discharging, full, etc.)
  Future<BatteryState> getBatteryState() async {
    return await _battery.batteryState;
  }

  /// Stream of battery state changes
  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;
}
