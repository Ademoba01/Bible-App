const { BOOK_LIST, TRANSLATIONS } = require('./_lib/bible-data');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Cache-Control', 's-maxage=86400, stale-while-revalidate=172800');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const oldTestament = BOOK_LIST.slice(0, 39);
  const newTestament = BOOK_LIST.slice(39);

  return res.status(200).json({
    count: BOOK_LIST.length,
    translations: TRANSLATIONS,
    oldTestament: { count: oldTestament.length, books: oldTestament },
    newTestament: { count: newTestament.length, books: newTestament },
    source: 'Rhema Study Bible API',
    url: 'https://rhemabibles.com',
  });
};
