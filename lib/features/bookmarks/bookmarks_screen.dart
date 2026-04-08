import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: bookmarks.isEmpty
          ? const Center(child: Text('No bookmarks yet.\nTap a verse to save it.', textAlign: TextAlign.center))
          : ListView.separated(
              itemCount: bookmarks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final id = bookmarks[i];
                final parsed = VerseRef.tryParse(id);
                return ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.brown),
                  title: Text(id),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(bookmarksProvider.notifier).toggle(id),
                  ),
                  onTap: parsed == null
                      ? null
                      : () {
                          ref.read(readingLocationProvider.notifier).setBook(parsed.book);
                          ref.read(readingLocationProvider.notifier).setChapter(parsed.chapter);
                          ref.read(tabIndexProvider.notifier).state = 0;
                        },
                );
              },
            ),
    );
  }
}
