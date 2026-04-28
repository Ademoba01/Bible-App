import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../services/ai_service.dart';
import '../../state/providers.dart';
import 'similar_verses_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  bool _aiLoading = false;
  String _lastQuery = '';
  String _aiOverview = '';
  List<({VerseRef ref, String text, String? reason, bool fromAi})> _results =
      const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _aiOverview = '';
        _lastQuery = '';
      });
      return;
    }

    setState(() {
      _loading = true;
      _lastQuery = q;
      _aiOverview = '';
    });

    final repo = ref.read(bibleRepositoryProvider);
    final tid = ref.read(settingsProvider).translation;

    // 1) Local token-based search first (fast). Repo.search() now has a
    //    reference-detection fast path — for queries like "2 Thess 2:11"
    //    it returns the exact verse instantly without scanning all 66
    //    books × every verse × 3 translations like before.
    final localHits = await repo.search(q, translationId: tid);
    final combined = localHits
        .map((r) => (
              ref: r.ref,
              text: r.text,
              reason: null as String?,
              fromAi: false,
            ))
        .toList();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = combined;
    });

    // Reference-detection: skip AI entirely for explicit verse-reference
    // queries. The user typed "Rom 8:28" because they want THAT verse —
    // not AI commentary or related verses. Round-tripping to AI for an
    // exact reference makes the search feel slow for no benefit. If they
    // want context they can tap the verse → "Find similar" / "Cross-
    // references" / "Original language" actions. Pattern matches
    // "Book Ch:Vs" loosely (allows "1 John 3:16", "Rom 8:28", "Ps 23:1").
    final refRe =
        RegExp(r'^\s*(?:[1-3]\s+)?[A-Za-z. ]+?\s+\d+:\d+\s*$');
    if (refRe.hasMatch(q)) return;

    // 2) Otherwise ask AI for its interpretation + additional matches.
    //    For strong local hits (>=5), AI only adds overview + backfills
    //    any missing verses. For weak/no hits, AI becomes the primary
    //    source.
    if (!AiService.isAvailable) return;
    setState(() => _aiLoading = true);
    final aiResult = await AiService.searchWithAI(q);
    if (!mounted) return;

    // Resolve AI-returned references against local Bible
    final seenIds = combined.map((r) => r.ref.id).toSet();
    final aiHits = <({VerseRef ref, String text, String? reason, bool fromAi})>[];
    for (final hit in aiResult.hits) {
      final resolved = await repo.lookupReference(hit.reference, translationId: tid);
      if (resolved != null && !seenIds.contains(resolved.ref.id)) {
        seenIds.add(resolved.ref.id);
        aiHits.add((
          ref: resolved.ref,
          text: resolved.text,
          reason: hit.reason.isEmpty ? null : hit.reason,
          fromAi: true,
        ));
      } else if (resolved == null && hit.text.isNotEmpty) {
        // Couldn't resolve locally — still show AI text
        final fallbackRef = VerseRef(hit.reference, 0, 0);
        if (!seenIds.contains(fallbackRef.id)) {
          seenIds.add(fallbackRef.id);
          aiHits.add((
            ref: fallbackRef,
            text: hit.text,
            reason: hit.reason.isEmpty ? null : hit.reason,
            fromAi: true,
          ));
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      _aiOverview = aiResult.overview;
      // Put AI-found verses after strong local exact matches
      _results = [...combined, ...aiHits];
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _run);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showingResults = _results.isNotEmpty || _aiOverview.isNotEmpty;
    final isSearching = _loading || _aiLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _run(),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search verses, topics, or paraphrases...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _run,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (!_loading && _aiLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI is searching for related verses...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: !showingResults
                ? _EmptyState(
                    isSearching: isSearching,
                    hasQuery: _lastQuery.isNotEmpty,
                    aiAvailable: AiService.isAvailable,
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (_aiOverview.isNotEmpty) _AiOverviewCard(text: _aiOverview),
                      ..._results.map((r) => _VerseResultTile(
                            ref: r.ref,
                            text: r.text,
                            reason: r.reason,
                            fromAi: r.fromAi,
                            onTap: () {
                              if (r.ref.chapter == 0) return; // unresolved ref
                              ref
                                  .read(readingLocationProvider.notifier)
                                  .setBook(r.ref.book);
                              ref
                                  .read(readingLocationProvider.notifier)
                                  .setChapter(r.ref.chapter);
                              ref
                                  .read(highlightVerseProvider.notifier)
                                  .state = r.ref.verse;
                              ref.read(tabIndexProvider.notifier).set(1);
                              Navigator.pop(context);
                            },
                            onSimilar: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SimilarVersesScreen(
                                  sourceRef: r.ref,
                                  sourceText: r.text,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearching,
    required this.hasQuery,
    required this.aiAvailable,
  });
  final bool isSearching;
  final bool hasQuery;
  final bool aiAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasQuery) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No verses matched your query.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              aiAvailable
                  ? 'Try rephrasing or use a shorter key phrase.'
                  : 'Enable AI in Settings to search by meaning and topic.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories,
              size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            'Search the Bible',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a verse, a topic, or even a paraphrase like\n"god is consuming fire" or "love your enemies".',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AiOverviewCard extends StatelessWidget {
  const _AiOverviewCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.10),
            theme.colorScheme.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'AI Overview',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _VerseResultTile extends StatelessWidget {
  const _VerseResultTile({
    required this.ref,
    required this.text,
    required this.reason,
    required this.fromAi,
    required this.onTap,
    required this.onSimilar,
  });
  final VerseRef ref;
  final String text;
  final String? reason;
  final bool fromAi;
  final VoidCallback onTap;
  final VoidCallback onSimilar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unresolved = ref.chapter == 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(
          fromAi ? Icons.auto_awesome : Icons.bookmark_outline,
          color: fromAi
              ? theme.colorScheme.secondary
              : theme.colorScheme.primary,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                unresolved ? ref.book : ref.id,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (fromAi) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  reason!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unresolved)
              IconButton(
                icon: Icon(Icons.auto_awesome,
                    size: 18, color: theme.colorScheme.secondary),
                tooltip: 'Find similar verses',
                onPressed: onSimilar,
              ),
            if (!unresolved)
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: theme.colorScheme.outline),
          ],
        ),
        onTap: unresolved ? null : onTap,
      ),
    );
  }
}
