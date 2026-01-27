import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

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
        children: [
          // App Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.monitor_heart, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConstants.appName, style: AppTypography.h3),
                    const SizedBox(height: 2),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.border),
          const SizedBox(height: 16),

          // Thesis Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Engineering Thesis Project',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"The Role of AI in Personal Stress Monitoring: A Mobile Cloud Approach"',
                  style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tech Stack
          _buildInfoRow(icon: Icons.phone_android, label: 'Frontend', value: 'Flutter'),
          const SizedBox(height: 10),
          _buildInfoRow(icon: Icons.memory, label: 'Edge AI', value: 'TensorFlow Lite'),
          const SizedBox(height: 10),
          _buildInfoRow(icon: Icons.cloud, label: 'Cloud', value: 'Firebase'),
          const SizedBox(height: 10),
          _buildInfoRow(icon: Icons.architecture, label: 'Architecture', value: 'Hybrid Edge/Cloud'),

          const SizedBox(height: 20),
          Divider(color: AppColors.border),
          const SizedBox(height: 12),

          // Copyright
          Text(
            '2026 - Built for thesis demonstration',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.caption),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
