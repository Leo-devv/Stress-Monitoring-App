import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SimulationControls extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const SimulationControls({
    super.key,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sensors,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensor Simulation',
                      style: AppTypography.h3.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Virtual WESAD sensor data stream',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning
                      ? AppColors.success
                      : AppColors.textMuted,
                  boxShadow: isRunning
                      ? [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning
                        ? AppColors.danger
                        : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    isRunning ? Icons.stop : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(
                    isRunning ? 'Stop' : 'Start',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
