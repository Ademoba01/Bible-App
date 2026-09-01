import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../data/translations.dart';
import '../../services/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../cross_references/cross_references_sheet.dart';
import '../share/verse_card_renderer.dart';
import '../study/my_lexicon_screen.dart';

/// Shows verses similar to a given source verse, ranked by relevance.
class SimilarVersesScreen extends ConsumerStatefulWidget {
  const SimilarVersesScreen({
    super.key,
    required this.sourceRef,
    required this.sourceText,
  });

  final VerseRef sourceRef;
  final String sourceText;

  @override
  ConsumerState<SimilarVersesScreen> createState() => _SimilarVersesScreenState();
}

class _SimilarVersesScreenState extends ConsumerState<SimilarVersesScreen> {
  List<({VerseRef ref, String text, double score, String? reason})>? _results;
  bool _loading = true;
  bool _isAiPowered = false;

  @override
  void initState() {
    super.initState();
    _loadSimilar();
  }

  Future<void> _loadSimilar() async {
    final settings = ref.read(settingsProvider);

    // Try AI-powered search first
    if (settings.useOnlineAi) {
      try {
        final aiResults = await AiService.findSimilarVerses(
          widget.sourceText,
          widget.sourceRef.id,
        );
        if (aiResults.isNotEmpty && mounted) {
          setState(() {
            _isAiPowered = true;
            _results = aiResults.map((r) {
              final parsed = VerseRef.tryParse(r.reference);
              return (
                ref: parsed ?? VerseRef(r.reference, 1, 1),
                text: r.text,
                score: 10.0, // AI results don't have numeric scores
                reason: r.reason,
              );
            }).toList();
            _loading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('AI similar verses failed, falling back to offline: $e');
      }
    }

    // Offline fallback
    final repo = ref.read(bibleRepositoryProvider);
    final tid = settings.translation;
    final results = await repo.findSimilar(
      widget.sourceText,
      sourceRef: widget.sourceRef,
      translationId: tid,
      limit: 25,
    );
    if (!mounted) return;
    setState(() {
      _isAiPowered = false;
      _results = results
          .map((r) => (ref: r.ref, text: r.text, score: r.score, reason: null as String?))
          .toList();
      _loading = false;
    });
  }

  void _showVersePreview(BuildContext context, VerseRef verseRef, String text) {
    // Full verse-action sheet — matches the actions available when
    // tapping a verse on the Read tab so users can Copy / Share /
    // Bookmark / open Original language / see Cross-refs / recurse
    // Find similar WITHOUT leaving the Similar Verses screen. Was
    // previously a single "Read full chapter" button, which forced
    // users off-screen just to copy.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _SimilarVerseActionSheet(
        parentRef: ref,
        verseRef: verseRef,
        text: text,
        sourceRef: widget.sourceRef,
        sourceText: widget.sourceText,
      ),
    );
  }

  /// Navigate to the source verse in the Read tab. Used by the
  /// "Back to source" tap on the gold source-verse card at the top
  /// (user feedback: the headline should take you back to the
  /// initial search).
  void _backToSource() {
    ref.read(readingLocationProvider.notifier).setBook(widget.sourceRef.book);
    ref
        .read(readingLocationProvider.notifier)
        .setChapter(widget.sourceRef.chapter);
    ref.read(highlightVerseProvider.notifier).state = widget.sourceRef.verse;
    ref.read(tabIndexProvider.notifier).set(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Open the translation picker sheet — reuses the same A/B layout
  /// pattern as the chapter bar's translation switcher. Switching
  /// translation re-fetches similar verses in the new language so
  /// users can compare KJV ↔ Yoruba ↔ BSB on the same passage.
  Future<void> _pickTranslation() async {
    final theme = Theme.of(context);
    final current = ref.read(settingsProvider).translation;
    final available = kTranslations.where((t) => t.available).toList();
    final local = available.where((t) => t.isLocal).toList();
    final online = available.where((t) => !t.isLocal).toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        Widget tile(Translation t) {
          final isCurrent = t.id == current;
          return ListTile(
            leading: Icon(
              isCurrent ? Icons.check_circle : Icons.menu_book_rounded,
              color:
                  isCurrent ? BrandColors.gold : BrandColors.brownMid,
            ),
            title: Text(t.name,
                style: GoogleFonts.lora(
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500)),
            subtitle: Text(
              t.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(fontSize: 12),
            ),
            trailing: t.isLocal
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Offline',
                        style: GoogleFonts.lora(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.brownDeep,
                        )))
                : null,
            onTap: () => Navigator.pop(sheetCtx, t.id),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Switch translation',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Re-runs the similar-verses search in the chosen translation. Useful for KJV ↔ Yoruba ↔ BSB study.',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (local.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text('Offline',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brownMid,
                      )),
                ),
                ...local.map(tile),
              ],
              if (online.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text('Online',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brownMid,
                      )),
                ),
                ...online.map(tile),
              ],
            ],
          ),
        );
      },
    );

    if (picked != null && picked != current && mounted) {
      await ref.read(settingsProvider.notifier).setTranslation(picked);
      // Re-fetch similar verses in the new translation. Wipe results
      // first so the user sees the loading state and knows the change
      // took effect.
      setState(() {
        _results = null;
        _loading = true;
      });
      await _loadSimilar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translationId =
        ref.watch(settingsProvider.select((s) => s.translation));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Similar Verses'),
        actions: [
          // Translation chip (same look as the chapter bar's chip in
          // Reading screen) — tap opens the picker, switching re-runs
          // the search in the new translation.
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: _pickTranslation,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BrandColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: BrandColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 13, color: BrandColors.brownDeep),
                      const SizedBox(width: 4),
                      Text(
                        translationById(translationId).name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: BrandColors.brownDeep,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.unfold_more,
                          size: 14, color: BrandColors.brownDeep),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Source verse card — now tappable ──
          // User feedback: "the similar verses headline should be
          // clickable to take us back to the initial search". This
          // gold card is the headline + source — tap navigates to
          // that verse in the Read tab with the highlight pulse.
          // Tooltip on hover (web) explains.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _backToSource,
                borderRadius: BorderRadius.circular(16),
                child: Tooltip(
                  message: 'Open ${widget.sourceRef.id} in Read',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.4),
                      border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote,
                                size: 18,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              widget.sourceRef.id,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                              ),
                              child: Text('TAP TO OPEN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 1,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.sourceText,
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.arrow_back,
                                size: 12,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Back to source verse',
                              style: GoogleFonts.lora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Results header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loading
                        ? 'Finding similar verses...'
                        : '${_results?.length ?? 0} similar verses found',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (!_loading && _isAiPowered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: BrandColors.gold.withValues(alpha: 0.15),
                      border: Border.all(color: BrandColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: BrandColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          'AI-powered',
                          style: GoogleFonts.lora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_results == null || _results!.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text('No similar verses found',
                                  style: GoogleFonts.lora(fontSize: 16)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _results!.length,
                        itemBuilder: (context, i) {
                          final r = _results![i];
                          return _SimilarVerseCard(
                            verseRef: r.ref,
                            text: r.text,
                            score: r.score,
                            rank: i + 1,
                            reason: r.reason,
                            isAiPowered: _isAiPowered,
                            onTap: () => _showVersePreview(context, r.ref, r.text),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SimilarVerseCard extends StatelessWidget {
  const _SimilarVerseCard({
    required this.verseRef,
    required this.text,
    required this.score,
    required this.rank,
    required this.onTap,
    this.reason,
    this.isAiPowered = false,
  });

  final VerseRef verseRef;
  final String text;
  final double score;
  final int rank;
  final VoidCallback onTap;
  final String? reason;
  final bool isAiPowered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Score bar: normalize to 0-1 (scores typically range 2-15)
    final normalizedScore = isAiPowered ? 1.0 : (score / 12).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rank <= 3
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    verseRef.id,
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (!isAiPowered) ...[
                    // Relevance indicator (offline mode only)
                    SizedBox(
                      width: 50,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: normalizedScore,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.arrow_forward_ios, size: 14,
                      color: theme.colorScheme.outline),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: BrandColors.gold.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14, color: BrandColors.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason!,
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full verse-action sheet reachable by tapping any similar-verses
/// row. Mirrors the actions in reading_screen.dart's verse modal:
/// gold primary CTA for Original Language, then Copy / Share /
/// Bookmark / Find similar / Cross-references / Highlight, plus
/// "Read full chapter" for jumping to context.
///
/// Keeps the sheet self-contained so the user copies inline —
/// they never have to leave the Similar Verses screen just to
/// grab a citation.
class _SimilarVerseActionSheet extends ConsumerWidget {
  const _SimilarVerseActionSheet({
    required this.parentRef,
    required this.verseRef,
    required this.text,
    required this.sourceRef,
    required this.sourceText,
  });

  /// The parent ConsumerState's ref — the sheet builds via ref.watch
  /// too, but we pass this so we can write providers even after the
  /// sheet is popped (e.g. after deep-linking to Read).
  final WidgetRef parentRef;
  final VerseRef verseRef;
  final String text;

  /// Preserved so tapping "Read full chapter" can populate
  /// similarVersesReturnProvider and the Read-tab back-chip works.
  final VerseRef sourceRef;
  final String sourceText;

  String _formattedCopy(String versionName) =>
      '${verseRef.id} ($versionName)\n$text\n\n— Rhema Study Bible\nhttps://rhemabibles.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarks = ref.watch(bookmarksProvider);
    final highlights = ref.watch(highlightsProvider);
    final isBookmarked = bookmarks.contains(verseRef.id);
    final activeHighlight = highlights[verseRef.id];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.60,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Verse header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  verseRef.id,
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Verse text
          SelectableText(
            text,
            style: GoogleFonts.lora(
              fontSize: 15,
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          // ── Primary CTA — same gold pill as the Read-tab modal ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.translate, size: 18),
              label: const Text('See the original Greek / Hebrew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.gold,
                foregroundColor: const Color(0xFF3E2723),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final wasOn =
                    parentRef.read(settingsProvider).scholarMode;
                if (!wasOn) {
                  parentRef
                      .read(settingsProvider.notifier)
                      .setScholarMode(true);
                }
                _saveReturnContext();
                _goToRead(context);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(wasOn
                        ? 'Tap any underlined word for Greek/Hebrew'
                        : 'Word study turned on — tap any underlined word'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'My Lexicon',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyLexiconScreen(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // ── Common actions row ──
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton.icon(
                icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                label: const Text('Copy'),
                onPressed: () {
                  final versionName = translationById(
                          parentRef.read(settingsProvider).translation)
                      .name;
                  Clipboard.setData(
                      ClipboardData(text: _formattedCopy(versionName)));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verse copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.share, color: theme.colorScheme.primary),
                label: const Text('Share'),
                onPressed: () {
                  final versionName = translationById(
                          parentRef.read(settingsProvider).translation)
                      .name;
                  Navigator.pop(context);
                  VerseCardRenderer.shareVerseCard(
                    context: context,
                    verseText: text,
                    reference: '${verseRef.id} ($versionName)',
                  );
                },
              ),
              TextButton.icon(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: theme.colorScheme.primary,
                ),
                label: Text(isBookmarked ? 'Bookmarked' : 'Bookmark'),
                onPressed: () {
                  parentRef
                      .read(bookmarksProvider.notifier)
                      .toggle(verseRef.id);
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.auto_awesome,
                    color: theme.colorScheme.secondary),
                label: const Text('Find similar'),
                onPressed: () {
                  Navigator.pop(context);
                  // Recursive drill: use THIS verse as the new source
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimilarVersesScreen(
                        sourceRef: verseRef,
                        sourceText: text,
                      ),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.alt_route,
                    color: theme.colorScheme.primary),
                label: const Text('Cross-references'),
                onPressed: () {
                  Navigator.pop(context);
                  showCrossReferencesSheet(context, parentRef, verseRef);
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.menu_book,
                    color: theme.colorScheme.primary),
                label: const Text('Read full chapter'),
                onPressed: () {
                  _saveReturnContext();
                  _goToRead(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Highlight color picker ──
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Highlight:',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant)),
              ...List.generate(HighlightsNotifier.colors.length, (i) {
                final isSelected = activeHighlight == i;
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      parentRef
                          .read(highlightsProvider.notifier)
                          .removeHighlight(verseRef.id);
                    } else {
                      parentRef
                          .read(highlightsProvider.notifier)
                          .highlight(verseRef.id, i);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
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
                            size: 18, color: theme.colorScheme.primary)
                        : null,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Save the source ref+text so the Read-tab floating chip can push
  /// SimilarVersesScreen back with the same source when the user is
  /// done. Called before any nav-to-Read action.
  void _saveReturnContext() {
    parentRef.read(similarVersesReturnProvider.notifier).state =
        SimilarVersesReturn(
      book: sourceRef.book,
      chapter: sourceRef.chapter,
      verse: sourceRef.verse,
      text: sourceText,
    );
    parentRef.read(returnContextProvider.notifier).state =
        'similar_verses';
  }

  void _goToRead(BuildContext context) {
    parentRef.read(highlightVerseProvider.notifier).state = verseRef.verse;
    parentRef
        .read(readingLocationProvider.notifier)
        .setBook(verseRef.book);
    parentRef
        .read(readingLocationProvider.notifier)
        .setChapter(verseRef.chapter);
    parentRef.read(tabIndexProvider.notifier).set(1);
    // Pop the sheet + SimilarVersesScreen; land on Home shell → Read.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
