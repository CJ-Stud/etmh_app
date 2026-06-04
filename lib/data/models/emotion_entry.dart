// lib/data/models/emotion_entry.dart
//
// A single check-in (one of the four daily slots).
//
// Design note: we deliberately avoid Hive's @HiveType / code-generation
// step. Instead, we persist this object as a JSON string in a
// `Box<String>`. This removes the need for `build_runner` entirely and
// means the project compiles in one shot with no extra commands.

import 'package:flutter/foundation.dart';

@immutable
class EmotionEntry {
  /// 1 = Very Bad, 5 = Very Happy. Validated to that range.
  final int emotionScore;
  final DateTime timestamp;

  /// Optional context tags like 'work', 'family', 'sleep'.
  final List<String>? tags;

  /// Optional free-text reflection.
  final String? notes;

  const EmotionEntry({
    required this.emotionScore,
    required this.timestamp,
    this.tags,
    this.notes,
  }) : assert(
          emotionScore >= 1 && emotionScore <= 5,
          'emotionScore must be between 1 and 5',
        );

  String get moodLabel => switch (emotionScore) {
        1 => 'Sangat Buruk',
        2 => 'Buruk',
        3 => 'Biasa',
        4 => 'Baik',
        _ => 'Sangat Baik',
      };

  EmotionEntry copyWith({
    int? emotionScore,
    DateTime? timestamp,
    List<String>? tags,
    String? notes,
  }) =>
      EmotionEntry(
        emotionScore: emotionScore ?? this.emotionScore,
        timestamp: timestamp ?? this.timestamp,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'emotionScore': emotionScore,
        'timestamp': timestamp.toIso8601String(),
        if (tags != null) 'tags': tags,
        if (notes != null) 'notes': notes,
      };

  factory EmotionEntry.fromJson(Map<String, dynamic> json) => EmotionEntry(
        emotionScore: (json['emotionScore'] as num).toInt(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
        notes: json['notes'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionEntry &&
          other.emotionScore == emotionScore &&
          other.timestamp == timestamp &&
          listEquals(other.tags, tags) &&
          other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(emotionScore, timestamp, Object.hashAll(tags ?? const []), notes);
}

/// Time slot during which an entry was recorded. Plain enum — no Hive
/// adapter needed since we never persist this enum directly (slots are
/// stored as the named fields of DailyLog).
enum EmotionSlot {
  morning,
  afternoon,
  evening,
  night;

  /// Derive the current slot from any DateTime. The boundaries are tunable.
  static EmotionSlot fromHour(int hour) {
    if (hour >= 5 && hour < 11) return EmotionSlot.morning;
    if (hour >= 11 && hour < 16) return EmotionSlot.afternoon;
    if (hour >= 16 && hour < 21) return EmotionSlot.evening;
    return EmotionSlot.night;
  }

  String get label => switch (this) {
        EmotionSlot.morning => 'Pagi',
        EmotionSlot.afternoon => 'Siang',
        EmotionSlot.evening => 'Sore',
        EmotionSlot.night => 'Malam',
      };

  /// Hour (0–23) at which this slot's window opens. Mirrors [fromHour].
  int get startHour => switch (this) {
        EmotionSlot.morning => 5,
        EmotionSlot.afternoon => 11,
        EmotionSlot.evening => 16,
        EmotionSlot.night => 21,
      };

  /// Whether this slot is open for logging at [now] (for today). A slot
  /// is open once its window has started; the slot that [now] currently
  /// falls into always counts as open too, so late-night logging
  /// (00:00–05:00, which maps to "Malam") keeps working. Future slots
  /// are closed.
  bool isOpenAt(DateTime now) =>
      now.hour >= startHour || this == EmotionSlot.fromHour(now.hour);
}
