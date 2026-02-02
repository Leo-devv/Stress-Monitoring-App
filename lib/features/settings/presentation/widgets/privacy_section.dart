import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacySection extends StatelessWidget {
  final bool dataCollectionEnabled;
  final int dataRetentionDays;
  final bool isDeletingData;
  final ValueChanged<bool> onDataCollectionChanged;
  final ValueChanged<int> onRetentionDaysChanged;
  final VoidCallback onNukeData;

  const PrivacySection({
    super.key,
    required this.dataCollectionEnabled,
    required this.dataRetentionDays,
    required this.isDeletingData,
    required this.onDataCollectionChanged,
    required this.onRetentionDaysChanged,
    required this.onNukeData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          // Data Collection Toggle
          _buildSettingTile(
            icon: Icons.cloud_upload,
            iconColor: AppColors.cloudMode,
            title: 'Data Collection',
            subtitle: 'Store analysis data in the cloud',
            trailing: Switch(
              value: dataCollectionEnabled,
              onChanged: onDataCollectionChanged,
              activeThumbColor: AppColors.primary,
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Data Retention
          _buildSettingTile(
            icon: Icons.schedule,
            iconColor: AppColors.stressElevated,
            title: 'Data Retention',
            subtitle: 'Keep data for $dataRetentionDays days',
            trailing: DropdownButton<int>(
              value: dataRetentionDays,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              items: [7, 14, 30, 60, 90].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days days'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onRetentionDaysChanged(value);
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Export Data
          _buildSettingTile(
            icon: Icons.download,
            iconColor: AppColors.success,
            title: 'Export My Data',
            subtitle: 'Download all your data (GDPR)',
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data export coming soon', style: AppTypography.bodyMedium),
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Nuke Data Button
          InkWell(
            onTap: isDeletingData ? null : onNukeData,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isDeletingData
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.danger,
                            ),
                          )
                        : const Icon(
                            Icons.delete_forever,
                            color: AppColors.danger,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete All My Data',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permanently remove all data (GDPR)',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.danger),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
