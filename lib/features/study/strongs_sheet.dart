import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/strongs_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'strongs_occurrences_screen.dart';
import 'sermon_collections_screen.dart';

/// Opens a slide-up modal sheet showing the Hebrew/Greek lexicon entry for
/// a tapped English word.
///
/// The data comes from STEPBible's TBESG/TBESH (CC BY 4.0), via the
/// per-word Strong's tagging baked into `assets/data/strongs_kjv.json`.
/// Tapping a word in Scholar Mode (Reading screen) is the entry point.
///
/// The sheet is no longer a dead-end — it offers Save / Browse occurrences
/// / Add to sermon, plus an "explored N times" history pill on repeat
/// lookups.
Future<void> showStrongsSheet(
  BuildContext context, {
  required StrongsWord word,
  required StrongsEntry? entry,
  required int occurrences,
  String? sourceVerseRef,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BrandColors.warmWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _StrongsSheet(
      word: word,
      entry: entry,
      occurrences: occurrences,
      sourceVerseRef: sourceVerseRef,
    ),
  );
}

class _StrongsSheet extends ConsumerStatefulWidget {
  const _StrongsSheet({
    required this.word,
    required this.entry,
    required this.occurrences,
    required this.sourceVerseRef,
  });

  final StrongsWord word;
  final StrongsEntry? entry;
  final int occurrences;
  final String? sourceVerseRef;

  @override
  ConsumerState<_StrongsSheet> createState() => _StrongsSheetState();
}

class _StrongsSheetState extends ConsumerState<_StrongsSheet> {
  /// Strong's id we're showing — synthesized once from word/entry.
  late final String _strongsId =
      widget.word.strongs ?? widget.entry?.strongs ?? '';

