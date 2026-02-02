import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/simulation_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../widgets/sensor_slider.dart';
import '../widgets/environment_controls.dart';
import '../widgets/preset_buttons.dart';

class SimulationPanelPage extends ConsumerWidget {
  const SimulationPanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);
    final dashboardNotifier = ref.read(dashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Simulation Control', style: AppTypography.h3),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: notifier.resetToDefaults,
            icon: const Icon(Icons.restart_alt,
                size: 18, color: AppColors.textSecondary),
            label: Text('Reset',
                style: AppTypography.label
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use these controls to simulate different stress '
                        'scenarios for your thesis demo.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Preset Buttons
              Text('Quick Presets', style: AppTypography.h3),
              const SizedBox(height: 12),
              PresetButtons(
                onPresetSelected: (preset) {
                  notifier.applyPreset(preset);
                },
              ),

              const SizedBox(height: 32),

              // Sensor Values Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sensor Values', style: AppTypography.h3),
                  Row(
                    children: [
                      Text('Manual Override', style: AppTypography.caption),
                      const SizedBox(width: 8),
                      Switch(
                        value: state.useManualValues,
                        onChanged: notifier.setUseManualValues,
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Heart Rate Slider
              SensorSlider(
                label: 'Heart Rate',
                value: state.heartRate,
                min: 40,
                max: 180,
                unit: 'BPM',
                icon: Icons.favorite,
                color: AppColors.heartRate,
                enabled: state.useManualValues,
                onChanged: notifier.setHeartRate,
                divisions: 140,
              ),

              const SizedBox(height: 16),

              // EDA Slider
              SensorSlider(
                label: 'Electrodermal Activity',
                value: state.eda,
                min: 0,
                max: 15,
                unit: 'µS',
                icon: Icons.water_drop,
                color: AppColors.eda,
                enabled: state.useManualValues,
                onChanged: notifier.setEda,
                divisions: 150,
              ),

              const SizedBox(height: 16),

              // Temperature Slider
              SensorSlider(
                label: 'Skin Temperature',
                value: state.temperature,
                min: 30,
                max: 40,
                unit: '°C',
                icon: Icons.thermostat,
                color: AppColors.temperature,
                enabled: state.useManualValues,
                onChanged: notifier.setTemperature,
                divisions: 100,
              ),

              const SizedBox(height: 32),

              // Environment Controls
              Text('Environment Simulation', style: AppTypography.h3),
              const SizedBox(height: 16),
              EnvironmentControls(
                batteryLevel: state.batteryLevel,
                isWifiConnected: state.isWifiConnected,
                onBatteryChanged: notifier.setBatteryLevel,
                onWifiChanged: notifier.setWifiConnected,
              ),

              const SizedBox(height: 32),

              // Inject Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    notifier.injectReading();
                    if (!ref.read(dashboardProvider).isSimulationRunning) {
                      dashboardNotifier.startSimulation();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: Text(
                    'Inject Reading',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
