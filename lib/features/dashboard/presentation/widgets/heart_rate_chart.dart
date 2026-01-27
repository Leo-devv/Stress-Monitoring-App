import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/sensor_reading.dart';
import '../../../../core/constants/stress_thresholds.dart';

class HeartRateChart extends StatelessWidget {
  final List<SensorReading> readings;

  const HeartRateChart({
    super.key,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: readings.isEmpty
          ? _buildEmptyState()
          : LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 150),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Waiting for sensor data...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start the simulation to see heart rate',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.heartRate);
    }).toList();

    // Calculate min/max for Y axis
    double minY = 40;
    double maxY = 140;
    if (readings.isNotEmpty) {
      final values = readings.map((r) => r.heartRate).toList();
      minY = (values.reduce((a, b) => a < b ? a : b) - 10).clamp(40, 180);
      maxY = (values.reduce((a, b) => a > b ? a : b) + 10).clamp(60, 200);
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border.withOpacity(0.5),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 30,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: AppTypography.caption,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: readings.length.toDouble() - 1,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: _getLineColor(),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _getLineColor().withOpacity(0.25),
                _getLineColor().withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: AppColors.surfaceElevated,
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()} BPM',
                AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Color _getLineColor() {
    if (readings.isEmpty) return AppColors.primary;

    final latestHr = readings.last.heartRate;
    if (latestHr > StressThresholds.hrHigh) {
      return AppColors.stressHigh;
    } else if (latestHr > StressThresholds.hrElevated) {
      return AppColors.stressElevated;
    } else if (latestHr > StressThresholds.hrRestingHigh) {
      return AppColors.stressNormal;
    }
    return AppColors.stressLow;
  }
}
