// Downloads the Berean Standard Bible (public domain) and converts it to the
// project's per-book flat-JSON format under assets/bibles/bsb/.
//
// Run from the repo root:
//   dart run tools/fetch_bsb.dart
//
// Source: bereanbible.com distributes the BSB as a single tab-separated file.
// We parse it line-by-line and group by book → per-book JSON.

import 'dart:convert';
import 'dart:io';

// Canonical BSB plain-text TSV (Reference\tText). If this URL ever moves,
// check https://bereanbible.com/ for the current "Download" link.
const _bsbTsvUrl =
    'https://bereanbible.com/bsb.txt';

// Maps the book names used in bsb.txt → project asset filenames (must match
// lib/data/books.dart).
const Map<String, String> _bookFile = {
  'Genesis': 'genesis',
  'Exodus': 'exodus',
  'Leviticus': 'leviticus',
  'Numbers': 'numbers',
  'Deuteronomy': 'deuteronomy',
  'Joshua': 'joshua',
  'Judges': 'judges',
  'Ruth': 'ruth',
  '1 Samuel': '1samuel',
  '2 Samuel': '2samuel',
  '1 Kings': '1kings',
  '2 Kings': '2kings',
  '1 Chronicles': '1chronicles',
  '2 Chronicles': '2chronicles',
  'Ezra': 'ezra',
  'Nehemiah': 'nehemiah',
  'Esther': 'esther',
  'Job': 'job',
  'Psalm': 'psalms',
  'Psalms': 'psalms',
  'Proverbs': 'proverbs',
  'Ecclesiastes': 'ecclesiastes',
  'Song of Solomon': 'songofsolomon',
  'Song of Songs': 'songofsolomon',
  'Isaiah': 'isaiah',
  'Jeremiah': 'jeremiah',
  'Lamentations': 'lamentations',
  'Ezekiel': 'ezekiel',
  'Daniel': 'daniel',
  'Hosea': 'hosea',
  'Joel': 'joel',
  'Amos': 'amos',
  'Obadiah': 'obadiah',
  'Jonah': 'jonah',
  'Micah': 'micah',
  'Nahum': 'nahum',
  'Habakkuk': 'habakkuk',
  'Zephaniah': 'zephaniah',
  'Haggai': 'haggai',
  'Zechariah': 'zechariah',
  'Malachi': 'malachi',
  'Matthew': 'matthew',
  'Mark': 'mark',
  'Luke': 'luke',
  'John': 'john',
  'Acts': 'acts',
  'Romans': 'romans',
  '1 Corinthians': '1corinthians',
  '2 Corinthians': '2corinthians',
  'Galatians': 'galatians',
  'Ephesians': 'ephesians',
  'Philippians': 'philippians',
  'Colossians': 'colossians',
  '1 Thessalonians': '1thessalonians',
  '2 Thessalonians': '2thessalonians',
  '1 Timothy': '1timothy',
  '2 Timothy': '2timothy',
  'Titus': 'titus',
  'Philemon': 'philemon',
  'Hebrews': 'hebrews',
  'James': 'james',
  '1 Peter': '1peter',
  '2 Peter': '2peter',
  '1 John': '1john',
  '2 John': '2john',
  '3 John': '3john',
  'Jude': 'jude',
  'Revelation': 'revelation',
};

Future<void> main() async {
  print('Downloading BSB from $_bsbTsvUrl ...');
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(_bsbTsvUrl));
  final resp = await req.close();
  if (resp.statusCode != 200) {
    stderr.writeln('Download failed: HTTP ${resp.statusCode}');
    exit(1);
  }
  final body = await resp.transform(utf8.decoder).join();
  client.close();

  // Per-book accumulator: book → list of {chapterNumber,verseNumber,value}
  final Map<String, List<Map<String, Object>>> books = {};

  // Parse lines like "Genesis 1:1\tIn the beginning..."
  // Skip the header / preamble lines until we see a valid reference.
  final ref = RegExp(r'^([\w ]+?) (\d+):(\d+)$');
  for (final raw in const LineSplitter().convert(body)) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    final reference = line.substring(0, tab).trim();
    final text = line.substring(tab + 1).trim();
    final m = ref.firstMatch(reference);
    if (m == null) continue;
    final bookName = m.group(1)!;
    final ch = int.parse(m.group(2)!);
    final vs = int.parse(m.group(3)!);
    final file = _bookFile[bookName];
    if (file == null) {
      stderr.writeln('WARN: unknown book "$bookName"');
      continue;
    }
    books.putIfAbsent(file, () => []).add({
      'type': 'paragraph text',
      'chapterNumber': ch,
      'verseNumber': vs,
      'value': text,
    });
  }

  final outDir = Directory('assets/bibles/bsb');
  await outDir.create(recursive: true);
  for (final entry in books.entries) {
    final f = File('${outDir.path}/${entry.key}.json');
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(entry.value));
    print('  wrote ${entry.key}.json (${entry.value.length} verses)');
  }

  print('\nDone. ${books.length} books written.');
  print('Now flip BSB.available = true in lib/data/translations.dart and run flutter pub get.');
}
