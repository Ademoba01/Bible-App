import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../state/providers.dart';
import 'books_screen.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(readingLocationProvider);
    final chaptersAsync = ref.watch(currentBookChaptersProvider);
    final settings = ref.watch(settingsProvider);
    final bookmarks = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () async {
            final picked = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const BooksScreen()),
            );
            if (picked != null) {
              ref.read(readingLocationProvider.notifier).setBook(picked);
            }
          },
          child: Text('${loc.book} ${loc.chapter}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(child: Text('No chapters found.'));
          }
          final maxChapter = chapters.length;
          final current = loc.chapter.clamp(1, maxChapter);
          final chapter = chapters[current - 1];

          return Column(
            children: [
              _ChapterBar(
                book: loc.book,
                chapter: current,
                max: maxChapter,
                onPick: (c) => ref.read(readingLocationProvider.notifier).setChapter(c),
                onPrev: () => ref.read(readingLocationProvider.notifier).prev(),
                onNext: () => ref.read(readingLocationProvider.notifier).next(maxChapter),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chapter.verses.length,
                  itemBuilder: (context, i) {
                    final v = chapter.verses[i];
                    final ref0 = VerseRef(loc.book, current, v.number).id;
                    final isMarked = bookmarks.contains(ref0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () => _showVerseSheet(context, ref, ref0, v),
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style.copyWith(
                                  fontSize: settings.fontSize,
                                  height: 1.55,
                                ),
                            children: [
                              TextSpan(
                                text: '${v.number}  ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                              TextSpan(text: v.text),
                              if (isMarked)
                                const WidgetSpan(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.bookmark, size: 16, color: Colors.brown),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVerseSheet(BuildContext context, WidgetRef ref, String refId, Verse v) {
    final isMarked = ref.read(bookmarksProvider).contains(refId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(refId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text(v.text, style: const TextStyle(fontSize: 17, height: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  icon: Icon(isMarked ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(isMarked ? 'Bookmarked' : 'Bookmark'),
                  onPressed: () {
                    ref.read(bookmarksProvider.notifier).toggle(refId);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterBar extends StatelessWidget {
  const _ChapterBar({
    required this.book,
    required this.chapter,
    required this.max,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
  });

  final String book;
  final int chapter;
  final int max;
  final ValueChanged<int> onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: chapter > 1 ? onPrev : null),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: () async {
                  final picked = await showModalBottomSheet<int>(
                    context: context,
                    builder: (_) => GridView.count(
                      crossAxisCount: 5,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (var c = 1; c <= max; c++)
                          InkWell(
                            onTap: () => Navigator.pop(context, c),
                            child: Card(
                              color: c == chapter ? Colors.brown[200] : null,
                              child: Center(child: Text('$c')),
                            ),
                          ),
                      ],
                    ),
                  );
                  if (picked != null) onPick(picked);
                },
                child: Text('$book — Chapter $chapter / $max',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: chapter < max ? onNext : null),
        ],
      ),
    );
  }
}
