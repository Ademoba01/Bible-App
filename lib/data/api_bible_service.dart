import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Fetches Bible data from the API.Bible service (https://rest.api.bible).
///
/// This service handles translations not available on HelloAO, including
/// Yoruba, Hausa, and Igbo contemporary Bibles from Biblica.
class ApiBibleService {
  static const _baseUrl = 'https://rest.api.bible/v1';
  static const _apiKey = 'L0hjuQeEIoiX86XUhPppC';

  /// Maps our internal translation IDs to API.Bible bible IDs.
  static const translationToBibleId = <String, String>{
    'OYCB': 'b8d1feac6e94bd74-01',  // Yoruba Contemporary Bible
    'OHCB': '0ab0c764d56a715d-02',  // Hausa Contemporary Bible
    'OICB': 'a36fc06b086699f1-02',  // Igbo Contemporary Bible
  };

  /// Map app book names to API.Bible 3-letter book codes.
  static const bookNameToCode = <String, String>{
    'Genesis': 'GEN',
    'Exodus': 'EXO',
    'Leviticus': 'LEV',
    'Numbers': 'NUM',
    'Deuteronomy': 'DEU',
    'Joshua': 'JOS',
    'Judges': 'JDG',
    'Ruth': 'RUT',
    '1 Samuel': '1SA',
    '2 Samuel': '2SA',
    '1 Kings': '1KI',
    '2 Kings': '2KI',
    '1 Chronicles': '1CH',
    '2 Chronicles': '2CH',
    'Ezra': 'EZR',
    'Nehemiah': 'NEH',
    'Esther': 'EST',
    'Job': 'JOB',
    'Psalms': 'PSA',
    'Proverbs': 'PRO',
    'Ecclesiastes': 'ECC',
    'Song of Solomon': 'SNG',
    'Isaiah': 'ISA',
    'Jeremiah': 'JER',
    'Lamentations': 'LAM',
    'Ezekiel': 'EZK',
    'Daniel': 'DAN',
    'Hosea': 'HOS',
    'Joel': 'JOL',
    'Amos': 'AMO',
    'Obadiah': 'OBA',
    'Jonah': 'JON',
    'Micah': 'MIC',
    'Nahum': 'NAM',
    'Habakkuk': 'HAB',
    'Zephaniah': 'ZEP',
    'Haggai': 'HAG',
    'Zechariah': 'ZEC',
    'Malachi': 'MAL',
    'Matthew': 'MAT',
    'Mark': 'MRK',
    'Luke': 'LUK',
    'John': 'JHN',
    'Acts': 'ACT',
    'Romans': 'ROM',
    '1 Corinthians': '1CO',
    '2 Corinthians': '2CO',
    'Galatians': 'GAL',
    'Ephesians': 'EPH',
    'Philippians': 'PHP',
    'Colossians': 'COL',
    '1 Thessalonians': '1TH',
    '2 Thessalonians': '2TH',
    '1 Timothy': '1TI',
    '2 Timothy': '2TI',
    'Titus': 'TIT',
    'Philemon': 'PHM',
    'Hebrews': 'HEB',
    'James': 'JAS',
    '1 Peter': '1PE',
    '2 Peter': '2PE',
    '1 John': '1JN',
    '2 John': '2JN',
    '3 John': '3JN',
    'Jude': 'JUD',
    'Revelation': 'REV',
  };

  // In-memory cache: "$translationId|$bookName" -> List<Chapter>
  final Map<String, List<Chapter>> _cache = {};

  // Chapter count cache: "$bibleId|$bookCode" -> chapter count
  final Map<String, int> _chapterCountCache = {};

  /// Returns true if this service handles the given translation.
  static bool handles(String translationId) =>
      translationToBibleId.containsKey(translationId);

  /// Clears cached data.
  void clearCache([String? translationId]) {
    if (translationId == null) {
      _cache.clear();
      _chapterCountCache.clear();
    } else {
      _cache.removeWhere((key, _) => key.startsWith('$translationId|'));
    }
  }

  /// Check if API.Bible is reachable for this translation.
  Future<bool> isAvailable(String translationId) async {
    final bibleId = translationToBibleId[translationId];
    if (bibleId == null) return false;
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/bibles/$bibleId'),
        headers: {'api-key': _apiKey},
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Load an entire book (all chapters) for a given translation.
  Future<List<Chapter>> loadBook(String bookName, String translationId) async {
    final cacheKey = '$translationId|$bookName';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final bibleId = translationToBibleId[translationId];
    final bookCode = bookNameToCode[bookName];
    if (bibleId == null || bookCode == null) return [];

    // First, get the list of chapters for this book
    final chapterCount = await _getChapterCount(bibleId, bookCode);
    if (chapterCount == 0) return [];

    // Fetch all chapters in batches of 5 (API.Bible rate limits)
    final chapters = <Chapter>[];
    const batchSize = 5;

    for (var i = 1; i <= chapterCount; i += batchSize) {
      final futures = <Future<Chapter?>>[];
      for (var ch = i; ch < i + batchSize && ch <= chapterCount; ch++) {
        futures.add(_fetchChapter(bibleId, bookCode, ch));
      }
      final results = await Future.wait(futures);
      for (final ch in results) {
        if (ch != null) chapters.add(ch);
      }
    }

    // Sort by chapter number
    chapters.sort((a, b) => a.number.compareTo(b.number));

    if (chapters.isNotEmpty) {
      _cache[cacheKey] = chapters;
    }
    return chapters;
  }

  /// Get the number of chapters in a book.
  Future<int> _getChapterCount(String bibleId, String bookCode) async {
    final cacheKey = '$bibleId|$bookCode';
    if (_chapterCountCache.containsKey(cacheKey)) {
      return _chapterCountCache[cacheKey]!;
    }

    try {
      final url = '$_baseUrl/bibles/$bibleId/books/$bookCode/chapters';
      final resp = await http.get(
        Uri.parse(url),
        headers: {'api-key': _apiKey},
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) return 0;

      final data = json.decode(resp.body);
      final chaptersData = data['data'] as List;

      // Filter out intro chapters (e.g., "GEN.intro")
      final chapterIds = chaptersData
          .map((c) => c['id'] as String)
          .where((id) => !id.contains('intro'))
          .toList();

      _chapterCountCache[cacheKey] = chapterIds.length;
      return chapterIds.length;
    } catch (e) {
      debugPrint('API.Bible chapter count failed for $bookCode: $e');
      return 0;
    }
  }

  /// Fetch a single chapter's content and parse into our Chapter model.
  Future<Chapter?> _fetchChapter(
      String bibleId, String bookCode, int chapterNum) async {
    try {
      final chapterId = '$bookCode.$chapterNum';
      final url =
          '$_baseUrl/bibles/$bibleId/chapters/$chapterId?content-type=text&include-verse-numbers=true';

      final resp = await http.get(
        Uri.parse(url),
        headers: {'api-key': _apiKey},
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        debugPrint('API.Bible fetch failed ($chapterId): ${resp.statusCode}');
        return null;
      }

      final data = json.decode(resp.body);
      final chapterData = data['data'];
      final content = chapterData['content'] as String? ?? '';
      final verseCount = chapterData['verseCount'] as int? ?? 0;

      if (content.isEmpty) return null;

      // Parse the text content — verses are marked with [1], [2], etc.
      final verses = _parseVerses(content, verseCount);

      if (verses.isEmpty) return null;

      return Chapter(chapterNum, verses);
    } catch (e) {
      debugPrint('API.Bible chapter fetch error ($bookCode.$chapterNum): $e');
      return null;
    }
  }

  /// Parse API.Bible plain text content into individual verses.
  ///
  /// API.Bible text format uses [1], [2], etc. for verse markers:
  ///   "[1] In the beginning... [2] And the earth was..."
  List<Verse> _parseVerses(String content, int expectedCount) {
    final verses = <Verse>[];

    // Match verse patterns: [number] followed by text
    final pattern = RegExp(r'\[(\d+)\]\s*');
    final matches = pattern.allMatches(content).toList();

    for (var i = 0; i < matches.length; i++) {
      final verseNum = int.parse(matches[i].group(1)!);
      final startIndex = matches[i].end;
      final endIndex =
          i + 1 < matches.length ? matches[i + 1].start : content.length;

      var verseText = content.substring(startIndex, endIndex).trim();

      // Clean up: remove extra whitespace, section headings, etc.
      verseText = verseText
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^\s+|\s+$'), '')
          .trim();

      if (verseText.isNotEmpty) {
        verses.add(Verse(verseNum, verseText));
      }
    }

    return verses;
  }
}
