class Verse {
  final int number;
  final String text;
  const Verse(this.number, this.text);
}

class Chapter {
  final int number;
  final List<Verse> verses;
  const Chapter(this.number, this.verses);
}

class BookInfo {
  final String name;
  final String file; // asset filename without extension
  final String testament; // 'OT' or 'NT'
  const BookInfo(this.name, this.file, this.testament);
}

class VerseRef {
  final String book;
  final int chapter;
  final int verse;
  const VerseRef(this.book, this.chapter, this.verse);

  String get id => '$book $chapter:$verse';

  static VerseRef? tryParse(String s) {
    final m = RegExp(r'^(.+) (\d+):(\d+)$').firstMatch(s);
    if (m == null) return null;
    return VerseRef(m.group(1)!, int.parse(m.group(2)!), int.parse(m.group(3)!));
  }
}
