import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../state/providers.dart';

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
  List<({VerseRef ref, String text, double score})>? _results;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSimilar();
  }

  Future<void> _loadSimilar() async {
    final repo = ref.read(bibleRepositoryProvider);
    final tid = ref.read(settingsProvider).translation;
    final results = await repo.findSimilar(
      widget.sourceText,
      sourceRef: widget.sourceRef,
      translationId: tid,
      limit: 25,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Similar Verses'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Source verse card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, size: 18, color: theme.colorScheme.primary),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Text('SOURCE',
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
              ],
            ),
          ),

          // Results header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  _loading
                      ? 'Finding similar verses...'
                      : '${_results?.length ?? 0} similar verses found',
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
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
                            onTap: () {
                              ref.read(readingLocationProvider.notifier).setBook(r.ref.book);
                              ref.read(readingLocationProvider.notifier).setChapter(r.ref.chapter);
                              ref.read(tabIndexProvider.notifier).state = 1;
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
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
  });

  final VerseRef verseRef;
  final String text;
  final double score;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Score bar: normalize to 0-1 (scores typically range 2-15)
    final normalizedScore = (score / 12).clamp(0.0, 1.0);

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
                  // Relevance indicator
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
            ],
          ),
        ),
      ),
    );
  }
}
