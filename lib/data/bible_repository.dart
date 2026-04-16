import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'api_bible_service.dart';
import 'bible_api_service.dart';
import 'books.dart';
import 'models.dart';
import 'translations.dart';

/// Loads and parses Bible data from local assets, HelloAO API, or API.Bible.
///
/// Local asset layout: `assets/bibles/<translationId>/<bookFile>.json`
/// Each file is a flat array of objects:
///   { "type": "paragraph text", "chapterNumber": 1, "verseNumber": 1,
///     "value": "..." }
/// Multiple text fragments sharing the same verseNumber are concatenated.
///
/// Online translations are fetched from:
///   - HelloAO: https://bible.helloao.org/api/
///   - API.Bible: https://rest.api.bible/v1/ (Yoruba, Hausa, Igbo)
class BibleRepository {
  // cache key: "$translationId|$bookName"
  final Map<String, List<Chapter>> _cache = {};

  final BibleApiService _apiService = BibleApiService();
  final ApiBibleService _apiBibleService = ApiBibleService();

  List<BookInfo> get books => kAllBooks;

  String _key(String translationId, String book) => '$translationId|$book';

  /// Clears cached data for a translation (or all if null).
  void clearCache([String? translationId]) {
    if (translationId == null) {
      _cache.clear();
      _apiService.clearCache();
      _apiBibleService.clearCache();
    } else {
      _cache.removeWhere((key, _) => key.startsWith('$translationId|'));
      _apiService.clearCache(translationId);
      _apiBibleService.clearCache(translationId);
    }
  }

  /// Returns true if assets exist for this translation (heuristically: tries
  /// to load John, the smallest non-trivial book that's always present).
  Future<bool> isTranslationAvailable(String translationId) async {
    // Check if it's a local translation first
    final translation = kTranslations.where((t) => t.id == translationId).firstOrNull;
    if (translation != null && translation.isLocal) {
      try {
        await rootBundle.loadString('assets/bibles/$translationId/john.json');
        return true;
      } catch (_) {
        return false;
      }
    }
    // Online translations are always "available" if in the registry
    return translation?.available ?? false;
  }

  /// Check if translation loads from local assets.
  bool _isLocalTranslation(String translationId) {
    final translation = kTranslations.where((t) => t.id == translationId).firstOrNull;
    return translation?.isLocal ?? false;
  }

  Future<List<Chapter>> loadBook(String bookName, {String translationId = 'web'}) async {
    final key = _key(translationId, bookName);
    if (_cache.containsKey(key)) return _cache[key]!;

    // Try local assets first for local translations
    if (_isLocalTranslation(translationId)) {
      return _loadLocalBook(bookName, translationId: translationId);
    }

    // Route to the correct API service
    try {
      final List<Chapter> chapters;
      if (ApiBibleService.handles(translationId)) {
        chapters = await _apiBibleService.loadBook(bookName, translationId);
      } else {
        chapters = await _apiService.loadBook(bookName, translationId);
      }
      if (chapters.isNotEmpty) {
        _cache[key] = chapters;
        return chapters;
      }
    } catch (e) {
      debugPrint('API load failed for $translationId/$bookName: $e');
    }

    // Fall back to WEB if API fails
    if (translationId != 'web') {
      debugPrint('Falling back to WEB for $bookName');
      return loadBook(bookName, translationId: 'web');
    }
    return [];
  }

