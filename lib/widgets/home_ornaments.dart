import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme.dart';

/// Illuminated-manuscript ornaments for the Home surfaces. Hand-drawn
/// via CustomPainter — no external SVG, no illustrator wait. Follows
/// the same brand idiom as [WaxSeal]: gilt lineart on parchment.
///
/// Two shapes ship here:
///   • [HomeHeroOrnament] — a time-of-day aware celestial mark (sunrise
///     rays / full sun / dusk / crescent moon) that drops into the
///     Welcome header's top-right corner.
///   • [ManuscriptFrame] — corner flourishes + a center-divider for
///     wrapping Scripture content (used on the Verse of the Day card
///     so it reads as a page from an illuminated manuscript, not a
///     flat beige block).
///
/// Call out: user feedback on 2026-10-10 ("can we honestly build a
/// better graphic interface") pointed at the Home surfaces feeling
/// generic. The 16-agent review had flagged this months prior — the
/// parchment + wax-seal aesthetic the brand already owns on Codex was
/// nowhere on Home. These ornaments start porting it over without
/// commissioning anything.

enum CelestialPhase { dawn, midday, dusk, night }

CelestialPhase celestialPhaseForHour(int hour) {
  if (hour < 7) return CelestialPhase.dawn;
  if (hour < 17) return CelestialPhase.midday;
  if (hour < 20) return CelestialPhase.dusk;
  return CelestialPhase.night;
}

class HomeHeroOrnament extends StatelessWidget {
  final CelestialPhase phase;
  final double size;

  const HomeHeroOrnament({
    super.key,
    required this.phase,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeroOrnamentPainter(phase: phase)),
    );
  }
}

