const { getVerse, resolveBookFile, TRANSLATIONS } = require('./_lib/bible-data');

module.exports = (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const { book, chapter, verse, translation = 'kjv' } = req.query;

  if (!book || !chapter) {
    return res.status(400).json({
      error: 'Missing required parameters',
      usage: 'GET /api/verse?book=John&chapter=3&verse=16&translation=kjv',
      parameters: {
        book: 'Book name (required) — e.g. "John", "1 Corinthians", "Psalms"',
        chapter: 'Chapter number (required)',
        verse: 'Verse number (optional — omit for full chapter)',
        translation: 'Translation ID (optional, default: kjv) — kjv, web, bsb',
      },
    });
  }

  if (!TRANSLATIONS.includes(translation.toLowerCase())) {
    return res.status(400).json({
      error: `Unknown translation "${translation}"`,
      available: TRANSLATIONS,
    });
  }

  if (!resolveBookFile(book)) {
    return res.status(404).json({
      error: `Book "${book}" not found`,
      hint: 'Use /api/books for a list of valid book names',
    });
  }

  const ch = parseInt(chapter);
  if (isNaN(ch) || ch < 1) {
    return res.status(400).json({ error: 'Invalid chapter number' });
  }

  const vn = verse ? parseInt(verse) : null;

  if (vn) {
    // Single verse
    const text = getVerse(translation.toLowerCase(), book, ch, vn);
    if (!text) {
      return res.status(404).json({ error: `Verse not found: ${book} ${ch}:${vn}` });
    }
    return res.status(200).json({
      reference: `${book} ${ch}:${vn}`,
      book,
      chapter: ch,
      verse: vn,
      text,
      translation: translation.toUpperCase(),
      source: 'Rhema Study Bible API',
      url: 'https://rhemabibles.com',
    });
  } else {
    // Full chapter
    const chapterData = getVerse(translation.toLowerCase(), book, ch, null);
    if (!chapterData) {
      return res.status(404).json({ error: `Chapter not found: ${book} ${ch}` });
    }
    const verses = Object.entries(chapterData)
      .map(([vn, text]) => ({ verse: parseInt(vn), text }))
      .sort((a, b) => a.verse - b.verse);

    return res.status(200).json({
      reference: `${book} ${ch}`,
      book,
      chapter: ch,
      verses,
      verseCount: verses.length,
      translation: translation.toUpperCase(),
      source: 'Rhema Study Bible API',
      url: 'https://rhemabibles.com',
    });
  }
};
