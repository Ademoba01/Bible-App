import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/bible_repository.dart';
import '../../services/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Map a mood chip to one or more topics in BibleRepository's curated topic
/// pool. Multiple topics are merged + de-duplicated to give richer suggestions.
const Map<String, List<String>> _moodToTopics = {
  'anxious': ['anxiety', 'fear', 'peace'],
  'grateful': ['gratitude', 'joy'],
  'lost': ['hope', 'loneliness', 'peace'],
  'hopeful': ['hope', 'joy', 'gratitude'],
};

const Map<String, ({String label, String emoji, Color tint})> _moodMeta = {
  'anxious': (label: 'anxious', emoji: '😟', tint: Color(0xFF6B5B95)),
  'grateful': (label: 'grateful', emoji: '🙏', tint: Color(0xFF7A2E2E)),
  'lost': (label: 'lost', emoji: '🌑', tint: Color(0xFF2E4A6B)),
  'hopeful': (label: 'hopeful', emoji: '☀️', tint: Color(0xFFD4A843)),
};

/// Open the mood-driven verse list as a draggable bottom sheet.
///
/// Shows curated verses for the chosen mood, optionally personalized by
/// Gemini if the user has AI enabled. Each verse is tappable to deep-link
/// into the reading view.
void showMoodVersesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String mood,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoodVersesSheet(mood: mood, parentRef: ref),
  );
}

class _MoodVersesSheet extends ConsumerStatefulWidget {
  const _MoodVersesSheet({required this.mood, required this.parentRef});
  final String mood;
  final WidgetRef parentRef;

  @override
  ConsumerState<_MoodVersesSheet> createState() => _MoodVersesSheetState();
}

class _MoodVersesSheetState extends ConsumerState<_MoodVersesSheet> {
  /// (reference, text, source) — source is 'curated' or 'ai'
  List<({String ref, String text, String source})> _verses = [];
  bool _loading = true;
  bool _aiAttempted = false;

  @override
  void initState() {
    super.initState();
    _loadCurated();
    _maybeLoadAi();
  }

  Future<void> _loadCurated() async {
    // 1) Pull canonical refs from the curated topic pool (instant, offline).
    final repo = ref.read(bibleRepositoryProvider);
    final topics = _moodToTopics[widget.mood] ?? const [];
    final seen = <String>{};
    final refs = <String>[];
    for (final topic in topics) {
      final pool = BibleRepository.getTopicVerses(topic) ?? const [];
      for (final r in pool) {
        if (seen.add(r)) refs.add(r);
      }
    }

    // 2) Resolve text for each ref. Cap at 12 — quality over quantity.
    final tid = ref.read(settingsProvider).translation;
    final out = <({String ref, String text, String source})>[];
    for (final r in refs.take(12)) {
      final resolved = await repo.lookupReference(r, translationId: tid);
      if (resolved != null) {
        out.add((ref: resolved.ref.id, text: resolved.text, source: 'curated'));
      } else {
        // Fallback — show ref even if we can't fetch text
        out.add((ref: r, text: '', source: 'curated'));
      }
    }
    if (!mounted) return;
    setState(() {
      _verses = out;
      _loading = false;
    });
  }

  Future<void> _maybeLoadAi() async {
    final settings = ref.read(settingsProvider);
    if (!settings.useOnlineAi || !AiService.isAvailable) return;

    setState(() => _aiAttempted = true);
    final svc = ref.read(personalizationServiceProvider);
    final recent = svc.getRecentRefs();

    try {
      final result = await AiService.searchWithAI(
        'verses for someone feeling ${widget.mood} '
        '${recent.isNotEmpty ? "(they recently read ${recent.take(5).join(", ")})" : ""}',
      );
      if (!mounted || result.hits.isEmpty) return;

      // Append AI-suggested verses (deduplicated against curated).
      final existing = _verses.map((v) => v.ref).toSet();
      final repo = ref.read(bibleRepositoryProvider);
      final tid = ref.read(settingsProvider).translation;
      final aiAdds = <({String ref, String text, String source})>[];
      for (final hit in result.hits.take(6)) {
        if (existing.contains(hit.reference)) continue;
        final resolved = await repo.lookupReference(
          hit.reference,
          translationId: tid,
        );
        if (resolved != null) {
          aiAdds.add((
            ref: resolved.ref.id,
            text: resolved.text,
            source: 'ai',
          ));
        } else if (hit.text.isNotEmpty) {
          aiAdds.add((ref: hit.reference, text: hit.text, source: 'ai'));
        }
      }
      if (!mounted || aiAdds.isEmpty) return;
      setState(() => _verses = [..._verses, ...aiAdds]);
    } catch (_) {
      // Silently fall back to curated only.
    }
  }

  void _openVerse(String refId) {
    // Parse "Book Chapter:Verse" — e.g. "Philippians 4:6"
    final m = RegExp(r'^(.+?)\s+(\d+):(\d+)').firstMatch(refId.trim());
    if (m == null) return;
    final book = m.group(1)!;
    final chapter = int.tryParse(m.group(2)!);
    final verse = int.tryParse(m.group(3)!);
    if (chapter == null || verse == null) return;

    Navigator.pop(context);
    widget.parentRef.read(readingLocationProvider.notifier).setBook(book);
    widget.parentRef
        .read(readingLocationProvider.notifier)
        .setChapter(chapter);
    widget.parentRef.read(highlightVerseProvider.notifier).state = verse;
    widget.parentRef.read(tabIndexProvider.notifier).state = 1;
    // Record this verse so future adaptive picks don't repeat it
    final svc = widget.parentRef.read(personalizationServiceProvider);
    svc.recordReadVerse(refId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _moodMeta[widget.mood] ??
        (label: widget.mood, emoji: '✨', tint: BrandColors.gold);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: BrandColors.parchment,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text(meta.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verses for when you feel ${meta.label}',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.brown,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap any verse to read it in context',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_aiAttempted && AiService.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: meta.tint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: meta.tint),
                          const SizedBox(width: 4),
                          Text(
                            'AI tuned',
                            style: GoogleFonts.lora(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: meta.tint,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _verses.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              "We couldn't find verses for this mood right now. Try another, or set a Gemini key in Settings to enable AI-tuned picks.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _verses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final v = _verses[i];
                            final isAi = v.source == 'ai';
                            return _VerseCard(
                              ref: v.ref,
                              text: v.text,
                              isAi: isAi,
                              tint: meta.tint,
                              onTap: () => _openVerse(v.ref),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.ref,
    required this.text,
    required this.isAi,
    required this.tint,
    required this.onTap,
  });

  final String ref;
  final String text;
  final bool isAi;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: BrandColors.warmWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BrandColors.gold.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAi ? Icons.auto_awesome : Icons.bookmark_outline,
                    size: 16,
                    color: isAi ? tint : BrandColors.brown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ref,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.brown,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    height: 1.45,
                    color: theme.colorScheme.onSurface,
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
