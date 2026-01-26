import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Offloading Strategy Section
            const Text(
              'Processing Strategy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            const Text(
              'Privacy & Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
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
              onNukeData: () async {
                final confirmed = await _showNukeConfirmation(context);
                if (confirmed) {
                  await ref.read(settingsProvider.notifier).nukeAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data has been deleted'),
                        backgroundColor: Color(0xFF22C55E),
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 32),

            // About Section
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const AboutSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<bool> _showNukeConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Delete All Data?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action will permanently delete:',
                ),
                const SizedBox(height: 12),
                _buildDeleteItem('All local sensor readings'),
                _buildDeleteItem('Stress analysis history'),
                _buildDeleteItem('Cloud-stored data (Firestore)'),
                _buildDeleteItem('User preferences'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
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
          Icon(
            Icons.remove_circle_outline,
            size: 16,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
