import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../data/translations.dart';
import '../../services/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (sheetContext) => Center(
        child: Container(
          width: 380,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4A843).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse reference as title
            Text(
              verseRef.id,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            // Verse text
            Text(
              text,
              style: GoogleFonts.lora(
                fontSize: 15,
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            // "Read full chapter" button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.menu_book, size: 18),
                label: Text(
                  'Read full chapter',
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(sheetContext); // dismiss bottom sheet
                  // Preserve the similar-verses source so the floating
                  // "Back to Similar Verses" chip on the Read screen
                  // can re-push SimilarVersesScreen with the same
                  // source verse pre-loaded — user lands back where
                  // they left off, not on a fresh search.
                  ref.read(similarVersesReturnProvider.notifier).state =
                      SimilarVersesReturn(
                    book: widget.sourceRef.book,
                    chapter: widget.sourceRef.chapter,
                    verse: widget.sourceRef.verse,
                    text: widget.sourceText,
                  );
                  // Set highlight + return context providers
                  ref.read(highlightVerseProvider.notifier).state = verseRef.verse;
                  ref.read(returnContextProvider.notifier).state = 'similar_verses';
                  ref.read(readingLocationProvider.notifier).setBook(verseRef.book);
                  ref.read(readingLocationProvider.notifier).setChapter(verseRef.chapter);
                  ref.read(tabIndexProvider.notifier).set(1);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          ],
        ),
      ),
          ),
        ),
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
