import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stress_gauge_widget.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/processing_mode_badge.dart';
import '../widgets/live_stats_card.dart';
import '../widgets/hrv_metrics_card.dart';
import '../widgets/simulation_controls.dart';
import '../widgets/subjective_stress_dialog.dart';
import '../../../../domain/entities/stress_assessment.dart';

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
              if (isHighStress) _buildStressAlertBanner(context, stressLevel),

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
                hrvMetrics: state.currentHRV,
                sourceType: state.activeSourceType,
              ),

              const SizedBox(height: AppSpacing.lg),

              // HRV Analysis Card
              HRVMetricsCard(
                metrics: state.currentHRV,
                baselineDeviation: state.baselineDeviation,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quick-access breathing exercise
              _buildBreathingShortcut(context),

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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.heartRate.withAlpha(38),
                            borderRadius: AppRadius.badge,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite,
                                  color: AppColors.heartRate, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${state.currentReading?.heartRate.round() ?? '--'} BPM',
                                style: AppTypography.label
                                    .copyWith(color: AppColors.heartRate),
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

              // Subjective stress self-report
              _buildSubjectiveRatingButton(context, ref, state.currentStress),

              const SizedBox(height: AppSpacing.lg),

              // Simulation Controls
              SimulationControls(
                isRunning: state.isSimulationRunning,
                onToggle: () =>
                    ref.read(dashboardProvider.notifier).toggleSimulation(),
                onReset: () =>
                    ref.read(dashboardProvider.notifier).resetData(),
              ),

              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStressAlertBanner(BuildContext context, int stressLevel) {
    final isCritical = stressLevel >= 85;
    final color = isCritical ? AppColors.stressCritical : AppColors.stressHigh;
    final title =
        isCritical ? 'Critical Stress Alert!' : 'High Stress Detected';
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
            color.withAlpha(64),
            color.withAlpha(25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withAlpha(130), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
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
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Quick action — open breathing exercise
          GestureDetector(
            onTap: () => context.push('/breathing'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.button,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.self_improvement,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Breathe',
                    style: AppTypography.label.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingShortcut(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/breathing'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(25),
              AppColors.stressNormal.withAlpha(20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.self_improvement,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Breathing Exercise',
                      style: AppTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text('4-7-8 technique for stress relief',
                      style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectiveRatingButton(
      BuildContext context, WidgetRef ref, StressAssessment? current) {
    final hasRated = current?.subjectiveRating != null;

    return GestureDetector(
      onTap: () async {
        final rating = await SubjectiveStressDialog.show(context);
        if (rating != null) {
          ref.read(dashboardProvider.notifier).recordSubjectiveRating(rating);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.stressNormal.withAlpha(25),
              AppColors.primary.withAlpha(20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.stressNormal.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.stressNormal.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.rate_review,
                  color: AppColors.stressNormal, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate Your Stress',
                      style: AppTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    hasRated
                        ? 'Last rating: ${current!.subjectiveRating}/10'
                        : 'How stressed do you feel right now?',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
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
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Your Stress is Measured',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tap for details',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
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
                  'Heart Rate Variability',
                  'RMSSD & SDNN indicate stress',
                ),
                const SizedBox(height: 8),
                _buildExplainRow(
                  Icons.monitor_heart,
                  AppColors.stressElevated,
                  'Baevsky Stress Index',
                  'Sympatho-vagal balance marker',
                ),
                const SizedBox(height: 8),
                _buildExplainRow(
                  Icons.person,
                  AppColors.primary,
                  'Personal Baseline',
                  'Adapts to your normal range',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Processing info
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isEdge ? AppColors.edgeMode : AppColors.cloudMode)
                  .withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isEdge ? AppColors.edgeMode : AppColors.cloudMode)
                    .withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEdge ? Icons.phone_android : Icons.cloud,
                  size: 16,
                  color:
                      isEdge ? AppColors.edgeMode : AppColors.cloudMode,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEdge
                        ? 'AI runs on your phone (EDGE mode)'
                        : 'AI runs on cloud server (CLOUD mode)',
                    style: AppTypography.caption.copyWith(
                      color: isEdge
                          ? AppColors.edgeMode
                          : AppColors.cloudMode,
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

  Widget _buildExplainRow(
      IconData icon, Color color, String title, String desc) {
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
                style: AppTypography.label
                    .copyWith(fontWeight: FontWeight.w500),
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

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
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
            color: widget.color.withAlpha((50 * _animation.value).round()),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color
                    .withAlpha((100 * _animation.value).round()),
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
