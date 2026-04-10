import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models.dart';
import '../../../state/providers.dart';
import '../../../theme.dart';
import '../../search/similar_verses_screen.dart';
import '../../study/chapter_quiz_screen.dart';
import 'books_screen.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(readingLocationProvider);
    final chaptersAsync = ref.watch(currentBookChaptersProvider);
    final fontSize = ref.watch(settingsProvider.select((s) => s.fontSize));
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
          onPressed: () async {
            final picked = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const BooksScreen()),
            );
            if (picked != null) {
              ref.read(readingLocationProvider.notifier).setBook(picked);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${loc.book} ${loc.chapter}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 22),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
            tooltip: 'Quiz me on this chapter',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterQuizScreen(
                    book: loc.book,
                    chapter: loc.chapter,
                  ),
                ),
              );
            },
          ),
        ],
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
              // Decorative divider with gold accent
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      BrandColors.gold.withValues(alpha: 0.4),
                      BrandColors.gold.withValues(alpha: 0.6),
                      BrandColors.gold.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
              Expanded(
                // ── Swipe left/right to change chapters ──
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity! < -300 && current < maxChapter) {
                      // Swipe left → next chapter
                      ref.read(readingLocationProvider.notifier).next(maxChapter);
                    } else if (details.primaryVelocity! > 300 && current > 1) {
                      // Swipe right → previous chapter
                      ref.read(readingLocationProvider.notifier).prev();
                    }
                  },
                  child: _VerseList(
                    chapter: chapters[current - 1],
                    book: loc.book,
                    chapterNum: current,
                    fontSize: fontSize,
                    bookmarks: bookmarks,
                    ref: ref,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerseList extends StatelessWidget {
  const _VerseList({
    required this.chapter,
    required this.book,
    required this.chapterNum,
    required this.fontSize,
    required this.bookmarks,
    required this.ref,
  });

  final Chapter chapter;
  final String book;
  final int chapterNum;
  final double fontSize;
  final List<String> bookmarks;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlights = ref.watch(highlightsProvider);
    return Container(
      color: isDark ? null : BrandColors.parchment,
      child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      itemCount: chapter.verses.length,
      itemBuilder: (context, i) {
        final v = chapter.verses[i];
        final ref0 = VerseRef(book, chapterNum, v.number).id;
        final isMarked = bookmarks.contains(ref0);
        final highlightColorIndex = highlights[ref0];

        // Drop cap for the first verse
        if (i == 0 && v.text.isNotEmpty) {
          final firstLetter = v.text[0];
          final restOfText = v.text.length > 1 ? v.text.substring(1) : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              decoration: highlightColorIndex != null
                  ? BoxDecoration(
                      color: HighlightsNotifier.colors[highlightColorIndex]
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              padding: highlightColorIndex != null
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : EdgeInsets.zero,
              child: InkWell(
                onTap: () => _showVerseSheet(context, ref0, v, theme),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${v.number} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: fontSize,
                        ),
                      ),
                      TextSpan(
                        text: firstLetter,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: fontSize * 2.5,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.gold,
                          height: 0.85,
                        ),
                      ),
                      TextSpan(
                        text: restOfText,
                        style: GoogleFonts.lora(
                          fontSize: fontSize,
                          height: 1.7,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isMarked)
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.bookmark, size: 16, color: theme.colorScheme.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            decoration: highlightColorIndex != null
                ? BoxDecoration(
                    color: HighlightsNotifier.colors[highlightColorIndex]
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            padding: highlightColorIndex != null
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                : EdgeInsets.zero,
            child: InkWell(
              onTap: () => _showVerseSheet(context, ref0, v, theme),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: fontSize,
                        height: 1.55,
                      ),
                  children: [
                    TextSpan(
                      text: '${v.number}  ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextSpan(text: v.text),
                    if (isMarked)
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.bookmark, size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
    );
  }

  void _showVerseSheet(BuildContext context, String refId, Verse v, ThemeData theme) {
    final isMarked = ref.read(bookmarksProvider).contains(refId);
    final parsedRef = VerseRef.tryParse(refId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(refId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text(v.text, style: const TextStyle(fontSize: 17, height: 1.5)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$refId\n${v.text}'));
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verse copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.share, color: theme.colorScheme.primary),
                  label: const Text('Share'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Share.share('$refId\n${v.text}\n\n— Our Bible App');
                  },
                ),
                TextButton.icon(
                  icon: Icon(isMarked ? Icons.bookmark : Icons.bookmark_border,
                      color: theme.colorScheme.primary),
                  label: Text(isMarked ? 'Bookmarked' : 'Bookmark'),
                  onPressed: () {
                    ref.read(bookmarksProvider.notifier).toggle(refId);
                    Navigator.pop(sheetContext);
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
                  label: const Text('Find similar'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    if (parsedRef != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SimilarVersesScreen(
                            sourceRef: parsedRef,
                            sourceText: v.text,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Highlight color picker
            Row(
              children: [
                Text('Highlight:',
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 12),
                ...List.generate(HighlightsNotifier.colors.length, (i) {
                  final isSelected =
                      ref.read(highlightsProvider)[refId] == i;
                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        ref
                            .read(highlightsProvider.notifier)
                            .removeHighlight(refId);
                      } else {
                        ref
                            .read(highlightsProvider.notifier)
                            .highlight(refId, i);
                      }
                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: HighlightsNotifier.colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              size: 16, color: theme.colorScheme.primary)
                          : null,
                    ),
                  );
                }),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous chapter',
            onPressed: chapter > 1 ? onPrev : null,
          ),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: () async {
                  final picked = await showModalBottomSheet<int>(
                    context: context,
                    builder: (_) => GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width < 400 ? 4 : MediaQuery.of(context).size.width < 600 ? 5 : 7,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (var c = 1; c <= max; c++)
                          InkWell(
                            onTap: () => Navigator.pop(context, c),
                            child: Card(
                              color: c == chapter
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              elevation: c == chapter ? 2 : 0,
                              child: Center(
                                child: Text('$c',
                                    style: TextStyle(
                                      fontWeight: c == chapter ? FontWeight.bold : FontWeight.normal,
                                      color: c == chapter
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    )),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                  if (picked != null) onPick(picked);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Chapter $chapter / $max',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.grid_view, size: 16),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next chapter',
            onPressed: chapter < max ? onNext : null,
          ),
        ],
      ),
    );
  }
}
