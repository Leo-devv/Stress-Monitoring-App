import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/offloading_manager.dart';

class OffloadingSection extends StatelessWidget {
  final OffloadingStrategy currentStrategy;
  final double batteryThreshold;
  final ValueChanged<OffloadingStrategy> onStrategyChanged;
  final ValueChanged<double> onThresholdChanged;

  const OffloadingSection({
    super.key,
    required this.currentStrategy,
    required this.batteryThreshold,
    required this.onStrategyChanged,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with explanation
          Row(
            children: [
              const Icon(Icons.memory, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('AI Processing Mode', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // Explanation box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha:0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'What is this?',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your stress level is calculated by AI. Choose WHERE that AI runs:',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                _buildMiniExplain(Icons.phone_android, AppColors.edgeMode, 'EDGE', 'AI on your phone (fast, works offline)'),
                const SizedBox(height: 4),
                _buildMiniExplain(Icons.cloud, AppColors.cloudMode, 'CLOUD', 'AI on server (when WiFi available)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Strategy options
          _buildStrategyOption(
            title: 'Automatic (Recommended)',
            description: 'Smart switching: Uses EDGE when battery low, CLOUD when on WiFi',
            icon: Icons.auto_mode,
            color: AppColors.primary,
            isSelected: currentStrategy == OffloadingStrategy.auto,
            onTap: () => onStrategyChanged(OffloadingStrategy.auto),
          ),
          const SizedBox(height: 10),
          _buildStrategyOption(
            title: 'Always On-Device (EDGE)',
            description: 'All processing on your phone. Best for privacy & offline use.',
            icon: Icons.phone_android,
            color: AppColors.edgeMode,
            isSelected: currentStrategy == OffloadingStrategy.forceEdge,
            onTap: () => onStrategyChanged(OffloadingStrategy.forceEdge),
          ),
          const SizedBox(height: 10),
          _buildStrategyOption(
            title: 'Always Cloud (SERVER)',
            description: 'Send data to server for analysis. Requires internet connection.',
            icon: Icons.cloud,
            color: AppColors.cloudMode,
            isSelected: currentStrategy == OffloadingStrategy.forceCloud,
            onTap: () => onStrategyChanged(OffloadingStrategy.forceCloud),
          ),

          // Battery threshold slider (only shown for auto mode)
          if (currentStrategy == OffloadingStrategy.auto) ...[
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Battery Threshold', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('Switch to Edge mode below this level', style: AppTypography.caption),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(batteryThreshold * 100).round()}%',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                trackHeight: 6,
              ),
              child: Slider(
                value: batteryThreshold,
                min: 0.10,
                max: 0.50,
                divisions: 8,
                onChanged: onThresholdChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStrategyOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.08) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha:0.4) : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha:isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(description, style: AppTypography.caption),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniExplain(IconData icon, Color color, String label, String desc) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
