// ignore_for_file: avoid_print
/// Downloads KJV from aruljohn/Bible-kjv on GitHub and converts to our format.
///
/// Usage: dart run tools/fetch_kjv.dart
///
/// Output: assets/bibles/kjv/<bookfile>.json for all 66 books.
import 'dart:convert';
import 'dart:io';

/// Book name in the GitHub repo → our asset filename
const _bookMap = <String, String>{
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
  'Psalms': 'psalms',
  'Proverbs': 'proverbs',
  'Ecclesiastes': 'ecclesiastes',
  'Song of Solomon': 'songofsolomon',
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

/// The repo uses PascalCase filenames with no spaces: "1Peter", "SongofSolomon"
String _repoFilename(String bookName) {
  return bookName.replaceAll(' ', '');
}

Future<void> main() async {
  final outDir = Directory('assets/bibles/kjv');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final client = HttpClient();
  var count = 0;

  for (final entry in _bookMap.entries) {
    final bookName = entry.key;
    final assetFile = entry.value;
    final url =
        'https://raw.githubusercontent.com/aruljohn/Bible-kjv/master/${_repoFilename(bookName)}.json';

    print('[$count/66] Fetching $bookName ...');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        print('  ⚠ HTTP ${response.statusCode} for $bookName');
        await response.drain();
        continue;
      }
      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body);

      // Format: {"book":"...","chapters":[{"chapter":"1","verses":[{"verse":"1","text":"..."}]}]}
      final List<Map<String, dynamic>> flat = [];

      if (data is Map && data.containsKey('chapters')) {
        final chapters = data['chapters'] as List;
        for (final ch in chapters) {
          final chNum = int.tryParse(ch['chapter'].toString()) ?? 0;
          final verses = ch['verses'] as List? ?? [];
          for (final v in verses) {
            final vNum = int.tryParse(v['verse'].toString()) ?? 0;
            flat.add({
              'type': 'paragraph text',
              'chapterNumber': chNum,
              'verseNumber': vNum,
              'value': v['text'] ?? '',
            });
          }
        }
      } else if (data is List) {
        for (final verse in data) {
          flat.add({
            'type': 'paragraph text',
            'chapterNumber': int.tryParse(verse['chapter']?.toString() ?? '') ?? verse['chapterNumber'] ?? 0,
            'verseNumber': int.tryParse(verse['verse']?.toString() ?? '') ?? verse['verseNumber'] ?? 0,
            'value': verse['text'] ?? verse['value'] ?? '',
          });
        }
      }

      final outFile = File('${outDir.path}/$assetFile.json');
      outFile.writeAsStringSync(
        const JsonEncoder().convert(flat),
      );
      count++;
      print('  ✓ ${flat.length} verses → $assetFile.json');
    } catch (e) {
      print('  ✗ Error: $e');
    }
  }

  client.close();
  print('\nDone! $count/66 books written to ${outDir.path}/');
  print('Add to pubspec.yaml assets if not already:\n  - assets/bibles/kjv/');
}
