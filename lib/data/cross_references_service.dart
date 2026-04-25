import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One entry in a verse's cross-reference list.
///
/// `votes` is the OpenBible.info "interest" score from the Treasury of
/// Scripture Knowledge (TSK) dataset — higher = more strongly linked.
typedef CrossRef = ({String ref, int votes});

/// Lazy-loaded singleton that serves OpenBible.info Treasury of Scripture
/// Knowledge cross-references baked into `assets/data/cross_references.json`.
///
/// Data shape:
///   { "Genesis 1:1": [{"ref": "John 1:1", "votes": 364}, ...], ... }
///
/// Refs are pre-sorted by votes desc and capped at 30 per source verse.
/// The build script `scripts/build_cross_references.py` produces the JSON.
class CrossReferencesService {
  CrossReferencesService._();
  static final CrossReferencesService instance = CrossReferencesService._();

  /// In-memory map: "Book C:V" → ranked list of refs.
  Map<String, List<CrossRef>>? _index;

  /// Tracks the in-flight load so concurrent callers share one Future.
  Future<void>? _loading;

  bool get isReady => _index != null;

  /// Lazy-loads the JSON asset on first call. Subsequent calls are no-ops.
  Future<void> init() {
    if (_index != null) return Future.value();
    return _loading ??= _loadFromAsset();
  }

  Future<void> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/cross_references.json',
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final out = <String, List<CrossRef>>{};
      decoded.forEach((source, refs) {
        final list = (refs as List).map<CrossRef>((e) {
          final m = e as Map<String, dynamic>;
          return (
            ref: m['ref'] as String,
            votes: (m['votes'] as num).toInt(),
          );
        }).toList(growable: false);
        out[source] = list;
      });
      _index = out;
    } catch (e, st) {
      debugPrint('CrossReferencesService load failed: $e\n$st');
      _index = {}; // fail soft — empty index, every lookup returns []
    } finally {
      _loading = null;
    }
  }

  /// Returns the ranked cross-references for `book chapter:verse`, or empty
  /// when none exist. Returns empty until `init()` resolves.
  List<CrossRef> forVerse(String book, int chapter, int verse) {
    final idx = _index;
    if (idx == null) return const [];
    return idx['$book $chapter:$verse'] ?? const [];
  }
}

/// Riverpod provider for the singleton.
final crossReferencesServiceProvider = Provider<CrossReferencesService>((ref) {
  final svc = CrossReferencesService.instance;
  // Kick off the load on first read; UI awaits via crossReferencesForProvider.
  svc.init();
  return svc;
});

/// Async provider that ensures the index is loaded, then returns the refs
/// for a given verse. Use this from the sheet — it auto-rebuilds when load
/// completes.
final crossReferencesForProvider = FutureProvider.family<
    List<CrossRef>, ({String book, int chapter, int verse})>((ref, key) async {
  final svc = ref.watch(crossReferencesServiceProvider);
  await svc.init();
  return svc.forVerse(key.book, key.chapter, key.verse);
});
