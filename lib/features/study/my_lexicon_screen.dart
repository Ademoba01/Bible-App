import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/strongs_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'strongs_sheet.dart';
import 'strongs_occurrences_screen.dart';

/// Personal lexicon — every Greek/Hebrew word the user has ever opened in
/// the Strong's sheet, displayed as a wall of original-language tiles
/// sized by frequency-of-lookup. Tapping a tile re-opens the lexicon
/// sheet for that word so the user can pick up where they left off.
///
/// Adds a "Word streak" counter — consecutive days with at least one
/// lookup — borrowing the engagement loop from the existing reading streak.
class MyLexiconScreen extends ConsumerWidget {
  const MyLexiconScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(strongsHistoryProvider);
    final saved = ref.watch(savedStrongsProvider);
    final streak = ref.watch(wordStreakProvider);
    final svc = ref.watch(strongsServiceProvider);

    // Sort entries: saved-first, then by lookup count desc, then by last seen.
    final entries = history.values.toList()
      ..sort((a, b) {
        final aSaved = saved.contains(a.strongsId) ? 1 : 0;
        final bSaved = saved.contains(b.strongsId) ? 1 : 0;
        if (aSaved != bSaved) return bSaved - aSaved;
        if (b.count != a.count) return b.count - a.count;
        return b.lastSeen.compareTo(a.lastSeen);
      });

    // Frequency scale: max count drives tile font sizing.
    final maxCount = entries.isEmpty
        ? 1
        : entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        title: Text(
          'My Lexicon',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Reset lexicon',
              onPressed: () => _confirmReset(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Streak banner ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: _StreakBanner(streak: streak, totalWords: entries.length),
          ),
          if (entries.isEmpty)
            Expanded(child: _EmptyState(theme: theme))
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final lex = svc.lookupStrong(entry.strongsId);
                  return _LexiconTile(
                    entry: entry,
                    lexEntry: lex,
                    isSaved: saved.contains(entry.strongsId),
                    weight: maxCount == 0 ? 0 : entry.count / maxCount,
                    onTap: () async {
                      if (lex == null) return;
                      // Reuse the same Strong's sheet from the reading flow.
                      // We don't have a StrongsWord here, so synthesize a
                      // minimal one with the lex's surface form.
                      await showStrongsSheet(
                        context,
                        word: StrongsWord(
                          word: lex.original.isEmpty
                              ? entry.strongsId
                              : lex.original,
                          strongs: entry.strongsId,
                          original: lex.original,
                          translit: lex.transliteration,
                        ),
                        entry: lex,
                        occurrences: svc.occurrencesOf(entry.strongsId),
                      );
                    },
                    onBrowse: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StrongsOccurrencesScreen(
                            strongsId: entry.strongsId,
                            original: lex?.original ?? '',
                            transliteration: lex?.transliteration ?? '',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset lexicon?'),
        content: const Text(
            'Removes every word from your lexicon and resets your word streak. Your saved words are also cleared.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(strongsHistoryProvider.notifier).clear();
    }
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak, required this.totalWords});
  final int streak;
  final int totalWords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColors.goldLight, BrandColors.gold],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department,
                color: Color(0xFF3E2723), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0
                      ? 'Start your word streak'
                      : '$streak-day word streak',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3E2723),
                  ),
                ),
                Text(
                  totalWords == 0
                      ? 'Tap any word in a verse to begin'
                      : '$totalWords ${totalWords == 1 ? 'word' : 'words'} explored',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.bookmark_added,
              color: Colors.white.withValues(alpha: 0.7),
              size: 18),
        ],
      ),
    );
  }
}

class _LexiconTile extends StatelessWidget {
  const _LexiconTile({
    required this.entry,
    required this.lexEntry,
    required this.isSaved,
    required this.weight,
    required this.onTap,
    required this.onBrowse,
  });

  final StrongsHistoryEntry entry;
  final StrongsEntry? lexEntry;
  final bool isSaved;
  final double weight; // 0..1
  final VoidCallback onTap;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHebrew = entry.strongsId.startsWith('H');
    // Tile size scales with frequency — most-tapped words stand out.
    final fontSize = 20 + (weight * 16);
    return Material(
      color: isHebrew
          ? BrandColors.brown.withValues(alpha: 0.06)
          : BrandColors.gold.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onBrowse,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSaved
                  ? BrandColors.gold
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lexEntry?.original.isNotEmpty == true
                    ? lexEntry!.original
                    : entry.strongsId,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lexEntry?.transliteration ?? entry.strongsId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.count}×',
                style: GoogleFonts.lora(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.goldDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Your lexicon is empty',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a verse, tap any word, and the original Greek or Hebrew shows up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
