import 'dart:convert';
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
    } catch (_) {
      // Fall back to WEB if a translation is selected but missing this book.
      if (translationId != 'web') {
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
      grouped[cn]!.putIfAbsent(vn, () => StringBuffer());
      final buf = grouped[cn]![vn]!;
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
}
