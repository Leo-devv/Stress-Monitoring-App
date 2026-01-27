import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';

/// History Screen - Shows stress calendar and daily charts
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock data for demo - stress levels per day
  final Map<DateTime, int> _stressData = _generateMockData();

  static Map<DateTime, int> _generateMockData() {
    final data = <DateTime, int>{};
    final now = DateTime.now();
    for (int i = 0; i < 60; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      // Generate realistic-looking stress patterns
      final baseStress = 40 + (i % 7) * 5;
      final variation = (i * 17) % 30 - 15;
      data[day] = (baseStress + variation).clamp(15, 95);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stress History'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Stats
            _buildSummaryStats(),
            const SizedBox(height: AppSpacing.lg),

            // Calendar
            _buildCalendar(),
            const SizedBox(height: AppSpacing.lg),

            // Daily Detail Chart (if day selected)
            if (_selectedDay != null) ...[
              _buildDayDetail(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Weekly Trend Chart
            _buildWeeklyTrend(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final avgStress = _calculateAverageStress();
    final peakDay = _findPeakDay();
    final calmDays = _countCalmDays();

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30-Day Summary', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.analytics_outlined,
                  label: 'Avg Stress',
                  value: '${avgStress.round()}%',
                  color: AppColors.getStressColor(avgStress.round()),
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.trending_up,
                  label: 'Peak Day',
                  value: peakDay,
                  color: AppColors.stressHigh,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.spa_outlined,
                  label: 'Calm Days',
                  value: '$calmDays',
                  color: AppColors.stressLow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: AppTypography.bodyMedium,
          weekendTextStyle: AppTypography.bodyMedium,
          selectedDecoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.stressHigh,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          formatButtonTextStyle: AppTypography.caption,
          titleTextStyle: AppTypography.h3,
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(day);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, isToday: true);
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool isToday = false}) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final stressLevel = _stressData[normalizedDay];
    final color = stressLevel != null
        ? AppColors.getStressColor(stressLevel)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: stressLevel != null ? color.withOpacity(0.3) : null,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: AppTypography.bodySmall.copyWith(
            color: stressLevel != null ? color : AppColors.textMuted,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetail() {
    final stressLevel = _stressData[DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    )];

    return Container(
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
              Text(
                _formatDate(_selectedDay!),
                style: AppTypography.h3,
              ),
              if (stressLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.getStressColor(stressLevel).withOpacity(0.2),
                    borderRadius: AppRadius.badge,
                  ),
                  child: Text(
                    '${AppColors.getStressLabel(stressLevel)} - $stressLevel%',
                    style: AppTypography.label.copyWith(
                      color: AppColors.getStressColor(stressLevel),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150,
            child: _buildDayChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChart() {
    // Generate hourly data for selected day
    final spots = List.generate(24, (i) {
      final baseStress = _stressData[DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
          )] ??
          50;
      final variation = ((i * 13 + 7) % 30) - 15;
      return FlSpot(i.toDouble(), (baseStress + variation).clamp(10, 100).toDouble());
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withOpacity(0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: AppTypography.caption,
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.3),
                  AppColors.accent.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Trend', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: _buildWeeklyBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.surfaceOverlay,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()}%',
                AppTypography.label.copyWith(color: AppColors.textPrimary),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    weekDays[value.toInt() % 7],
                    style: AppTypography.caption,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day - (6 - i));
          final stress = _stressData[day] ?? 50;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: stress.toDouble(),
                color: AppColors.getStressColor(stress),
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _calculateAverageStress() {
    final now = DateTime.now();
    double total = 0;
    int count = 0;
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final stress = _stressData[day];
      if (stress != null) {
        total += stress;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  String _findPeakDay() {
    final now = DateTime.now();
    int maxStress = 0;
    DateTime? peakDay;
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final stress = _stressData[day] ?? 0;
      if (stress > maxStress) {
        maxStress = stress;
        peakDay = day;
      }
    }
    if (peakDay != null) {
      return '${peakDay.day}/${peakDay.month}';
    }
    return '-';
  }

  int _countCalmDays() {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final stress = _stressData[day] ?? 100;
      if (stress < 40) count++;
    }
    return count;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export feature - Coming soon', style: AppTypography.bodyMedium),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.h3.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
