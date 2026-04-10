import 'books.dart';

// ─── Data Models ────────────────────────────────────────────────

/// A single day's reading assignment.
class DayReading {
  final int day; // 1-based
  final String book;
  final int chapter;
  final int? endChapter; // if reading spans multiple chapters
  final String label; // e.g. "Genesis 1-3"

  const DayReading({
    required this.day,
    required this.book,
    required this.chapter,
    this.endChapter,
    required this.label,
  });
}

/// A complete reading plan with metadata.
class ReadingPlan {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int totalDays;
  final int color; // ARGB
  final List<DayReading> readings;
  final List<String> tags; // for discovery

  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.totalDays,
    required this.color,
    required this.readings,
    this.tags = const [],
  });
}

/// Plan template (before generating actual readings).
class PlanTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int defaultDays;
  final int color;
  final List<String> booksIncluded; // book names
  final List<String> tags;

  const PlanTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.defaultDays,
    required this.color,
    required this.booksIncluded,
    this.tags = const [],
  });
}

// ─── Chapter Counts ─────────────────────────────────────────────

const kChapterCounts = <String, int>{
  'Genesis': 50, 'Exodus': 40, 'Leviticus': 27, 'Numbers': 36,
  'Deuteronomy': 34, 'Joshua': 24, 'Judges': 21, 'Ruth': 4,
  '1 Samuel': 31, '2 Samuel': 24, '1 Kings': 22, '2 Kings': 25,
  '1 Chronicles': 29, '2 Chronicles': 36, 'Ezra': 10, 'Nehemiah': 13,
  'Esther': 10, 'Job': 42, 'Psalms': 150, 'Proverbs': 31,
  'Ecclesiastes': 12, 'Song of Solomon': 8, 'Isaiah': 66, 'Jeremiah': 52,
  'Lamentations': 5, 'Ezekiel': 48, 'Daniel': 12, 'Hosea': 14,
  'Joel': 3, 'Amos': 9, 'Obadiah': 1, 'Jonah': 4, 'Micah': 7,
  'Nahum': 3, 'Habakkuk': 3, 'Zephaniah': 3, 'Haggai': 2,
  'Zechariah': 14, 'Malachi': 4,
  'Matthew': 28, 'Mark': 16, 'Luke': 24, 'John': 21, 'Acts': 28,
  'Romans': 16, '1 Corinthians': 16, '2 Corinthians': 13,
  'Galatians': 6, 'Ephesians': 6, 'Philippians': 4, 'Colossians': 4,
  '1 Thessalonians': 5, '2 Thessalonians': 3, '1 Timothy': 6,
  '2 Timothy': 4, 'Titus': 3, 'Philemon': 1, 'Hebrews': 13,
  'James': 5, '1 Peter': 5, '2 Peter': 3, '1 John': 5, '2 John': 1,
  '3 John': 1, 'Jude': 1, 'Revelation': 22,
};

// ─── Pre-defined Plan Templates ─────────────────────────────────

