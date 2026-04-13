const { getDailyVerse, TRANSLATIONS } = require('./_lib/bible-data');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  // Cache for 1 hour (same verse all day, but allow refresh)
  res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate=7200');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const { translation = 'kjv' } = req.query;

  if (!TRANSLATIONS.includes(translation.toLowerCase())) {
    return res.status(400).json({
      error: `Unknown translation "${translation}"`,
      available: TRANSLATIONS,
    });
  }

  const verse = getDailyVerse(translation.toLowerCase());

  return res.status(200).json({
    ...verse,
    source: 'Rhema Study Bible API',
    url: 'https://rhemabibles.com',
    embed: `<blockquote class="rhema-verse"><p>"${verse.text}"</p><footer>— ${verse.reference} (${verse.translation}) | <a href="https://rhemabibles.com">Rhema Study Bible</a></footer></blockquote>`,
  });
};
