const { getTopicVerses, getAvailableTopics } = require('./_lib/bible-data');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Cache-Control', 's-maxage=86400, stale-while-revalidate=172800');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const { topic } = req.query;

  // If no topic specified, return list of available topics
  if (!topic) {
    const topics = getAvailableTopics();
    return res.status(200).json({
      count: topics.length,
      topics,
      usage: 'GET /api/topics?topic=honesty',
      source: 'Rhema Study Bible API',
      url: 'https://rhemabibles.com',
    });
  }

  const verses = getTopicVerses(topic);

  if (!verses) {
    return res.status(404).json({
      error: `Topic "${topic}" not found`,
      available: getAvailableTopics(),
      hint: 'Try: honesty, love, faith, hope, peace, patience, courage, wisdom',
    });
  }

  return res.status(200).json({
    topic: topic.toLowerCase(),
    count: verses.length,
    verses,
    source: 'Rhema Study Bible API',
    url: 'https://rhemabibles.com',
  });
};
