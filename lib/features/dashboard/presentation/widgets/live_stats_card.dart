import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/sensor_reading.dart';
import '../../../../domain/entities/stress_assessment.dart';

class LiveStatsCard extends StatelessWidget {
  final SensorReading? currentReading;
  final StressAssessment? currentStress;

  const LiveStatsCard({
    super.key,
    this.currentReading,
    this.currentStress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            label: 'Heart Rate',
            value: currentReading != null
                ? '${currentReading!.heartRate.toInt()}'
                : '--',
            unit: 'BPM',
            color: AppColors.heartRate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.water_drop,
            label: 'EDA',
            value: currentReading != null
                ? currentReading!.eda.toStringAsFixed(1)
                : '--',
            unit: 'µS',
            color: AppColors.eda,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.thermostat,
            label: 'Temp',
            value: currentReading != null
                ? currentReading!.temperature.toStringAsFixed(1)
                : '--',
            unit: '°C',
            color: AppColors.temperature,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with color indicator
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.numeric.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
