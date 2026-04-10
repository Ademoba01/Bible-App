import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/providers.dart';
import '../../theme.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrandColors.brown, BrandColors.brownMid],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Hero(
                    tag: 'brand-hero',
                    child: Image.asset(
                      'assets/brand/hero.png',
                      width: 220,
                      height: 220,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Our Bible',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'that listens and speaks\nyour language',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                _ModeButton(
                  label: 'Start reading',
                  icon: Icons.menu_book,
                  primary: true,
                  onTap: () async {
                    await ref.read(settingsProvider.notifier).setKidsMode(false);
                    await ref.read(settingsProvider.notifier).completeOnboarding();
                  },
                ),
                const SizedBox(height: 14),
                _ModeButton(
                  label: 'Kids mode',
                  icon: Icons.child_care,
                  primary: false,
                  onTap: () async {
                    await ref.read(settingsProvider.notifier).setKidsMode(true);
                    await ref.read(settingsProvider.notifier).completeOnboarding();
                  },
                ),
                const SizedBox(height: 24),
                // Translation chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _TranslationChip(label: 'KJV', available: true),
                    _TranslationChip(label: 'WEB', available: true),
                    _TranslationChip(label: 'BSB', available: false),
                    _TranslationChip(label: 'Pidgin', available: false),
                    _TranslationChip(label: 'Yoruba', available: false),
                  ],
                ),
                const SizedBox(height: 8),
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
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: available
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        available ? label : '$label (soon)',
        style: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: available
              ? Colors.white
              : Colors.white.withValues(alpha: 0.6),
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
    final bg = primary ? BrandColors.gold : Colors.white.withValues(alpha: 0.14);
    final fg = primary ? BrandColors.dark : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
