// lib/presentation/widgets/insight_card.dart
//
// Renders an AI-generated insight with three visual states:
//   • Loading       — soft skeleton bars.
//   • Has insight   — full body + timestamp.
//   • Fallback      — same look, plus a small "Offline" pill.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/gemini_insight_service.dart';

enum InsightCardType { daily, weekly, monthly }

class InsightCard extends StatelessWidget {
  final InsightCardType type;
  final InsightResult? insight;
  final bool loading;
  final VoidCallback? onRefresh;

  const InsightCard({
    super.key,
    required this.type,
    this.insight,
    this.loading = false,
    this.onRefresh,
  });

  String get _title => switch (type) {
        InsightCardType.daily => 'Refleksi Hari Ini',
        InsightCardType.weekly => 'Tren 7 Hari Terakhir',
        InsightCardType.monthly => 'Pola 30 Hari Terakhir',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondaryLavender.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.secondaryLavender.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: AppColors.primarySageDeep,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (insight?.isFallback == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  onPressed: loading ? null : onRefresh,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (loading)
            const _SkeletonBody()
          else if (insight != null) ...[
            Text(
              insight!.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Diperbarui ${_formatTimestamp(insight!.generatedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ] else
            const Text(
              'Isi setidaknya satu check-in untuk melihat refleksi Milo. 🌿',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    // Falls back to default locale if Indonesian isn't initialised yet.
    try {
      return DateFormat('d MMM, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('d MMM, HH:mm').format(dt);
    }
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          height: 12,
          width: w,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(double.infinity),
        bar(280),
        bar(220),
      ],
    );
  }
}
