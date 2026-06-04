// lib/presentation/widgets/trend_chart.dart
//
// A calm line chart of average daily mood (1–5) over a recent window.
// Missing days are simply skipped. Needs at least two data points to be
// meaningful — otherwise it shows a gentle empty state.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/daily_log.dart';

class TrendChart extends StatelessWidget {
  /// Chronological (oldest → newest) list of logs, nulls allowed.
  final List<DailyLog?> days;
  final int window;

  const TrendChart({super.key, required this.days, this.window = 14});

  @override
  Widget build(BuildContext context) {
    final recent =
        days.length > window ? days.sublist(days.length - window) : days;

    final spots = <FlSpot>[];
    for (var i = 0; i < recent.length; i++) {
      final avg = recent[i]?.averageScore;
      if (avg != null) spots.add(FlSpot(i.toDouble(), avg));
    }

    if (spots.length < 2) return const _EmptyChart();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          minX: 0,
          maxX: (recent.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, _) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  const map = {
                    1: '😢',
                    2: '😕',
                    3: '😐',
                    4: '🙂',
                    5: '😊',
                  };
                  final emoji = map[value.toInt()];
                  if (emoji == null) return const SizedBox.shrink();
                  return Text(emoji, style: const TextStyle(fontSize: 13));
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.primarySage,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primarySageDeep,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secondaryLavender.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Text(
        'Catat emosimu beberapa hari lagi untuk melihat grafik trennya '
        'di sini. 🌱',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
    );
  }
}
