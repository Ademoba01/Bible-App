import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/reading_plans.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'create_plan_screen.dart';
import 'plan_detail_screen.dart';
import 'bible_maps_screen.dart';
import 'study_notes_screen.dart';
import 'study_timer_widget.dart';
import 'quiz_screen.dart';

// ---------------------------------------------------------------------------
// Study Screen — the devotional home for reading plans, maps, and progress.
// ---------------------------------------------------------------------------

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(studyProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve the active plan template + generated plan (if any).
    // Plan IDs are stored as "templateId_Xd" (e.g. "bible_in_year_365d")
    PlanTemplate? activeTemplate;
    int? customDays;
    if (progress.activePlanId != null) {
      final storedId = progress.activePlanId!;
      // Extract days suffix and match template
      final daysMatch = RegExp(r'_(\d+)d$').firstMatch(storedId);
      if (daysMatch != null) {
        customDays = int.tryParse(daysMatch.group(1)!);
        final baseId = storedId.substring(0, daysMatch.start);
        activeTemplate = kPlanTemplates.cast<PlanTemplate?>().firstWhere(
              (t) => t!.id == baseId,
              orElse: () => null,
            );
      } else {
        // Fallback: try direct match
        activeTemplate = kPlanTemplates.cast<PlanTemplate?>().firstWhere(
              (t) => t!.id == storedId,
              orElse: () => null,
            );
      }
    }
    final ReadingPlan? activePlan = activeTemplate != null
        ? PlanGenerator.generate(activeTemplate, customDays: customDays)
        : null;

    // Today's reading.
    DayReading? todayReading;
    int dayOfPlan = 0;
    if (activePlan != null && progress.startDate != null) {
      dayOfPlan =
          DateTime.now().difference(progress.startDate!).inDays + 1;
      todayReading = activePlan.readings.cast<DayReading?>().firstWhere(
            (r) => r!.day == dayOfPlan,
            orElse: () => null,
          );
    }

    final double planProgress = activePlan != null
        ? (progress.completedDays.length / activePlan.totalDays)
            .clamp(0.0, 1.0)
        : 0;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // No app bar — the header gradient card acts as the visual top.
          SliverToBoxAdapter(
            child: _HeaderCard(
              hasPlan: activePlan != null,
              planName: activePlan?.name,
              progress: planProgress,
              completedDays: progress.completedDays.length,
              totalDays: activePlan?.totalDays ?? 0,
              isDark: isDark,
            ),
          ),

          // Active plan: today's reading
          if (activePlan != null && todayReading != null)
            SliverToBoxAdapter(
              child: _TodayReadingCard(
                reading: todayReading,
                dayOfPlan: dayOfPlan,
                isCompleted: progress.completedDays.contains(dayOfPlan),
                onToggle: () =>
                    ref.read(studyProgressProvider.notifier).toggleDay(dayOfPlan),
                onReadNow: () {
                  ref
                      .read(readingLocationProvider.notifier)
                      .setBook(todayReading!.book);
                  ref
                      .read(readingLocationProvider.notifier)
                      .setChapter(todayReading.chapter);
                  ref.read(tabIndexProvider.notifier).state = 1;
                },
                onViewPlan: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlanDetailScreen(plan: activePlan),
                  ));
                },
              ),
            ),

          // Study Timer
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: StudyTimerWidget(),
            ),
          ),

          // Browse Plans heading
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                28,
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: BrandColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Browse Plans',
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontally scrollable plan templates
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kPlanTemplates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final t = kPlanTemplates[index];
                  return _PlanTemplateCard(
                    template: t,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CreatePlanScreen(template: t),
                      ));
                    },
                  );
                },
              ),
            ),
          ),

          // Explore Maps
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                28,
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                0,
              ),
              child: _ExploreMapsCard(
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BibleMapsScreen(),
                  ));
                },
              ),
            ),
          ),

          // Study Notes
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                16,
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                0,
              ),
              child: _StudyToolCard(
                isDark: isDark,
                emoji: '\u{1F4DD}',
                title: 'Study Notes',
                subtitle: 'Capture your insights',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StudyNotesScreen(),
                  ));
                },
              ),
            ),
          ),

          // Bible Quiz
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                16,
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                0,
              ),
              child: _StudyToolCard(
                isDark: isDark,
                emoji: '\u{1F9E0}',
                title: 'Bible Quiz',
                subtitle: 'Test your knowledge',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const QuizScreen(),
                  ));
                },
              ),
            ),
          ),

          // Quick Stats heading
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                28,
                MediaQuery.of(context).size.width < 400 ? 12 : 20,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: BrandColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Quick Stats',
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Stats row
          SliverToBoxAdapter(
            child: _QuickStatsRow(
              chaptersRead: _countChaptersRead(activePlan, progress),
              currentStreak: _computeStreak(progress),
              daysOnPlan: activePlan != null && progress.startDate != null
                  ? DateTime.now()
                      .difference(progress.startDate!)
                      .inDays
                      .clamp(0, 99999)
                  : 0,
              isDark: isDark,
            ),
          ),

          // Bottom breathing room
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ---- helpers ---------------------------------------------------------

  static int _countChaptersRead(ReadingPlan? plan, StudyProgress progress) {
    if (plan == null) return 0;
    int total = 0;
    for (final day in progress.completedDays) {
      final reading = plan.readings.cast<DayReading?>().firstWhere(
            (r) => r!.day == day,
            orElse: () => null,
          );
      if (reading != null) {
        total += (reading.endChapter ?? reading.chapter) - reading.chapter + 1;
      }
    }
    return total;
  }

  static int _computeStreak(StudyProgress progress) {
    if (progress.completedDays.isEmpty || progress.startDate == null) return 0;
    final sorted = progress.completedDays.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    final todayDay =
        DateTime.now().difference(progress.startDate!).inDays + 1;
    int expected = todayDay;
    for (final d in sorted) {
      if (d == expected || d == expected - 1) {
        streak++;
        expected = d - 1;
      } else {
        break;
      }
    }
    return streak;
  }
}

