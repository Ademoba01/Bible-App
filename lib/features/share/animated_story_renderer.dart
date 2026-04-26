import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
// flutter_map and lottie both export a `Marker` class. Hide Lottie's so
// flutter_map's MarkerLayer Marker wins — we use the latter for the era
// pin on the mini-map; Lottie's Marker is internal animation metadata.
import 'package:lottie/lottie.dart' hide Marker;

import '../../theme.dart';
import 'verse_card_templates.dart';

/// Story export geometry — Instagram / TikTok / WhatsApp 9:16 portrait.
///
/// Kept as a single source of truth so the live preview + GIF capture stay
/// pixel-aligned. The values are exact 9:16 (1080x1920) for camera-roll
/// quality; the live preview scales down by [previewScale].
class StoryGeometry {
  static const double width = 1080;
  static const double height = 1920;
  static const double previewScale = 0.32; // ~346 x 614 on-screen
  static const Duration totalDuration = Duration(milliseconds: 2400);
}

/// Configuration object passed to [AnimatedStoryRenderer]. Pass an optional
/// [center] to render a Bible-Maps mini-map background (used by the Bible
/// Timeline era cards). [accentColor] defaults to the style's gold; supply
/// a per-era color to colour-match the source surface.
class StoryConfig {
  final String reference;
  final String verseText;
  final LatLng? center;
  final Color? accentColor;
  final VerseCardStyle style;

  const StoryConfig({
    required this.reference,
    required this.verseText,
    this.center,
    this.accentColor,
    this.style = VerseCardStyle.midnight,
  });

  StoryConfig copyWith({VerseCardStyle? style}) => StoryConfig(
        reference: reference,
        verseText: verseText,
        center: center,
        accentColor: accentColor,
        style: style ?? this.style,
      );
}

/// Animated 9:16 story frame.
///
/// This widget is the single visual source for both the live preview and
/// the GIF capture. It exposes a [progress] (0..1) so the parent can either
/// drive it via an [AnimationController] (preview) or scrub through it
/// frame-by-frame to capture pixels (export).
///
/// Animation timeline (assumes [progress] linearly maps to [StoryGeometry.totalDuration]):
///   - 0.00 – 0.25 (0–600ms):   Background fade-in + tiny "Rhema" badge top-left
///   - 0.25 – 0.75 (600–1800ms): Verse text fades in word-by-word
///   - 0.75 – 1.00 (1800–2400ms): Reference slides up + confetti Lottie burst
class AnimatedStoryFrame extends StatelessWidget {
  const AnimatedStoryFrame({
    super.key,
    required this.config,
    required this.progress,
    this.lottieController,
  });

  final StoryConfig config;
  final double progress;

  /// Drives the bottom-right confetti when present. For the static GIF capture
  /// we don't pass a controller — we instead seek the underlying Lottie at the
  /// captured time.
  final AnimationController? lottieController;

