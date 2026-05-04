import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/chronologies_service.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../../widgets/rhema_title.dart';

/// Landing screen for ALL biblical chronologies — patriarchs, kings,
/// pharaohs, Persian/Babylonian/Assyrian rulers, Roman emperors, the
/// Herodian dynasty, high priests, the Twelve Apostles. One scrollable
/// list of cards; tap one to see its full vertical timeline.
///
/// Complements the existing Bible-eras screen (chronology_screen.dart):
/// that one walks history by ERA (Patriarchs → Exodus → Kingdom →
/// Exile → New Testament). This one walks the FAMILY TREES + KING LISTS
/// inside each era. Both surface the same biblical timeline, indexed
/// by different cuts.
class BibleChronologiesScreen extends ConsumerWidget {
  const BibleChronologiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final svc = ref.watch(chronologiesServiceProvider);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        centerTitle: true,
        title: const RhemaTitle(),
      ),
      body: !svc.isReady
          ? FutureBuilder<void>(
              future: svc.init(),
              builder: (_, snap) => snap.connectionState ==
                      ConnectionState.done
                  ? _buildList(context, svc.all)
                  : const Center(child: CircularProgressIndicator()),
            )
          : _buildList(context, svc.all),
    );
  }

  Widget _buildList(BuildContext context, List<Chronology> all) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bible Chronologies',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.brownDeep,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Every named lineage and king list in Scripture — '
                  'patriarchs, kings of Israel and Judah, pharaohs, '
                  'Persian and Babylonian rulers, the Herodian dynasty, '
                  'Roman emperors, high priests, and the Twelve Apostles. '
                  'Tap any chronology to see the full timeline with '
                  'verse links.',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    height: 1.5,
                    color: BrandColors.brownMid,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _ChronologyCard(chronology: all[i]),
          ),
        ),
      ],
    );
  }
}

class _ChronologyCard extends StatelessWidget {
  const _ChronologyCard({required this.chronology});
  final Chronology chronology;

