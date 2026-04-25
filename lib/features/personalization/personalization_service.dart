import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/reading_plan.dart';

/// Persists user-tailored data — active reading plan, recent verse refs read,
/// and today's mood — for the AI personalization features.
///
/// Single instance, lazily-initialized via [init]. Reads/writes
/// SharedPreferences directly. Riverpod-aware via [personalizationServiceProvider].
class PersonalizationService {
  PersonalizationService._();
  static final PersonalizationService instance = PersonalizationService._();

  // ─── SharedPreferences keys ───────────────────────────────────
  static const _kActivePlan = 'reading_plan_active';
  static const _kRecentRefs = 'vod_recent_refs';
  static const _moodKeyPrefix = 'mood_';

  static const _recentRefsCap = 30;

  SharedPreferences? _prefs;
  ReadingPlan? _activePlan;
  bool _initialized = false;

  /// Load active plan from disk. Idempotent — safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kActivePlan);
    if (raw != null && raw.isNotEmpty) {
      try {
        _activePlan = ReadingPlan.fromJsonString(raw);
      } catch (_) {
        _activePlan = null;
      }
    }
    _initialized = true;
  }

  // ─── Reading plan ─────────────────────────────────────────────

  ReadingPlan? get activePlan => _activePlan;

  Future<void> saveActivePlan(ReadingPlan p) async {
    await _ensureInit();
    _activePlan = p;
    await _prefs!.setString(_kActivePlan, p.toJsonString());
  }

  Future<void> markDayCompleted(int day) async {
    await _ensureInit();
    final plan = _activePlan;
    if (plan == null) return;
    var changed = false;
    for (final d in plan.schedule) {
      if (d.day == day) {
        d.completed = !(d.completed ?? false);
        d.completedAt = (d.completed ?? false) ? DateTime.now() : null;
        changed = true;
        break;
      }
    }
    if (changed) {
      await _prefs!.setString(_kActivePlan, plan.toJsonString());
    }
  }

  Future<void> clearPlan() async {
    await _ensureInit();
    _activePlan = null;
    await _prefs!.remove(_kActivePlan);
  }

  // ─── Adaptive VotD: history + mood ────────────────────────────

  /// Record a verse the user read. Prepends, dedups, caps at 30.
  Future<void> recordReadVerse(String ref) async {
    await _ensureInit();
    if (ref.trim().isEmpty) return;
    final list = getRecentRefs();
    list.removeWhere((e) => e == ref);
    list.insert(0, ref);
    if (list.length > _recentRefsCap) {
      list.removeRange(_recentRefsCap, list.length);
    }
    await _prefs!.setString(_kRecentRefs, json.encode(list));
  }

  /// Returns the most recent (capped) verse refs read.
  List<String> getRecentRefs() {
    final raw = _prefs?.getString(_kRecentRefs);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return <String>[];
  }

  /// Persist today's mood. Mood string is one of:
  /// 'anxious' | 'grateful' | 'lost' | 'hopeful' (anything else is allowed).
  Future<void> setMoodForToday(String mood) async {
    await _ensureInit();
    await _prefs!.setString(_todayMoodKey(), mood);
  }

  /// Returns today's mood, or null if none set.
  String? getMoodForToday() {
    final v = _prefs?.getString(_todayMoodKey());
    return (v == null || v.isEmpty) ? null : v;
  }

  String _todayMoodKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$_moodKeyPrefix$y$m$d';
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}

// ─── Riverpod ─────────────────────────────────────────────────

/// Singleton personalization service provider.
final personalizationServiceProvider =
    Provider<PersonalizationService>((ref) => PersonalizationService.instance);

/// Async-loaded active plan. Fires init under the hood. Returns null if none.
final activePlanProvider = FutureProvider<ReadingPlan?>((ref) async {
  final svc = ref.watch(personalizationServiceProvider);
  await svc.init();
  return svc.activePlan;
});
