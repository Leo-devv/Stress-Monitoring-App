import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/hrv_metrics.dart';

/// Displays real-time HRV metrics in a compact card layout.
///
/// Shows the four primary time-domain HRV indicators:
///   RMSSD, SDNN, pNN50, and the Baevsky Stress Index.
/// Optionally shows deviation from personal baseline.
class HRVMetricsCard extends StatelessWidget {
  final HRVMetrics? metrics;
  final double? baselineDeviation;

  const HRVMetricsCard({
    super.key,
    this.metrics,
    this.baselineDeviation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HRV Analysis', style: AppTypography.h3),
              if (metrics != null)
                _buildConfidenceBadge(metrics!.confidence),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Metrics grid
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'RMSSD',
                  value: metrics != null
                      ? metrics!.rmssd.toStringAsFixed(1)
                      : '--',
                  unit: 'ms',
                  icon: Icons.timeline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'SDNN',
                  value: metrics != null
                      ? metrics!.sdnn.toStringAsFixed(1)
                      : '--',
                  unit: 'ms',
                  icon: Icons.show_chart,
                  color: AppColors.stressNormal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'pNN50',
                  value: metrics != null
                      ? '${metrics!.pnn50.toStringAsFixed(1)}%'
                      : '--',
                  unit: '',
                  icon: Icons.percent,
                  color: AppColors.stressLow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Stress Index',
                  value: metrics != null
                      ? metrics!.stressIndex.toStringAsFixed(0)
                      : '--',
                  unit: '',
                  icon: Icons.monitor_heart,
                  color: AppColors.heartRate,
                ),
              ),
            ],
          ),

          // Frequency-domain metrics
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'LF Power',
                  value: metrics != null
                      ? metrics!.lfPower.toStringAsFixed(0)
                      : '--',
                  unit: 'ms\u00B2',
                  icon: Icons.waves,
                  color: AppColors.stressElevated,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'HF Power',
                  value: metrics != null
                      ? metrics!.hfPower.toStringAsFixed(0)
                      : '--',
                  unit: 'ms\u00B2',
                  icon: Icons.waves_outlined,
                  color: AppColors.stressNormal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'LF/HF',
                  value: metrics != null
                      ? metrics!.lfHfRatio.toStringAsFixed(2)
                      : '--',
                  unit: '',
                  icon: Icons.balance,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),

          // Baseline comparison
          if (baselineDeviation != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildBaselineComparison(baselineDeviation!),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percent = (confidence * 100).round();
    final color = confidence >= 0.7
        ? AppColors.stressLow
        : confidence >= 0.4
            ? AppColors.stressElevated
            : AppColors.stressHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: AppRadius.badge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$percent%',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineComparison(double deviation) {
    final isAbove = deviation > 0;
    final color = isAbove ? AppColors.stressHigh : AppColors.stressLow;
    final icon = isAbove ? Icons.trending_up : Icons.trending_down;
    final label = isAbove
        ? '${deviation.toStringAsFixed(0)}% above your baseline'
        : '${deviation.abs().toStringAsFixed(0)}% below your baseline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.numeric.copyWith(
                  fontSize: 20,
                  color: AppColors.textPrimary,
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
        ],
      ),
    );
  }
}