class _HeroOrnamentPainter extends CustomPainter {
  _HeroOrnamentPainter({required this.phase});
  final CelestialPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 4;
    switch (phase) {
      case CelestialPhase.dawn:
        _drawRisingSun(canvas, c, r);
        break;
      case CelestialPhase.midday:
        _drawFullSun(canvas, c, r);
        break;
      case CelestialPhase.dusk:
        _drawSettingSun(canvas, c, r);
        break;
      case CelestialPhase.night:
        _drawNightSky(canvas, c, r);
        break;
    }
  }

  Paint _gilt({double stroke = 1.3, double alpha = 1.0}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = stroke
    ..color = BrandColors.goldDeep.withValues(alpha: alpha);

  Paint _giltFill({double alpha = 0.6}) => Paint()
    ..style = PaintingStyle.fill
    ..color = BrandColors.gold.withValues(alpha: alpha);

  void _drawRisingSun(Canvas canvas, Offset c, double r) {
    // Horizon line below center.
    final horizonY = c.dy + r * 0.3;
    canvas.drawLine(
      Offset(c.dx - r * 1.0, horizonY),
      Offset(c.dx + r * 1.0, horizonY),
      _gilt(stroke: 1.1, alpha: 0.75),
    );
    // Sun half-disc rising from horizon.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(c.dx - r, c.dy - r, c.dx + r, horizonY));
    canvas.drawCircle(
      Offset(c.dx, horizonY),
      r * 0.55,
      _giltFill(alpha: 0.5),
    );
    canvas.drawCircle(
      Offset(c.dx, horizonY),
      r * 0.55,
      _gilt(stroke: 1.3),
    );
    canvas.restore();
    // 7 rays fanning up and out.
    for (int i = -3; i <= 3; i++) {
      final angle = -math.pi / 2 + (i / 3) * (math.pi * 0.42);
      final from = Offset(
        c.dx + math.cos(angle) * r * 0.62,
        horizonY + math.sin(angle) * r * 0.62,
      );
      final to = Offset(
        c.dx + math.cos(angle) * r * 0.95,
        horizonY + math.sin(angle) * r * 0.95,
      );
      canvas.drawLine(from, to, _gilt(stroke: 1.2));
    }
  }

  void _drawFullSun(Canvas canvas, Offset c, double r) {
    // Core disc.
    canvas.drawCircle(c, r * 0.42, _giltFill(alpha: 0.55));
    canvas.drawCircle(c, r * 0.42, _gilt(stroke: 1.3));
    // 12 alternating rays — long + short, like a monstrance.
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2;
      final rayLen = i.isEven ? r * 0.95 : r * 0.78;
      final from = Offset(
        c.dx + math.cos(angle) * r * 0.52,
        c.dy + math.sin(angle) * r * 0.52,
      );
      final to = Offset(
        c.dx + math.cos(angle) * rayLen,
        c.dy + math.sin(angle) * rayLen,
      );
      canvas.drawLine(from, to, _gilt(stroke: i.isEven ? 1.4 : 1.0));
    }
  }

  void _drawSettingSun(Canvas canvas, Offset c, double r) {
    final horizonY = c.dy + r * 0.1;
    canvas.drawLine(
      Offset(c.dx - r * 1.0, horizonY),
      Offset(c.dx + r * 1.0, horizonY),
      _gilt(stroke: 1.1, alpha: 0.75),
    );
    // Lower-horizon sun (half-set).
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(c.dx - r, c.dy - r, c.dx + r, horizonY));
    canvas.drawCircle(
      Offset(c.dx, horizonY),
      r * 0.6,
      _giltFill(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(c.dx, horizonY),
      r * 0.6,
      _gilt(stroke: 1.3),
    );
    canvas.restore();
    // Three gentle horizontal cloud lines above.
    for (int i = 0; i < 3; i++) {
      final y = horizonY - r * (0.55 + i * 0.18);
      final w = r * (0.65 - i * 0.12);
      canvas.drawLine(
        Offset(c.dx - w / 2, y),
        Offset(c.dx + w / 2, y),
        _gilt(stroke: 0.9, alpha: 0.5),
      );
    }
  }

  void _drawNightSky(Canvas canvas, Offset c, double r) {
    // Changed from a crescent moon (2026-10-10 user feedback: reads
    // as Islamic iconography — wrong brand signal on a Christian Bible
    // app) to a scattered starfield. Non-sectarian, poetic, and nods
    // to Psalm 147:4 — "He telleth the number of the stars; He
    // calleth them all by their names."
    //
    // Positions chosen by hand to feel like a natural evening sky
    // rather than a grid: one dominant 8-pointed star of Bethlehem
    // slightly left of center, with 6 smaller 4-point stars
    // scattered around it at varying sizes to give depth.
    _drawRadiantStar(
      canvas,
      Offset(c.dx - r * 0.12, c.dy + r * 0.05),
      r * 0.36,
    );
    _drawStar(canvas, Offset(c.dx + r * 0.55, c.dy - r * 0.65), r * 0.11);
    _drawStar(canvas, Offset(c.dx + r * 0.75, c.dy + r * 0.15), r * 0.08);
    _drawStar(canvas, Offset(c.dx - r * 0.70, c.dy - r * 0.55), r * 0.09);
    _drawStar(canvas, Offset(c.dx + r * 0.25, c.dy + r * 0.75), r * 0.07);
    _drawStar(canvas, Offset(c.dx - r * 0.55, c.dy + r * 0.60), r * 0.08);
    _drawStar(canvas, Offset(c.dx + r * 0.10, c.dy - r * 0.90), r * 0.06);
  }

  /// Larger, more decorative 8-pointed star (long + short arms
  /// alternating) with a filled center. Visually distinct from the
  /// small 4-pointed scatter stars so one star in the field reads as
  /// the dominant "Star of Bethlehem" anchor.
  void _drawRadiantStar(Canvas canvas, Offset c, double outer) {
    final inner = outer * 0.38;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final from = c;
      final tip = Offset(
        c.dx + math.cos(angle) * (i.isEven ? outer : outer * 0.55),
        c.dy + math.sin(angle) * (i.isEven ? outer : outer * 0.55),
      );
      path.moveTo(from.dx, from.dy);
      path.lineTo(tip.dx, tip.dy);
    }
    canvas.drawPath(path, _gilt(stroke: 1.1));
    canvas.drawCircle(c, inner * 0.4, _giltFill(alpha: 0.75));
  }

  void _drawStar(Canvas canvas, Offset c, double size) {
    final p = Path();
    for (int i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      p.moveTo(c.dx, c.dy);
      p.lineTo(
        c.dx + math.cos(angle) * size,
        c.dy + math.sin(angle) * size,
      );
    }
    canvas.drawPath(p, _gilt(stroke: 1.0));
  }

  @override
  bool shouldRepaint(_HeroOrnamentPainter old) => old.phase != phase;
}

