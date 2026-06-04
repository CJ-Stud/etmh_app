// lib/data/repositories/emotion_repository.dart
//
// Single source of truth for reading & writing DailyLog data.
//
// Storage strategy:
//   • Write path  : Hive  → Firestore  (Hive first guarantees instant UI)
//   • Read path   : Hive  if present, else Firestore, else fresh empty log
//
// Logs are persisted as JSON strings in a Hive `Box<String>` — this
// removes the need for code-generated Hive adapters entirely.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/daily_log.dart';

class EmotionRepository {
  EmotionRepository({
    required this.box,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const String boxName = 'daily_logs';

  final Box<String> box;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _userLogs {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('daily_logs');
  }

  // ── Read ───────────────────────────────────────────────────────────

  /// Returns the log for [date] (00:00-normalised). If neither cache nor
  /// Firestore has data, returns an empty log so callers never see null.
  Future<DailyLog> getDay(DateTime date) async {
    final id = _idOf(date);
    final cached = _readLocal(id);
    if (cached != null) return cached;

    final remote = await _readRemote(id);
    if (remote != null) {
      await _writeLocal(remote);
      return remote;
    }
    return DailyLog(date: date);
  }

  /// Fetches the last [days] days as a chronologically-ordered list.
  /// Days with no data appear as `null` in the result.
  Future<List<DailyLog?>> getRange({required int days}) async {
    final today = _today();
    final results = <DailyLog?>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final id = _idOf(d);
      DailyLog? log = _readLocal(id);
      log ??= await _readRemote(id);
      if (log != null) await _writeLocal(log);
      results.add((log != null && log.filledCount > 0) ? log : null);
    }
    return results;
  }

  /// Fetches every recorded log within the calendar month that contains
  /// [month]. Returns a map keyed by day-of-month (1–31). Days that have
  /// no check-ins are simply absent from the map.
  ///
  /// Note: this reads day-by-day (local cache first, Firestore fallback),
  /// which keeps it consistent with [getDay]/[getRange]. For very large
  /// histories you could swap this for a single ranged Firestore query
  /// on the document id, but the per-day loop is plenty for this app and
  /// is served almost entirely from the local Hive cache.
  Future<Map<int, DailyLog>> getMonth(DateTime month) async {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final result = <int, DailyLog>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(month.year, month.month, day);
      final id = _idOf(d);
      DailyLog? log = _readLocal(id);
      log ??= await _readRemote(id);
      if (log != null) {
        await _writeLocal(log);
        if (log.filledCount > 0) result[day] = log;
      }
    }
    return result;
  }

  // ── Write ──────────────────────────────────────────────────────────

  Future<DailyLog> saveDay(DailyLog log) async {
    await _writeLocal(log);
    await _writeRemote(log);
    return log;
  }

  /// Persists the cached insight back into both stores.
  Future<DailyLog> updateInsight(DailyLog log, String insight) async {
    final updated = log.copyWith(
      dailyInsight: insight,
      insightGeneratedAt: DateTime.now(),
    );
    await _writeLocal(updated);
    await _writeRemote(updated);
    return updated;
  }

  /// Removes a day entirely from both stores. Used when a user deletes
  /// the last remaining slot of a day. Failures are swallowed so the UI
  /// stays calm; the local store is the source of truth for the session.
  Future<void> deleteDay(DateTime date) async {
    final id = _idOf(date);
    try {
      await box.delete(id);
    } catch (_) {
      // Local delete failed — ignore; nothing else we can safely do.
    }
    final coll = _userLogs;
    if (coll == null) return;
    try {
      await coll.doc(id).delete();
    } catch (_) {
      // Network / permissions — Firestore will reconcile when online.
    }
  }

  // ── Internal ───────────────────────────────────────────────────────

  DailyLog? _readLocal(String id) {
    final raw = box.get(id);
    if (raw == null) return null;
    try {
      return DailyLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // Corrupt entry — treat as missing.
    }
  }

  Future<void> _writeLocal(DailyLog log) async {
    await box.put(log.id, jsonEncode(log.toJson()));
  }

  Future<DailyLog?> _readRemote(String id) async {
    final coll = _userLogs;
    if (coll == null) return null;
    try {
      final snap = await coll.doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      return DailyLog.fromJson(data);
    } catch (_) {
      return null; // Network / permissions → fall back to local.
    }
  }

  Future<void> _writeRemote(DailyLog log) async {
    final coll = _userLogs;
    if (coll == null) return; // User not signed in — local only.
    try {
      await coll.doc(log.id).set(log.toJson());
    } catch (_) {
      // Sync silently — Firestore's offline cache will retry when online.
    }
  }

  String _idOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
