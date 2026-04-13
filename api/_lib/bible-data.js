const fs = require('fs');
const path = require('path');

// ── Book name → filename mapping ──────────────────────────────────
const BOOK_FILES = {
  'genesis': 'genesis', 'exodus': 'exodus', 'leviticus': 'leviticus',
  'numbers': 'numbers', 'deuteronomy': 'deuteronomy', 'joshua': 'joshua',
  'judges': 'judges', 'ruth': 'ruth', '1 samuel': '1samuel', '2 samuel': '2samuel',
  '1 kings': '1kings', '2 kings': '2kings', '1 chronicles': '1chronicles',
  '2 chronicles': '2chronicles', 'ezra': 'ezra', 'nehemiah': 'nehemiah',
  'esther': 'esther', 'job': 'job', 'psalms': 'psalms', 'proverbs': 'proverbs',
  'ecclesiastes': 'ecclesiastes', 'song of solomon': 'songofsolomon',
  'isaiah': 'isaiah', 'jeremiah': 'jeremiah', 'lamentations': 'lamentations',
  'ezekiel': 'ezekiel', 'daniel': 'daniel', 'hosea': 'hosea', 'joel': 'joel',
  'amos': 'amos', 'obadiah': 'obadiah', 'jonah': 'jonah', 'micah': 'micah',
  'nahum': 'nahum', 'habakkuk': 'habakkuk', 'zephaniah': 'zephaniah',
  'haggai': 'haggai', 'zechariah': 'zechariah', 'malachi': 'malachi',
  'matthew': 'matthew', 'mark': 'mark', 'luke': 'luke', 'john': 'john',
  'acts': 'acts', 'romans': 'romans', '1 corinthians': '1corinthians',
  '2 corinthians': '2corinthians', 'galatians': 'galatians',
  'ephesians': 'ephesians', 'philippians': 'philippians',
  'colossians': 'colossians', '1 thessalonians': '1thessalonians',
  '2 thessalonians': '2thessalonians', '1 timothy': '1timothy',
  '2 timothy': '2timothy', 'titus': 'titus', 'philemon': 'philemon',
  'hebrews': 'hebrews', 'james': 'james', '1 peter': '1peter',
  '2 peter': '2peter', '1 john': '1john', '2 john': '2john',
  '3 john': '3john', 'jude': 'jude', 'revelation': 'revelation',
};

const TRANSLATIONS = ['kjv', 'web', 'bsb'];

const BOOK_LIST = Object.keys(BOOK_FILES).map(b =>
  b.split(' ').map(w => w[0].toUpperCase() + w.slice(1)).join(' ')
);

// Cache loaded books in memory (serverless functions stay warm for a bit)
const cache = {};

function resolveBookFile(bookName) {
  const lower = bookName.toLowerCase().trim();
  if (BOOK_FILES[lower]) return BOOK_FILES[lower];
  // Try partial match
  for (const [key, file] of Object.entries(BOOK_FILES)) {
    if (key.startsWith(lower) || key.replace(/\s/g, '').startsWith(lower.replace(/\s/g, ''))) {
      return file;
    }
  }
  return null;
}

function loadBook(translation, bookName) {
  const file = resolveBookFile(bookName);
  if (!file) return null;

  const cacheKey = `${translation}|${file}`;
  if (cache[cacheKey]) return cache[cacheKey];

  const filePath = path.join(process.cwd(), 'assets', 'bibles', translation, `${file}.json`);
  if (!fs.existsSync(filePath)) return null;

  const raw = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

  // Parse into chapters → verses
  const chapters = {};
  for (const entry of raw) {
    const ch = entry.chapterNumber;
    const vn = entry.verseNumber;
    if (!chapters[ch]) chapters[ch] = {};
    if (!chapters[ch][vn]) chapters[ch][vn] = '';
    chapters[ch][vn] += (chapters[ch][vn] ? ' ' : '') + entry.value.trim();
  }

  cache[cacheKey] = chapters;
  return chapters;
}

function getVerse(translation, book, chapter, verse) {
  const chapters = loadBook(translation, book);
  if (!chapters || !chapters[chapter]) return null;
  if (verse) return chapters[chapter][verse] || null;
  return chapters[chapter]; // return full chapter
}

