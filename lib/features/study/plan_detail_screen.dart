import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/reading_plans.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class PlanDetailScreen extends ConsumerWidget {
  final ReadingPlan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(studyProgressProvider);
    final completedDays = progress.completedDays;
    final completedCount = completedDays.length;
    final totalDays = plan.totalDays;
    final percent = totalDays > 0 ? completedCount / totalDays : 0.0;
    final allDone = completedCount >= totalDays;

    // Determine "today's" day in the plan
    final startDate = progress.startDate ?? DateTime.now();
    final dayOfPlan = DateTime.now().difference(startDate).inDays + 1;

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${plan.emoji} ${plan.name}'),
      ),
      body: Column(
        children: [
          // ── Progress Header (sticky) ──────────────────────────
          _ProgressHeader(
            percent: percent,
            completedCount: completedCount,
            totalDays: totalDays,
            allDone: allDone,
            isDark: isDark,
            scheme: scheme,
          ),

          // ── Day-by-day list ───────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: plan.readings.length,
              itemBuilder: (context, index) {
                final reading = plan.readings[index];
                final isCompleted = completedDays.contains(reading.day);
                final isToday = reading.day == dayOfPlan;

                return _DayCard(
                  reading: reading,
                  isCompleted: isCompleted,
                  isToday: isToday,
                  isDark: isDark,
                  scheme: scheme,
                  planColor: Color(plan.color),
                  onToggle: () {
                    ref.read(studyProgressProvider.notifier).toggleDay(reading.day);
                  },
                  onTapReading: () {
                    // Navigate to the reading in the Read tab
                    ref.read(readingLocationProvider.notifier).setBook(reading.book);
                    ref.read(readingLocationProvider.notifier).setChapter(reading.chapter);
                    ref.read(tabIndexProvider.notifier).set(1);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── Footer: Reset Plan ───────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton.icon(
            onPressed: () => _showResetDialog(context, ref),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Reset Plan',
              style: GoogleFonts.lora(fontSize: 14),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent.shade200,
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Plan?',
          style: GoogleFonts.lora(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will clear all your progress for this plan. This action cannot be undone.',
          style: GoogleFonts.lora(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.lora()),
          ),
          FilledButton(
            onPressed: () {
              ref.read(studyProgressProvider.notifier).clearPlan();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.shade200,
            ),
            child: Text('Reset', style: GoogleFonts.lora()),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Header ───────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final double percent;
  final int completedCount;
  final int totalDays;
  final bool allDone;
  final bool isDark;
  final ColorScheme scheme;

  const _ProgressHeader({
    required this.percent,
    required this.completedCount,
    required this.totalDays,
    required this.allDone,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1E19) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BrandColors.brown.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 72,
            height: 72,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : BrandColors.cream,
                        valueColor: AlwaysStoppedAnimation(
                          allDone ? const Color(0xFF4CAF50) : BrandColors.gold,
                        ),
                      ),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),

          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedCount of $totalDays days completed',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                if (allDone)
                  Text(
                    'Congratulations! You finished!',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4CAF50),
                    ),
                  )
                else
                  Text(
                    "You're ${(percent * 100).round()}% through!",
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day Card ──────────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  final DayReading reading;
  final bool isCompleted;
  final bool isToday;
  final bool isDark;
  final ColorScheme scheme;
  final Color planColor;
  final VoidCallback onToggle;
  final VoidCallback onTapReading;

  const _DayCard({
    required this.reading,
    required this.isCompleted,
    required this.isToday,
    required this.isDark,
    required this.scheme,
    required this.planColor,
    required this.onToggle,
    required this.onTapReading,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _DayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger bounce when completion state changes to completed
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.isCompleted;
    final isToday = widget.isToday;
    final reading = widget.reading;

    final cardColor = isToday
        ? (widget.isDark
            ? BrandColors.gold.withValues(alpha: 0.12)
            : BrandColors.gold.withValues(alpha: 0.08))
        : (widget.isDark ? const Color(0xFF2B1E19) : Colors.white);

    final borderColor = isToday
        ? BrandColors.gold
        : (isCompleted
            ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
            : Colors.transparent);

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            if (!widget.isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTapReading,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Day number badge
                  _DayBadge(
                    day: reading.day,
                    isCompleted: isCompleted,
                    planColor: widget.planColor,
                    isDark: widget.isDark,
                  ),
                  const SizedBox(width: 14),

                  // Reading label + today badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isToday) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: BrandColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TODAY',
                                  style: GoogleFonts.lora(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: BrandColors.dark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              'Day ${reading.day}',
                              style: GoogleFonts.lora(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.scheme.onSurface
                                    .withValues(alpha: isCompleted ? 0.45 : 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reading.label,
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.scheme.onSurface
                                .withValues(alpha: isCompleted ? 0.5 : 1.0),
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: widget.scheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Completion checkbox
                  _AnimatedCheckbox(
                    isCompleted: isCompleted,
                    onTap: widget.onToggle,
                    planColor: widget.planColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Day Badge ─────────────────────────────────────────────────────

class _DayBadge extends StatelessWidget {
  final int day;
  final bool isCompleted;
  final Color planColor;
  final bool isDark;

  const _DayBadge({
    required this.day,
    required this.isCompleted,
    required this.planColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? planColor
            : (isDark
                ? planColor.withValues(alpha: 0.15)
                : planColor.withValues(alpha: 0.08)),
        border: isCompleted
            ? null
            : Border.all(
                color: planColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : Text(
              '$day',
              style: GoogleFonts.lora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: planColor,
              ),
            ),
    );
  }
}

// ─── Animated Checkbox ─────────────────────────────────────────────

class _AnimatedCheckbox extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;
  final Color planColor;

  const _AnimatedCheckbox({
    required this.isCompleted,
    required this.onTap,
    required this.planColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isCompleted
                ? const Color(0xFF4CAF50)
                : Colors.transparent,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : Colors.grey.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    key: ValueKey('checked'),
                    color: Colors.white,
                    size: 18,
                  )
                : const SizedBox.shrink(key: ValueKey('unchecked')),
          ),
        ),
      ),
    );
  }
}
