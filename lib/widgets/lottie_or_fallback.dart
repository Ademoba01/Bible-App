import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Renders a Lottie animation OR a graceful icon fallback if the asset is
/// missing / fails to decode. Most of our screens use Material Icons or
/// CustomPainter for animation; this widget is reserved for "moments" where
/// a proper Lottie sells the experience — quiz celebrations, codex unlocks,
/// streak milestones.
///
/// We deliberately do NOT use Lottie for things tied to an existing
/// AnimationController (like the Listen disc waveform) — Lottie animations
/// have their own internal timeline that drifts from controller-driven
/// effects.
class LottieOrFallback extends StatelessWidget {
  const LottieOrFallback({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.fallbackColor,
    this.size = 120,
    this.repeat = true,
    this.controller,
  });

  /// e.g. "assets/animations/confetti.json"
  final String assetPath;

  /// Shown when the Lottie asset fails to load. Keeps the layout stable
  /// even if a designer hasn't dropped in the JSON yet.
  final IconData fallbackIcon;
  final Color? fallbackColor;

  /// Widget size. The Lottie composition will scale to fit.
  final double size;

  /// Whether the animation loops. Most celebrations should be `false`.
  final bool repeat;

  /// Optional external controller. If null, Lottie drives itself.
  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        repeat: repeat,
        controller: controller,
        fit: BoxFit.contain,
        // Graceful fallback: show a tinted icon instead of a red error box
        // if the asset is missing or malformed.
        errorBuilder: (context, error, stack) => Center(
          child: Icon(
            fallbackIcon,
            size: size * 0.6,
            color: fallbackColor ??
                Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Pre-configured paths to the bundled Lottie animations. Centralized so
/// designers / contributors know where to drop new files (and so the app
/// only references these in one place — easy to swap implementations).
class LottieAssets {
  LottieAssets._();

  /// Burst of confetti — perfect for quiz "you got it!" moments.
  static const confetti = 'assets/animations/confetti.json';

  /// Single sparkle — for codex seal unlocks and streak milestones.
  static const sparkle = 'assets/animations/sparkle.json';

  /// Animated checkmark — for "completed" affirmations.
  static const checkmark = 'assets/animations/checkmark.json';
}