// ── Daily Verse ──────────────────────────────────────────────────
const DAILY_VERSES = [
  { ref: 'John 3:16', book: 'John', chapter: 3, verse: 16 },
  { ref: 'Philippians 4:13', book: 'Philippians', chapter: 4, verse: 13 },
  { ref: 'Jeremiah 29:11', book: 'Jeremiah', chapter: 29, verse: 11 },
  { ref: 'Romans 8:28', book: 'Romans', chapter: 8, verse: 28 },
  { ref: 'Isaiah 41:10', book: 'Isaiah', chapter: 41, verse: 10 },
  { ref: 'Psalm 23:1', book: 'Psalms', chapter: 23, verse: 1 },
  { ref: 'Proverbs 3:5', book: 'Proverbs', chapter: 3, verse: 5 },
  { ref: 'Matthew 11:28', book: 'Matthew', chapter: 11, verse: 28 },
  { ref: 'Romans 12:2', book: 'Romans', chapter: 12, verse: 2 },
  { ref: 'Psalm 46:1', book: 'Psalms', chapter: 46, verse: 1 },
  { ref: 'Hebrews 11:1', book: 'Hebrews', chapter: 11, verse: 1 },
  { ref: 'Isaiah 40:31', book: 'Isaiah', chapter: 40, verse: 31 },
  { ref: 'Psalm 119:105', book: 'Psalms', chapter: 119, verse: 105 },
  { ref: 'Joshua 1:9', book: 'Joshua', chapter: 1, verse: 9 },
  { ref: 'Romans 15:13', book: 'Romans', chapter: 15, verse: 13 },
  { ref: '2 Timothy 1:7', book: '2 Timothy', chapter: 1, verse: 7 },
  { ref: 'Psalm 37:4', book: 'Psalms', chapter: 37, verse: 4 },
  { ref: 'Matthew 6:33', book: 'Matthew', chapter: 6, verse: 33 },
  { ref: 'Ephesians 2:8', book: 'Ephesians', chapter: 2, verse: 8 },
  { ref: '1 Corinthians 10:13', book: '1 Corinthians', chapter: 10, verse: 13 },
  { ref: 'Galatians 5:22', book: 'Galatians', chapter: 5, verse: 22 },
  { ref: 'Psalm 27:1', book: 'Psalms', chapter: 27, verse: 1 },
  { ref: 'James 1:5', book: 'James', chapter: 1, verse: 5 },
  { ref: 'Lamentations 3:22-23', book: 'Lamentations', chapter: 3, verse: 22 },
  { ref: 'Psalm 34:18', book: 'Psalms', chapter: 34, verse: 18 },
  { ref: 'Nehemiah 8:10', book: 'Nehemiah', chapter: 8, verse: 10 },
  { ref: '1 John 4:19', book: '1 John', chapter: 4, verse: 19 },
  { ref: 'Colossians 3:23', book: 'Colossians', chapter: 3, verse: 23 },
  { ref: 'Psalm 16:11', book: 'Psalms', chapter: 16, verse: 11 },
  { ref: 'Micah 6:8', book: 'Micah', chapter: 6, verse: 8 },
  { ref: 'Psalm 139:14', book: 'Psalms', chapter: 139, verse: 14 },
];

