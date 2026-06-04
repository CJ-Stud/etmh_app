// lib/presentation/providers/emotion_provider.dart
//
// The single ChangeNotifier the UI listens to for the current day,
// recent history, and AI insights. All blocking I/O lives here so
// widgets stay declarative.

import 'package:flutter/foundation.dart';

import '../../data/models/daily_log.dart';
import '../../data/models/emotion_entry.dart';
import '../../data/repositories/emotion_repository.dart';
import '../../services/gemini_insight_service.dart';

class EmotionProvider extends ChangeNotifier {
  EmotionProvider({
    required EmotionRepository repository,
    required GeminiInsightService aiService,
  })  : _repo = repository,
        _ai = aiService {
    _bootstrap();
  }

  final EmotionRepository _repo;
  final GeminiInsightService _ai;

  DailyLog _today = DailyLog(date: DateTime.now());
  DailyLog get today => _today;

  InsightResult? _dailyInsight;
  InsightResult? get dailyInsight => _dailyInsight;

  bool _loadingInsight = false;
  bool get loadingInsight => _loadingInsight;

  bool _initialised = false;
  bool get initialised => _initialised;

  // ── Initial load ───────────────────────────────────────────────────
  Future<void> _bootstrap() async {
    _today = await _repo.getDay(DateTime.now());
    _initialised = true;
    notifyListeners();
    // Generate insight in the background so the UI paints first.
    unawaitedRefreshInsight();
  }

  // ── Mutations ──────────────────────────────────────────────────────

  Future<void> recordEntry({
    required EmotionSlot slot,
    required EmotionEntry entry,
  }) async {
    _today = _today.withSlot(slot, entry);
    notifyListeners(); // optimistic UI update
    _today = await _repo.saveDay(_today);
    notifyListeners();
    await refreshDailyInsight();
  }

  /// Fire-and-forget wrapper used during bootstrap.
  void unawaitedRefreshInsight() {
    refreshDailyInsight();
  }

  Future<void> refreshDailyInsight() async {
    if (_today.isEmpty) {
      _dailyInsight = null;
      notifyListeners();
      return;
    }
    _loadingInsight = true;
    notifyListeners();

    final result = await _ai.generateDailyInsight(_today);
    _dailyInsight = result;

    // Persist the new insight if it came from the live model (not the
    // local fallback) — fallbacks shouldn't pollute the cache.
    if (!result.isFallback) {
      _today = await _repo.updateInsight(_today, result.text);
    }

    _loadingInsight = false;
    notifyListeners();
  }

  // ── Read-only helpers used by trend screens ───────────────────────

  Future<InsightResult> weeklyInsight() async {
    final logs = await _repo.getRange(days: 7);
    return _ai.generateWeeklyInsight(logs);
  }

  Future<InsightResult> monthlyInsight() async {
    final logs = await _repo.getRange(days: 30);
    return _ai.generateMonthlyInsight(logs);
  }
}