  @override
  Widget build(BuildContext context) {
    final spec = VerseCardStyleSpec.forStyle(config.style);
    final accent = config.accentColor ?? spec.accentColor;

    // Phase progress — clamped 0..1 within each beat.
    final bgFade = _norm(progress, 0.0, 0.25);
    final wordsProgress = _norm(progress, 0.25, 0.75);
    final refProgress = _norm(progress, 0.75, 1.0);

    return SizedBox(
      width: StoryGeometry.width,
      height: StoryGeometry.height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: optional Bible-Maps mini-map (era cards) ──────────
            // Slowly zooms in for a subtle "Ken Burns" feel. Behind the dark
            // gradient so the verse always reads cleanly.
            if (config.center != null)
              _MapBackground(
                center: config.center!,
                progress: progress,
              ),

            // ── Layer 2: brand-aligned dark gradient + vignette ───────────
            Opacity(
              opacity: bgFade.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: config.center != null
                        ? [
                            BrandColors.brownDeep.withOpacity(0.55),
                            Colors.black.withOpacity(0.85),
                          ]
                        : spec.gradient,
                  ),
                ),
              ),
            ),

            // ── Layer 3: corner vignette for legibility ───────────────────
            const _Vignette(),

            // ── Layer 4: top-left Rhema badge ─────────────────────────────
            Positioned(
              top: 80,
              left: 56,
              child: Opacity(
                opacity: bgFade,
                child: _RhemaBadge(accent: accent),
              ),
            ),

            // ── Layer 5: verse text — word-by-word fade-in ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 360, 80, 380),
              child: Align(
                alignment: Alignment.topLeft,
                child: _AccentRule(color: accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 420, 80, 380),
              child: _AnimatedVerseText(
                verseText: config.verseText,
                progress: wordsProgress,
                color: spec.textColor,
                fontSize: 64,
                spec: spec,
              ),
            ),

            // ── Layer 6: reference + confetti slide-in ────────────────────
            Positioned(
              left: 80,
              right: 80,
              bottom: 200,
              child: Opacity(
                opacity: refProgress,
                child: Transform.translate(
                  offset: Offset(0, 60 * (1 - refProgress)),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 4,
                            width: 96,
                            color: accent,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            config.reference.toUpperCase(),
                            style: spec.textStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: spec.referenceColor,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      // Confetti burst — fires when reference arrives. We
                      // align it to the right of the reference so it doesn't
                      // obscure the typography.
                      if (refProgress > 0.0)
                        Positioned(
                          right: -40,
                          top: -120,
                          child: SizedBox(
                            width: 360,
                            height: 360,
                            child: Lottie.asset(
                              'assets/animations/confetti.json',
                              controller: lottieController,
                              fit: BoxFit.contain,
                              repeat: false,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Layer 7: rhemabibles.com watermark (bottom-right, every frame) ─
            const Positioned(
              right: 56,
              bottom: 80,
              child: _StoryWatermark(),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps [t] from `[a, b]` to `[0, 1]`, clamped.
  static double _norm(double t, double a, double b) {
    if (t <= a) return 0.0;
    if (t >= b) return 1.0;
    return (t - a) / (b - a);
  }
}

/// Word-by-word verse fade-in. Tokenises on whitespace and reveals each
/// word as `progress` advances. The first word appears at progress=0,
/// the last at progress=1, with a small fade-in window per word so the
/// transitions feel smooth rather than chunky.
class _AnimatedVerseText extends StatelessWidget {
  const _AnimatedVerseText({
    required this.verseText,
    required this.progress,
    required this.color,
    required this.fontSize,
    required this.spec,
  });

  final String verseText;
  final double progress;
  final Color color;
  final double fontSize;
  final VerseCardStyleSpec spec;

  @override
  Widget build(BuildContext context) {
    final words = verseText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const SizedBox.shrink();

    // Each word gets a slot of width 1/N; we cross-fade over a window of
    // `windowSize * slot` so consecutive words overlap slightly.
    final n = words.length;
    final slot = 1.0 / n;
    const windowSize = 1.6;
    final fadeWindow = slot * windowSize;

    final baseStyle = spec.textStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.32,
      letterSpacing: 0.4,
    );

    final spans = <TextSpan>[];
    for (int i = 0; i < n; i++) {
      final wordStart = i * slot;
      final wordOpacity =
          ((progress - wordStart) / fadeWindow).clamp(0.0, 1.0);
      spans.add(TextSpan(
        text: i == 0 ? '“${words[i]}' : ' ${words[i]}',
        style: baseStyle.copyWith(
          color: color.withOpacity(wordOpacity),
        ),
      ));
    }
    // Closing quote follows the last word.
    spans.add(TextSpan(
      text: '”',
      style: baseStyle.copyWith(
        color: color.withOpacity(progress.clamp(0.0, 1.0)),
      ),
    ));

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
    );
  }
}

/// Tiny "Rhema" pill in the corner — ties every story back to the brand.
class _RhemaBadge extends StatelessWidget {
  const _RhemaBadge({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: accent.withOpacity(0.6), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories, color: accent, size: 32),
          const SizedBox(width: 12),
          Text(
            'Rhema',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentRule extends StatelessWidget {
  const _AccentRule({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _StoryWatermark extends StatelessWidget {
  const _StoryWatermark();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'rhemabibles.com',
        style: GoogleFonts.lora(
          fontSize: 22,
          color: Colors.white.withOpacity(0.92),
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.05,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.45),
            ],
          ),
        ),
      ),
    );
  }
}

/// FlutterMap background that subtly zooms while the verse fades in.
///
/// The map tile fetch is async, so when the GIF frame is captured before
/// tiles arrive the background falls back to a brand-toned gradient — the
/// composition still reads cleanly.
class _MapBackground extends StatelessWidget {
  const _MapBackground({required this.center, required this.progress});
  final LatLng center;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // Subtle zoom from 4.5 → 5.5 across the animation; clamp lower bound
    // so the very first frame doesn't show empty world tiles.
    final zoom = 4.6 + 0.9 * progress;
    // Slight scale-up for a "Ken Burns" cinematic feel.
    final scale = 1.0 + 0.05 * progress;

    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rhemabibles.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        color: BrandColors.gold,
                        size: math.max(60.0, 60.0 + 16 * progress),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Heavy black overlay so the map reads as ambience, not content.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
