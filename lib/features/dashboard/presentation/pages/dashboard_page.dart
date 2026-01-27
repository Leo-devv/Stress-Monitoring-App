import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stress_gauge_widget.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/processing_mode_badge.dart';
import '../../../../domain/entities/stress_assessment.dart';
import '../widgets/live_stats_card.dart';
import '../widgets/simulation_controls.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final stressLevel = state.currentStress?.level ?? 0;
    final isHighStress = stressLevel >= 70;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Stress Monitor',
          style: AppTypography.h2,
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
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HIGH STRESS ALERT BANNER
              if (isHighStress) _buildStressAlertBanner(stressLevel),

              // Stress Gauge with glow effect
              Center(
                child: AnimatedContainer(
                  duration: AppDurations.slow,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isHighStress
                        ? AppShadows.stressGlow(AppColors.stressHigh, 0.8)
                        : null,
                  ),
                  child: StressGaugeWidget(
                    stressLevel: stressLevel,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // How It Works - Explanation for testers
              _buildHowItWorksCard(state.processingMode),

              const SizedBox(height: AppSpacing.lg),

              // Live Stats Cards
              LiveStatsCard(
                currentReading: state.currentReading,
                currentStress: state.currentStress,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Heart Rate Chart Section
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Heart Rate History', style: AppTypography.h3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.heartRate.withOpacity(0.15),
                            borderRadius: AppRadius.badge,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, color: AppColors.heartRate, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${state.currentReading?.heartRate.round() ?? '--'} BPM',
                                style: AppTypography.label.copyWith(color: AppColors.heartRate),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HeartRateChart(
                      readings: state.sensorHistory,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

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

  Widget _buildStressAlertBanner(int stressLevel) {
    final isCritical = stressLevel >= 85;
    final color = isCritical ? AppColors.stressCritical : AppColors.stressHigh;
    final title = isCritical ? 'Critical Stress Alert!' : 'High Stress Detected';
    final subtitle = isCritical
        ? 'Take immediate action to relax'
        : 'Consider taking a short break';

    return AnimatedContainer(
      duration: AppDurations.normal,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing warning icon
          _PulsingIcon(color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Quick action button
          GestureDetector(
            onTap: () {
              // TODO: Open breathing exercise
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.button,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.self_improvement, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Breathe',
                    style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(ProcessingMode mode) {
    final isEdge = mode == ProcessingMode.edge;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Your Stress is Measured',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tap for details',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),

          // Quick explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildExplainRow(
                  Icons.favorite,
                  AppColors.heartRate,
                  'Heart Rate',
                  'Higher when stressed',
                ),
                const SizedBox(height: 8),
                _buildExplainRow(
                  Icons.water_drop,
                  AppColors.eda,
                  'Skin Conductance (EDA)',
                  'Sweating indicates stress',
                ),
                const SizedBox(height: 8),
                _buildExplainRow(
                  Icons.thermostat,
                  AppColors.temperature,
                  'Temperature',
                  'Changes with stress',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Processing info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isEdge ? AppColors.edgeMode : AppColors.cloudMode).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isEdge ? AppColors.edgeMode : AppColors.cloudMode).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEdge ? Icons.phone_android : Icons.cloud,
                  size: 16,
                  color: isEdge ? AppColors.edgeMode : AppColors.cloudMode,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEdge
                        ? 'AI runs on your phone (EDGE mode)'
                        : 'AI runs on cloud server (CLOUD mode)',
                    style: AppTypography.caption.copyWith(
                      color: isEdge ? AppColors.edgeMode : AppColors.cloudMode,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainRow(IconData icon, Color color, String title, String desc) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                desc,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pulsing warning icon for alert banner
class _PulsingIcon extends StatefulWidget {
  final Color color;

  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.2 * _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 * _animation.value),
                blurRadius: 12 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: widget.color,
            size: 28,
          ),
        );
      },
    );
  }
}
