// lib/presentation/screens/insights/insights_screen.dart
//
// "Tren & Insight" — surfaces the weekly and monthly reflections that
// the Gemini service already knows how to produce, plus a mood trend
// chart. Backend was always there; this screen finally shows it.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/emotion_repository.dart';
import '../../../services/gemini_insight_service.dart';
import '../../providers/insights_provider.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/trend_chart.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InsightsProvider>(
      create: (_) => InsightsProvider(
        repository: context.read<EmotionRepository>(),
        aiService: context.read<GeminiInsightService>(),
      ),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tren & Insight',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const _SectionLabel('Grafik Suasana Hati'),
            const SizedBox(height: AppSpacing.md),
            if (provider.loadingChart)
              const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primarySage,
                  ),
                ),
              )
            else
              TrendChart(days: provider.last30),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Refleksi Milo'),
            const SizedBox(height: AppSpacing.md),
            InsightCard(
              type: InsightCardType.weekly,
              insight: provider.weekly,
              loading: provider.loadingWeekly,
              onRefresh: provider.refreshWeekly,
            ),
            const SizedBox(height: AppSpacing.lg),
            InsightCard(
              type: InsightCardType.monthly,
              insight: provider.monthly,
              loading: provider.loadingMonthly,
              onRefresh: provider.refreshMonthly,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Tag yang Sering Muncul'),
            const SizedBox(height: AppSpacing.md),
            _TagCloud(tags: provider.topTags),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _TagCloud extends StatelessWidget {
  final List<MapEntry<String, int>> tags;
  const _TagCloud({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text(
          'Tambahkan tag seperti #kerja atau #tidur saat mencatat emosi, '
          'dan tag yang paling sering muncul akan tampil di sini. 🏷️',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
      );
    }

    final maxCount = tags.first.value;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tags.map((e) {
        // Bigger / bolder tint for more frequent tags.
        final ratio = maxCount == 0 ? 0.0 : e.value / maxCount;
        final alpha = 0.25 + 0.45 * ratio;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondaryLavender.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.secondaryLavender.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            '#${e.key} · ${e.value}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
