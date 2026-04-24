import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A wax-seal style milestone badge. Rendered entirely with [CustomPainter] —
/// no image assets required.
///
/// When [earned] is true, draws a full oxblood wax impression with a subtle
/// embossed highlight on the emblem. When false, draws a faint intaglio
/// outline on parchment, hinting at what's to come.
///
/// Supported [emblem] values:
/// `dove`, `scroll`, `cross`, `crown`, `alpha_omega`.
class WaxSeal extends StatelessWidget {
  final String emblem;
  final double size;
  final bool earned;

  const WaxSeal({
    super.key,
    required this.emblem,
    this.size = 80,
    this.earned = false,
  });

  static const Color oxblood = Color(0xFF7A2E2E);
  static const Color parchment = Color(0xFFF4E9D0);
  static const Color gilt = Color(0xFFC4923E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WaxSealPainter(emblem: emblem, earned: earned),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  _WaxSealPainter({required this.emblem, required this.earned});

  final String emblem;
  final bool earned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    if (earned) {
      _paintEarned(canvas, center, radius);
    } else {
      _paintLocked(canvas, center, radius);
    }
  }

  // ─── Earned: full oxblood wax impression ────────────────────
  void _paintEarned(Canvas canvas, Offset c, double r) {
    // Soft drop shadow.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(c.translate(0, 1.5), r, shadow);

    // Wax body — radial gradient so the seal feels three-dimensional.
    final wax = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: const [
          Color(0xFF9B3D3D),
          WaxSeal.oxblood,
          Color(0xFF5C2222),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, wax);

    // Decorative scalloped rim.
    _drawScallops(canvas, c, r, WaxSeal.oxblood.withValues(alpha: 0.85));

    // Inner ring suggests the impression depth.
    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.black.withValues(alpha: 0.20);
    canvas.drawCircle(c, r * 0.78, innerRing);

    // Emblem.
    final emblemPaint = Paint()
      ..color = WaxSeal.parchment.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    _drawEmblem(canvas, c, r * 0.5, emblemPaint, highlight, embossed: true);
  }

  // ─── Locked: faint intaglio outline ─────────────────────────
  void _paintLocked(Canvas canvas, Offset c, double r) {
    final bg = Paint()..color = WaxSeal.parchment;
    canvas.drawCircle(c, r, bg);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = WaxSeal.oxblood.withValues(alpha: 0.28);
    canvas.drawCircle(c, r, outline);
    canvas.drawCircle(c, r * 0.78, outline);

    final emblemPaint = Paint()
      ..color = WaxSeal.oxblood.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    _drawEmblem(canvas, c, r * 0.5, emblemPaint, null, embossed: false);
  }

