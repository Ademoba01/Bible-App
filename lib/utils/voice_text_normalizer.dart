/// Post-processes raw STT output to make Bible search queries more accurate.
///
/// Why this exists: the speech_to_text package doesn't expose phrase hints
/// to the platform STT engines, so we can't tell iOS / Android "expect
/// these words." Instead we fix common recognition errors AFTER the engine
/// returns its best guess.
///
/// Two passes:
/// 1. **Pidgin → English** — for our Nigerian audience (Yoruba/Hausa/Igbo
///    translations). A Pidgin speaker dictating in English mode often gets
///    "pikin" recognized; we map it to "son" so the search hits Bible text.
/// 2. **Bible-name capitalization** — STT engines lowercase everything; the
///    proper noun forms ("Jesus", "Moses") help downstream search and look
///    correct in the search bar UI.
///
/// Both passes are pure string substitution — fast, predictable, no
/// network. The substitutions are word-bounded so we don't mangle
/// fragments inside other words ("hod" inside "shod" wouldn't get touched).
class VoiceTextNormalizer {
  VoiceTextNormalizer._();

  /// Common Nigerian Pidgin words that an English STT engine often
  /// recognizes literally — mapped to their English Bible equivalents.
  static const Map<String, String> _pidginToEnglish = {
    'pikin': 'son',
    'wey': 'that',
    'na so': 'so',
    'wahala': 'trouble',
    'oga': 'lord',
    'abeg': 'please',
    'sabi': 'know',
    'abi': 'or',
    'no fit': 'cannot',
    'don': 'have',
  };

  /// Bible proper nouns. Map values are the canonical capitalization.
  /// Order matters where one is a prefix of another — process longer first
  /// so "holy spirit" wins over "holy".
  static const List<MapEntry<String, String>> _bibleNouns = [
    // Multi-word first
    MapEntry('holy spirit', 'Holy Spirit'),
    MapEntry('son of god', 'Son of God'),
    MapEntry('son of man', 'Son of Man'),
    MapEntry('mary magdalene', 'Mary Magdalene'),
    MapEntry('john the baptist', 'John the Baptist'),
    // Persons
    MapEntry('jesus', 'Jesus'),
    MapEntry('christ', 'Christ'),
    MapEntry('god', 'God'),
    MapEntry('lord', 'Lord'),
    MapEntry('father', 'Father'),
    MapEntry('moses', 'Moses'),
    MapEntry('abraham', 'Abraham'),
    MapEntry('isaac', 'Isaac'),
    MapEntry('jacob', 'Jacob'),
    MapEntry('david', 'David'),
    MapEntry('solomon', 'Solomon'),
    MapEntry('paul', 'Paul'),
    MapEntry('peter', 'Peter'),
    MapEntry('john', 'John'),
    MapEntry('mary', 'Mary'),
    MapEntry('joseph', 'Joseph'),
    MapEntry('elijah', 'Elijah'),
    MapEntry('elisha', 'Elisha'),
    MapEntry('isaiah', 'Isaiah'),
    MapEntry('jeremiah', 'Jeremiah'),
    MapEntry('daniel', 'Daniel'),
    MapEntry('jonah', 'Jonah'),
    MapEntry('noah', 'Noah'),
    MapEntry('ruth', 'Ruth'),
    MapEntry('esther', 'Esther'),
    // Books (lowercased recognition)
    MapEntry('genesis', 'Genesis'),
    MapEntry('exodus', 'Exodus'),
    MapEntry('psalms', 'Psalms'),
    MapEntry('proverbs', 'Proverbs'),
    MapEntry('matthew', 'Matthew'),
    MapEntry('mark', 'Mark'),
    MapEntry('luke', 'Luke'),
    MapEntry('romans', 'Romans'),
    MapEntry('revelation', 'Revelation'),
  ];

  /// Apply both passes. Safe to call on any STT output (empty string returns
  /// empty). Returns the normalized text.
  static String normalize(String raw) {
    if (raw.isEmpty) return raw;

    // Lowercase for matching, preserve original spacing
    var text = raw;

    // Pass 1: Pidgin → English. Match whole-word boundaries so we don't
    // touch "donate" when looking for "don".
    for (final entry in _pidginToEnglish.entries) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      text = text.replaceAllMapped(pattern, (_) => entry.value);
    }

    // Pass 2: Bible-name capitalization. Same word-bounded match. Replace
    // longer multi-word entries first (handled by list order above).
    for (final entry in _bibleNouns) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(entry.key) + r'\b',
        caseSensitive: false,
      );
      text = text.replaceAllMapped(pattern, (_) => entry.value);
    }

    return text;
  }
}
