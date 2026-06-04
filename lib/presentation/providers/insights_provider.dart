// lib/presentation/providers/insights_provider.dart
//
// Drives the "Tren & Insight" screen. Loads the last 30 days once (for
// the trend chart) and asks Milo for a weekly and a monthly reflection.
// The Gemini service already returns calm fallbacks on failure, so this
// provider only needs light extra guarding.

import 'package:flutter/foundation.dart';

import '../../data/models/daily_log.dart';
import '../../data/repositories/emotion_repository.dart';
import '../../services/gemini_insight_service.dart';

class InsightsProvider extends ChangeNotifier {
  InsightsProvider({
    required EmotionRepository repository,
    required GeminiInsightService aiService,
  })  : _repo = repository,
        _ai = aiService {
    load();
  }

  final EmotionRepository _repo;
  final GeminiInsightService _ai;

  List<DailyLog?> _last30 = const [];
  List<DailyLog?> get last30 => _last30;

  InsightResult? _weekly;
  InsightResult? get weekly => _weekly;

  InsightResult? _monthly;
  InsightResult? get monthly => _monthly;

  bool _loadingChart = false;
  bool get loadingChart => _loadingChart;

  bool _loadingWeekly = false;
  bool get loadingWeekly => _loadingWeekly;

  bool _loadingMonthly = false;
  bool get loadingMonthly => _loadingMonthly;

  String? _error;
  String? get error => _error;

  /// Most-used tags across the loaded window, most frequent first.
  /// Normalised to lowercase so "Kerja" and "kerja" merge.
  List<MapEntry<String, int>> get topTags {
    final counts = <String, int>{};
    for (final log in _last30) {
      if (log == null) continue;
      for (final entry in log.filledSlots.values) {
        for (final t in (entry.tags ?? const <String>[])) {
          final norm = t.trim().toLowerCase();
          if (norm.isEmpty) continue;
          counts.update(norm, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).toList();
  }

  Future<void> load() async {
    await _loadChart();
    await Future.wait([_loadWeekly(), _loadMonthly()]);
  }

  Future<void> _loadChart() async {
    _loadingChart = true;
    _error = null;
    notifyListeners();
    try {
      _last30 = await _repo.getRange(days: 30);
    } catch (_) {
      _last30 = const [];
      _error = 'Gagal memuat data tren. Coba lagi nanti.';
    } finally {
      _loadingChart = false;
      notifyListeners();
    }
  }

  Future<void> refreshWeekly() => _loadWeekly();
  Future<void> refreshMonthly() => _loadMonthly();

  Future<void> _loadWeekly() async {
    _loadingWeekly = true;
    notifyListeners();
    try {
      final last7 = _last30.length >= 7
          ? _last30.sublist(_last30.length - 7)
          : _last30;
      _weekly = await _ai.generateWeeklyInsight(last7);
    } catch (_) {
      // Service already degrades gracefully; ignore.
    } finally {
      _loadingWeekly = false;
      notifyListeners();
    }
  }

  Future<void> _loadMonthly() async {
    _loadingMonthly = true;
    notifyListeners();
    try {
      _monthly = await _ai.generateMonthlyInsight(_last30);
    } catch (_) {
      // Service already degrades gracefully; ignore.
    } finally {
      _loadingMonthly = false;
      notifyListeners();
    }
  }
}
