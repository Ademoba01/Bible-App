import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual style options for shareable verse cards.
///
/// Each style targets a different mood / audience:
///   * [minimalist] — light cream parchment, classic serif (Lora) with a gold
///     accent rule. Default fallback.
///   * [sunset]     — warm orange→pink gradient with confident white serif
///     (Cormorant). Good for evening posts.
///   * [scroll]     — simulated parchment, Cormorant italic — feels like an
///     old-world manuscript.
///   * [midnight]   — deep navy with gold typography (Lora) for high contrast.
///   * [kids]       — bright yellow + sky blue with rounded Fredoka — playful,
///     pairs with the Kids portal.
enum VerseCardStyle { minimalist, sunset, scroll, midnight, kids }

/// Identifies which Google Fonts family a style uses. We resolve the actual
/// [TextStyle] inside [VerseCardStyleSpec.textStyle] so the call sites don't
/// have to know about the GoogleFonts API surface.
enum VerseCardFont { lora, cormorant, fredoka }

/// Lightweight design tokens describing a [VerseCardStyle].
///
/// Held as a separate value object so [VerseCardTemplate] can compose backgrounds
/// and typography without `switch` statements scattered through the build tree.
class VerseCardStyleSpec {
  final List<Color> gradient;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final Color textColor;
  final Color referenceColor;
  final Color accentColor;
  final Color watermarkColor;
  final VerseCardFont font;
  final double verseSize;
  final double referenceSize;
  final FontStyle verseFontStyle;
  final FontWeight verseFontWeight;
  final FontWeight referenceFontWeight;
  final double letterSpacing;
  final String label;

  const VerseCardStyleSpec({
    required this.gradient,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.textColor,
    required this.referenceColor,
    required this.accentColor,
    required this.watermarkColor,
    required this.font,
    required this.verseSize,
    required this.referenceSize,
    required this.verseFontStyle,
    required this.verseFontWeight,
    required this.referenceFontWeight,
    required this.letterSpacing,
    required this.label,
  });

