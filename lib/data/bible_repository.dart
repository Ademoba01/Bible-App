import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'books.dart';
import 'models.dart';

/// Loads and parses Bible JSON assets, scoped per translation.
///
/// Asset layout: `assets/bibles/<translationId>/<bookFile>.json`
/// Each file is a flat array of objects:
///   { "type": "paragraph text", "chapterNumber": 1, "verseNumber": 1,
///     "value": "..." }
/// Multiple text fragments sharing the same verseNumber are concatenated.
class BibleRepository {
  // cache key: "$translationId|$bookName"
  final Map<String, List<Chapter>> _cache = {};

  List<BookInfo> get books => kAllBooks;

  String _key(String translationId, String book) => '$translationId|$book';

  /// Clears cached data for a translation (or all if null).
  void clearCache([String? translationId]) {
    if (translationId == null) {
      _cache.clear();
    } else {
      _cache.removeWhere((key, _) => key.startsWith('$translationId|'));
    }
  }

  /// Returns true if assets exist for this translation (heuristically: tries
  /// to load John, the smallest non-trivial book that's always present).
  Future<bool> isTranslationAvailable(String translationId) async {
    try {
      await rootBundle.loadString('assets/bibles/$translationId/john.json');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Chapter>> loadBook(String bookName, {String translationId = 'web'}) async {
    final key = _key(translationId, bookName);
    if (_cache.containsKey(key)) return _cache[key]!;

    final info = bookByName(bookName);
    final path = 'assets/bibles/$translationId/${info.file}.json';
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (e) {
      // Fall back to WEB if a translation is selected but missing this book.
      if (translationId != 'web') {
        debugPrint('Translation $translationId not found for $bookName, falling back to WEB');
        return loadBook(bookName, translationId: 'web');
      }
      rethrow;
    }

    final List<dynamic> items = json.decode(raw) as List<dynamic>;

    final Map<int, Map<int, StringBuffer>> grouped = {};
    for (final item in items) {
      if (item is! Map) continue;
      final cn = item['chapterNumber'];
      final vn = item['verseNumber'];
      final value = item['value'];
      if (cn is! int || vn is! int || value is! String) continue;
      grouped.putIfAbsent(cn, () => {});
      final chapterMap = grouped[cn]!;
      chapterMap.putIfAbsent(vn, () => StringBuffer());
      final buf = chapterMap[vn]!;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(value.trim());
    }

    final chapterNums = grouped.keys.toList()..sort();
    final chapters = <Chapter>[];
    for (final cn in chapterNums) {
      final verseMap = grouped[cn]!;
      final verseNums = verseMap.keys.toList()..sort();
      chapters.add(Chapter(cn, [
        for (final vn in verseNums) Verse(vn, verseMap[vn]!.toString().trim()),
      ]));
    }

    _cache[key] = chapters;
    return chapters;
  }

  /// Global search across all books for a given translation.
  Future<List<({VerseRef ref, String text})>> search(
    String query, {
    String translationId = 'web',
    int limit = 200,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <({VerseRef ref, String text})>[];
    for (final b in kAllBooks) {
      if (results.length >= limit) break;
      final chapters = await loadBook(b.name, translationId: translationId);
      for (final c in chapters) {
        for (final v in c.verses) {
          if (v.text.toLowerCase().contains(q)) {
            results.add((ref: VerseRef(b.name, c.number, v.number), text: v.text));
            if (results.length >= limit) return results;
          }
        }
      }
    }
    return results;
  }

  // ─── Semantic similarity engine ───────────────────────────────────────

  /// Common English stop words to ignore during similarity scoring.
  static final _stopWords = <String>{
    'the', 'and', 'of', 'to', 'in', 'a', 'that', 'is', 'was', 'he', 'for',
    'it', 'with', 'his', 'as', 'i', 'had', 'not', 'are', 'but', 'be', 'they',
    'have', 'him', 'one', 'our', 'do', 'this', 'from', 'or', 'an', 'my', 'by',
    'we', 'she', 'them', 'her', 'all', 'were', 'which', 'will', 'there',
    'their', 'been', 'has', 'who', 'shall', 'me', 'when', 'what', 'so',
    'no', 'if', 'out', 'up', 'than', 'then', 'into', 'did', 'you', 'your',
    'upon', 'may', 'its', 'also', 'am', 'on', 'at', 'said', 'say', 'says',
    'those', 'these', 'about', 'would', 'could', 'should', 'how', 'can',
    'unto', 'thee', 'thou', 'thy', 'ye', 'hath', 'doth', 'thereof',
  };

  /// Biblical theme keywords — weighted higher for topical similarity.
  static final _themeKeywords = <String, double>{
    // Core theological
    'god': 2.0, 'lord': 2.0, 'jesus': 2.5, 'christ': 2.5, 'spirit': 2.0,
    'holy': 1.8, 'father': 1.5, 'son': 1.5,
    // Salvation / grace
    'faith': 2.5, 'grace': 2.5, 'salvation': 2.5, 'saved': 2.0, 'save': 2.0,
    'redeem': 2.5, 'redeemed': 2.5, 'forgive': 2.0, 'forgiveness': 2.0,
    'mercy': 2.0, 'justified': 2.0, 'righteous': 2.0, 'righteousness': 2.0,
    // Love / fruit
    'love': 2.5, 'loved': 2.0, 'loves': 2.0, 'joy': 2.0, 'peace': 2.0,
    'hope': 2.0, 'patient': 1.5, 'patience': 1.5, 'kindness': 1.5,
    // Power / kingdom
    'kingdom': 2.0, 'heaven': 2.0, 'eternal': 2.0, 'everlasting': 2.0,
    'power': 1.5, 'glory': 1.8, 'mighty': 1.5, 'strength': 1.5,
    // Sin / judgment
    'sin': 2.0, 'sinned': 2.0, 'death': 1.8, 'judgment': 1.8, 'wrath': 1.5,
    'evil': 1.5, 'wicked': 1.5, 'iniquity': 1.8,
    // Prayer / worship
    'prayer': 2.0, 'pray': 2.0, 'worship': 2.0, 'praise': 2.0,
    'blessing': 1.8, 'blessed': 1.8, 'bless': 1.5,
    // Covenant / promise
    'covenant': 2.0, 'promise': 2.0, 'promised': 2.0, 'commandment': 1.8,
    'law': 1.5, 'word': 1.5, 'truth': 2.0,
    // Life / light
    'life': 2.0, 'light': 1.8, 'darkness': 1.8, 'bread': 1.5, 'water': 1.3,
    'blood': 1.8, 'lamb': 2.0, 'cross': 2.0, 'resurrection': 2.5,
    // People / relationship
    'children': 1.3, 'people': 1.3, 'israel': 1.5, 'church': 1.8,
    'disciples': 1.5, 'apostle': 1.5, 'prophet': 1.5,
  };

  /// Extracts significant keywords from text, lowercased and cleaned.
  Set<String> _extractKeywords(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();
    return words;
  }

  /// Scores similarity between two sets of keywords.
  double _scoreSimilarity(Set<String> sourceWords, Set<String> candidateWords) {
    if (sourceWords.isEmpty || candidateWords.isEmpty) return 0;

    double score = 0;
    int matches = 0;

    for (final word in sourceWords) {
      if (candidateWords.contains(word)) {
        matches++;
        // Apply theme weighting
        score += _themeKeywords[word] ?? 1.0;
      }
    }

    if (matches == 0) return 0;

    // Normalize: reward overlap ratio but also raw match count
    final overlapRatio = matches / sourceWords.length;
    return score * (0.5 + 0.5 * overlapRatio);
  }

  /// Finds verses similar to [verseText] across the entire Bible.
  ///
  /// Excludes the source verse ([sourceRef]) from results.
  /// Returns up to [limit] results sorted by similarity score (highest first).
  Future<List<({VerseRef ref, String text, double score})>> findSimilar(
    String verseText, {
    VerseRef? sourceRef,
    String translationId = 'web',
    int limit = 20,
  }) async {
    final sourceKeywords = _extractKeywords(verseText);
    if (sourceKeywords.length < 2) {
      // Too few meaningful words — fall back to simple word search
      final longestWord = sourceKeywords.isEmpty
          ? ''
          : (sourceKeywords.toList()..sort((a, b) => b.length.compareTo(a.length))).first;
      if (longestWord.isEmpty) return const [];
      final simple = await search(longestWord, translationId: translationId, limit: limit);
      return simple
          .where((r) => sourceRef == null || r.ref.id != sourceRef.id)
          .map((r) => (ref: r.ref, text: r.text, score: 1.0))
          .toList();
    }

    final results = <({VerseRef ref, String text, double score})>[];

    for (final b in kAllBooks) {
      final chapters = await loadBook(b.name, translationId: translationId);
      for (final c in chapters) {
        for (final v in c.verses) {
          final vRef = VerseRef(b.name, c.number, v.number);
          // Skip the source verse itself
          if (sourceRef != null && vRef.id == sourceRef.id) continue;

          final candidateKeywords = _extractKeywords(v.text);
          final score = _scoreSimilarity(sourceKeywords, candidateKeywords);

          if (score > 1.5) {
            // Only include meaningfully similar verses
            results.add((ref: vRef, text: v.text, score: score));
          }
        }
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(limit).toList();
  }
}
