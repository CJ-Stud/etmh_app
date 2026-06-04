// lib/data/models/daily_log.dart
//
// One document per calendar day, holding up to 4 nullable slots.
// Edge-case contract: a `null` slot must NEVER crash the app and must
// NEVER reach Gemini. See `DataSanitizer` for the cleaning rules.

import 'package:flutter/foundation.dart';

import 'emotion_entry.dart';

@immutable
class DailyLog {
  /// Calendar date this log refers to. Always normalised to 00:00.
  final DateTime date;

  final EmotionEntry? morning;
  final EmotionEntry? afternoon;
  final EmotionEntry? evening;
  final EmotionEntry? night;

  /// Cached AI insight for the day. Regenerated whenever a new slot is added.
  final String? dailyInsight;

  /// When the cached insight was produced.
  final DateTime? insightGeneratedAt;

  DailyLog({
    required DateTime date,
    this.morning,
    this.afternoon,
    this.evening,
    this.night,
    this.dailyInsight,
    this.insightGeneratedAt,
  }) : date = DateTime(date.year, date.month, date.day);

  // ── Convenience helpers (all null-safe) ────────────────────────────

  Map<EmotionSlot, EmotionEntry> get filledSlots => {
        if (morning != null) EmotionSlot.morning: morning!,
        if (afternoon != null) EmotionSlot.afternoon: afternoon!,
        if (evening != null) EmotionSlot.evening: evening!,
        if (night != null) EmotionSlot.night: night!,
      };

  int get filledCount => filledSlots.length;
  bool get isEmpty => filledCount == 0;
  bool get isComplete => filledCount == 4;

  double? get averageScore {
    final entries = filledSlots.values;
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (s, e) => s + e.emotionScore);
    return total / entries.length;
  }

  /// Stable document ID — used as the Hive box key and Firestore doc ID.
  String get id =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DailyLog copyWith({
    DateTime? date,
    EmotionEntry? morning,
    EmotionEntry? afternoon,
    EmotionEntry? evening,
    EmotionEntry? night,
    String? dailyInsight,
    DateTime? insightGeneratedAt,
    bool clearInsight = false,
  }) =>
      DailyLog(
        date: date ?? this.date,
        morning: morning ?? this.morning,
        afternoon: afternoon ?? this.afternoon,
        evening: evening ?? this.evening,
        night: night ?? this.night,
        dailyInsight:
            clearInsight ? null : (dailyInsight ?? this.dailyInsight),
        insightGeneratedAt: clearInsight
            ? null
            : (insightGeneratedAt ?? this.insightGeneratedAt),
      );

  /// Returns a new log with the given slot updated. We deliberately clear
  /// the cached insight so the next read re-generates it.
  DailyLog withSlot(EmotionSlot slot, EmotionEntry entry) => switch (slot) {
        EmotionSlot.morning => copyWith(morning: entry, clearInsight: true),
        EmotionSlot.afternoon =>
          copyWith(afternoon: entry, clearInsight: true),
        EmotionSlot.evening => copyWith(evening: entry, clearInsight: true),
        EmotionSlot.night => copyWith(night: entry, clearInsight: true),
      };

  /// Returns a new log with the given slot emptied. Rebuilt explicitly
  /// (rather than via copyWith) because copyWith can't set a field back
  /// to null. The cached insight is dropped since the day changed.
  DailyLog clearSlot(EmotionSlot slot) => DailyLog(
        date: date,
        morning: slot == EmotionSlot.morning ? null : morning,
        afternoon: slot == EmotionSlot.afternoon ? null : afternoon,
        evening: slot == EmotionSlot.evening ? null : evening,
        night: slot == EmotionSlot.night ? null : night,
      );

  // ── JSON ────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'morning': morning?.toJson(),
        'afternoon': afternoon?.toJson(),
        'evening': evening?.toJson(),
        'night': night?.toJson(),
        if (dailyInsight != null) 'dailyInsight': dailyInsight,
        if (insightGeneratedAt != null)
          'insightGeneratedAt': insightGeneratedAt!.toIso8601String(),
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
        date: DateTime.parse(json['date'] as String),
        morning: _entryFromJson(json['morning']),
        afternoon: _entryFromJson(json['afternoon']),
        evening: _entryFromJson(json['evening']),
        night: _entryFromJson(json['night']),
        dailyInsight: json['dailyInsight'] as String?,
        insightGeneratedAt: json['insightGeneratedAt'] == null
            ? null
            : DateTime.parse(json['insightGeneratedAt'] as String),
      );

  static EmotionEntry? _entryFromJson(dynamic raw) {
    if (raw == null) return null;
    return EmotionEntry.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}