function getDailyVerse(translation = 'kjv') {
  // Deterministic based on date — same verse all day everywhere
  const today = new Date();
  const dayOfYear = Math.floor(
    (today - new Date(today.getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24)
  );
  const entry = DAILY_VERSES[dayOfYear % DAILY_VERSES.length];
  const text = getVerse(translation, entry.book, entry.chapter, entry.verse);
  return {
    reference: entry.ref,
    text: text || '',
    translation: translation.toUpperCase(),
    date: today.toISOString().split('T')[0],
  };
}

// ── Topic verses ─────────────────────────────────────────────────
const TOPIC_VERSES = {
  honesty: ['Proverbs 12:22', 'Proverbs 11:1', 'Colossians 3:9', 'Ephesians 4:25', 'Zechariah 8:16', 'Psalm 15:1-2', 'Leviticus 19:11', 'Luke 16:10'],
  truth: ['John 8:32', 'John 14:6', 'Psalm 119:160', 'Proverbs 12:19', '3 John 1:4', 'John 17:17', 'Ephesians 4:15'],
  patience: ['James 1:3-4', 'Romans 12:12', 'Galatians 6:9', 'Psalm 27:14', 'Isaiah 40:31', 'Hebrews 10:36', 'Colossians 1:11'],
  forgiveness: ['Matthew 6:14-15', 'Ephesians 4:32', 'Colossians 3:13', 'Mark 11:25', 'Luke 6:37', 'Psalm 103:12', '1 John 1:9'],
  courage: ['Joshua 1:9', 'Deuteronomy 31:6', 'Isaiah 41:10', 'Psalm 27:1', '2 Timothy 1:7', 'Psalm 31:24', '1 Corinthians 16:13'],
  strength: ['Philippians 4:13', 'Isaiah 40:31', 'Psalm 46:1', 'Nehemiah 8:10', '2 Corinthians 12:9-10', 'Ephesians 6:10'],
  wisdom: ['James 1:5', 'Proverbs 4:7', 'Proverbs 9:10', 'Proverbs 2:6', 'Colossians 2:3', 'Psalm 111:10'],
  love: ['1 Corinthians 13:4-7', 'John 3:16', 'Romans 8:38-39', '1 John 4:19', 'John 15:13', 'Romans 5:8'],
  faith: ['Hebrews 11:1', 'Romans 10:17', 'Matthew 17:20', '2 Corinthians 5:7', 'James 2:17', 'Galatians 2:20'],
  hope: ['Romans 15:13', 'Jeremiah 29:11', 'Romans 8:28', 'Psalm 42:11', 'Lamentations 3:22-23', '1 Peter 1:3'],
  peace: ['Philippians 4:6-7', 'John 14:27', 'Isaiah 26:3', 'Romans 8:6', 'Psalm 29:11', 'Colossians 3:15'],
  joy: ['Nehemiah 8:10', 'Psalm 16:11', 'John 15:11', 'Romans 15:13', 'Philippians 4:4', 'Galatians 5:22'],
  anxiety: ['Philippians 4:6-7', 'Matthew 6:34', '1 Peter 5:7', 'Psalm 55:22', 'Isaiah 41:10', 'John 14:27'],
  fear: ['2 Timothy 1:7', 'Psalm 23:4', 'Isaiah 41:10', 'Psalm 56:3', '1 John 4:18', 'Deuteronomy 31:6'],
  anger: ['Proverbs 15:1', 'James 1:19-20', 'Ephesians 4:26', 'Proverbs 29:11', 'Psalm 37:8', 'Ecclesiastes 7:9'],
  marriage: ['Genesis 2:24', 'Ephesians 5:25', 'Mark 10:9', 'Hebrews 13:4', 'Proverbs 18:22', '1 Corinthians 13:4-7'],
  money: ['1 Timothy 6:10', 'Hebrews 13:5', 'Matthew 6:24', 'Proverbs 22:7', 'Luke 12:15', 'Matthew 6:19-21'],
  healing: ['Jeremiah 17:14', 'James 5:14-15', 'Psalm 103:3', 'Isaiah 53:5', 'Psalm 30:2', 'Exodus 15:26'],
  death: ['John 11:25-26', '1 Corinthians 15:55', 'Revelation 21:4', 'Psalm 23:4', 'Philippians 1:21', '2 Corinthians 5:8'],
  salvation: ['Romans 10:9', 'Ephesians 2:8-9', 'John 14:6', 'Acts 4:12', 'Romans 6:23', 'Titus 3:5'],
  prayer: ['Philippians 4:6', 'Matthew 6:9-13', '1 Thessalonians 5:17', 'James 5:16', 'Mark 11:24', 'Psalm 145:18'],
  humility: ['Philippians 2:3', 'James 4:10', '1 Peter 5:6', 'Proverbs 22:4', 'Micah 6:8', 'Matthew 23:12'],
  gratitude: ['1 Thessalonians 5:18', 'Colossians 3:17', 'Psalm 100:4', 'Psalm 107:1', 'Ephesians 5:20'],
  children: ['Proverbs 22:6', 'Psalm 127:3', 'Mark 10:14', 'Ephesians 6:4', 'Deuteronomy 6:7', '3 John 1:4'],
  generosity: ['2 Corinthians 9:7', 'Proverbs 11:25', 'Acts 20:35', 'Luke 6:38', '1 Timothy 6:18'],
};

function getTopicVerses(topic) {
  const lower = topic.toLowerCase().trim();
  return TOPIC_VERSES[lower] || null;
}

function getAvailableTopics() {
  return Object.keys(TOPIC_VERSES).sort();
}

// ── Search ───────────────────────────────────────────────────────
function searchBible(query, translation = 'kjv', limit = 20) {
  const lower = query.toLowerCase().trim();
  if (!lower) return [];

  const results = [];
  for (const [bookName, fileName] of Object.entries(BOOK_FILES)) {
    if (results.length >= limit) break;
    const chapters = loadBook(translation, bookName);
    if (!chapters) continue;
    const displayBook = bookName.split(' ').map(w => w[0].toUpperCase() + w.slice(1)).join(' ');
    for (const [ch, verses] of Object.entries(chapters)) {
      for (const [vn, text] of Object.entries(verses)) {
        if (text.toLowerCase().includes(lower)) {
          results.push({
            reference: `${displayBook} ${ch}:${vn}`,
            book: displayBook,
            chapter: parseInt(ch),
            verse: parseInt(vn),
            text,
            translation: translation.toUpperCase(),
          });
          if (results.length >= limit) break;
        }
      }
      if (results.length >= limit) break;
    }
  }
  return results;
}

module.exports = {
  BOOK_FILES, BOOK_LIST, TRANSLATIONS,
  loadBook, getVerse, resolveBookFile,
  getDailyVerse, getTopicVerses, getAvailableTopics,
  searchBible,
};
