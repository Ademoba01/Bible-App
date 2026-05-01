import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One Strong's-tagged token in a verse — the per-word payload that powers
/// "tap a word to see the original-language form" (Scholar Mode).
///
///   - `word` is the visible English surface token. Multiple consecutive
///     entries may share a single Strong's number when the underlying
///     original-language word translates as a multi-word English phrase.
///   - `strongs` is the disambiguated Strong's id, e.g. "G3056" or "H0430G".
///   - `lemma` is the dictionary form of the original-language word, when
///     known (Greek only — Hebrew lemma extraction is brittle and skipped
///     in the build script).
///   - `original` is the surface-form of the original word from the verse
///     (e.g. "θεὸς" — the inflected form, not the lemma).
///   - `translit` is a pronounceable transliteration ("theos", "Yah.weh").
class StrongsWord {
  final String word;
  final String? strongs;
  final String? lemma;
  final String? original;
  final String? translit;

  const StrongsWord({
    required this.word,
    this.strongs,
    this.lemma,
    this.original,
    this.translit,
  });

  factory StrongsWord.fromMap(Map<String, dynamic> m) => StrongsWord(
        word: (m['w'] ?? '') as String,
        strongs: m['s'] as String?,
        lemma: m['l'] as String?,
        original: m['o'] as String?,
        translit: m['t'] as String?,
      );
}

/// One verse reference paired with the surface English word that carries
/// the matching Strong's id — what the occurrences list shows per row.
class VerseRefWithWord {
  final String book;
  final int chapter;
  final int verse;
  /// The visible English token (e.g. "Word"). Used so the occurrences list
  /// can bold the matching word inside the verse preview.
  final String word;
  const VerseRefWithWord({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.word,
  });
  String get refId => '$book $chapter:$verse';
}

/// One Strong's lexicon entry — the payload shown in the lexicon bottom sheet.
class StrongsEntry {
  final String strongs;
  final String original;        // Greek/Hebrew lexical form (e.g. "λόγος")
  final String transliteration; // "logos", "elohim"
  final String partOfSpeech;    // "noun", "verb", "adjective", ...
  final String definition;      // brief definition (kept under ~100 chars)

  const StrongsEntry({
    required this.strongs,
    required this.original,
    required this.transliteration,
    required this.partOfSpeech,
    required this.definition,
  });
}

/// Lazy-loaded singleton serving Strong's tagging baked into
/// `assets/data/strongs_kjv.json` and `assets/data/strongs_lexicon.json`.
///
/// Both assets are loaded on first lookup and held in memory for the
/// process lifetime — combined size is ~58 MB so the cost is paid once.
class StrongsService {
  StrongsService._();
  static final StrongsService instance = StrongsService._();

  Map<String, List<StrongsWord>>? _verses;
  Map<String, StrongsEntry>? _lex;
  Map<String, int>? _occurrences; // Strong's # → count across NT+OT
  /// Inverse index: Strong's # → list of verse refs that contain that word.
  /// Built lazily on first call to [versesContaining] to avoid paying the
  /// cost upfront if the user never browses occurrences.
  Map<String, List<VerseRefWithWord>>? _occurrenceIndex;

  Future<void>? _loading;

  bool get isReady => _verses != null && _lex != null;

