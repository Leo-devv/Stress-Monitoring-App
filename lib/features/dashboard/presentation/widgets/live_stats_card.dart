import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/sensor_reading.dart';
import '../../../../domain/entities/stress_assessment.dart';
import '../../../../domain/entities/hrv_metrics.dart';
import '../../../../services/sensor/heart_rate_source.dart';

/// Compact row of live sensor stats.
///
/// When [hrvMetrics] is provided (real HRV data from BLE or camera),
/// displays Heart Rate, RMSSD, and Stress Index.
/// Otherwise falls back to the original BVP/EDA/Temp display.
///
/// Shows inference latency badge when available.
class LiveStatsCard extends StatelessWidget {
  final SensorReading? currentReading;
  final StressAssessment? currentStress;
  final HRVMetrics? hrvMetrics;
  final SensorSourceType? sourceType;

  const LiveStatsCard({
    super.key,
    this.currentReading,
    this.currentStress,
    this.hrvMetrics,
    this.sourceType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Latency badge row
        if (currentStress?.latencyMs != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LatencyBadge(
              latencyMs: currentStress!.latencyMs!,
              mode: currentStress!.processedBy,
            ),
          ),

        // Sensor stats
        _buildStatsRow(),
      ],
    );
  }

  Widget _buildStatsRow() {
    // When HRV data is available, show HRV-focused metrics
    if (hrvMetrics != null && hrvMetrics!.hasSufficientData) {
      return Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.favorite,
              label: 'Heart Rate',
              value: '${hrvMetrics!.meanHeartRate}',
              unit: 'BPM',
              color: AppColors.heartRate,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.timeline,
              label: 'RMSSD',
              value: hrvMetrics!.rmssd.toStringAsFixed(1),
              unit: 'ms',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.monitor_heart,
              label: 'Stress Idx',
              value: hrvMetrics!.stressIndex.toStringAsFixed(0),
              unit: '',
              color: AppColors.stressElevated,
            ),
          ),
        ],
      );
    }

    // Fallback: original sensor reading display
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

/// Small badge showing inference latency and processing mode.
class _LatencyBadge extends StatelessWidget {
  final int latencyMs;
  final ProcessingMode mode;

  const _LatencyBadge({required this.latencyMs, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isEdge = mode == ProcessingMode.edge;
    final color = isEdge ? AppColors.edgeMode : AppColors.cloudMode;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: AppRadius.badge,
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '${latencyMs}ms',
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isEdge ? 'EDGE' : 'CLOUD',
                style: AppTypography.caption.copyWith(
                  color: color.withAlpha(180),
                  fontSize: 10,
                ),
              ),
            ],
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
              color: color.withAlpha(30),
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
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
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
