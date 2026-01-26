import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: const Text(
          'Simulation Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: notifier.resetToDefaults,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.science,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use these controls to simulate different stress scenarios for your thesis demo.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Preset Buttons
              const Text(
                'Quick Presets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  const Text(
                    'Sensor Values',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Manual Override',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: state.useManualValues,
                        onChanged: notifier.setUseManualValues,
                        activeColor: const Color(0xFF6366F1),
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
                color: const Color(0xFFEF4444),
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
                color: const Color(0xFF22D3EE),
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
                color: const Color(0xFFF59E0B),
                enabled: state.useManualValues,
                onChanged: notifier.setTemperature,
                divisions: 100,
              ),

              const SizedBox(height: 32),

              // Environment Controls
              const Text(
                'Environment Simulation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Inject Reading',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