final kPlanTemplates = <PlanTemplate>[
  PlanTemplate(
    id: 'bible_in_year',
    name: 'Bible in a Year',
    emoji: '📖',
    description: 'Read the entire Bible from Genesis to Revelation in 365 days. About 3-4 chapters per day.',
    defaultDays: 365,
    color: 0xFF5D4037,
    booksIncluded: kAllBooks.map((b) => b.name).toList(),
    tags: ['complete', 'classic', 'popular'],
  ),
  PlanTemplate(
    id: 'nt_90',
    name: 'New Testament in 90 Days',
    emoji: '✝️',
    description: 'Focus on the life of Jesus and the early church. Perfect for new believers or a fresh start.',
    defaultDays: 90,
    color: 0xFF1565C0,
    booksIncluded: kAllBooks.where((b) => b.testament == 'NT').map((b) => b.name).toList(),
    tags: ['new testament', 'beginner', 'focused'],
  ),
  PlanTemplate(
    id: 'gospels_30',
    name: 'The Four Gospels',
    emoji: '🕊️',
    description: "Walk with Jesus through Matthew, Mark, Luke, and John. Experience His life, miracles, and teachings.",
    defaultDays: 30,
    color: 0xFFAB47BC,
    booksIncluded: ['Matthew', 'Mark', 'Luke', 'John'],
    tags: ['jesus', 'gospels', 'devotional'],
  ),
  PlanTemplate(
    id: 'prophets',
    name: 'The Prophets',
    emoji: '🔥',
    description: "Hear the voices of God's prophets — Isaiah, Jeremiah, Ezekiel, Daniel, and the twelve minor prophets.",
    defaultDays: 120,
    color: 0xFFE65100,
    booksIncluded: [
      'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
      'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
      'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    ],
    tags: ['prophets', 'old testament', 'deep study'],
  ),
  PlanTemplate(
    id: 'psalms_proverbs',
    name: 'Psalms & Proverbs',
    emoji: '🎵',
    description: 'Daily wisdom and worship. Let the Psalms lift your spirit and Proverbs guide your day.',
    defaultDays: 60,
    color: 0xFF2E7D32,
    booksIncluded: ['Psalms', 'Proverbs'],
    tags: ['wisdom', 'worship', 'daily', 'devotional'],
  ),
  PlanTemplate(
    id: 'paul_letters',
    name: "Paul's Letters",
    emoji: '✉️',
    description: 'Romans through Philemon — deep theology, practical advice, and passionate encouragement from the Apostle Paul.',
    defaultDays: 45,
    color: 0xFF00838F,
    booksIncluded: [
      'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
      'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
      '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
    ],
    tags: ['paul', 'letters', 'theology'],
  ),
  PlanTemplate(
    id: 'genesis_exodus',
    name: 'The Beginning',
    emoji: '🌅',
    description: 'Creation, the patriarchs, slavery in Egypt, and the Exodus. The foundation stories of faith.',
    defaultDays: 30,
    color: 0xFF8D6E63,
    booksIncluded: ['Genesis', 'Exodus'],
    tags: ['beginning', 'foundation', 'history'],
  ),
  PlanTemplate(
    id: 'acts_revolution',
    name: 'Acts: The Revolution',
    emoji: '⚡',
    description: 'The explosive birth of the church. From Pentecost to Paul in Rome — 28 chapters of unstoppable faith.',
    defaultDays: 28,
    color: 0xFFD32F2F,
    booksIncluded: ['Acts'],
    tags: ['acts', 'church', 'history'],
  ),
  PlanTemplate(
    id: 'bible_3months',
    name: 'Bible in 3 Months',
    emoji: '🏃',
    description: 'An intensive journey through the entire Bible. About 13 chapters per day — for the committed reader.',
    defaultDays: 90,
    color: 0xFF37474F,
    booksIncluded: kAllBooks.map((b) => b.name).toList(),
    tags: ['complete', 'intensive', 'challenge'],
  ),
  PlanTemplate(
    id: 'revelation',
    name: 'Revelation Unveiled',
    emoji: '🌟',
    description: 'A focused 22-day journey through the most mysterious book of the Bible.',
    defaultDays: 22,
    color: 0xFF4A148C,
    booksIncluded: ['Revelation'],
    tags: ['revelation', 'prophecy', 'end times'],
  ),
];

// ─── Plan Generator (the "AI" engine) ───────────────────────────

class PlanGenerator {
  /// Generates a [ReadingPlan] from a template, adapting to the user's
  /// preferred number of days.
  ///
  /// The algorithm distributes chapters as evenly as possible across
  /// the requested days, grouping by book to maintain narrative flow.
  static ReadingPlan generate(PlanTemplate template, {int? customDays}) {
    final days = customDays ?? template.defaultDays;

    // Collect all (book, chapter) pairs in canonical order
    final allChapters = <({String book, int chapter})>[];
    for (final bookName in template.booksIncluded) {
      final count = kChapterCounts[bookName] ?? 1;
      for (var ch = 1; ch <= count; ch++) {
        allChapters.add((book: bookName, chapter: ch));
      }
    }

    final totalChapters = allChapters.length;
    final chaptersPerDay = totalChapters / days;

    final readings = <DayReading>[];
    var idx = 0;

    for (var day = 1; day <= days && idx < totalChapters; day++) {
      // How many chapters to assign today
      final targetEnd = (day * chaptersPerDay).round().clamp(idx + 1, totalChapters);
      final dayChapters = allChapters.sublist(idx, targetEnd);

      if (dayChapters.isEmpty) continue;

      // Group consecutive chapters in the same book for a clean label
      final segments = <String>[];
      String? currentBook;
      int? startCh;
      int? endCh;

      for (final dc in dayChapters) {
        if (dc.book == currentBook && dc.chapter == (endCh ?? 0) + 1) {
          endCh = dc.chapter;
        } else {
          if (currentBook != null) {
            segments.add(_formatRange(currentBook, startCh!, endCh!));
          }
          currentBook = dc.book;
          startCh = dc.chapter;
          endCh = dc.chapter;
        }
      }
      if (currentBook != null) {
        segments.add(_formatRange(currentBook, startCh!, endCh!));
      }

      readings.add(DayReading(
        day: day,
        book: dayChapters.first.book,
        chapter: dayChapters.first.chapter,
        endChapter: dayChapters.last.chapter != dayChapters.first.chapter
            ? dayChapters.last.chapter
            : null,
        label: segments.join(', '),
      ));

      idx = targetEnd;
    }

    return ReadingPlan(
      id: '${template.id}_${days}d',
      name: template.name,
      description: template.description,
      emoji: template.emoji,
      totalDays: days,
      color: template.color,
      readings: readings,
      tags: template.tags,
    );
  }

  /// Generates a custom plan from hand-picked books.
  static ReadingPlan custom({
    required String name,
    required List<String> books,
    required int days,
    String emoji = '📘',
    String description = 'Your custom reading plan',
    int color = 0xFF5D4037,
  }) {
    final template = PlanTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      description: description,
      defaultDays: days,
      color: color,
      booksIncluded: books,
      tags: ['custom'],
    );
    return generate(template, customDays: days);
  }

  static String _formatRange(String book, int start, int end) {
    if (start == end) return '$book $start';
    return '$book $start–$end';
  }

  /// Returns a smart recommendation based on how many days the user
  /// wants to read and what areas interest them.
  static List<PlanTemplate> recommend({
    int? maxDays,
    String? interest, // 'jesus', 'wisdom', 'history', 'prophecy', 'all'
  }) {
    var templates = List<PlanTemplate>.from(kPlanTemplates);

    if (maxDays != null) {
      templates = templates.where((t) => t.defaultDays <= maxDays + 30).toList();
    }

    if (interest != null && interest.isNotEmpty) {
      final i = interest.toLowerCase();
      templates.sort((a, b) {
        final aScore = a.tags.any((t) => t.contains(i)) ? 0 : 1;
        final bScore = b.tags.any((t) => t.contains(i)) ? 0 : 1;
        return aScore.compareTo(bScore);
      });
    }

    return templates;
  }
}
