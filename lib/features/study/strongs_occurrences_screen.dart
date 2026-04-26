import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/strongs_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Lists every verse in the tagged corpus that contains a given Strong's
/// number. Reachable from the Strong's bottom sheet via the "Browse N
/// verses" button — the inverse of the "tap a word to see its lookup" flow.
///
/// Tapping a row sets [readingLocationProvider] + [highlightVerseProvider]
/// and pops back to the root, so the user lands on Reading with the verse
/// flashing gold. Same deep-link pattern as ReadingPlanScreen.
class StrongsOccurrencesScreen extends ConsumerWidget {
  const StrongsOccurrencesScreen({
    super.key,
    required this.strongsId,
    required this.original,
    required this.transliteration,
  });

  /// Canonical Strong's id (e.g. "G3056").
  final String strongsId;

  /// Original-language form, shown in the title for context.
  final String original;
  final String transliteration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final svc = ref.watch(strongsServiceProvider);
    // versesContaining is synchronous-but-lazy. The first call on a given
    // Strong's id can take ~1s while the inverse index is built; subsequent
    // calls are instant.
    final occurrences = svc.versesContaining(strongsId);
    // Group by book → preserves canonical reading order while letting us
    // render a sticky-ish "Genesis (4)" header per group.
    final grouped = <String, List<VerseRefWithWord>>{};
    for (final v in occurrences) {
      grouped.putIfAbsent(v.book, () => []).add(v);
    }
    final books = grouped.keys.toList();
    final isHebrew = strongsId.startsWith('H');

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              original.isEmpty ? strongsId : original,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (transliteration.isNotEmpty)
              Text(
                '$transliteration  ·  ${occurrences.length} ${occurrences.length == 1 ? 'verse' : 'verses'} in ${isHebrew ? 'OT' : 'NT'}',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        centerTitle: false,
      ),
      body: occurrences.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No tagged occurrences found.\n(Strong’s data is still loading or this id is missing.)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: books.length,
              itemBuilder: (context, bookIdx) {
                final book = books[bookIdx];
                final verses = grouped[book]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 18, 20, 6),
                      child: Row(
                        children: [
                          Text(
                            book,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: BrandColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${verses.length}',
                              style: GoogleFonts.lora(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: BrandColors.brownDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...verses.map((v) => _OccurrenceRow(
                          ref: ref,
                          verse: v,
                          theme: theme,
                        )),
                  ],
                );
              },
            ),
    );
  }
}

class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({
    required this.ref,
    required this.verse,
    required this.theme,
  });

  final WidgetRef ref;
  final VerseRefWithWord verse;
  final ThemeData theme;

  void _open(BuildContext context) {
    // Same deep-link pattern as reading_plan_screen.dart:141
    ref.read(readingLocationProvider.notifier).setBook(verse.book);
    ref.read(readingLocationProvider.notifier).setChapter(verse.chapter);
    ref.read(highlightVerseProvider.notifier).state = verse.verse;
    ref.read(tabIndexProvider.notifier).set(1); // Read tab
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                '${verse.chapter}:${verse.verse}',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '“${verse.word}”',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