  @override
  Widget build(BuildContext context) {
    final color = Color(chronology.color);
    return Material(
      color: BrandColors.warmWhite,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChronologyDetailScreen(chronology: chronology),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(chronology.icon),
                    color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chronology.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brownDeep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chronology.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: BrandColors.brownMid,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${chronology.entries.length} entries  ·  ${chronology.source}',
                        style: GoogleFonts.lora(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.brownDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: BrandColors.brownMid),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String name) {
  switch (name) {
    case 'crown':
      return Icons.workspace_premium;
    case 'shield':
      return Icons.shield;
    case 'pyramid':
      return Icons.change_history;
    case 'dove':
      return Icons.flutter_dash;
    case 'cross':
      return Icons.add;
    case 'scroll':
    default:
      return Icons.menu_book_rounded;
  }
}

// ───────────────────────────────────────────────────────────────────
// DETAIL SCREEN
// ───────────────────────────────────────────────────────────────────

/// Vertical timeline for a single chronology — each entry rendered as a
/// card with name, alias, dates/regnal/age, notes, and tappable verse
/// references that deep-link into the Read tab.
class ChronologyDetailScreen extends ConsumerWidget {
  const ChronologyDetailScreen({super.key, required this.chronology});
  final Chronology chronology;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = Color(chronology.color);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        title: Text(
          chronology.title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: chronology.entries.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _DetailHeader(chronology: chronology, color: color);
          }
          final entry = chronology.entries[i - 1];
          final isLast = i == chronology.entries.length;
          return _EntryRow(
            entry: entry,
            color: color,
            isLast: isLast,
            onOpenRef: (ref0) => _openVerse(context, ref, ref0),
          );
        },
      ),
    );
  }

  void _openVerse(BuildContext context, WidgetRef ref, String refStr) {
    final parsed = VerseRef.tryParse(refStr);
    if (parsed == null) {
      // Fall back to the first verse of a chapter range like "Genesis 5:3-5"
      final compactMatch = RegExp(r'^([1-3]?\s*[A-Za-z ]+)\s+(\d+):(\d+)')
          .firstMatch(refStr);
      if (compactMatch != null) {
        final book = compactMatch.group(1)!.trim();
        final chapter = int.tryParse(compactMatch.group(2)!) ?? 1;
        final verse = int.tryParse(compactMatch.group(3)!) ?? 1;
        ref.read(readingLocationProvider.notifier).setBook(book);
        ref.read(readingLocationProvider.notifier).setChapter(chapter);
        ref.read(highlightVerseProvider.notifier).state = verse;
        ref.read(tabIndexProvider.notifier).set(1);
        Navigator.of(context).popUntil((route) => route.isFirst);
        HapticFeedback.lightImpact();
      }
      return;
    }
    ref.read(readingLocationProvider.notifier).setBook(parsed.book);
    ref.read(readingLocationProvider.notifier).setChapter(parsed.chapter);
    ref.read(highlightVerseProvider.notifier).state = parsed.verse;
    ref.read(tabIndexProvider.notifier).set(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
    HapticFeedback.lightImpact();
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.chronology, required this.color});
  final Chronology chronology;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(chronology.icon), color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chronology.subtitle,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.brownDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Source: ${chronology.source}',
              style: GoogleFonts.lora(
                fontSize: 11,
                color: BrandColors.brownMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.color,
    required this.isLast,
    required this.onOpenRef,
  });

  final ChronologyEntry entry;
  final Color color;
  final bool isLast;
  final ValueChanged<String> onOpenRef;

  @override
  Widget build(BuildContext context) {
    final stats = <String>[];
    if (entry.dates != null) stats.add(entry.dates!);
    if (entry.regnal != null) {
      stats.add('${entry.regnal} ${entry.regnal == 1 ? "yr" : "yrs"} reigned');
    }
    if (entry.ageAtFathering != null) {
      stats.add('age ${entry.ageAtFathering} at fathering');
    }
    if (entry.lifespan != null) {
      stats.add('lived ${entry.lifespan} yrs');
    }

    final allRefs = <String>[entry.verseRef, ...entry.refs];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline rail (dot + connector line) ──
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BrandColors.warmWhite,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Card ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BrandColors.warmWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brownDeep,
                      ),
                    ),
                    if (entry.alias != null && entry.alias!.isNotEmpty)
                      Text(
                        entry.alias!,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: BrandColors.brownMid,
                        ),
                      ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: stats
                            .map((s) => _Stat(text: s, color: color))
                            .toList(),
                      ),
                    ],
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.notes!,
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          height: 1.45,
                          color: BrandColors.brownDeep,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: allRefs
                          .where((r) => r.isNotEmpty && r != '—')
                          .map(
                            (r) => _VerseRefChip(
                              refStr: r,
                              onTap: () => onOpenRef(r),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Verse-reference chip with "open in new tab" affordance on web.
///
/// Standard tap → in-app deep link (existing behavior).
/// Web only: a small `↗` icon next to the chip → builds the canonical
/// URL `https://rhemabibles.com/?book=X&chapter=Y&verse=Z` and opens
/// it in a new tab. The new tab is genuinely useful — main.dart's
/// `_applyDeepLinkFromUrl` parses those query params on boot and
/// applies them to the providers, so the new tab loads on the right
/// verse instead of the home screen.
class _VerseRefChip extends StatelessWidget {
  const _VerseRefChip({required this.refStr, required this.onTap});

  final String refStr;
  final VoidCallback onTap;

  String? _verseUrl() {
    final m = RegExp(r'^([1-3]?\s*[A-Za-z ]+?)\s+(\d+):(\d+)')
        .firstMatch(refStr.trim());
    if (m == null) return null;
    final book = Uri.encodeComponent(m.group(1)!.trim());
    final chapter = m.group(2)!;
    final verse = m.group(3)!;
    return 'https://rhemabibles.com/?book=$book&chapter=$chapter&verse=$verse';
  }

  Future<void> _openInNewTab() async {
    final url = _verseUrl();
    if (url == null) return;
    final uri = Uri.parse(url);
    // webOnlyWindowName='_blank' tells the browser to open a new tab.
    // On native this parameter is ignored, but the kIsWeb guard at the
    // call site means this path is web-only anyway.
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BrandColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book,
              size: 11, color: BrandColors.brownDeep),
          const SizedBox(width: 4),
          Text(
            refStr,
            style: GoogleFonts.lora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandColors.brownDeep,
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Open in new tab',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openInNewTab,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.open_in_new,
                        size: 11, color: BrandColors.brownDeep),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: chip,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.lora(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: BrandColors.brownDeep,
        ),
      ),
    );
  }
}