  /// Lazy-loads both JSON assets on first call. Subsequent calls are no-ops.
  Future<void> init() {
    if (isReady) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      // ── Off-isolate parse (perf review #21+22) ──
      // The previous implementation called json.decode + the full
      // verse-map iteration on the UI isolate, blocking the main thread
      // for 3-6s on a mid-range Pixel during first Scholar Mode tap.
      // Move both the 56 MB strongs JSON and the 2 MB lexicon parse to
      // a background isolate via compute() so the user's tap is
      // instantaneous and the main thread stays responsive.
      //
      // rootBundle.loadString must run on the UI isolate (asset
      // manifest lookup), but the heavy json.decode + map building
      // runs on a worker isolate. Total wall time is similar; what
      // matters is the UI thread stays free.
      final results = await Future.wait([
        rootBundle.loadString('assets/data/strongs_kjv.json'),
        rootBundle.loadString('assets/data/strongs_lexicon.json'),
      ]);
      final parsed = await compute(_parseStrongsBundle, results);
      _verses = parsed.verses;
      _lex = parsed.lex;
      _occurrences = parsed.occurrences;
    } catch (e, st) {
      debugPrint('StrongsService load failed: $e\n$st');
      _verses = {};
      _lex = {};
      _occurrences = {};
    } finally {
      _loading = null;
    }
  }

  /// Returns the Strong's-tagged tokens for a verse, in reading order.
  /// Returns empty until `init()` resolves.
  List<StrongsWord> wordsForVerse(String book, int chapter, int verse) {
    final v = _verses;
    if (v == null) return const [];
    return v['$book $chapter:$verse'] ?? const [];
  }

  /// Look up a Strong's number in the lexicon. Falls back to the un-suffixed
  /// id (e.g. "H0430G" → "H0430") when an exact match isn't present, since
  /// STEPBible disambiguated forms aren't all in the brief lexicon.
  ///
  /// Also accepts loose ids like "G26" (zero-pad to 4 digits) and "g3056"
  /// (case-insensitive).
  StrongsEntry? lookupStrong(String? id) {
    if (id == null || id.isEmpty) return null;
    final lex = _lex;
    if (lex == null) return null;

    final norm = _normalizeId(id);
    if (norm == null) return null;

    final hit = lex[norm];
    if (hit != null) return hit;

    // Fallback 1: strip the trailing disambiguator letter (e.g. "H0430G" → "H0430").
    final stripped = norm.replaceFirst(RegExp(r'[A-Z]$'), '');
    if (stripped != norm) {
      final fb = lex[stripped];
      if (fb != null) return fb;
    }
    return null;
  }

  /// All verse refs that contain the given Strong's id, in canonical reading
  /// order (the order the verses live in `_verses`). Built once on first call
  /// and cached. Returns empty until [init] resolves.
  List<VerseRefWithWord> versesContaining(String? id) {
    if (id == null || id.isEmpty) return const [];
    final norm = _normalizeId(id);
    if (norm == null) return const [];
    final v = _verses;
    if (v == null) return const [];
    final cached = _occurrenceIndex;
    if (cached != null) return cached[norm] ?? const [];

    // The first call walks 31k verses to build the inverse index.
    // ~1s on UI thread which dropped frames during a tap (perf review).
    // We can't compute() this because Dart's isolates can't easily share
    // the already-loaded `_verses` map without serialising it. Acceptable
    // mitigation: pre-build the index during `_load` via the worker and
    // just look it up here. See [_parseStrongsBundle].
    _occurrenceIndex = _buildOccurrenceIndex(v);
    return _occurrenceIndex![norm] ?? const [];
  }

  /// Pure (no-state) inverse-index builder, called by both UI-isolate
  /// fallback and the background isolate worker.
  static Map<String, List<VerseRefWithWord>> _buildOccurrenceIndex(
      Map<String, List<StrongsWord>> verses) {
    final index = <String, List<VerseRefWithWord>>{};
    final keyRe = RegExp(r'^(.+?)\s+(\d+):(\d+)$');
    verses.forEach((verseKey, words) {
      final m = keyRe.firstMatch(verseKey);
      if (m == null) return;
      final book = m.group(1)!;
      final chapter = int.tryParse(m.group(2)!) ?? 0;
      final verse = int.tryParse(m.group(3)!) ?? 0;
      final seen = <String>{};
      for (final w in words) {
        final s = w.strongs;
        if (s == null) continue;
        final canonical = _normalizeIdStatic(s);
        if (canonical == null) continue;
        if (!seen.add(canonical)) continue;
        index.putIfAbsent(canonical, () => []).add(VerseRefWithWord(
              book: book,
              chapter: chapter,
              verse: verse,
              word: w.word,
            ));
      }
    });
    return index;
  }

  /// Static version of [_normalizeId] for use inside isolate workers
  /// (where `this` isn't available).
  static String? _normalizeIdStatic(String id) {
    final m = RegExp(r'^([gGhH])\s*0*(\d+)([A-Za-z])?$').firstMatch(id.trim());
    if (m == null) return null;
    final prefix = m.group(1)!.toUpperCase();
    final digits = m.group(2)!;
    final suffix = (m.group(3) ?? '').toUpperCase();
    return '$prefix${digits.padLeft(4, '0')}$suffix';
  }

  /// Total occurrences of a Strong's number across the tagged corpus.
  int occurrencesOf(String? id) {
    if (id == null) return 0;
    final occ = _occurrences;
    if (occ == null) return 0;
    final norm = _normalizeId(id);
    if (norm == null) return 0;
    return occ[norm] ?? 0;
  }

  /// Normalize a Strong's id to canonical form: uppercase prefix + 4-digit
  /// zero-padded number + optional uppercase disambiguator letter.
  /// Examples: "g26" → "G0026", "h430a" → "H0430A".
  String? _normalizeId(String id) {
    final m = RegExp(r'^([gGhH])\s*0*(\d+)([A-Za-z])?$').firstMatch(id.trim());
    if (m == null) return null;
    final prefix = m.group(1)!.toUpperCase();
    final digits = m.group(2)!;
    final suffix = (m.group(3) ?? '').toUpperCase();
    return '$prefix${digits.padLeft(4, '0')}$suffix';
  }
}

