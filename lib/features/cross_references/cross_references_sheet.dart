import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/cross_references_service.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Opens a slide-up modal sheet listing OpenBible.info Treasury of Scripture
/// Knowledge cross-references for [sourceRef], ranked by votes desc.
///
/// Tapping a ref closes the sheet and jumps the Read tab to that verse.
Future<void> showCrossReferencesSheet(
  BuildContext context,
  WidgetRef ref,
  VerseRef sourceRef,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BrandColors.warmWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CrossReferencesSheet(sourceRef: sourceRef),
  );
}

class _CrossReferencesSheet extends ConsumerWidget {
  const _CrossReferencesSheet({required this.sourceRef});

  final VerseRef sourceRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncRefs = ref.watch(crossReferencesForProvider((
      book: sourceRef.book,
      chapter: sourceRef.chapter,
      verse: sourceRef.verse,
    )));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B1E19) : BrandColors.warmWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: BrandColors.brownMid.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.alt_route, size: 20, color: BrandColors.goldDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cross-references',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: BrandColors.brownMid,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sourceRef.id,
                          style: GoogleFonts.lora(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Gold divider
            Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
            // ── Body ──
            Expanded(
              child: asyncRefs.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load cross-references.',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                data: (refs) {
                  if (refs.isEmpty) {
                    return _EmptyState(theme: theme);
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    itemCount: refs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: BrandColors.gold.withValues(alpha: 0.12),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, i) {
                      final r = refs[i];
                      final isTopThree = i < 3;
                      final parsed = VerseRef.tryParse(r.ref);
                      return ListTile(
                        leading: Icon(
                          isTopThree ? Icons.star : Icons.star_outline,
                          color: isTopThree
                              ? BrandColors.gold
                              : BrandColors.brownMid.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        title: Text(
                          r.ref,
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight:
                                isTopThree ? FontWeight.w700 : FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${r.votes} ${r.votes == 1 ? "vote" : "votes"}',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onTap: parsed == null
                            ? null
                            : () => _peek(context, ref, parsed),
                      );
                    },
                  );
                },
              ),
            ),
            // ── Footer attribution ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Treasury of Scripture Knowledge — OpenBible.info (CC BY)',
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

  /// Peek the referenced verse in a parchment bubble ON TOP of the
  /// cross-refs sheet. User feedback: tapping a cross-ref was popping
  /// the sheet AND teleporting away, which lost the user's place when
  /// they were scanning 4-5 TSK refs in a row. Now it stays in the
  /// sheet; the bubble has a "Read full chapter" button that still
  /// does the teleport (the escape hatch) for users who want to leave.
  void _peek(BuildContext context, WidgetRef ref, VerseRef target) async {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final repo = ref.read(bibleRepositoryProvider);
    final translation = ref.read(settingsProvider).translation;
    String? verseText;
    try {
      final chapters =
          await repo.loadBook(target.book, translationId: translation);
      final chapter =
          chapters[(target.chapter - 1).clamp(0, chapters.length - 1)];
      for (final v in chapter.verses) {
        if (v.number == target.verse) {
          verseText = v.text;
          break;
        }
      }
    } catch (_) {
      // Load failed — fall through to the teleport fallback below.
    }
    if (!context.mounted) return;
    if (verseText == null) {
      _jumpTo(context, ref, target);
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Center(
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: BrandColors.gold.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book,
                          size: 18, color: BrandColors.brownDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          target.id,
                          style: GoogleFonts.lora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.brownDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verseText!,
                    style: BrandColors.verseStyle(size: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          _jumpTo(context, ref, target);
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: BrandColors.brownDeep),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Read full chapter'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: TextButton.styleFrom(
                            foregroundColor: BrandColors.brownDeep),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _jumpTo(BuildContext context, WidgetRef ref, VerseRef target) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    ref.read(readingLocationProvider.notifier).setBook(target.book);
    ref.read(readingLocationProvider.notifier).setChapter(target.chapter);
    ref.read(highlightVerseProvider.notifier).state = target.verse;
    ref.read(tabIndexProvider.notifier).set(1); // Read tab
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alt_route,
              size: 48,
              color: BrandColors.brownMid.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No cross-references for this verse yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
