import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/providers.dart';
import '../../theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _featuresFade;
  late Animation<Offset> _buttonsSlide;
  late Animation<double> _buttonsFade;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic)),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.15, 0.5, curve: Curves.easeOut)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    _featuresFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.5, 0.8, curve: Curves.elasticOut)),
    );
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic)),
    );
    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );

    // Pulsing gold glow
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 700;
    final heroSize = (screenHeight * 0.18).clamp(100.0, 160.0);
    final titleSize = (screenWidth * 0.115).clamp(32.0, 48.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0E0A),
              Color(0xFF3E2723),
              Color(0xFF5D4037),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 400 ? 24 : 32,
              vertical: isShort ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacer(flex: isShort ? 1 : 2),

                // ── Hero logo with animated gold glow ──
                FadeTransition(
                  opacity: _heroFade,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _glowPulse,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.gold.withValues(alpha: _glowPulse.value),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: BrandColors.gold.withValues(alpha: _glowPulse.value * 1.2),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Hero(
                        tag: 'brand-hero',
                        child: Container(
                          width: heroSize,
                          height: heroSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF5D4037),
                                Color(0xFF3E2723),
                              ],
                            ),
                            border: Border.all(
                              color: BrandColors.gold.withValues(alpha: 0.6),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Cross
                              Icon(
                                Icons.add,
                                size: heroSize * 0.18,
                                color: BrandColors.gold,
                              ),
                              SizedBox(height: heroSize * 0.02),
                              // Open Bible icon
                              Icon(
                                Icons.auto_stories,
                                size: heroSize * 0.35,
                                color: const Color(0xFFF5ECD7),
                              ),
                              SizedBox(height: heroSize * 0.04),
                              // "R" monogram
                              Text(
                                'R',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: heroSize * 0.15,
                                  fontWeight: FontWeight.w700,
                                  color: BrandColors.gold,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isShort ? 20 : 32),

                // ── Title with slide-up animation ──
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Column(
                      children: [
                        Text(
                          'Rhema',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'STUDY BIBLE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: (titleSize * 0.3).clamp(11.0, 14.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                            color: BrandColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isShort ? 8 : 12),

                // ── Subtitle fade-in ──
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'The Bible that listens\nand speaks your language',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: (screenWidth * 0.042).clamp(14.0, 17.0),
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: isShort ? 16 : 24),

                // ── Feature icons with elastic pop ──
                FadeTransition(
                  opacity: _featuresFade,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: const [
                      _FeatureIcon(Icons.auto_awesome, 'AI Search'),
                      _FeatureIcon(Icons.headphones, 'Audio'),
                      _FeatureIcon(Icons.map_outlined, 'Maps'),
                      _FeatureIcon(Icons.quiz_outlined, 'Quizzes'),
                    ],
                  ),
                ),
                Spacer(flex: isShort ? 1 : 2),

                // ── Buttons with slide-up ──
                SlideTransition(
                  position: _buttonsSlide,
                  child: FadeTransition(
                    opacity: _buttonsFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Daily verse teaser
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: BrandColors.gold.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 18, color: BrandColors.gold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '"God is our refuge and strength, an ever-present help in trouble."',
                                  style: GoogleFonts.lora(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ModeButton(
                          label: 'Start reading',
                          icon: Icons.menu_book,
                          primary: true,
                          onTap: () async {
                            await ref.read(settingsProvider.notifier).setKidsMode(false);
                            await ref.read(settingsProvider.notifier).completeOnboarding();
                          },
                        ),
                        const SizedBox(height: 12),
                        _ModeButton(
                          label: 'Kids mode',
                          icon: Icons.child_care,
                          primary: false,
                          onTap: () async {
                            await ref.read(settingsProvider.notifier).setKidsMode(true);
                            await ref.read(settingsProvider.notifier).completeOnboarding();
                          },
                        ),
                        const SizedBox(height: 16),
                        // Translation chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: const [
                            _TranslationChip(label: 'KJV', available: true),
                            _TranslationChip(label: 'WEB', available: true),
                            _TranslationChip(label: 'BSB', available: true),
                            _TranslationChip(label: 'Hindi', available: true),
                            _TranslationChip(label: '10+ more', available: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslationChip extends StatelessWidget {
  const _TranslationChip({required this.label, required this.available});
  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: available
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: available
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        available ? label : '$label (soon)',
        style: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: available
              ? Colors.white
              : Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrandColors.goldLight, BrandColors.gold],
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.gold.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Icon(icon, color: BrandColors.dark, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.dark,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: BrandColors.dark),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: BrandColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, size: 24, color: BrandColors.gold),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