  @override
  void initState() {
    super.initState();
    // Record this lookup in the personal lexicon. Deferred so the build
    // pass that opens this sheet doesn't write providers during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_strongsId.isNotEmpty) {
        ref.read(strongsHistoryProvider.notifier).record(
              _strongsId,
              widget.sourceVerseRef ?? '',
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final original = widget.entry?.original.isNotEmpty == true
        ? widget.entry!.original
        : (widget.word.original ?? '');
    final translit = widget.entry?.transliteration.isNotEmpty == true
        ? widget.entry!.transliteration
        : (widget.word.translit ?? '');
    final pos = widget.entry?.partOfSpeech ?? '';
    final definition = widget.entry?.definition ?? '';
    final isHebrew = _strongsId.startsWith('H');
    final testamentLabel = isHebrew ? 'OT' : 'NT';

    final saved = ref.watch(savedStrongsProvider).contains(_strongsId);
    final history = ref.watch(strongsHistoryProvider)[_strongsId];
    final hasHistory = history != null && history.count > 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B1E19) : BrandColors.parchment,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BrandColors.brownMid.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // ── English tap target ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, size: 18, color: BrandColors.goldDark),
                  const SizedBox(width: 8),
                  Text(
                    'You tapped',
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: BrandColors.brownMid,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '"${widget.word.word}"',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ── Original-language word ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Center(
                child: Text(
                  original.isEmpty ? '—' : original,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: isDark ? BrandColors.gold : BrandColors.brownDeep,
                  ),
                ),
              ),
            ),
            if (translit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    translit,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            // ── Strong's chip + part of speech + history ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_strongsId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: BrandColors.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: BrandColors.gold.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Strong\'s $_strongsId',
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: BrandColors.brownDeep,
                        ),
                      ),
                    ),
                  if (pos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: BrandColors.brownMid.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        pos,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.brown,
                        ),
                      ),
                    ),
                  if (hasHistory)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: BrandColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 12, color: BrandColors.brownMid),
                          const SizedBox(width: 4),
                          Text(
                            'Explored ${history.count}×',
                            style: GoogleFonts.lora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.brownMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Decorative gold divider ──
            Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    BrandColors.gold.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ── Action row — kills the dead-end ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: saved
                          ? Icons.bookmark_added
                          : Icons.bookmark_add_outlined,
                      label: saved ? 'Saved' : 'Save word',
                      highlight: saved,
                      onTap: () => ref
                          .read(savedStrongsProvider.notifier)
                          .toggle(_strongsId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.format_list_bulleted,
                      label: widget.occurrences > 0
                          ? 'Browse ${widget.occurrences}'
                          : 'No verses',
                      onTap: widget.occurrences == 0
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StrongsOccurrencesScreen(
                                    strongsId: _strongsId,
                                    original: original,
                                    transliteration: translit,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Add to sermon',
                      onTap: () => _addToSermon(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ── Definition ──
            if (definition.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(
                  definition,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    height: 1.55,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(
                  'Lexicon entry not available for $_strongsId.',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            // ── Occurrences chip — now tappable, opens the occurrences screen ──
            if (widget.occurrences > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StrongsOccurrencesScreen(
                              strongsId: _strongsId,
                              original: original,
                              transliteration: translit,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: BrandColors.brown.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag,
                                size: 14, color: BrandColors.brownMid),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.occurrences} ${widget.occurrences == 1 ? "occurrence" : "occurrences"} in $testamentLabel',
                              style: GoogleFonts.lora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.brownMid,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward,
                                size: 12, color: BrandColors.brownMid),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            // ── Footer attribution ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'STEPBible Tagged ${isHebrew ? "Hebrew OT" : "Greek NT"} — TBES${isHebrew ? "H" : "G"} (CC BY 4.0)',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  color: BrandColors.brownMid.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Add to sermon" — pick (or create) a collection, capture an optional
  /// note, then drop the insight into [sermonCollectionsProvider].
  Future<void> _addToSermon(BuildContext context) async {
    final collections = ref.read(sermonCollectionsProvider);
    String? collectionId;

    if (collections.isEmpty) {
      // No collections yet — let the user create the first one inline.
      final created = await _promptNewCollection(context);
      if (created == null) return;
      collectionId = created;
    } else {
      // Show a picker (collections + "+ New series").
      collectionId = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add to series',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              ...collections.map((c) => ListTile(
                    leading: Icon(Icons.menu_book_rounded,
                        color: BrandColors.brownDeep),
                    title: Text(c.title),
                    subtitle: Text(
                        '${c.insights.length} ${c.insights.length == 1 ? "insight" : "insights"}'),
                    onTap: () => Navigator.pop(sheetCtx, c.id),
                  )),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New series…'),
                onTap: () async {
                  final id = await _promptNewCollection(context);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx, id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    if (collectionId == null || !mounted) return;

    // Optional note capture — keep it lightweight (one TextField).
    final note = await _promptNote(context);
    if (note == null) return; // cancelled

    final insight = SermonInsight(
      strongsId: _strongsId,
      verseRef: widget.sourceVerseRef ?? '',
      word: widget.word.word,
      note: note,
      createdAt: DateTime.now(),
    );
    await ref
        .read(sermonCollectionsProvider.notifier)
        .addInsight(collectionId, insight);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Insight added to sermon notes'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _promptNewCollection(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New sermon series'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. "Series on Love"',
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return null;
    final c = await ref
        .read(sermonCollectionsProvider.notifier)
        .createCollection(title);
    return c.id;
  }

  Future<String?> _promptNote(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Why this word? (optional)',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }
}

/// Compact action button used in the sheet's "Save / Browse / Sermon" row.
/// Keeps tap-target ≥44px (WCAG 2.5.8) without dominating the sheet.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    return Material(
      color: highlight
          ? BrandColors.gold.withValues(alpha: 0.18)
          : theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: disabled ? 0.4 : 1.0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: disabled
                      ? theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)
                      : BrandColors.brownDeep),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)
                      : BrandColors.brownDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
