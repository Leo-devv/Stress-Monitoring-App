import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
        ? AppColors.danger
        : batteryLevel < 0.50
            ? AppColors.stressElevated
            : AppColors.stressLow;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Battery Slider
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: batteryColor.withAlpha(30),
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
                        Text(
                          'Battery Level',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: batteryColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$batteryPercentage%',
                            style: AppTypography.label.copyWith(
                              color: batteryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: batteryColor,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: batteryColor,
                        overlayColor: batteryColor.withAlpha(50),
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

          const Divider(height: 32, color: AppColors.divider),

          // WiFi Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isWifiConnected
                      ? AppColors.cloudMode.withAlpha(30)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isWifiConnected ? Icons.wifi : Icons.wifi_off,
                  color: isWifiConnected
                      ? AppColors.cloudMode
                      : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WiFi Connection',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWifiConnected ? 'Connected' : 'Disconnected',
                      style: AppTypography.bodySmall.copyWith(
                        color: isWifiConnected
                            ? AppColors.cloudMode
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isWifiConnected,
                onChanged: onWifiChanged,
                activeColor: AppColors.cloudMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    batteryLevel < 0.20
                        ? 'Low battery forces EDGE processing to save power'
                        : isWifiConnected
                            ? 'WiFi available — CLOUD processing enabled'
                            : 'No WiFi — using EDGE processing',
                    style: AppTypography.bodySmall,
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
