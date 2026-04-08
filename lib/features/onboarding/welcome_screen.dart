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
                  'The Bible',
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
                Text(
                  'WEB  •  BSB  •  Pidgin  •  Yoruba  •  more coming',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
