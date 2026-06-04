// lib/presentation/screens/home/home_screen.dart
//
// HOME LAYOUT (top → bottom):
//
//   ┌────────────────────────────────────────────────────────┐
//   │  AppBar:  ETMH  •  Sign-out                            │
//   ├────────────────────────────────────────────────────────┤
//   │              [ Milo Lottie + Greeting ]                │ ← hero
//   │     ┌──────────────────────────────────────────┐       │
//   │     │ 😢   😕   😐   🙂   😊   ← 5 Quick Buttons │       │ ← thumb-
//   │     └──────────────────────────────────────────┘       │   zone
//   │     [ Pagi ✓ ][ Siang ○ ][ Sore ○ ][ Malam ○ ]         │
//   │     ╭────────────────────────────────────────╮         │
//   │     │  Refleksi Hari Ini  (Insight Card)     │         │
//   │     ╰────────────────────────────────────────╯         │
//   └────────────────────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_log.dart';
import '../../../data/models/emotion_entry.dart';
import '../../providers/emotion_provider.dart';
import '../history/calendar_screen.dart';
import '../insights/insights_screen.dart';
import '../help/crisis_help_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/emotion_picker_sheet.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/milo_mascot.dart';
import '../../widgets/smooth_tap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ETMH',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Tren & Insight',
            onPressed: () => Navigator.of(context).push(
              fadeThroughRoute(const InsightsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Riwayat Emosi',
            onPressed: () => Navigator.of(context).push(
              fadeThroughRoute(const CalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_rounded),
            tooltip: 'Butuh bantuan?',
            color: AppColors.secondaryLavenderDeep,
            onPressed: () => Navigator.of(context).push(
              fadeThroughRoute(const CrisisHelpScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.of(context).push(
              fadeThroughRoute(const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<EmotionProvider>(
          builder: (context, provider, _) {
            if (!provider.initialised) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primarySage,
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primarySage,
              onRefresh: provider.refreshDailyInsight,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  // ── 1. Hero: Milo + greeting ──────────────────────
                  const Center(child: MiloMascot()),
                  const SizedBox(height: AppSpacing.xl),

                  // ── 2. Five quick emoji buttons ────────────────────
                  _QuickEmojiRow(
                    onPick: (score) => _onQuickPick(context, score),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── CTA for the full detail sheet ─────────────────
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _openFullSheet(context),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Catat dengan detail'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 3. Today's 4-slot status row ───────────────────
                  _SlotStatusRow(
                    log: provider.today,
                    now: DateTime.now(),
                    onTapSlot: (slot) => _openFullSheet(
                      context,
                      presetSlot: slot,
                    ),
                    onLocked: (slot) => _showNotYetMessage(context, slot),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── 4. Insight Card ───────────────────────────────
                  InsightCard(
                    type: InsightCardType.daily,
                    insight: provider.dailyInsight,
                    loading: provider.loadingInsight,
                    onRefresh: provider.refreshDailyInsight,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onQuickPick(BuildContext context, int score) async {
    final entry = EmotionEntry(
      emotionScore: score,
      timestamp: DateTime.now(),
    );
    final slot = EmotionSlot.fromHour(entry.timestamp.hour);
    await context
        .read<EmotionProvider>()
        .recordEntry(slot: slot, entry: entry);
  }

  Future<void> _openFullSheet(
    BuildContext context, {
    EmotionSlot? presetSlot,
  }) async {
    final entry = await showEmotionPickerSheet(context);
    if (entry == null) return;
    if (!context.mounted) return;
    final slot = presetSlot ?? EmotionSlot.fromHour(entry.timestamp.hour);
    await context
        .read<EmotionProvider>()
        .recordEntry(slot: slot, entry: entry);
  }

  void _showNotYetMessage(BuildContext context, EmotionSlot slot) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.secondaryLavenderDeep,
          content: Text(
            'Sesi ${slot.label} belum waktunya. Yuk kembali lagi nanti ya 🌱',
          ),
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════

class _QuickEmojiRow extends StatelessWidget {
  final ValueChanged<int> onPick;
  const _QuickEmojiRow({required this.onPick});

  static const List<_QuickEmojiData> _items = [
    _QuickEmojiData(1, '😢', AppColors.emotion1),
    _QuickEmojiData(2, '😕', AppColors.emotion2),
    _QuickEmojiData(3, '😐', AppColors.emotion3),
    _QuickEmojiData(4, '🙂', AppColors.emotion4),
    _QuickEmojiData(5, '😊', AppColors.emotion5),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _items
          .map(
            (it) => _EmojiButton(
              emoji: it.emoji,
              color: it.color,
              onTap: () => onPick(it.score),
            ),
          )
          .toList(),
    );
  }
}

class _QuickEmojiData {
  final int score;
  final String emoji;
  final Color color;
  const _QuickEmojiData(this.score, this.emoji, this.color);
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _EmojiButton({
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      radius: 40,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _SlotStatusRow extends StatelessWidget {
  final DailyLog log;
  final DateTime now;
  final ValueChanged<EmotionSlot> onTapSlot;
  final ValueChanged<EmotionSlot> onLocked;
  const _SlotStatusRow({
    required this.log,
    required this.now,
    required this.onTapSlot,
    required this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(EmotionSlot.morning, log.morning),
        _chip(EmotionSlot.afternoon, log.afternoon),
        _chip(EmotionSlot.evening, log.evening),
        _chip(EmotionSlot.night, log.night),
      ],
    );
  }

  Widget _chip(EmotionSlot slot, EmotionEntry? entry) {
    final filled = entry != null;
    final open = slot.isOpenAt(now);
    // A filled slot is always shown as filled; an open-but-empty slot
    // invites a tap; a future slot is locked.
    final Color bg = filled
        ? AppColors.primarySage.withValues(alpha: 0.2)
        : (open
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.45));
    final Color borderColor =
        filled ? AppColors.primarySage : AppColors.divider;

    final Widget valueWidget = filled
        ? Text(
            _emojiForScore(entry.emotionScore),
            style: const TextStyle(fontSize: 18),
          )
        : (open
            ? const Text('—', style: TextStyle(fontSize: 18))
            : const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.textMuted,
              ));

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SmoothTap(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: open ? () => onTapSlot(slot) : () => onLocked(slot),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Text(
                  slot.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: open
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(height: 22, child: Center(child: valueWidget)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _emojiForScore(int s) => switch (s) {
        1 => '😢',
        2 => '😕',
        3 => '😐',
        4 => '🙂',
        _ => '😊',
      };
}
