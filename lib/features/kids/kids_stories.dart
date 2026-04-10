/// Curated kids Bible stories. Each story points to a real passage in the
/// currently-selected translation (WEB by default). When the child taps one,
/// we open the reader at the start verse and they can listen or read along.
class KidsStory {
  final String title;
  final String emoji;
  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String blurb;
  final int color; // ARGB for tile background
  const KidsStory({
    required this.title,
    required this.emoji,
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.blurb,
    required this.color,
  });
}

const kKidsStories = <KidsStory>[
  KidsStory(
    title: 'Creation',
    emoji: '🌍',
    book: 'Genesis', chapter: 1, startVerse: 1, endVerse: 31,
    blurb: 'God makes the world in six days.',
    color: 0xFF66BB6A,
  ),
  KidsStory(
    title: "Noah's Ark",
    emoji: '🌊',
    book: 'Genesis', chapter: 6, startVerse: 9, endVerse: 22,
    blurb: 'Noah builds a huge boat for the animals.',
    color: 0xFF42A5F5,
  ),
  KidsStory(
    title: 'Joseph and his coat',
    emoji: '🧥',
    book: 'Genesis', chapter: 37, startVerse: 1, endVerse: 36,
    blurb: 'A dreamer, a coat, and a long journey.',
    color: 0xFFFFCA28,
  ),
  KidsStory(
    title: 'Baby Moses',
    emoji: '👶',
    book: 'Exodus', chapter: 2, startVerse: 1, endVerse: 10,
    blurb: 'A baby hidden in a basket on the river.',
    color: 0xFFEC407A,
  ),
  KidsStory(
    title: 'The Red Sea',
    emoji: '🌊',
    book: 'Exodus', chapter: 14, startVerse: 15, endVerse: 31,
    blurb: 'God opens the sea so His people can cross.',
    color: 0xFF29B6F6,
  ),
  KidsStory(
    title: 'David & Goliath',
    emoji: '🪨',
    book: '1 Samuel', chapter: 17, startVerse: 32, endVerse: 50,
    blurb: 'A little shepherd beats a giant.',
    color: 0xFF8D6E63,
  ),
  KidsStory(
    title: "Daniel & the lions",
    emoji: '🦁',
    book: 'Daniel', chapter: 6, startVerse: 10, endVerse: 23,
    blurb: 'God keeps Daniel safe in the lions\' den.',
    color: 0xFFFFA726,
  ),
  KidsStory(
    title: 'Jonah & the big fish',
    emoji: '🐟',
    book: 'Jonah', chapter: 1, startVerse: 1, endVerse: 17,
    blurb: 'Jonah runs, but God has other plans.',
    color: 0xFF26A69A,
  ),
  KidsStory(
    title: 'Baby Jesus',
    emoji: '⭐',
    book: 'Luke', chapter: 2, startVerse: 1, endVerse: 20,
    blurb: 'Jesus is born in a little town called Bethlehem.',
    color: 0xFFAB47BC,
  ),
  KidsStory(
    title: 'Jesus calms the storm',
    emoji: '⛵',
    book: 'Mark', chapter: 4, startVerse: 35, endVerse: 41,
    blurb: 'Even the wind and waves obey Him.',
    color: 0xFF5C6BC0,
  ),
  KidsStory(
    title: 'The lost sheep',
    emoji: '🐑',
    book: 'Luke', chapter: 15, startVerse: 1, endVerse: 7,
    blurb: 'A shepherd who never stops searching.',
    color: 0xFF9CCC65,
  ),
  KidsStory(
    title: 'Jesus is alive!',
    emoji: '✨',
    book: 'Matthew', chapter: 28, startVerse: 1, endVerse: 10,
    blurb: 'The happiest morning in all of history.',
    color: 0xFFFFEE58,
  ),
  KidsStory(
    title: 'Adam & Eve',
    emoji: '🍎',
    book: 'Genesis', chapter: 3, startVerse: 1, endVerse: 24,
    blurb: 'The first garden and the first choice.',
    color: 0xFF4CAF50,
  ),
  KidsStory(
    title: 'Tower of Babel',
    emoji: '🏗️',
    book: 'Genesis', chapter: 11, startVerse: 1, endVerse: 9,
    blurb: 'People build a tower that reaches the sky.',
    color: 0xFF78909C,
  ),
  KidsStory(
    title: "Abraham's Promise",
    emoji: '⭐',
    book: 'Genesis', chapter: 15, startVerse: 1, endVerse: 6,
    blurb: 'God promises as many children as the stars.',
    color: 0xFF1565C0,
  ),
  KidsStory(
    title: 'Isaac is Born',
    emoji: '👶',
    book: 'Genesis', chapter: 21, startVerse: 1, endVerse: 7,
    blurb: 'A baby that made everyone laugh with joy.',
    color: 0xFFE91E63,
  ),
  KidsStory(
    title: "Jacob's Ladder",
    emoji: '🪜',
    book: 'Genesis', chapter: 28, startVerse: 10, endVerse: 22,
    blurb: 'A dream of angels going up and down.',
    color: 0xFF7E57C2,
  ),
  KidsStory(
    title: 'Moses & the Burning Bush',
    emoji: '🔥',
    book: 'Exodus', chapter: 3, startVerse: 1, endVerse: 15,
    blurb: 'A bush that burns but never burns up.',
    color: 0xFFFF5722,
  ),
  KidsStory(
    title: 'The Ten Commandments',
    emoji: '📜',
    book: 'Exodus', chapter: 20, startVerse: 1, endVerse: 17,
    blurb: "God's ten important rules for living.",
    color: 0xFF455A64,
  ),
  KidsStory(
    title: 'Walls of Jericho',
    emoji: '🎺',
    book: 'Joshua', chapter: 6, startVerse: 1, endVerse: 20,
    blurb: 'Marching and trumpets bring the walls down.',
    color: 0xFFD84315,
  ),
  KidsStory(
    title: 'Ruth & Naomi',
    emoji: '💕',
    book: 'Ruth', chapter: 1, startVerse: 1, endVerse: 18,
    blurb: 'A beautiful story of love and loyalty.',
    color: 0xFFAD1457,
  ),
  KidsStory(
    title: 'Samuel Hears God',
    emoji: '👂',
    book: '1 Samuel', chapter: 3, startVerse: 1, endVerse: 21,
    blurb: 'A boy hears God calling his name at night.',
    color: 0xFF0277BD,
  ),
  KidsStory(
    title: 'Elijah & the Ravens',
    emoji: '🐦',
    book: '1 Kings', chapter: 17, startVerse: 1, endVerse: 6,
    blurb: 'Birds bring food to a hungry prophet.',
    color: 0xFF33691E,
  ),
  KidsStory(
    title: 'Queen Esther',
    emoji: '👑',
    book: 'Esther', chapter: 4, startVerse: 1, endVerse: 17,
    blurb: 'A brave queen saves her people.',
    color: 0xFF6A1B9A,
  ),
  KidsStory(
    title: 'Fiery Furnace',
    emoji: '🔥',
    book: 'Daniel', chapter: 3, startVerse: 1, endVerse: 30,
    blurb: "Three friends walk through fire and don't get burned.",
    color: 0xFFBF360C,
  ),
];
