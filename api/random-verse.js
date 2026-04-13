const { getVerse, BOOK_FILES, TRANSLATIONS } = require('./_lib/bible-data');

const POPULAR_VERSES = [
  { book: 'John', chapter: 3, verse: 16 },
  { book: 'Philippians', chapter: 4, verse: 13 },
  { book: 'Jeremiah', chapter: 29, verse: 11 },
  { book: 'Romans', chapter: 8, verse: 28 },
  { book: 'Isaiah', chapter: 41, verse: 10 },
  { book: 'Proverbs', chapter: 3, verse: 5 },
  { book: 'Matthew', chapter: 11, verse: 28 },
  { book: 'Psalm', chapter: 23, verse: 1 },
  { book: 'Romans', chapter: 12, verse: 2 },
  { book: 'Hebrews', chapter: 11, verse: 1 },
  { book: 'Isaiah', chapter: 40, verse: 31 },
  { book: 'Joshua', chapter: 1, verse: 9 },
  { book: 'Galatians', chapter: 5, verse: 22 },
  { book: 'Ephesians', chapter: 2, verse: 8 },
  { book: 'James', chapter: 1, verse: 5 },
  { book: 'Psalm', chapter: 46, verse: 1 },
  { book: 'Psalm', chapter: 119, verse: 105 },
  { book: 'Matthew', chapter: 6, verse: 33 },
  { book: '2 Timothy', chapter: 1, verse: 7 },
  { book: 'Romans', chapter: 15, verse: 13 },
  { book: '1 Corinthians', chapter: 13, verse: 4 },
  { book: 'Proverbs', chapter: 22, verse: 6 },
  { book: 'Psalm', chapter: 37, verse: 4 },
  { book: 'Matthew', chapter: 28, verse: 20 },
  { book: 'Psalm', chapter: 139, verse: 14 },
  { book: 'Colossians', chapter: 3, verse: 23 },
  { book: 'Micah', chapter: 6, verse: 8 },
  { book: 'Nehemiah', chapter: 8, verse: 10 },
  { book: '1 John', chapter: 4, verse: 19 },
  { book: 'Psalm', chapter: 34, verse: 18 },
  { book: 'Lamentations', chapter: 3, verse: 22 },
  { book: 'Psalm', chapter: 27, verse: 1 },
  { book: 'Romans', chapter: 5, verse: 8 },
  { book: 'Psalm', chapter: 16, verse: 11 },
  { book: 'Deuteronomy', chapter: 31, verse: 6 },
  { book: 'Matthew', chapter: 5, verse: 16 },
  { book: 'Proverbs', chapter: 16, verse: 3 },
  { book: 'John', chapter: 14, verse: 6 },
  { book: 'Genesis', chapter: 1, verse: 1 },
  { book: 'Romans', chapter: 10, verse: 9 },
];

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  // No cache — random each time
  res.setHeader('Cache-Control', 'no-cache');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const { translation = 'kjv' } = req.query;

  if (!TRANSLATIONS.includes(translation.toLowerCase())) {
    return res.status(400).json({
      error: `Unknown translation "${translation}"`,
      available: TRANSLATIONS,
    });
  }

  const entry = POPULAR_VERSES[Math.floor(Math.random() * POPULAR_VERSES.length)];
  // Map "Psalm" to "Psalms" for file lookup
  const lookupBook = entry.book === 'Psalm' ? 'Psalms' : entry.book;
  const text = getVerse(translation.toLowerCase(), lookupBook, entry.chapter, entry.verse);

  return res.status(200).json({
    reference: `${entry.book} ${entry.chapter}:${entry.verse}`,
    book: entry.book,
    chapter: entry.chapter,
    verse: entry.verse,
    text: text || '',
    translation: translation.toUpperCase(),
    source: 'Rhema Study Bible API',
    url: 'https://rhemabibles.com',
  });
};
