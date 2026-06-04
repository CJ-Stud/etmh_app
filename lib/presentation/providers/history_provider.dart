// lib/presentation/providers/history_provider.dart
//
// State for the emotion history calendar. Holds the currently visible
// month and the logs within it, and exposes month navigation. All I/O
// is funnelled through a single try-catch so the UI can show a calm
// error state instead of crashing.

import 'package:flutter/foundation.dart';

import '../../data/models/daily_log.dart';
import '../../data/models/emotion_entry.dart';
import '../../data/repositories/emotion_repository.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({required EmotionRepository repository})
      : _repo = repository {
    _visibleMonth = _firstOfMonth(DateTime.now());
    loadMonth();
  }

  final EmotionRepository _repo;

  /// Always normalised to the 1st of the month at 00:00.
  late DateTime _visibleMonth;
  DateTime get visibleMonth => _visibleMonth;

  /// day-of-month (1–31) → that day's log. Empty days are absent.
  Map<int, DailyLog> _logs = const {};
  Map<int, DailyLog> get logs => _logs;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// Block paging into the future — there's nothing to show there yet.
  bool get canGoNext => _visibleMonth.isBefore(_firstOfMonth(DateTime.now()));

  // ── Loading ────────────────────────────────────────────────────────
  Future<void> loadMonth() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _logs = await _repo.getMonth(_visibleMonth);
    } catch (_) {
      _logs = const {};
      _error = 'Gagal memuat riwayat. Coba lagi nanti.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────
  Future<void> goToPreviousMonth() async {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    await loadMonth();
  }

  Future<void> goToNextMonth() async {
    if (!canGoNext) return;
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    await loadMonth();
  }

  // ── Edit / delete ──────────────────────────────────────────────────
  /// Adds or overwrites the entry in [slot] on [date], then refreshes.
  Future<void> editEntry(
    DateTime date,
    EmotionSlot slot,
    EmotionEntry entry,
  ) async {
    try {
      final day = await _repo.getDay(date);
      await _repo.saveDay(day.withSlot(slot, entry));
    } catch (_) {
      _error = 'Gagal menyimpan perubahan. Coba lagi nanti.';
    }
    await loadMonth();
  }

  /// Clears the entry in [slot] on [date]. If it was the day's last
  /// remaining slot, the whole day is deleted. Then refreshes.
  Future<void> deleteEntry(DateTime date, EmotionSlot slot) async {
    try {
      final day = await _repo.getDay(date);
      final cleared = day.clearSlot(slot);
      if (cleared.isEmpty) {
        await _repo.deleteDay(date);
      } else {
        await _repo.saveDay(cleared);
      }
    } catch (_) {
      _error = 'Gagal menghapus catatan. Coba lagi nanti.';
    }
    await loadMonth();
  }

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
}