  /// Resolves the configured Google Font into a concrete [TextStyle].
  TextStyle textStyle({
    required double fontSize,
    required FontWeight fontWeight,
    FontStyle fontStyle = FontStyle.normal,
    required Color color,
    double height = 1.3,
    double letterSpacing = 0,
  }) {
    switch (font) {
      case VerseCardFont.lora:
        return GoogleFonts.lora(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case VerseCardFont.cormorant:
        return GoogleFonts.cormorant(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case VerseCardFont.fredoka:
        return GoogleFonts.fredoka(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
    }
  }

  static VerseCardStyleSpec forStyle(VerseCardStyle style) {
    switch (style) {
      case VerseCardStyle.minimalist:
        return VerseCardStyleSpec(
          gradient: const [Color(0xFFFDF6EC), Color(0xFFF5EAD3)],
          gradientBegin: Alignment.topCenter,
          gradientEnd: Alignment.bottomCenter,
          textColor: const Color(0xFF3E2723),
          referenceColor: const Color(0xFF5D4037),
          accentColor: const Color(0xFFD4A843),
          watermarkColor: const Color(0xFF8D6E63),
          font: VerseCardFont.lora,
          verseSize: 56,
          referenceSize: 32,
          verseFontStyle: FontStyle.normal,
          verseFontWeight: FontWeight.w500,
          referenceFontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          label: 'Minimalist',
        );
      case VerseCardStyle.sunset:
        return VerseCardStyleSpec(
          gradient: const [Color(0xFFFF8A4C), Color(0xFFFF5E8A), Color(0xFFB23E80)],
          gradientBegin: Alignment.topLeft,
          gradientEnd: Alignment.bottomRight,
          textColor: Colors.white,
          referenceColor: Colors.white,
          accentColor: const Color(0xFFFFE0B2),
          watermarkColor: Colors.white70,
          font: VerseCardFont.cormorant,
          verseSize: 60,
          referenceSize: 32,
          verseFontStyle: FontStyle.normal,
          verseFontWeight: FontWeight.w700,
          referenceFontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          label: 'Sunset',
        );
      case VerseCardStyle.scroll:
        return VerseCardStyleSpec(
          gradient: const [Color(0xFFF6E4C1), Color(0xFFE8CFA1), Color(0xFFD9B97C)],
          gradientBegin: Alignment.topLeft,
          gradientEnd: Alignment.bottomRight,
          textColor: const Color(0xFF4A2E10),
          referenceColor: const Color(0xFF6B3E12),
          accentColor: const Color(0xFFA07B28),
          watermarkColor: const Color(0xFF6B3E12),
          font: VerseCardFont.cormorant,
          verseSize: 58,
          referenceSize: 32,
          verseFontStyle: FontStyle.italic,
          verseFontWeight: FontWeight.w500,
          referenceFontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          label: 'Scroll',
        );
      case VerseCardStyle.midnight:
        return VerseCardStyleSpec(
          gradient: const [Color(0xFF0B1B36), Color(0xFF132B55), Color(0xFF0A1628)],
          gradientBegin: Alignment.topCenter,
          gradientEnd: Alignment.bottomCenter,
          textColor: const Color(0xFFF4E5B7),
          referenceColor: const Color(0xFFD4A843),
          accentColor: const Color(0xFFD4A843),
          watermarkColor: const Color(0xFFD4A843),
          font: VerseCardFont.lora,
          verseSize: 56,
          referenceSize: 32,
          verseFontStyle: FontStyle.normal,
          verseFontWeight: FontWeight.w500,
          referenceFontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          label: 'Midnight',
        );
      case VerseCardStyle.kids:
        return VerseCardStyleSpec(
          gradient: const [Color(0xFFFFE17B), Color(0xFFFFCA28), Color(0xFF42A5F5)],
          gradientBegin: Alignment.topLeft,
          gradientEnd: Alignment.bottomRight,
          textColor: const Color(0xFF1A237E),
          referenceColor: const Color(0xFFFFFFFF),
          accentColor: const Color(0xFFEC407A),
          watermarkColor: const Color(0xFF1A237E),
          font: VerseCardFont.fredoka,
          verseSize: 54,
          referenceSize: 34,
          verseFontStyle: FontStyle.normal,
          verseFontWeight: FontWeight.w600,
          referenceFontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          label: 'Kids',
        );
    }
  }
}

/// Builds a 1080x1080 verse card widget ready to be captured to PNG.
///
/// The widget always has fixed pixel dimensions so [RepaintBoundary.toImage]
/// produces a predictable square output regardless of screen size.
class VerseCardTemplate {
  static const double cardSize = 1080;

  /// Returns a widget tree representing the verse card. Wrap the result in a
  /// [RepaintBoundary] (and a [GlobalKey]) at the call site to capture it.
  Widget build(
    BuildContext context, {
    required String verseText,
    required String reference,
    required VerseCardStyle style,
  }) {
    final spec = VerseCardStyleSpec.forStyle(style);

    final verseStyle = spec.textStyle(
      fontSize: spec.verseSize,
      fontWeight: spec.verseFontWeight,
      fontStyle: spec.verseFontStyle,
      color: spec.textColor,
      height: 1.32,
      letterSpacing: spec.letterSpacing,
    );

    final referenceStyle = spec.textStyle(
      fontSize: spec.referenceSize,
      fontWeight: spec.referenceFontWeight,
      color: spec.referenceColor,
      letterSpacing: 1.6,
    );

    final cleanedVerse = '“${verseText.trim().replaceAll(RegExp(r'\s+'), ' ')}”';

    return SizedBox(
      width: cardSize,
      height: cardSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: spec.gradientBegin,
            end: spec.gradientEnd,
            colors: spec.gradient,
          ),
        ),
        child: Stack(
          children: [
            // Subtle texture overlay for the parchment / scroll look.
            if (style == VerseCardStyle.scroll)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF6B3E12).withOpacity(0.08),
                      ],
                    ),
                  ),
                ),
              ),
            // Soft vignette for darker styles.
            if (style == VerseCardStyle.midnight || style == VerseCardStyle.sunset)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.18),
                      ],
                    ),
                  ),
                ),
              ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(96, 96, 96, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top accent line — gold rule that anchors the composition.
                  Container(
                    width: 96,
                    height: 4,
                    decoration: BoxDecoration(
                      color: spec.accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 56),
                  // Verse text
                  Flexible(
                    child: Text(
                      cleanedVerse,
                      style: verseStyle,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Reference (e.g. JOHN 3:16)
                  Text(
                    reference.toUpperCase(),
                    style: referenceStyle,
                  ),
                  const Spacer(),
                  // Watermark row at the bottom of every card.
                  _WatermarkRow(spec: spec),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatermarkRow extends StatelessWidget {
  final VerseCardStyleSpec spec;
  const _WatermarkRow({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_stories, size: 22, color: spec.watermarkColor.withOpacity(0.85)),
        const SizedBox(width: 10),
        Text(
          'rhemabibles.com',
          style: spec.textStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: spec.watermarkColor.withOpacity(0.85),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
