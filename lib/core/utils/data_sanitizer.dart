// lib/core/utils/data_sanitizer.dart
//
// Pure functions that turn DailyLog(s) into the structured payload
// consumed by the Gemini prompt builders.
//
// Hard contract:
//   • Never pass null slots to the AI.
//   • Never crash if a user filled 0/4 slots.
//   • Produce deterministic, human-readable JSON the model can parse.

import 'package:collection/collection.dart';

import '../../data/models/daily_log.dart';

class DataSanitizer {
  DataSanitizer._();

  /// Strips nulls out of a single day's log and produces the dict-shape
  /// that the daily prompt expects.
  static Map<String, dynamic> sanitizeDay(DailyLog log) {
    final slots = <Map<String, dynamic>>[];
    log.filledSlots.forEach((slot, entry) {
      slots.add({
        'slot': slot.label,
        'mood': entry.moodLabel,
        'score': entry.emotionScore,
        'time': entry.timestamp.toIso8601String(),
        if (entry.tags != null && entry.tags!.isNotEmpty) 'tags': entry.tags,
        if (entry.notes != null && entry.notes!.trim().isNotEmpty)
          'notes': entry.notes!.trim(),
      });
    });

    return {
      'date': _isoDate(log.date),
      'filled_slot_count': slots.length,
      'missing_slot_count': 4 - slots.length,
      'average_score': log.averageScore,
      'slots': slots,
    };
  }

  /// Aggregates an arbitrary list of [DailyLog]s for weekly / monthly views.
  /// Null entries (days with zero data) are silently dropped.
  static Map<String, dynamic> sanitizeRange(List<DailyLog?> logs) {
    final cleaned = logs
        .whereType<DailyLog>()
        .where((l) => l.filledCount > 0)
        .toList();

    final allEntries = cleaned.expand((l) => l.filledSlots.values).toList();

    // Dominant mood score (mode)
    final scoreCounts = <int, int>{};
    for (final e in allEntries) {
      scoreCounts.update(e.emotionScore, (v) => v + 1, ifAbsent: () => 1);
    }
    final dominantScore = scoreCounts.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .firstOrNull
        ?.key;

    // Top tags (lower-cased, trimmed)
    final tagCounts = <String, int>{};
    for (final e in allEntries) {
      for (final t in (e.tags ?? const <String>[])) {
        final norm = t.trim().toLowerCase();
        if (norm.isEmpty) continue;
        tagCounts.update(norm, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final topTags = tagCounts.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(5)
        .map((e) => {'tag': e.key, 'count': e.value})
        .toList();

    final avg = allEntries.isEmpty
        ? null
        : allEntries.fold<int>(0, (s, e) => s + e.emotionScore) /
            allEntries.length;

    return {
      'period_days': logs.length,
      'days_with_data': cleaned.length,
      'total_check_ins': allEntries.length,
      'average_score': avg,
      'dominant_score': dominantScore,
      'dominant_mood_label':
          dominantScore == null ? null : _scoreLabel(dominantScore),
      'top_tags': topTags,
      'daily_summaries': cleaned
          .map((l) => {
                'date': _isoDate(l.date),
                'avg': l.averageScore,
                'count': l.filledCount,
              })
          .toList(),
    };
  }

  // ── helpers ────────────────────────────────────────────────────────
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _scoreLabel(int score) => switch (score) {
        1 => 'Sangat Buruk',
        2 => 'Buruk',
        3 => 'Biasa',
        4 => 'Baik',
        _ => 'Sangat Baik',
      };
}
