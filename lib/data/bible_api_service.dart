import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Fetches Bible data from the HelloAO Bible API.
/// API docs: https://bible.helloao.org/docs/
class BibleApiService {
  static const _baseUrl = 'https://bible.helloao.org/api';

  // In-memory cache: "$translationId|$bookCode|$chapter" -> Chapter
  final Map<String, List<Chapter>> _chapterCache = {};

  // Book-code cache: "$translationId" -> List of book codes
  final Map<String, List<_ApiBookInfo>> _bookListCache = {};

  /// Map app book names to API 3-letter codes.
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

  /// Fetch the list of books for a translation (to get chapter counts).
  Future<List<_ApiBookInfo>> _fetchBookList(String translationId) async {
    if (_bookListCache.containsKey(translationId)) {
      return _bookListCache[translationId]!;
    }

    final url = '$_baseUrl/$translationId/books.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final List<dynamic> books = data['books'] ?? [];
      final result = books.map((b) => _ApiBookInfo(
            id: b['id'] ?? '',
            name: b['name'] ?? '',
            chapters: (b['chapters'] as List?)?.length ?? 0,
          )).toList();

      _bookListCache[translationId] = result;
      return result;
    } catch (e) {
      debugPrint('Failed to fetch book list for $translationId: $e');
      return [];
    }
  }

  /// Load a full book from the API, chapter by chapter.
  Future<List<Chapter>> loadBook(
      String bookName, String translationId) async {
    final cacheKey = '$translationId|$bookName';
    if (_chapterCache.containsKey(cacheKey)) {
      return _chapterCache[cacheKey]!;
    }

    final bookCode = bookNameToCode[bookName];
    if (bookCode == null) {
      debugPrint('Unknown book name: $bookName');
      return [];
    }

    // First get the book list to know how many chapters
    final bookList = await _fetchBookList(translationId);
    final bookInfo = bookList.where((b) => b.id == bookCode).firstOrNull;

    // If we can't get chapter count from book list, try fetching chapter 1
    // and use the response to discover total chapters
    int totalChapters = bookInfo?.chapters ?? 0;

    if (totalChapters == 0) {
      // Try to load chapter 1 and see what we get
      final firstChapter = await _fetchChapter(translationId, bookCode, 1);
      if (firstChapter == null) return [];
      // We'll load chapters one by one until we get an error
      final chapters = <Chapter>[firstChapter];
      for (int c = 2; c <= 150; c++) {
        // Psalms has 150 chapters
        final ch = await _fetchChapter(translationId, bookCode, c);
        if (ch == null) break;
        chapters.add(ch);
      }
      _chapterCache[cacheKey] = chapters;
      return chapters;
    }

    // Fetch all chapters in parallel (batched)
    final chapters = <Chapter>[];
    const batchSize = 10;
    for (int start = 1; start <= totalChapters; start += batchSize) {
      final end =
          (start + batchSize - 1).clamp(start, totalChapters);
      final futures = <Future<Chapter?>>[];
      for (int c = start; c <= end; c++) {
        futures.add(_fetchChapter(translationId, bookCode, c));
      }
      final results = await Future.wait(futures);
      for (final ch in results) {
        if (ch != null) chapters.add(ch);
      }
    }

    _chapterCache[cacheKey] = chapters;
    return chapters;
  }

  /// Fetch a single chapter from the API.
  Future<Chapter?> _fetchChapter(
      String translationId, String bookCode, int chapterNum) async {
    final url = '$_baseUrl/$translationId/$bookCode/$chapterNum.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final chapter = data['chapter'];
      if (chapter == null) return null;

      final number = chapter['number'] as int? ?? chapterNum;
      final List<dynamic> content = chapter['content'] ?? [];

      final verses = <Verse>[];
      for (final item in content) {
        if (item is! Map) continue;
        if (item['type'] != 'verse') continue;

        final verseNum = item['number'] as int? ?? 0;
        if (verseNum == 0) continue;

        final List<dynamic> contentParts = item['content'] ?? [];
        final textBuffer = StringBuffer();
        for (final part in contentParts) {
          if (part is String) {
            if (textBuffer.isNotEmpty) textBuffer.write(' ');
            textBuffer.write(part);
          } else if (part is Map) {
            // Handle formatted text (poetry, etc.)
            final text = part['text'];
            if (text is String) {
              if (textBuffer.isNotEmpty) textBuffer.write(' ');
              textBuffer.write(text);
            }
            // Skip noteId references, lineBreaks, etc.
          }
        }

        final verseText = textBuffer.toString().trim();
        if (verseText.isNotEmpty) {
          verses.add(Verse(verseNum, verseText));
        }
      }

      if (verses.isEmpty) return null;
      return Chapter(number, verses);
    } catch (e) {
      debugPrint('Failed to fetch $bookCode $chapterNum: $e');
      return null;
    }
  }

  /// Check if a translation is available on the API.
  Future<bool> isAvailable(String translationId) async {
    try {
      final url = '$_baseUrl/$translationId/books.json';
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void clearCache([String? translationId]) {
    if (translationId == null) {
      _chapterCache.clear();
      _bookListCache.clear();
    } else {
      _chapterCache
          .removeWhere((key, _) => key.startsWith('$translationId|'));
      _bookListCache.remove(translationId);
    }
  }
}

class _ApiBookInfo {
  final String id;
  final String name;
  final int chapters;
  const _ApiBookInfo(
      {required this.id, required this.name, required this.chapters});
}