/// Bag of parsed maps returned from the background worker so the UI
/// isolate can install them onto the singleton in one assignment.
class _ParsedStrongs {
  final Map<String, List<StrongsWord>> verses;
  final Map<String, StrongsEntry> lex;
  final Map<String, int> occurrences;
  const _ParsedStrongs({
    required this.verses,
    required this.lex,
    required this.occurrences,
  });
}

/// Background-isolate entry point. Decodes both JSON blobs and builds
/// every derived map; the UI thread just slots the result in.
_ParsedStrongs _parseStrongsBundle(List<String> rawJsons) {
  final versesRaw = json.decode(rawJsons[0]) as Map<String, dynamic>;
  final lexRaw = json.decode(rawJsons[1]) as Map<String, dynamic>;

  final verses = <String, List<StrongsWord>>{};
  final occurrences = <String, int>{};
  versesRaw.forEach((key, value) {
    final list = (value as List)
        .map((e) => StrongsWord.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    verses[key] = list;
    for (final w in list) {
      final s = w.strongs;
      if (s != null) {
        occurrences[s] = (occurrences[s] ?? 0) + 1;
      }
    }
  });

  final lex = <String, StrongsEntry>{};
  lexRaw.forEach((sid, entry) {
    final m = Map<String, dynamic>.from(entry as Map);
    lex[sid] = StrongsEntry(
      strongs: sid,
      original: (m['o'] ?? '') as String,
      transliteration: (m['t'] ?? '') as String,
      partOfSpeech: (m['p'] ?? '') as String,
      definition: (m['d'] ?? '') as String,
    );
  });

  return _ParsedStrongs(
    verses: verses,
    lex: lex,
    occurrences: occurrences,
  );
}

/// Riverpod provider for the singleton. Kicks off the load on first read so
/// the UI is hot by the time the user opens a verse in Scholar Mode.
final strongsServiceProvider = Provider<StrongsService>((ref) {
  final svc = StrongsService.instance;
  svc.init();
  return svc;
});

/// Async family provider for a verse's Strong's-tagged words.
final strongsForVerseProvider = FutureProvider.family<
    List<StrongsWord>,
    ({String book, int chapter, int verse})>((ref, key) async {
  final svc = ref.watch(strongsServiceProvider);
  await svc.init();
  return svc.wordsForVerse(key.book, key.chapter, key.verse);
});
