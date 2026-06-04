// lib/presentation/screens/history/calendar_screen.dart
//
// Emotion history calendar. Each day is tinted by its average mood using
// the Healing Palette emotion scale. Tapping a day with data opens a
// thumb-reachable BottomSheet showing that day's four slots + any cached
// Milo insight.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_log.dart';
import '../../../data/models/emotion_entry.dart';
import '../../../data/repositories/emotion_repository.dart';
import '../../providers/history_provider.dart';
import '../../widgets/emotion_picker_sheet.dart';
import '../../widgets/smooth_tap.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The repository is provided above MaterialApp in main.dart, so it's
    // available here. We spin up a HistoryProvider scoped to this screen.
    return ChangeNotifierProvider<HistoryProvider>(
      create: (_) => HistoryProvider(
        repository: context.read<EmotionRepository>(),
      ),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  static const List<String> _weekdayLabels = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Emosi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _MonthHeader(provider: provider),
            const SizedBox(height: AppSpacing.sm),
            _buildWeekdayRow(),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: _buildBody(context, provider)),
            const _Legend(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: _weekdayLabels
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HistoryProvider provider) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primarySage),
      );
    }
    if (provider.error != null) {
      return _ErrorState(
        message: provider.error!,
        onRetry: provider.loadMonth,
      );
    }
    return _CalendarGrid(provider: provider);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Month header with ‹ Bulan Tahun ›
// ═══════════════════════════════════════════════════════════════════
class _MonthHeader extends StatelessWidget {
  final HistoryProvider provider;
  const _MonthHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final title =
        DateFormat('MMMM yyyy', 'id_ID').format(provider.visibleMonth);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primarySageDeep,
            onPressed: provider.goToPreviousMonth,
            tooltip: 'Bulan sebelumnya',
          ),
          Text(
            _capitalise(title),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: provider.canGoNext
                ? AppColors.primarySageDeep
                : AppColors.textMuted.withValues(alpha: 0.4),
            onPressed: provider.canGoNext ? provider.goToNextMonth : null,
            tooltip: 'Bulan berikutnya',
          ),
        ],
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════
//  The 7-column day grid
// ═══════════════════════════════════════════════════════════════════
class _CalendarGrid extends StatelessWidget {
  final HistoryProvider provider;
  const _CalendarGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final month = provider.visibleMonth;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // weekday: 1 = Mon ... 7 = Sun. We render Monday-first.
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.85,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();
        final day = index - leadingBlanks + 1;
        final log = provider.logs[day];
        final isToday = isCurrentMonth && now.day == day;
        return _DayCell(
          day: day,
          log: log,
          isToday: isToday,
          onTap: log == null
              ? null
              : () => _showDayDetail(context, month, day, log),
        );
      },
    );
  }

  void _showDayDetail(
    BuildContext context,
    DateTime month,
    int day,
    DailyLog log,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _DayDetailSheet(
        date: DateTime(month.year, month.month, day),
        log: log,
        provider: provider,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DailyLog? log;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.log,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = emotionColorForAverage(log?.averageScore);
    final Color fill =
        color == null ? AppColors.surface : color.withValues(alpha: 0.75);
    final Color borderColor = isToday
        ? AppColors.primarySageDeep
        : (color ?? AppColors.divider);

    return SmoothTap(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: borderColor,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Detail BottomSheet for a single day
// ═══════════════════════════════════════════════════════════════════
class _DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final DailyLog log;
  final HistoryProvider provider;
  const _DayDetailSheet({
    required this.date,
    required this.log,
    required this.provider,
  });

  Future<void> _onEdit(
    BuildContext context,
    EmotionSlot slot,
    EmotionEntry? entry,
  ) async {
    final result = await showEmotionPickerSheet(context, initial: entry);
    if (result == null) return;
    await provider.editEntry(date, slot, result);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onDelete(
    BuildContext context,
    EmotionSlot slot,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Hapus catatan ini?'),
        content: Text(
          'Catatan ${slot.label} akan dihapus dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.deleteEntry(date, slot);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _capitalise(title),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _slotTile(context, EmotionSlot.morning, log.morning),
          _slotTile(context, EmotionSlot.afternoon, log.afternoon),
          _slotTile(context, EmotionSlot.evening, log.evening),
          _slotTile(context, EmotionSlot.night, log.night),
          if (log.dailyInsight != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _insightBox(log.dailyInsight!),
          ],
        ],
      ),
    );
  }

  Widget _slotTile(BuildContext context, EmotionSlot slot, EmotionEntry? entry) {
    final String emoji =
        entry == null ? '—' : _emojiForScore(entry.emotionScore);
    final String label = entry == null ? 'Belum dicatat' : entry.moodLabel;
    final List<String> tags = entry?.tags ?? const <String>[];
    final String? notes = entry?.notes;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: entry == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLavender
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (notes != null && notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _slotActions(context, slot, entry),
        ],
      ),
    );
  }

  Widget _slotActions(
    BuildContext context,
    EmotionSlot slot,
    EmotionEntry? entry,
  ) {
    if (entry == null) {
      return IconButton(
        icon: const Icon(Icons.add_rounded),
        color: AppColors.primarySageDeep,
        tooltip: 'Tambah catatan',
        visualDensity: VisualDensity.compact,
        onPressed: () => _onEdit(context, slot, null),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.textSecondary,
          tooltip: 'Ubah',
          visualDensity: VisualDensity.compact,
          onPressed: () => _onEdit(context, slot, entry),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: AppColors.errorSoft,
          tooltip: 'Hapus',
          visualDensity: VisualDensity.compact,
          onPressed: () => _onDelete(context, slot),
        ),
      ],
    );
  }

  Widget _insightBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: AppColors.primarySageDeep,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Refleksi Milo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _emojiForScore(int s) => switch (s) {
        1 => '😢',
        2 => '😕',
        3 => '😐',
        4 => '🙂',
        _ => '😊',
      };
}

// ═══════════════════════════════════════════════════════════════════
//  Legend + error state + shared color helper
// ═══════════════════════════════════════════════════════════════════
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppColors.emotion1, 'Sangat Buruk'),
      (AppColors.emotion3, 'Biasa'),
      (AppColors.emotion5, 'Sangat Baik'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items
            .map(
              (it) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: it.$1,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      it.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps an average mood score (1.0–5.0) to a Healing Palette tone.
/// Returns null when there's no data for the day.
Color? emotionColorForAverage(double? avg) {
  if (avg == null) return null;
  final int s = avg.round().clamp(1, 5).toInt();
  return switch (s) {
    1 => AppColors.emotion1,
    2 => AppColors.emotion2,
    3 => AppColors.emotion3,
    4 => AppColors.emotion4,
    _ => AppColors.emotion5,
  };
}
