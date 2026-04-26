import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/books.dart';
import '../../state/codex_provider.dart';
import '../../widgets/lottie_or_fallback.dart';
import '../../widgets/wax_seal.dart';

/// "Your Codex" — gamified milestone screen rendered on parchment with
/// oxblood wax seals. Reads from [codexProvider].
class CodexScreen extends ConsumerStatefulWidget {
  const CodexScreen({super.key});

  @override
  ConsumerState<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends ConsumerState<CodexScreen> {
  static const _parchment = Color(0xFFF4E9D0);
  static const _oxblood = Color(0xFF7A2E2E);
  static const _gilt = Color(0xFFC4923E);
  static const _ink = Color(0xFF3E2A1B);

  // Gospels of the New Testament, used to test the "Four Gospels" milestone.
  static const _gospels = ['Matthew', 'Mark', 'Luke', 'John'];

  // Milestone definitions — order matters, this is the visual order on the
  // grid. `test` reads streak state and decides whether the seal is earned.
  late final List<_Milestone> _milestones = [
    _Milestone(
      label: 'First Chapter',
      emblem: 'scroll',
      test: (s) => s.chaptersRead.isNotEmpty,
    ),
    _Milestone(
      label: 'First Book',
      emblem: 'scroll',
      test: (s) => s.booksCompleted.isNotEmpty,
    ),
    _Milestone(
      label: 'Gospel of Matthew',
      emblem: 'cross',
      test: (s) => s.booksCompleted.contains('Matthew'),
    ),
    _Milestone(
      label: 'All Four Gospels',
      emblem: 'dove',
      test: (s) => _gospels.every(s.booksCompleted.contains),
    ),
    _Milestone(
      label: 'New Testament',
      emblem: 'crown',
      test: (s) => kAllBooks
          .where((b) => b.testament == 'NT')
          .every((b) => s.booksCompleted.contains(b.name)),
    ),
    _Milestone(
      label: 'Consummatum',
      emblem: 'alpha_omega',
      test: (s) =>
          kAllBooks.every((b) => s.booksCompleted.contains(b.name)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(codexProvider);

    return Scaffold(
      backgroundColor: _parchment,
      appBar: AppBar(
        backgroundColor: _parchment,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          'Your Codex',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _streakBadge(streak.current, streak.longest),
            const SizedBox(height: 28),
            _sectionTitle('Seals Earned'),
            const SizedBox(height: 12),
            _sealsGrid(streak),
            const SizedBox(height: 32),
            _sectionTitle('Books Read'),
            const SizedBox(height: 12),
            _booksGrid(streak.booksCompleted),
            const SizedBox(height: 32),
            _sectionTitle('Streak Freezes'),
            const SizedBox(height: 12),
            _freezesRow(streak.freezesAvailable),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Header streak badge ─────────────────────────────────────
  Widget _streakBadge(int current, int longest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _oxblood.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _oxblood.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: _oxblood, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$current day${current == 1 ? '' : 's'}',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              Text(
                'Current streak  ·  Longest: $longest',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: _ink.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _ink,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: _gilt.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  // ─── Seals grid ──────────────────────────────────────────────
  Widget _sealsGrid(CodexState streak) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _milestones.length,
      itemBuilder: (_, i) {
        final m = _milestones[i];
        final earned = m.test(streak);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stack the seal under a Lottie sparkle when earned — gives an
            // ambient "this milestone is alive" treatment without an
            // intrusive popup. Sparkle loops gently, low-key.
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  WaxSeal(emblem: m.emblem, size: 76, earned: earned),
                  if (earned)
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0.7,
                        child: LottieOrFallback(
                          assetPath: LottieAssets.sparkle,
                          fallbackIcon: Icons.auto_awesome,
                          fallbackColor: const Color(0xFFC4923E),
                          size: 92,
                          repeat: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              m.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 12,
                fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
                color: earned ? _ink : _ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Books grid (66) ─────────────────────────────────────────
  Widget _booksGrid(Set<String> completed) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
      ),
      itemCount: kAllBooks.length,
      itemBuilder: (_, i) {
        final book = kAllBooks[i];
        final isDone = completed.contains(book.name);
        return _bookTile(book.name, isDone);
      },
    );
  }

  Widget _bookTile(String name, bool isDone) {
    final dropCap = name.replaceAll(RegExp(r'^[0-9 ]+'), '').isNotEmpty
        ? name.replaceAll(RegExp(r'^[0-9 ]+'), '')[0]
        : name[0];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? _gilt.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? _gilt.withValues(alpha: 0.55)
              : _ink.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Illuminated drop-cap.
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone
                  ? _gilt.withValues(alpha: 0.85)
                  : _ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              dropCap,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDone ? Colors.white : _ink.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 11,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                color: isDone ? _ink : _ink.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Freezes ─────────────────────────────────────────────────
  Widget _freezesRow(int freezes) {
    if (freezes <= 0) {
      return Text(
        'No freezes available. Earn them through study plans.',
        style: GoogleFonts.lora(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: _ink.withValues(alpha: 0.6),
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        freezes,
        (_) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F0F7),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF6FA8C9).withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.ac_unit,
            color: Color(0xFF3E6E89),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _Milestone {
  final String label;
  final String emblem;
  final bool Function(CodexState s) test;
  const _Milestone({
    required this.label,
    required this.emblem,
    required this.test,
  });
}