  // ─── Scalloped rim (12 small arcs) ──────────────────────────
  void _drawScallops(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()..color = color;
    const count = 12;
    final scallopR = r * 0.12;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2;
      final x = c.dx + math.cos(angle) * r;
      final y = c.dy + math.sin(angle) * r;
      canvas.drawCircle(Offset(x, y), scallopR, paint);
    }
  }

  // ─── Emblem dispatch ────────────────────────────────────────
  void _drawEmblem(
    Canvas canvas,
    Offset c,
    double s,
    Paint p,
    Paint? highlight, {
    required bool embossed,
  }) {
    switch (emblem) {
      case 'dove':
        _drawDove(canvas, c, s, p, highlight, embossed);
        break;
      case 'scroll':
        _drawScroll(canvas, c, s, p, highlight, embossed);
        break;
      case 'cross':
        _drawCross(canvas, c, s, p, highlight, embossed);
        break;
      case 'crown':
        _drawCrown(canvas, c, s, p, highlight, embossed);
        break;
      case 'alpha_omega':
        _drawAlphaOmega(canvas, c, s, p);
        break;
      default:
        // Fallback: dot.
        canvas.drawCircle(c, s * 0.3, p);
    }
  }

  // Dove — body + triangular wing.
  void _drawDove(Canvas canvas, Offset c, double s, Paint p, Paint? highlight, bool embossed) {
    final body = Path()
      ..moveTo(c.dx - s * 0.7, c.dy + s * 0.1)
      ..quadraticBezierTo(c.dx - s * 0.2, c.dy - s * 0.4, c.dx + s * 0.4, c.dy - s * 0.1)
      ..quadraticBezierTo(c.dx + s * 0.7, c.dy - s * 0.05, c.dx + s * 0.85, c.dy + s * 0.15)
      ..lineTo(c.dx + s * 0.55, c.dy + s * 0.2)
      ..quadraticBezierTo(c.dx, c.dy + s * 0.5, c.dx - s * 0.7, c.dy + s * 0.1)
      ..close();
    canvas.drawPath(body, p);

    // Triangular wing.
    final wing = Path()
      ..moveTo(c.dx - s * 0.1, c.dy - s * 0.15)
      ..lineTo(c.dx + s * 0.35, c.dy - s * 0.05)
      ..lineTo(c.dx + s * 0.05, c.dy + s * 0.25)
      ..close();
    if (embossed && highlight != null) {
      canvas.drawPath(wing, highlight);
    } else {
      canvas.drawPath(wing, p);
    }
  }

  // Scroll — central rect with two curls (left/right).
  void _drawScroll(Canvas canvas, Offset c, double s, Paint p, Paint? highlight, bool embossed) {
    // Body.
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: s * 1.3, height: s * 0.7),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(body, p);

    // Left curl.
    final leftCurl = Path()
      ..addOval(Rect.fromCircle(center: Offset(c.dx - s * 0.65, c.dy), radius: s * 0.35));
    canvas.drawPath(leftCurl, p);
    // Right curl.
    final rightCurl = Path()
      ..addOval(Rect.fromCircle(center: Offset(c.dx + s * 0.65, c.dy), radius: s * 0.35));
    canvas.drawPath(rightCurl, p);

    // Inner highlight rings.
    if (embossed && highlight != null) {
      canvas.drawCircle(Offset(c.dx - s * 0.65, c.dy), s * 0.15, highlight);
      canvas.drawCircle(Offset(c.dx + s * 0.65, c.dy), s * 0.15, highlight);
    } else {
      final inner = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = p.color;
      canvas.drawCircle(Offset(c.dx - s * 0.65, c.dy), s * 0.15, inner);
      canvas.drawCircle(Offset(c.dx + s * 0.65, c.dy), s * 0.15, inner);
    }
  }

  // Cross — vertical + horizontal bar.
  void _drawCross(Canvas canvas, Offset c, double s, Paint p, Paint? highlight, bool embossed) {
    final vertical = Rect.fromCenter(center: c, width: s * 0.3, height: s * 1.6);
    final horizontal = Rect.fromCenter(
      center: Offset(c.dx, c.dy - s * 0.2),
      width: s * 0.95,
      height: s * 0.3,
    );
    if (embossed) {
      canvas.drawRect(vertical, p);
      canvas.drawRect(horizontal, p);
      if (highlight != null) {
        // Light stripe on the left side of the cross.
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(c.dx - s * 0.06, c.dy),
            width: s * 0.06,
            height: s * 1.5,
          ),
          highlight,
        );
      }
    } else {
      canvas.drawRect(vertical, p);
      canvas.drawRect(horizontal, p);
    }
  }

  // Crown — three peaks rising from a base.
  void _drawCrown(Canvas canvas, Offset c, double s, Paint p, Paint? highlight, bool embossed) {
    final path = Path()
      ..moveTo(c.dx - s * 0.8, c.dy + s * 0.4)
      ..lineTo(c.dx - s * 0.8, c.dy - s * 0.05)
      ..lineTo(c.dx - s * 0.45, c.dy + s * 0.2)
      ..lineTo(c.dx - s * 0.15, c.dy - s * 0.55)
      ..lineTo(c.dx + s * 0.15, c.dy + s * 0.2)
      ..lineTo(c.dx + s * 0.45, c.dy - s * 0.55)
      ..lineTo(c.dx + s * 0.8, c.dy + s * 0.2)
      ..lineTo(c.dx + s * 0.8, c.dy - s * 0.05)
      ..lineTo(c.dx + s * 0.8, c.dy + s * 0.4)
      ..close();

    canvas.drawPath(path, p);

    // Three small jewels at the tips.
    if (embossed && highlight != null) {
      canvas.drawCircle(Offset(c.dx - s * 0.15, c.dy - s * 0.5), s * 0.08, highlight);
      canvas.drawCircle(Offset(c.dx + s * 0.45, c.dy - s * 0.5), s * 0.08, highlight);
      canvas.drawCircle(Offset(c.dx - s * 0.75, c.dy - s * 0.05), s * 0.06, highlight);
    }

    // Base bar.
    canvas.drawRect(
      Rect.fromLTWH(
        c.dx - s * 0.85,
        c.dy + s * 0.3,
        s * 1.7,
        s * 0.18,
      ),
      p,
    );
  }

  // Α / Ω — two letters drawn with TextPainter.
  void _drawAlphaOmega(Canvas canvas, Offset c, double s, Paint p) {
    final style = TextStyle(
      color: p.color,
      fontSize: s * 1.1,
      fontWeight: FontWeight.w700,
      // System serif is fine here — keeps widget self-contained.
      fontFamily: 'serif',
    );
    final alpha = TextPainter(
      text: TextSpan(text: 'Α', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final omega = TextPainter(
      text: TextSpan(text: 'Ω', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    alpha.paint(
      canvas,
      Offset(c.dx - s * 0.85, c.dy - alpha.height / 2),
    );
    omega.paint(
      canvas,
      Offset(c.dx + s * 0.05, c.dy - omega.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _WaxSealPainter old) =>
      old.emblem != emblem || old.earned != earned;
}
