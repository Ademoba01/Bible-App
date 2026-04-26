import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/strongs_service.dart';
import '../../theme.dart';

/// Opens a slide-up modal sheet showing the Hebrew/Greek lexicon entry for
/// a tapped English word.
///
/// The data comes from STEPBible's TBESG/TBESH (CC BY 4.0), via the
/// per-word Strong's tagging baked into `assets/data/strongs_kjv.json`.
/// Tapping a word in Scholar Mode (Reading screen) is the entry point.
Future<void> showStrongsSheet(
  BuildContext context, {
  required StrongsWord word,
  required StrongsEntry? entry,
  required int occurrences,
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
    ),
  );
}

class _StrongsSheet extends StatelessWidget {
  const _StrongsSheet({
    required this.word,
    required this.entry,
    required this.occurrences,
  });

  final StrongsWord word;
  final StrongsEntry? entry;
  final int occurrences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final original = entry?.original.isNotEmpty == true
        ? entry!.original
        : (word.original ?? '');
    final translit = entry?.transliteration.isNotEmpty == true
        ? entry!.transliteration
        : (word.translit ?? '');
    final pos = entry?.partOfSpeech ?? '';
    final definition = entry?.definition ?? '';
    final strongsId = word.strongs ?? entry?.strongs ?? '';
    final isHebrew = strongsId.startsWith('H');
    final testamentLabel = isHebrew ? 'OT' : 'NT';

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
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
                      '"${word.word}"',
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
            // ── Strong's chip + part of speech ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (strongsId.isNotEmpty)
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
                        'Strong\'s $strongsId',
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
                  'Lexicon entry not available for $strongsId.',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            // ── Occurrences counter ──
            if (occurrences > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
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
                        Icon(Icons.tag, size: 14, color: BrandColors.brownMid),
                        const SizedBox(width: 6),
                        Text(
                          '$occurrences ${occurrences == 1 ? "occurrence" : "occurrences"} in $testamentLabel',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.brownMid,
                          ),
                        ),
                      ],
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
}
