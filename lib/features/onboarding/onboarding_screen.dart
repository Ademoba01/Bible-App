import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// 3-step onboarding: Intent -> Language -> First Verse.
/// Persists step + intent so a user resumes mid-flow on next launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _kStepKey = 'onboarding_step';
  static const _kIntentKey = 'onboarding_intent';

  final PageController _pageController = PageController();
  int _step = 0;
  String? _intent;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStep = prefs.getInt(_kStepKey) ?? 0;
    final savedIntent = prefs.getString(_kIntentKey);
    if (!mounted) return;
    setState(() {
      _step = savedStep.clamp(0, 2);
      _intent = savedIntent;
      _restored = true;
    });
    // Jump the PageController after the first frame so the page exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _step != 0) {
        _pageController.jumpToPage(_step);
      }
    });
  }

  Future<void> _persistStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStepKey, step);
  }

  Future<void> _persistIntent(String intent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIntentKey, intent);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStepKey);
    await prefs.remove(_kIntentKey);
  }

  void _goToStep(int step) {
    if (step < 0 || step > 2) return;
    setState(() => _step = step);
    _persistStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    await _clearProgress();
    if (!mounted) return;
    ref.read(readingLocationProvider.notifier).setBook('John');
    ref.read(readingLocationProvider.notifier).setChapter(3);
    ref.read(highlightVerseProvider.notifier).state = 16;
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0E0A),
        body: Center(
          child: CircularProgressIndicator(color: BrandColors.gold),
        ),
      );
    }

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
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() => _step = i);
                    _persistStep(i);
                  },
                  children: [
                    _IntentStep(
                      selected: _intent,
                      onSelected: (intent) {
                        setState(() => _intent = intent);
                        _persistIntent(intent);
                      },
                    ),
                    const _LanguageStep(),
                    _FirstVerseStep(onCompleted: _finishOnboarding),
                  ],
                ),
              ),
              _BottomBar(
                step: _step,
                canAdvance: _step != 0 || _intent != null,
                onBack: _step > 0 ? () => _goToStep(_step - 1) : null,
                onNext: _step < 2 ? () => _goToStep(_step + 1) : null,
                onFinish: _finishOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Step 1 — Intent
// ────────────────────────────────────────────────────────────────────

class _IntentOption {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  const _IntentOption(this.id, this.emoji, this.title, this.subtitle);
}

const _intentOptions = <_IntentOption>[
  _IntentOption(
      'new', '\u{1F331}', 'New to the Bible', 'Start with the basics'),
  _IntentOption(
      'hard_time', '\u{1F4AA}', 'Going through a hard time',
      'Verses for when life feels heavy'),
  _IntentOption(
      'pray', '\u{1F64F}', 'Learning to pray',
      'How Jesus taught us to talk to God'),
  _IntentOption(
      'study', '\u{1F4D6}', 'Study deeper',
      'Go further with study tools and AI'),
  _IntentOption(
      'explore', '\u{2728}', 'Just exploring',
      'See what the Bible has to say'),
];

class _IntentStep extends StatelessWidget {
  const _IntentStep({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Why are you\nhere today?',
            style: GoogleFonts.lora(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pick what feels closest. We\u2019ll tailor your first verses.',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _intentOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final opt = _intentOptions[i];
                return _IntentCard(
                  option: opt,
                  selected: selected == opt.id,
                  onTap: () => onSelected(opt.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _IntentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? BrandColors.gold.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? BrandColors.gold
                  : Colors.white.withValues(alpha: 0.16),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? BrandColors.gold
                    : Colors.white.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Step 2 — Language / Translation
// ────────────────────────────────────────────────────────────────────

class _TranslationOption {
  final String id;
  final String label;
  final String language;
  final String note;
  const _TranslationOption(this.id, this.label, this.language, this.note);
}

const _translationOptions = <_TranslationOption>[
  _TranslationOption('kjv', 'KJV', 'English', 'Offline \u2022 Classic 1611'),
  _TranslationOption('web', 'WEB', 'English', 'Offline \u2022 Modern public domain'),
  _TranslationOption('OYCB', 'OYCB', 'Yorùbá', 'Bíbélì Mímọ́ ní Èdè Yorùbá'),
  _TranslationOption('OHCB', 'OHCB', 'Hausa', 'Littafi Mai Tsarki'),
  _TranslationOption('OICB', 'OICB', 'Igbo', 'Baịbụl Nsọ'),
];

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider).translation;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Read in your\nlanguage',
            style: GoogleFonts.lora(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pick a translation. You can change this anytime in Settings.',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _translationOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _translationOptions[i];
                final selected = current == opt.id;
                return _TranslationTile(
                  option: opt,
                  selected: selected,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setTranslation(opt.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationTile extends StatelessWidget {
  const _TranslationTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _TranslationOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? BrandColors.gold.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? BrandColors.gold
                  : Colors.white.withValues(alpha: 0.16),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Radio(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          option.label,
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            option.language,
                            style: GoogleFonts.lora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.note,
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? BrandColors.gold
              : Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.gold,
                ),
              ),
            )
          : null,
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Step 3 — First Verse (John 3:16)
// ────────────────────────────────────────────────────────────────────

class _FirstVerseStep extends ConsumerWidget {
  const _FirstVerseStep({required this.onCompleted});
  final Future<void> Function() onCompleted;

  Future<String?> _loadVerse(WidgetRef ref, String tid) async {
    final repo = ref.read(bibleRepositoryProvider);
    try {
      final chapters = await repo.loadBook('John', translationId: tid);
      if (chapters.length < 3) return null;
      final c3 = chapters.firstWhere(
        (c) => c.number == 3,
        orElse: () => Chapter(0, const []),
      );
      if (c3.verses.isEmpty) return null;
      final v16 = c3.verses.where((v) => v.number == 16).firstOrNull;
      return v16?.text;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tid = ref.watch(settingsProvider).translation;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Your first\nverse awaits',
            style: GoogleFonts.lora(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'John 3:16 \u2014 the heart of the Gospel.',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<String?>(
              future: _loadVerse(ref, tid),
              builder: (context, snap) {
                final text = snap.data;
                final loading =
                    snap.connectionState == ConnectionState.waiting;
                return _VerseCard(
                  reference: 'John 3:16',
                  text: text,
                  loading: loading,
                  onTap: onCompleted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.reference,
    required this.text,
    required this.loading,
    required this.onTap,
  });
  final String reference;
  final String? text;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: loading ? null : onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BrandColors.gold.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: BrandColors.gold.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.gold.withValues(alpha: 0.15),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_quote,
                            color: BrandColors.gold, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          reference,
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: BrandColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: loading
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Loading\u2026',
                                  style: GoogleFonts.lora(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              )
                            : Text(
                                text ??
                                    'For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life.',
                                style: GoogleFonts.lora(
                                  fontSize: 19,
                                  height: 1.55,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tap to open',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.gold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 16, color: BrandColors.gold),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bottom bar — dots indicator + Back / Next / final CTA
// ────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.canAdvance,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
  });
  final int step;
  final bool canAdvance;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    final isLast = step == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active
                      ? BrandColors.gold
                      : Colors.white.withValues(alpha: 0.25),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.85),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isLast
                    ? _PrimaryButton(
                        label: 'Read your first verse',
                        enabled: true,
                        onTap: () => onFinish(),
                      )
                    : _PrimaryButton(
                        label: 'Next',
                        enabled: canAdvance,
                        onTap: canAdvance ? onNext : null,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrandColors.goldLight, BrandColors.gold],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: BrandColors.gold.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.dark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward,
                      color: BrandColors.dark, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
