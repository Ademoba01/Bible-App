import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Word-index spans for red-letter (Christ's words) and blue-letter
/// (God's direct speech) annotations, loaded from the OSIS-derived
/// dataset baked into `assets/data/redletter_kjv.json`.
///
/// Indices are 0-based and inclusive over whitespace-tokenized verse
/// text. Range [3, 7] colors words 3, 4, 5, 6, 7 (5 words). Indices
/// align with our `verse.text.split()` tokenization — matching the same
/// scheme the build script (`scripts/build_redletter.py`) uses.
///
/// Source:
///   • Red:  ``<q who="Jesus">`` markers from eBible.org KJV OSIS
///           (public domain, 2,058 verses, exact)
///   • Blue: heuristic regex pass over our local KJV text matching
///           the standard "Thus saith the LORD" / "the LORD said" /
///           "And God said" templates, with multi-verse propagation
///           through ", saying," openers until a narrative re-entry.
///           ~2,510 verses, 80%+ accurate.
class RedLetterEntry {
  /// Word-index ranges (inclusive) where Christ's words appear.
  final List<List<int>> red;
  /// Word-index ranges (inclusive) where God's direct speech appears.
  final List<List<int>> blue;

  const RedLetterEntry({this.red = const [], this.blue = const []});

  /// Returns true if [wordIndex] falls inside any red range.
  bool isRed(int wordIndex) {
    for (final r in red) {
      if (wordIndex >= r[0] && wordIndex <= r[1]) return true;
    }
    return false;
  }

  /// Returns true if [wordIndex] falls inside any blue range.
  bool isBlue(int wordIndex) {
    for (final r in blue) {
      if (wordIndex >= r[0] && wordIndex <= r[1]) return true;
    }
    return false;
  }
}

/// Lazy-loaded singleton serving red/blue letter data. Asset is small
/// (~190 KB) so we hold the whole map in memory.
class RedLetterService {
  RedLetterService._();
  static final RedLetterService instance = RedLetterService._();

  Map<String, RedLetterEntry>? _data;
  Future<void>? _loading;

  bool get isReady => _data != null;

  Future<void> init() {
    if (isReady) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/redletter_kjv.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final out = <String, RedLetterEntry>{};
      decoded.forEach((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        final red = (m['red'] as List?)
                ?.map((e) => List<int>.from(e as List))
                .toList() ??
            const <List<int>>[];
        final blue = (m['blue'] as List?)
                ?.map((e) => List<int>.from(e as List))
                .toList() ??
            const <List<int>>[];
        out[key] = RedLetterEntry(red: red, blue: blue);
      });
      _data = out;
    } catch (e, st) {
      debugPrint('RedLetterService load failed: $e\n$st');
      _data = const {};
    } finally {
      _loading = null;
    }
  }

  /// Returns the red/blue entry for a verse, or an empty entry if no
  /// annotations exist (the common case — most verses are plain).
  RedLetterEntry forVerse(String book, int chapter, int verse) {
    final d = _data;
    if (d == null) return const RedLetterEntry();
    return d['$book $chapter:$verse'] ?? const RedLetterEntry();
  }
}

/// Riverpod provider for the singleton. Reads kick off the async load
/// so the dataset is ready by the time the user opens a chapter.
final redLetterServiceProvider = Provider<RedLetterService>((ref) {
  final svc = RedLetterService.instance;
  svc.init();
  return svc;
});