  Future<List<Chapter>> _loadLocalBook(String bookName, {String translationId = 'web'}) async {
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
        return _loadLocalBook(bookName, translationId: 'web');
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

  // ── Synonym map for smart search ────────────────────────────────
  static const _synonyms = <String, List<String>>{
    'fornication': ['sexual immorality', 'sexually immoral', 'immorality', 'harlot', 'whoredom', 'adultery', 'unchastity'],
    'sexual immorality': ['fornication', 'sexually immoral', 'immorality', 'harlot', 'whoredom'],
    'hell': ['hades', 'sheol', 'gehenna', 'lake of fire', 'pit', 'abyss', 'eternal fire'],
    'heaven': ['kingdom of god', 'kingdom of heaven', 'paradise', 'eternal life', 'new jerusalem'],
    'love': ['charity', 'lovingkindness', 'loving-kindness', 'compassion', 'mercy', 'kindness'],
    'charity': ['love', 'lovingkindness'],
    'holy spirit': ['holy ghost', 'spirit of god', 'spirit of the lord', 'comforter', 'helper'],
    'holy ghost': ['holy spirit', 'spirit of god', 'spirit of the lord', 'comforter'],
    'demon': ['devil', 'unclean spirit', 'evil spirit', 'satan', 'fallen angel'],
    'devil': ['satan', 'serpent', 'dragon', 'tempter', 'adversary', 'lucifer', 'demon'],
    'satan': ['devil', 'serpent', 'adversary', 'tempter', 'dragon', 'lucifer'],
    'faith': ['believe', 'trust', 'confidence', 'assurance'],
    'grace': ['mercy', 'favor', 'favour', 'unmerited favor', 'kindness'],
    'sin': ['transgression', 'iniquity', 'trespass', 'wickedness', 'unrighteousness'],
    'transgression': ['sin', 'iniquity', 'trespass', 'offense'],
    'righteous': ['just', 'upright', 'blameless', 'godly', 'holy'],
    'wrath': ['anger', 'fury', 'indignation', 'vengeance', 'judgment'],
    'salvation': ['saved', 'redemption', 'deliverance', 'rescue'],
    'pray': ['prayer', 'supplication', 'intercession', 'petition', 'cry out'],
    'baptism': ['baptize', 'baptized', 'baptise', 'immerse', 'washing'],
    'rapture': ['caught up', 'taken up', 'meet the lord in the air', 'gathering together'],
    'tithe': ['tithes', 'tenth', 'offering', 'firstfruits', 'first fruits'],
    'worship': ['praise', 'adore', 'glorify', 'bow down', 'magnify'],
    'miracle': ['sign', 'wonder', 'mighty work', 'power'],
    'angel': ['messenger', 'heavenly host', 'seraphim', 'cherubim'],
    'prophet': ['seer', 'man of god', 'prophesy', 'prophecy'],
    'covenant': ['promise', 'testament', 'oath', 'agreement'],
    'repent': ['repentance', 'turn from', 'turn away', 'confess'],
    'blessed': ['happy', 'fortunate', 'favored', 'favoured'],
    'resurrection': ['raised from the dead', 'rise again', 'risen'],
  };

  // ── Topic-to-verse map for thematic/concept searches ──────────
  static const _topicVerses = <String, List<String>>{
    'honesty': ['Proverbs 12:22', 'Proverbs 11:1', 'Colossians 3:9', 'Ephesians 4:25', 'Proverbs 6:16-17', 'Zechariah 8:16', 'Psalm 15:1-2', 'Leviticus 19:11', 'Luke 16:10', 'Proverbs 24:26'],
    'truth': ['John 8:32', 'John 14:6', 'Psalm 119:160', 'Proverbs 12:19', '3 John 1:4', 'John 17:17', 'Ephesians 4:15', 'Zechariah 8:16'],
    'integrity': ['Proverbs 10:9', 'Proverbs 11:3', 'Psalm 25:21', 'Proverbs 20:7', 'Job 2:3', 'Titus 2:7', 'Psalm 26:1', 'Luke 16:10'],
    'patience': ['James 1:3-4', 'Romans 12:12', 'Galatians 6:9', 'Psalm 27:14', 'Isaiah 40:31', 'Hebrews 10:36', 'Ecclesiastes 7:8', 'Colossians 1:11', 'Romans 8:25', '2 Peter 3:9'],
    'forgiveness': ['Matthew 6:14-15', 'Ephesians 4:32', 'Colossians 3:13', 'Mark 11:25', 'Luke 6:37', 'Matthew 18:21-22', 'Psalm 103:12', 'Isaiah 1:18', '1 John 1:9', 'Acts 3:19'],
    'courage': ['Joshua 1:9', 'Deuteronomy 31:6', 'Isaiah 41:10', 'Psalm 27:1', '2 Timothy 1:7', 'Psalm 31:24', 'Isaiah 43:1', '1 Corinthians 16:13', 'Psalm 56:3-4'],
    'strength': ['Philippians 4:13', 'Isaiah 40:31', 'Psalm 46:1', 'Nehemiah 8:10', '2 Corinthians 12:9-10', 'Psalm 73:26', 'Ephesians 6:10', 'Psalm 18:32'],
    'wisdom': ['James 1:5', 'Proverbs 4:7', 'Proverbs 9:10', 'Proverbs 2:6', 'Ecclesiastes 7:12', 'Colossians 2:3', 'Proverbs 16:16', 'Psalm 111:10'],
    'humility': ['Philippians 2:3', 'James 4:10', '1 Peter 5:6', 'Proverbs 22:4', 'Micah 6:8', 'Matthew 23:12', 'Proverbs 11:2', 'Colossians 3:12'],
    'joy': ['Nehemiah 8:10', 'Psalm 16:11', 'John 15:11', 'Romans 15:13', 'Philippians 4:4', 'Galatians 5:22', 'Psalm 30:5', 'James 1:2', 'Habakkuk 3:18'],
    'peace': ['Philippians 4:6-7', 'John 14:27', 'Isaiah 26:3', 'Romans 8:6', 'Psalm 29:11', 'Colossians 3:15', 'Romans 12:18', 'Matthew 5:9', 'Psalm 4:8'],
    'hope': ['Romans 15:13', 'Jeremiah 29:11', 'Hebrews 11:1', 'Romans 8:28', 'Psalm 42:11', 'Lamentations 3:22-23', '1 Peter 1:3', 'Isaiah 40:31'],
    'kindness': ['Ephesians 4:32', 'Proverbs 11:17', 'Colossians 3:12', 'Galatians 5:22', 'Luke 6:35', 'Proverbs 19:17', 'Micah 6:8', 'Romans 2:4'],
    'faithfulness': ['Lamentations 3:22-23', 'Psalm 36:5', 'Proverbs 3:3-4', '1 Corinthians 1:9', '2 Timothy 2:13', 'Deuteronomy 7:9', 'Psalm 119:90'],
    'money': ['1 Timothy 6:10', 'Hebrews 13:5', 'Matthew 6:24', 'Proverbs 22:7', 'Ecclesiastes 5:10', 'Luke 12:15', 'Proverbs 13:11', 'Matthew 6:19-21'],
    'marriage': ['Genesis 2:24', 'Ephesians 5:25', 'Mark 10:9', 'Hebrews 13:4', 'Proverbs 18:22', '1 Corinthians 13:4-7', 'Colossians 3:19', 'Proverbs 31:10'],
    'anxiety': ['Philippians 4:6-7', 'Matthew 6:34', '1 Peter 5:7', 'Psalm 55:22', 'Isaiah 41:10', 'Psalm 94:19', 'Matthew 6:25-27', 'John 14:27'],
    'fear': ['2 Timothy 1:7', 'Psalm 23:4', 'Isaiah 41:10', 'Psalm 56:3', 'Romans 8:15', '1 John 4:18', 'Psalm 27:1', 'Deuteronomy 31:6'],
    'anger': ['Proverbs 15:1', 'James 1:19-20', 'Ephesians 4:26', 'Proverbs 29:11', 'Psalm 37:8', 'Colossians 3:8', 'Proverbs 14:29', 'Ecclesiastes 7:9'],
    'friendship': ['Proverbs 17:17', 'Proverbs 18:24', 'Ecclesiastes 4:9-10', 'John 15:13', 'Proverbs 27:17', 'Proverbs 27:9', 'Proverbs 22:24-25'],
    'pride': ['Proverbs 16:18', 'James 4:6', 'Proverbs 11:2', 'Proverbs 29:23', '1 John 2:16', 'Obadiah 1:3', 'Proverbs 8:13'],
    'suffering': ['Romans 5:3-4', 'James 1:2-4', '2 Corinthians 4:17', '1 Peter 4:12-13', 'Romans 8:18', 'Psalm 34:18', 'Isaiah 53:5'],
    'death': ['John 11:25-26', '1 Corinthians 15:55', 'Revelation 21:4', 'Psalm 23:4', 'Philippians 1:21', 'Romans 8:38-39', '2 Corinthians 5:8'],
    'temptation': ['1 Corinthians 10:13', 'James 1:13-14', 'Matthew 26:41', 'Hebrews 4:15', 'James 4:7', 'Ephesians 6:11', '1 Peter 5:8-9'],
    'obedience': ['John 14:15', 'Deuteronomy 5:33', '1 Samuel 15:22', 'James 1:22', 'Acts 5:29', 'Romans 6:16', 'John 15:14'],
    'generosity': ['2 Corinthians 9:7', 'Proverbs 11:25', 'Acts 20:35', 'Luke 6:38', 'Proverbs 22:9', '1 Timothy 6:18', 'Matthew 6:3-4'],
    'contentment': ['Philippians 4:11-12', '1 Timothy 6:6', 'Hebrews 13:5', 'Psalm 37:16', 'Proverbs 15:16', 'Matthew 6:25-26'],
    'gratitude': ['1 Thessalonians 5:18', 'Colossians 3:17', 'Psalm 100:4', 'Psalm 107:1', 'Ephesians 5:20', 'Philippians 4:6'],
    'loneliness': ['Psalm 25:16-17', 'Deuteronomy 31:8', 'Isaiah 41:10', 'Psalm 68:6', 'Matthew 28:20', 'Hebrews 13:5'],
    'justice': ['Micah 6:8', 'Isaiah 1:17', 'Proverbs 21:3', 'Amos 5:24', 'Psalm 89:14', 'Isaiah 61:8', 'Zechariah 7:9'],
    'jealousy': ['Proverbs 14:30', 'James 3:16', 'Galatians 5:26', 'Song of Solomon 8:6', '1 Corinthians 13:4', 'Proverbs 27:4'],
    'laziness': ['Proverbs 6:6', 'Proverbs 13:4', 'Proverbs 10:4', '2 Thessalonians 3:10', 'Proverbs 21:25', 'Colossians 3:23'],
    'gossip': ['Proverbs 16:28', 'Proverbs 11:13', 'Proverbs 20:19', 'James 1:26', 'Ephesians 4:29', 'Proverbs 26:20', 'Psalm 34:13'],
    'healing': ['Jeremiah 17:14', 'James 5:14-15', 'Psalm 103:3', 'Isaiah 53:5', '3 John 1:2', 'Psalm 30:2', 'Exodus 15:26'],
    'leadership': ['Proverbs 29:2', 'Mark 10:42-45', '1 Timothy 3:1-2', 'Joshua 1:9', 'Proverbs 11:14', 'Isaiah 40:11'],
    'children': ['Proverbs 22:6', 'Psalm 127:3', 'Mark 10:14', 'Ephesians 6:4', 'Deuteronomy 6:7', 'Proverbs 29:17', '3 John 1:4'],
    'virtue': ['Philippians 4:8', '2 Peter 1:5-7', 'Proverbs 31:10', 'Galatians 5:22-23', 'Colossians 3:12-14'],
  };

  /// Check if query matches a topic and return suggested verse references
  static List<String>? getTopicVerses(String query) {
    final lower = query.toLowerCase().trim();
    // Check for exact topic match
    if (_topicVerses.containsKey(lower)) return _topicVerses[lower];
    // Check if query words match a topic
    final words = lower.split(RegExp(r'\s+'));
    for (final word in words) {
      if (_topicVerses.containsKey(word)) return _topicVerses[word];
    }
    // Check if any topic is contained in the query
    for (final entry in _topicVerses.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Get expanded search terms (original + synonyms)
  List<String> _expandQuery(String query) {
    final q = query.toLowerCase().trim();
    final terms = <String>[q];
    // Check for exact synonym matches
    if (_synonyms.containsKey(q)) {
      terms.addAll(_synonyms[q]!);
    }
    // Check if query is part of any synonym group
    for (final entry in _synonyms.entries) {
      if (entry.value.any((syn) => syn == q) && !terms.contains(entry.key)) {
        terms.add(entry.key);
        terms.addAll(entry.value.where((s) => !terms.contains(s)));
      }
    }
    return terms.toSet().toList(); // deduplicate
  }

  /// Global search across all books for a given translation.
  /// Uses synonym expansion to find semantically related results.
  Future<List<({VerseRef ref, String text})>> search(
    String query, {
    String translationId = 'web',
    int limit = 200,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final searchTerms = _expandQuery(q);
    final exactResults = <({VerseRef ref, String text})>[];
    final synonymResults = <({VerseRef ref, String text})>[];

    // Search in the requested translation
    await _searchTranslation(translationId, q, searchTerms, exactResults, synonymResults, limit);

    // If searching WEB and few results, also search KJV (has older terms like "fornication")
    if (translationId == 'web' && exactResults.length + synonymResults.length < 10) {
      await _searchTranslation('kjv', q, searchTerms, exactResults, synonymResults, limit);
    }

    // If searching KJV and few results, also search WEB
    if (translationId == 'kjv' && exactResults.length + synonymResults.length < 10) {
      await _searchTranslation('web', q, searchTerms, exactResults, synonymResults, limit);
    }

    // Combine: exact matches first, then synonym matches (no duplicates)
    final combined = <({VerseRef ref, String text})>[];
    final seenIds = <String>{};
    for (final r in exactResults) {
      if (seenIds.add(r.ref.id)) combined.add(r);
    }
    for (final r in synonymResults) {
      if (seenIds.add(r.ref.id)) combined.add(r);
    }
    return combined.take(limit).toList();
  }

  Future<void> _searchTranslation(
    String translationId,
    String exactQuery,
    List<String> allTerms,
    List<({VerseRef ref, String text})> exactResults,
    List<({VerseRef ref, String text})> synonymResults,
    int limit,
  ) async {
    for (final b in kAllBooks) {
      if (exactResults.length + synonymResults.length >= limit) break;
      final chapters = await loadBook(b.name, translationId: translationId);
      for (final c in chapters) {
        for (final v in c.verses) {
          final lower = v.text.toLowerCase();
          // Exact match
          if (lower.contains(exactQuery)) {
            exactResults.add((ref: VerseRef(b.name, c.number, v.number), text: v.text));
          } else {
            // Synonym match — check all expanded terms
            for (final term in allTerms) {
              if (term != exactQuery && lower.contains(term)) {
                synonymResults.add((ref: VerseRef(b.name, c.number, v.number), text: v.text));
                break;
              }
            }
          }
          if (exactResults.length + synonymResults.length >= limit) return;
        }
      }
    }
  }

  /// Returns the text of all verses in a given chapter, in order.
  /// Useful for feeding chapter content to AI quiz generation.
  Future<List<String>> getChapterVerseTexts(
    String book,
    int chapter, {
    String translationId = 'web',
  }) async {
    final chapters = await loadBook(book, translationId: translationId);
    final chapterIndex = (chapter - 1).clamp(0, chapters.length - 1);
    if (chapterIndex >= chapters.length) return [];
    return chapters[chapterIndex].verses.map((v) => v.text).toList();
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
