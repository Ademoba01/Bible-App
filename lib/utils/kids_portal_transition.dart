import 'package:flutter/material.dart';
import '../../theme.dart';

/// A fun, animated "portal" transition for entering Kids mode.
/// Shows a colorful expanding circle with stars before switching modes.
class KidsPortalOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const KidsPortalOverlay({super.key, required this.onComplete});

  @override
  State<KidsPortalOverlay> createState() => _KidsPortalOverlayState();
}

class _KidsPortalOverlayState extends State<KidsPortalOverlay>
    with TickerProviderStateMixin {
  late AnimationController _expandCtrl;
  late AnimationController _starsCtrl;
  late Animation<double> _expandAnim;
  late Animation<double> _starsFade;
  late Animation<double> _starsScale;

  @override
  void initState() {
    super.initState();

    // Circle expand animation
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _expandAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic),
    );

    // Stars/emoji pop animation
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _starsCtrl, curve: Curves.easeOut),
    );
    _starsScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _starsCtrl, curve: Curves.elasticOut),
    );

    // Start sequence
    _starsCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _expandCtrl.forward();
    });

    _expandCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxRadius = size.longestSide * 1.5;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Expanding colorful circle
          AnimatedBuilder(
            animation: _expandAnim,
            builder: (context, _) {
              return Center(
                child: Container(
                  width: maxRadius * _expandAnim.value,
                  height: maxRadius * _expandAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        BrandColors.kidsBlue,
                        BrandColors.kidsPurple,
                        BrandColors.kidsPink,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Fun emojis bursting out
          Center(
            child: FadeTransition(
              opacity: _starsFade,
              child: ScaleTransition(
                scale: _starsScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '\u2728 \u{1F60A} \u2728',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kids Mode!',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the kids portal animation overlay, then switches to kids mode.
void showKidsPortal(BuildContext context, VoidCallback switchToKids) {
  final overlay = OverlayEntry(
    builder: (ctx) => KidsPortalOverlay(
      onComplete: () {},
    ),
  );

  Overlay.of(context).insert(overlay);

  // After animation, switch mode and remove overlay
  Future.delayed(const Duration(milliseconds: 1000), () {
    switchToKids();
    Future.delayed(const Duration(milliseconds: 200), () {
      overlay.remove();
    });
  });
}