/// Illuminated frame: subtle gold hairline rectangle with filigree
/// corner flourishes and (optionally) a decorative center-divider that
/// slots between a verse body and its reference line.
class ManuscriptFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const ManuscriptFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ManuscriptFramePainter(borderRadius: borderRadius),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ManuscriptFramePainter extends CustomPainter {
  _ManuscriptFramePainter({required this.borderRadius});
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Inset hairline rectangle, 8px inside the card's own border.
    final inset = rect.deflate(8);
    final rrect = RRect.fromRectAndRadius(
        inset, Radius.circular(borderRadius * 0.6));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = BrandColors.goldDeep.withValues(alpha: 0.45),
    );
    // Corner flourishes.
    _drawCornerFlourish(canvas, Offset(inset.left, inset.top), 0);
    _drawCornerFlourish(canvas, Offset(inset.right, inset.top), math.pi / 2);
    _drawCornerFlourish(
        canvas, Offset(inset.right, inset.bottom), math.pi);
    _drawCornerFlourish(
        canvas, Offset(inset.left, inset.bottom), -math.pi / 2);
  }

  void _drawCornerFlourish(Canvas canvas, Offset corner, double rotation) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.rotate(rotation);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = BrandColors.goldDeep.withValues(alpha: 0.7);
    // A quarter-circle arc with two small ticks — reads as a vine
    // flourish without being busy.
    final arcRect = Rect.fromCircle(center: Offset.zero, radius: 10);
    canvas.drawArc(arcRect, 0, math.pi / 2, false, paint);
    // Decorative seed at the arc endpoint.
    canvas.drawCircle(
      Offset(10, 0),
      1.6,
      Paint()..color = BrandColors.goldDeep.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(0, 10),
      1.6,
      Paint()..color = BrandColors.goldDeep.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ManuscriptFramePainter old) =>
      old.borderRadius != borderRadius;
}

/// Horizontal divider used between a verse body and its reference line.
/// A hairline with a central diamond + two small seeds.
class ManuscriptDivider extends StatelessWidget {
  final double height;
  final double maxWidth;

  const ManuscriptDivider({
    super.key,
    this.height = 18,
    this.maxWidth = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: maxWidth,
        height: height,
        child: CustomPaint(painter: _ManuscriptDividerPainter()),
      ),
    );
  }
}

class _ManuscriptDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8
      ..color = BrandColors.goldDeep.withValues(alpha: 0.6);
    final diamondHalfW = 4.0;
    final leftEnd = size.width / 2 - diamondHalfW - 6;
    final rightStart = size.width / 2 + diamondHalfW + 6;
    // Two hairlines flanking the center diamond.
    canvas.drawLine(Offset(0, mid), Offset(leftEnd, mid), paint);
    canvas.drawLine(Offset(rightStart, mid), Offset(size.width, mid), paint);
    // Diamond.
    final diamond = Path()
      ..moveTo(size.width / 2, mid - 4)
      ..lineTo(size.width / 2 + diamondHalfW, mid)
      ..lineTo(size.width / 2, mid + 4)
      ..lineTo(size.width / 2 - diamondHalfW, mid)
      ..close();
    canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.fill
          ..color = BrandColors.goldDeep.withValues(alpha: 0.75));
    canvas.drawPath(diamond, paint);
    // Seeds at the outer ends of the hairlines.
    canvas.drawCircle(Offset(0, mid), 1.4,
        Paint()..color = BrandColors.goldDeep.withValues(alpha: 0.7));
    canvas.drawCircle(Offset(size.width, mid), 1.4,
        Paint()..color = BrandColors.goldDeep.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(_ManuscriptDividerPainter old) => false;
}