// ===========================================================================
//  HEADER GRADIENT CARD
// ===========================================================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.hasPlan,
    this.planName,
    required this.progress,
    required this.completedDays,
    required this.totalDays,
    required this.isDark,
  });

  final bool hasPlan;
  final String? planName;
  final double progress;
  final int completedDays;
  final int totalDays;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF3E2723), const Color(0xFF4E342E)]
              : [BrandColors.brown, BrandColors.brownMid],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.brown.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: hasPlan ? _activePlanHeader() : _noPlanHeader(),
      ),
    );
  }

  Widget _noPlanHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Study Journey',
          style: GoogleFonts.lora(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: BrandColors.cream,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Start your Bible journey today',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  color: BrandColors.cream.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a reading plan below and grow in the Word every day.',
          style: GoogleFonts.lora(
            fontSize: 13,
            color: BrandColors.cream.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _activePlanHeader() {
    final pct = (progress * 100).toInt();
    return Row(
      children: [
        // Progress ring
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: progress,
              trackColor: Colors.white.withValues(alpha: 0.15),
              progressColor: BrandColors.gold,
              strokeWidth: 7,
            ),
            child: Center(
              child: Text(
                '$pct%',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.gold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Plan info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Study Journey',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: BrandColors.cream.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                planName ?? '',
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.cream,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '$completedDays of $totalDays days completed',
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: BrandColors.cream.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
//  PROGRESS RING PAINTER
// ===========================================================================

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            progressColor,
            progressColor.withValues(alpha: 0.7),
            progressColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      // Glow dot at the end of the arc
      final dotAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotCenter = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );
      canvas.drawCircle(
        dotCenter,
        strokeWidth * 0.7,
        Paint()..color = progressColor.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        dotCenter,
        strokeWidth * 0.45,
        Paint()..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}

// ===========================================================================
//  TODAY'S READING CARD
// ===========================================================================

class _TodayReadingCard extends StatelessWidget {
  const _TodayReadingCard({
    required this.reading,
    required this.dayOfPlan,
    required this.isCompleted,
    required this.onToggle,
    required this.onReadNow,
    required this.onViewPlan,
  });

  final DayReading reading;
  final int dayOfPlan;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onReadNow;
  final VoidCallback onViewPlan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B1E19) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BrandColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.brown.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent gradient bar
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [BrandColors.gold, BrandColors.brownMid],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day label
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: BrandColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Day $dayOfPlan',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.gold.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Complete',
                                style: GoogleFonts.lora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // "Today's Reading" label
                  Text(
                    "Today's Reading",
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: isDark
                          ? BrandColors.cream.withValues(alpha: 0.55)
                          : BrandColors.brownMid,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reading.label,
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action buttons
                  Row(
                    children: [
                      // Read Now
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onReadNow,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Read Now'),
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandColors.brown,
                            foregroundColor: BrandColors.cream,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Mark complete checkbox
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onToggle,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isCompleted
                                    ? Colors.green
                                    : BrandColors.brownMid.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              color: isCompleted
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_rounded
                                  : Icons.check_rounded,
                              color: isCompleted
                                  ? Colors.green
                                  : BrandColors.brownMid.withValues(alpha: 0.35),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // View full plan
                  Center(
                    child: TextButton(
                      onPressed: onViewPlan,
                      child: Text(
                        'View Full Plan',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.brownMid,
                          decoration: TextDecoration.underline,
                          decorationColor: BrandColors.brownMid.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  PLAN TEMPLATE CARD (horizontal scroll)
// ===========================================================================

class _PlanTemplateCard extends StatelessWidget {
  const _PlanTemplateCard({
    required this.template,
    required this.onTap,
  });

  final PlanTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(template.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor.withValues(alpha: 0.78),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji
              Text(template.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),

              // Name
              Text(
                template.name,
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Duration
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${template.defaultDays} days',
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const Spacer(),

              // Description snippet
              Text(
                template.description,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  EXPLORE MAPS CARD
// ===========================================================================

class _ExploreMapsCard extends StatelessWidget {
  const _ExploreMapsCard({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF33291F), const Color(0xFF3E2723)]
                : [
                    BrandColors.cream,
                    BrandColors.gold.withValues(alpha: 0.18),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BrandColors.gold.withValues(alpha: isDark ? 0.25 : 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.brown.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Map emoji
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('\u{1F5FA}\u{FE0F}',
                    style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Bible Maps',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Walk the ancient paths',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? BrandColors.cream.withValues(alpha: 0.6)
                          : BrandColors.brownMid,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: BrandColors.brownMid.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  STUDY TOOL CARD (reusable for Notes, Quiz, etc.)
// ===========================================================================

class _StudyToolCard extends StatelessWidget {
  const _StudyToolCard({
    required this.isDark,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isDark;
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF33291F), const Color(0xFF3E2723)]
                : [
                    BrandColors.cream,
                    BrandColors.gold.withValues(alpha: 0.18),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BrandColors.gold.withValues(alpha: isDark ? 0.25 : 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.brown.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? BrandColors.cream.withValues(alpha: 0.6)
                          : BrandColors.brownMid,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: BrandColors.brownMid.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  QUICK STATS ROW
// ===========================================================================

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.chaptersRead,
    required this.currentStreak,
    required this.daysOnPlan,
    required this.isDark,
  });

  final int chaptersRead;
  final int currentStreak;
  final int daysOnPlan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              emoji: '\u{1F4D6}',
              label: 'Chapters\nRead',
              value: '$chaptersRead',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              emoji: '\u{1F525}',
              label: 'Current\nStreak',
              value: '$currentStreak',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              emoji: '\u{1F4C5}',
              label: 'Days on\nPlan',
              value: '$daysOnPlan',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String emoji;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2B1E19), const Color(0xFF33251D)]
              : [Colors.white, BrandColors.gold.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BrandColors.gold.withValues(alpha: isDark ? 0.15 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.brown.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? BrandColors.gold : BrandColors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 11,
              color: isDark
                  ? BrandColors.cream.withValues(alpha: 0.55)
                  : BrandColors.brownMid,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
