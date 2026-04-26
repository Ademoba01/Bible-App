import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/providers.dart';
import '../theme.dart';

/// Centered Rhema logo + wordmark used as an AppBar title across the app.
///
/// Visual: small icon disc on the left of "Rhema Study Bible" in
/// Playfair Display, gold against whatever AppBar background it sits on.
///
/// Tap behavior: navigates back to the Home tab (tabIndexProvider = 0)
/// AND pops the current screen if it can be popped — so it works both
/// as a brand mark on top-level screens and as a "go home" affordance
/// on pushed routes.
class RhemaTitle extends ConsumerWidget {
  const RhemaTitle({
    super.key,
    this.color,
    this.compact = false,
  });

  /// Wordmark color — defaults to BrandColors.gold for visibility on the
  /// brown AppBar; pass a contrasting color for light/dark backgrounds.
  final Color? color;

  /// Compact mode hides the wordmark on small viewports so the icon alone
  /// stands as the brand mark (used on narrow screens).
  final bool compact;

  void _goHome(BuildContext context, WidgetRef ref) {
    ref.read(tabIndexProvider.notifier).set(0);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordmarkColor = color ?? BrandColors.gold;
    return Semantics(
      button: true,
      label: 'Rhema Study Bible — go to home',
      child: InkWell(
        onTap: () => _goHome(context, ref),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand icon disc — uses the bundled launcher icon so it always
              // matches the app icon users see on their home screen.
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.gold.withValues(alpha: 0.15),
                  border: Border.all(
                    color: BrandColors.gold.withValues(alpha: 0.45),
                    width: 1,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/brand/icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Text(
                  'Rhema Study Bible',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: wordmarkColor,
                    letterSpacing: 0.4,
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
