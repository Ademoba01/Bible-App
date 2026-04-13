const { searchBible, TRANSLATIONS } = require('./_lib/bible-data');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const { q, query, translation = 'kjv', limit = '20' } = req.query;
  const searchQuery = q || query;

  if (!searchQuery) {
    return res.status(400).json({
      error: 'Missing search query',
      usage: 'GET /api/search?q=love&translation=kjv&limit=20',
      parameters: {
        q: 'Search query (required)',
        translation: 'Translation ID (optional, default: kjv)',
        limit: 'Max results (optional, default: 20, max: 100)',
      },
    });
  }

  if (!TRANSLATIONS.includes(translation.toLowerCase())) {
    return res.status(400).json({
      error: `Unknown translation "${translation}"`,
      available: TRANSLATIONS,
    });
  }

  const maxLimit = Math.min(parseInt(limit) || 20, 100);
  const results = searchBible(searchQuery, translation.toLowerCase(), maxLimit);

  return res.status(200).json({
    query: searchQuery,
    translation: translation.toUpperCase(),
    count: results.length,
    results,
    source: 'Rhema Study Bible API',
    url: 'https://rhemabibles.com',
  });
};
