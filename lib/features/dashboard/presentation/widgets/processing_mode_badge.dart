import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/stress_assessment.dart';
import '../../../../services/offloading_manager.dart';

class ProcessingModeBadge extends StatelessWidget {
  final ProcessingMode mode;
  final OffloadingStatus? offloadingStatus;

  const ProcessingModeBadge({
    super.key,
    required this.mode,
    this.offloadingStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isEdge = mode == ProcessingMode.edge;
    final color = isEdge ? AppColors.edgeMode : AppColors.cloudMode;
    final icon = isEdge ? Icons.phone_android : Icons.cloud;
    final label = isEdge ? 'EDGE' : 'CLOUD';
    final subtitle = isEdge ? 'On-Device AI' : 'Server AI';

    return GestureDetector(
      onTap: () => _showStatusDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha:0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: color.withValues(alpha:0.8),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 12, color: color.withValues(alpha:0.6)),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    if (offloadingStatus == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'Processing Status',
              style: AppTypography.h3,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation box at top
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What does this mean?',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    offloadingStatus!.currentMode == ProcessingMode.edge
                        ? 'Your stress is being analyzed BY YOUR PHONE using on-device AI. This is faster and works offline.'
                        : 'Your stress is being analyzed ON A SERVER using cloud AI. This happens when you have WiFi.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Mode',
              offloadingStatus!.currentMode == ProcessingMode.edge
                  ? 'Edge (On-Device)'
                  : 'Cloud (Firebase)',
              offloadingStatus!.currentMode == ProcessingMode.edge
                  ? AppColors.edgeMode
                  : AppColors.cloudMode,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Battery',
              '${offloadingStatus!.batteryPercentage}%',
              offloadingStatus!.batteryLevel < 0.20
                  ? AppColors.danger
                  : AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'WiFi',
              offloadingStatus!.isWifiConnected ? 'Connected' : 'Disconnected',
              offloadingStatus!.isWifiConnected
                  ? AppColors.success
                  : AppColors.stressElevated,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Strategy',
              _getStrategyLabel(offloadingStatus!.strategy),
              AppColors.primary,
            ),
            const SizedBox(height: 16),
            // Why this mode was chosen
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why: ${offloadingStatus!.reason}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: AppTypography.label.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getStrategyLabel(OffloadingStrategy strategy) {
    switch (strategy) {
      case OffloadingStrategy.auto:
        return 'Auto';
      case OffloadingStrategy.forceEdge:
        return 'Force Edge';
      case OffloadingStrategy.forceCloud:
        return 'Force Cloud';
    }
  }
}
