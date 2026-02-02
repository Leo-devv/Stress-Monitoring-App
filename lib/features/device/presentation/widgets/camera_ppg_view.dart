import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Camera PPG measurement view with instructions and signal indicator.
///
/// Guides the user through placing their fingertip over the rear camera
/// and displays real-time signal quality feedback.
class CameraPpgView extends StatelessWidget {
  final bool isActive;
  final int? heartRate;
  final double signalQuality;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const CameraPpgView({
    super.key,
    required this.isActive,
    this.heartRate,
    this.signalQuality = 0,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isActive
              ? AppColors.heartRate.withAlpha(80)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.heartRate.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.heartRate, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Camera PPG', style: AppTypography.h3),
                    Text(
                      'Measure heart rate with your phone camera',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isActive && heartRate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.heartRate.withAlpha(30),
                    borderRadius: AppRadius.badge,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite,
                          color: AppColors.heartRate, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$heartRate BPM',
                        style: AppTypography.label
                            .copyWith(color: AppColors.heartRate),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Camera preview or instruction area
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.heartRate.withAlpha(15)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? AppColors.heartRate.withAlpha(40)
                    : AppColors.borderSubtle,
              ),
            ),
            child: isActive
                ? _buildActiveView()
                : _buildInstructionView(),
          ),

          const SizedBox(height: AppSpacing.md),

          // Signal quality bar
          if (isActive) ...[
            _buildSignalQuality(),
            const SizedBox(height: AppSpacing.md),
          ],

          // Start/Stop button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActive ? onStop : onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActive ? AppColors.stressHigh : AppColors.heartRate,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: Text(
                isActive ? 'Stop Measurement' : 'Start Camera PPG',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.fingerprint,
            size: 40, color: AppColors.textMuted.withAlpha(120)),
        const SizedBox(height: 12),
        Text(
          'Place your fingertip over the rear camera',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'The flash will turn on to illuminate your finger',
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActiveView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite,
            size: 48,
            color: AppColors.heartRate.withAlpha(180)),
        const SizedBox(height: 8),
        Text(
          heartRate != null ? 'Measuring...' : 'Detecting pulse...',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.heartRate,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep your finger steady',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignalQuality() {
    final quality = signalQuality.clamp(0.0, 1.0);
    final color = quality >= 0.7
        ? AppColors.stressLow
        : quality >= 0.4
            ? AppColors.stressElevated
            : AppColors.stressHigh;
    final label = quality >= 0.7
        ? 'Good signal'
        : quality >= 0.4
            ? 'Fair signal'
            : 'Weak signal – adjust finger position';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Signal Quality', style: AppTypography.caption),
            Text(
              '${(quality * 100).round()}%',
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: quality,
            backgroundColor: AppColors.surfaceElevated,
            color: color,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.caption.copyWith(color: color)),
      ],
    );
  }
}
