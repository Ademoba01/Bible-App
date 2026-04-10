import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../state/providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 20 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_outline, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'No bookmarks yet',
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'While reading, tap any verse to bookmark it',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Start reading'),
                      onPressed: () => ref.read(tabIndexProvider.notifier).state = 1,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              itemCount: bookmarks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final id = bookmarks[i];
                final parsed = VerseRef.tryParse(id);
                return ListTile(
                  leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
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
                          ref.read(tabIndexProvider.notifier).state = 1;
                        },
                );
              },
            ),
    );
  }
}
