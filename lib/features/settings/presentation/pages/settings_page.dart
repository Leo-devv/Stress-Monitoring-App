import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../../simulation/providers/simulation_provider.dart';
import '../widgets/privacy_section.dart';
import '../widgets/offloading_section.dart';
import '../widgets/about_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Settings', style: AppTypography.h2),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: AppSpacing.screenPadding,
          children: [
            // Offloading Strategy Section
            Text('Processing Strategy', style: AppTypography.h3),
            const SizedBox(height: 12),
            OffloadingSection(
              currentStrategy: state.offloadingStrategy,
              batteryThreshold: state.batteryThreshold,
              onStrategyChanged: (strategy) {
                ref.read(settingsProvider.notifier).setOffloadingStrategy(strategy);
                ref.read(simulationProvider.notifier).setStrategy(strategy);
              },
              onThresholdChanged: (threshold) {
                ref.read(settingsProvider.notifier).setBatteryThreshold(threshold);
              },
            ),

            const SizedBox(height: 32),

            // Privacy Section
            Text('Privacy & Data', style: AppTypography.h3),
            const SizedBox(height: 12),
            PrivacySection(
              dataCollectionEnabled: state.dataCollectionEnabled,
              dataRetentionDays: state.dataRetentionDays,
              isDeletingData: state.isDeletingData,
              onDataCollectionChanged: (enabled) {
                ref.read(settingsProvider.notifier).setDataCollectionEnabled(enabled);
              },
              onRetentionDaysChanged: (days) {
                ref.read(settingsProvider.notifier).setDataRetentionDays(days);
              },
              onExportData: () => _handleExport(context, ref),
              onNukeData: () async {
                final confirmed = await _showNukeConfirmation(context);
                if (confirmed) {
                  await ref.read(settingsProvider.notifier).nukeAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('All data has been deleted', style: AppTypography.bodyMedium),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 32),

            // About Section
            Text('About', style: AppTypography.h3),
            const SizedBox(height: 12),
            const AboutSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(settingsProvider.notifier).exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/stress_monitor_export.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Stress Monitor — Data Export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e', style: AppTypography.bodyMedium),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<bool> _showNukeConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever, color: AppColors.danger),
                ),
                const SizedBox(width: 12),
                Text('Delete All Data?', style: AppTypography.h3),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This action will permanently delete:', style: AppTypography.bodyMedium),
                const SizedBox(height: 12),
                _buildDeleteItem('All local sensor readings'),
                _buildDeleteItem('Stress analysis history'),
                _buildDeleteItem('Cloud-stored data (Firestore)'),
                _buildDeleteItem('User preferences'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: AppTypography.label.copyWith(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(text, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
