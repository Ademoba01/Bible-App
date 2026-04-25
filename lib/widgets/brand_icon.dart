import 'package:flutter/material.dart';

/// A styled icon "chip" — Material icon inside a circular tinted badge with
/// a subtle ring and inner gradient. Used for Quick Action tiles, Verse-of-
/// the-Day affordances, and any other place where a plain `Icon()` looks
/// flat.
///
/// Visual: 44dp circle (configurable), tinted background derived from the
/// passed [color], a 1px ring at 30% alpha, and a soft radial gradient inside.
/// The icon itself is rendered at ~55% of the circle in the same brand color
/// at full opacity for clean contrast.
///
/// Why not just `CircleAvatar`? CircleAvatar gives a flat fill. This widget
/// gives tactile depth without leaving the parchment palette feeling foreign.
class BrandIcon extends StatelessWidget {
  const BrandIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconScale = 0.55,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// Icon glyph as a fraction of the circle diameter.
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.95,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.32),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * iconScale,
        color: color,
      ),
    );
  }
}
