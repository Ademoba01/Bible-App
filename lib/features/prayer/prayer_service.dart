import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/prayer_request.dart';

/// Local-only persistence for the user's private prayer ledger.
/// Backed by SharedPreferences under the key `prayer_requests`
/// (a JSON array of [PrayerRequest.toJson] maps).
///
/// MVP: no Firestore, no cross-device sync. This is intentionally a
/// devotional-grade local store the user fully owns.
class PrayerService {
  PrayerService._();
  static final PrayerService instance = PrayerService._();

  static const _prefsKey = 'prayer_requests';

  final List<PrayerRequest> _items = [];
  bool _initialized = false;

  /// Hydrate the in-memory list from SharedPreferences. Idempotent — calling
  /// `init()` more than once is safe and re-reads from disk.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _items.add(PrayerRequest.fromJson(item));
            } else if (item is Map) {
              _items.add(PrayerRequest.fromJson(
                  Map<String, dynamic>.from(item)));
            }
          }
        }
      } catch (_) {
        // Corrupt or legacy data — start fresh rather than crash.
        _items.clear();
      }
    }
    _initialized = true;
  }

  /// Open prayers, newest first.
  List<PrayerRequest> allOpen() {
    final list = _items.where((r) => !r.isAnswered).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Answered prayers, most-recently-answered first.
  List<PrayerRequest> allAnswered() {
    final list = _items.where((r) => r.isAnswered).toList();
    list.sort((a, b) => b.answeredAt!.compareTo(a.answeredAt!));
    return list;
  }

  /// Look up a prayer by id, or null if it's been deleted.
  PrayerRequest? getById(String id) {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Insert a new prayer at the top of the ledger.
  Future<void> add(PrayerRequest r) async {
    await _ensureInit();
    _items.insert(0, r);
    await _persist();
  }

  /// Update any field on an existing prayer (matched by id).
  Future<void> update(PrayerRequest r) async {
    await _ensureInit();
    final idx = _items.indexWhere((x) => x.id == r.id);
    if (idx == -1) return;
    _items[idx] = r;
    await _persist();
  }

  /// Mark the prayer with [id] as answered now, optionally attaching a
  /// reflection note.
  Future<void> markAnswered(String id, {String? answerNote}) async {
    await _ensureInit();
    final idx = _items.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      answeredAt: DateTime.now(),
      answerNote: (answerNote != null && answerNote.trim().isNotEmpty)
          ? answerNote.trim()
          : _items[idx].answerNote,
    );
    await _persist();
  }

  /// Move a previously-answered prayer back to the open list.
  Future<void> reopen(String id) async {
    await _ensureInit();
    final idx = _items.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      clearAnswered: true,
      clearAnswerNote: true,
    );
    await _persist();
  }

  /// Permanently remove a prayer. There is no undo (yet).
  Future<void> delete(String id) async {
    await _ensureInit();
    _items.removeWhere((x) => x.id == id);
    await _persist();
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_items.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}

// ---------- Riverpod providers ----------

/// The shared singleton service. Eagerly initialized via the provider's
/// FutureProvider counterparts below.
final prayerServiceProvider = Provider<PrayerService>((ref) {
  return PrayerService.instance;
});

/// Internal: an auto-incrementing counter the UI bumps after every mutation
/// so the list providers re-read from disk and rebuild.
final prayerRefreshProvider = StateProvider<int>((ref) => 0);

/// Open prayers, sorted newest-first. Re-reads on every mutation.
final openPrayersProvider =
    FutureProvider<List<PrayerRequest>>((ref) async {
  ref.watch(prayerRefreshProvider);
  final svc = ref.watch(prayerServiceProvider);
  await svc.init();
  return svc.allOpen();
});

/// Answered prayers, sorted by most-recently-answered. Re-reads on every
/// mutation.
final answeredPrayersProvider =
    FutureProvider<List<PrayerRequest>>((ref) async {
  ref.watch(prayerRefreshProvider);
  final svc = ref.watch(prayerServiceProvider);
  await svc.init();
  return svc.allAnswered();
});

/// Convenience: bumps the refresh counter so the list providers rebuild.
void bumpPrayerRefresh(WidgetRef ref) {
  ref.read(prayerRefreshProvider.notifier).state++;
}
