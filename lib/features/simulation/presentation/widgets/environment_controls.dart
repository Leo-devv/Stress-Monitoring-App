import 'package:flutter/material.dart';

class EnvironmentControls extends StatelessWidget {
  final double batteryLevel;
  final bool isWifiConnected;
  final ValueChanged<double> onBatteryChanged;
  final ValueChanged<bool> onWifiChanged;

  const EnvironmentControls({
    super.key,
    required this.batteryLevel,
    required this.isWifiConnected,
    required this.onBatteryChanged,
    required this.onWifiChanged,
  });

  @override
  Widget build(BuildContext context) {
    final batteryPercentage = (batteryLevel * 100).round();
    final batteryColor = batteryLevel < 0.20
        ? const Color(0xFFEF4444)
        : batteryLevel < 0.50
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Battery Slider
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: batteryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getBatteryIcon(),
                  color: batteryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Battery Level',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: batteryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$batteryPercentage%',
                            style: TextStyle(
                              color: batteryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: batteryColor,
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: batteryColor,
                        overlayColor: batteryColor.withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: batteryLevel,
                        min: 0.05,
                        max: 1.0,
                        divisions: 19,
                        onChanged: onBatteryChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32, color: Colors.white10),

          // WiFi Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isWifiConnected
                      ? const Color(0xFF3B82F6).withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isWifiConnected ? Icons.wifi : Icons.wifi_off,
                  color: isWifiConnected
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withOpacity(0.4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WiFi Connection',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWifiConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        color: isWifiConnected
                            ? const Color(0xFF3B82F6)
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isWifiConnected,
                onChanged: onWifiChanged,
                activeColor: const Color(0xFF3B82F6),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.white.withOpacity(0.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    batteryLevel < 0.20
                        ? 'Low battery forces EDGE processing to save power'
                        : isWifiConnected
                            ? 'WiFi available - CLOUD processing enabled'
                            : 'No WiFi - using EDGE processing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon() {
    if (batteryLevel >= 0.90) return Icons.battery_full;
    if (batteryLevel >= 0.70) return Icons.battery_5_bar;
    if (batteryLevel >= 0.50) return Icons.battery_4_bar;
    if (batteryLevel >= 0.30) return Icons.battery_3_bar;
    if (batteryLevel >= 0.20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}
