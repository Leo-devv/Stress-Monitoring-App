import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stress_gauge_widget.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/processing_mode_badge.dart';
import '../widgets/live_stats_card.dart';
import '../widgets/simulation_controls.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stress Monitor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Processing mode badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ProcessingModeBadge(
              mode: state.processingMode,
              offloadingStatus: state.offloadingStatus,
            ),
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
              // Stress Gauge
              Center(
                child: StressGaugeWidget(
                  stressLevel: state.currentStress?.level ?? 0,
                ),
              ),

              const SizedBox(height: 24),

              // Live Stats Cards
              LiveStatsCard(
                currentReading: state.currentReading,
                currentStress: state.currentStress,
              ),

              const SizedBox(height: 24),

              // Heart Rate Chart
              const Text(
                'Heart Rate History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              HeartRateChart(
                readings: state.sensorHistory,
              ),

              const SizedBox(height: 24),

              // Simulation Controls
              SimulationControls(
                isRunning: state.isSimulationRunning,
                onToggle: () =>
                    ref.read(dashboardProvider.notifier).toggleSimulation(),
                onReset: () => ref.read(dashboardProvider.notifier).resetData(),
              ),

              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }
}
