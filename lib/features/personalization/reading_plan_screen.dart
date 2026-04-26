import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../../widgets/rhema_title.dart';
import 'models/reading_plan.dart';
import 'personalization_service.dart';

/// AI-tailored, multi-day Bible reading plan.
///
/// Two states:
///  • No active plan — onboarding form (goal + days + optional life context).
///  • Has active plan — vertical day cards with completion toggles + verse chips.
class ReadingPlanScreen extends ConsumerStatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  ConsumerState<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends ConsumerState<ReadingPlanScreen> {
  final _goalCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  int _days = 14;
  bool _contextExpanded = false;
  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _goalCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) {
      setState(() => _error = 'Tell me what you want to grow into.');
      return;
    }
    final settings = ref.read(settingsProvider);
    if (!settings.useOnlineAi) {
      setState(() => _error =
          'Reading plans require AI. Add a Gemini key in Settings to use this.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final ctx = _contextCtrl.text.trim();
      final raw = await AiService.generateReadingPlan(
        goal: goal,
        days: _days,
        lifeContext: ctx.isEmpty ? null : ctx,
      );
      if (raw.isEmpty) {
        setState(() {
          _generating = false;
          _error = "Couldn't build the plan. Check your connection or try again.";
        });
        return;
      }
      final schedule = raw
          .map((r) => PlanDay(
                day: r.day,
                verseRefs: r.verseRefs,
                theme: r.theme,
                reflection: r.reflection,
                completed: false,
              ))
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
      final plan = ReadingPlan(
        id: ReadingPlan.newId(),
        goal: goal,
        createdAt: DateTime.now(),
        days: _days,
        schedule: schedule,
        lifeContext: ctx.isEmpty ? null : ctx,
      );
      await ref.read(personalizationServiceProvider).saveActivePlan(plan);
      ref.invalidate(activePlanProvider);
      if (mounted) setState(() => _generating = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = 'Generation failed. Try again.';
        });
      }
    }
  }

  Future<void> _confirmEndPlan(ReadingPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('End this plan?', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: Text(
          'You\u2019ll lose your progress. You can always start a new plan.',
          style: GoogleFonts.cormorantGaramond(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End plan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(personalizationServiceProvider).clearPlan();
      ref.invalidate(activePlanProvider);
    }
  }

  Future<void> _navigateToRef(String reference) async {
    final repo = ref.read(bibleRepositoryProvider);
    final translation = ref.read(settingsProvider).translation;
    final cleaned = reference.split('-').first;
    final hit = await repo.lookupReference(cleaned, translationId: translation);
    if (!mounted) return;
    if (hit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\u2019t open $reference', style: GoogleFonts.lora())),
      );
      return;
    }
    final vref = hit.ref;
    ref.read(readingLocationProvider.notifier).setBook(vref.book);
    ref.read(readingLocationProvider.notifier).setChapter(vref.chapter);
    ref.read(highlightVerseProvider.notifier).state = vref.verse;
    ref.read(tabIndexProvider.notifier).set(1);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(activePlanProvider);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        centerTitle: true,
        title: const RhemaTitle(),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading plan: $e', style: GoogleFonts.lora()),
          ),
        ),
        data: (plan) => plan == null ? _buildEmpty(theme) : _buildActive(theme, plan),
      ),
    );
  }

  // ─── Empty state — onboarding form ────────────────────────────

  Widget _buildEmpty(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandColors.gold.withValues(alpha: 0.18),
                  BrandColors.gold.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: BrandColors.gold.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: BrandColors.gold, size: 22),
                    const SizedBox(width: 8),
                    Text('A plan, just for you',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.gold,
                          letterSpacing: 1.2,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Build me a plan',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell me what you want to grow into. I\u2019ll shape a Scripture path.',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Goal input
          Text('Your goal', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _goalCtrl,
            minLines: 2,
            maxLines: 4,
            style: GoogleFonts.cormorantGaramond(fontSize: 17, height: 1.45),
            decoration: InputDecoration(
              hintText: "e.g. 'I want to learn about forgiveness after a divorce'",
              hintStyle: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: BrandColors.gold.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: BrandColors.gold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Days picker
          Text('Length', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [7, 14, 21, 30].map((d) {
              final selected = _days == d;
              return ChoiceChip(
                label: Text('$d days', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                selected: selected,
                onSelected: (_) => setState(() => _days = d),
                selectedColor: BrandColors.gold.withValues(alpha: 0.25),
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selected ? BrandColors.gold : theme.dividerColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Optional context
          InkWell(
            onTap: () => setState(() => _contextExpanded = !_contextExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _contextExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add life context (optional)',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_contextExpanded) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _contextCtrl,
              minLines: 2,
              maxLines: 4,
              style: GoogleFonts.cormorantGaramond(fontSize: 16, height: 1.45),
              decoration: InputDecoration(
                hintText: 'Anything that shapes how you read \u2014 your role, season, struggles.',
                hintStyle: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _generating ? 'Crafting your plan\u2026' : 'Generate',
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active state — day cards ─────────────────────────────────

  Widget _buildActive(ThemeData theme, ReadingPlan plan) {
    final today = (DateTime.now().difference(plan.createdAt).inDays + 1)
        .clamp(1, plan.days);
    final completed = plan.schedule.where((d) => d.completed == true).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: BrandColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: BrandColors.gold.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note, color: BrandColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Day $today of ${plan.days}',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.gold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completed / ${plan.days} done',
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.goal,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 19,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: plan.days == 0 ? 0 : completed / plan.days,
                  minHeight: 6,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(BrandColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Day cards
        for (final d in plan.schedule)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DayCard(
              day: d,
              isToday: d.day == today,
              onToggleCompleted: () async {
                await ref
                    .read(personalizationServiceProvider)
                    .markDayCompleted(d.day);
                ref.invalidate(activePlanProvider);
              },
              onTapRef: _navigateToRef,
            ),
          ),

        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _confirmEndPlan(plan),
          icon: const Icon(Icons.delete_outline),
          label: Text('End plan',
              style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
        ),
      ],
    );
  }
}

/// Single day card.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.onToggleCompleted,
    required this.onTapRef,
  });

  final PlanDay day;
  final bool isToday;
  final VoidCallback onToggleCompleted;
  final void Function(String ref) onTapRef;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = day.completed == true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.cardColor,
        border: Border.all(
          color: isToday
              ? BrandColors.gold.withValues(alpha: 0.6)
              : theme.dividerColor,
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: BrandColors.gold.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday
                      ? BrandColors.gold
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DAY ${day.day}',
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: isToday ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Text(
                  'TODAY',
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: BrandColors.gold,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onToggleCompleted,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? Colors.green.shade600 : theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            day.theme,
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: day.verseRefs.map((r) {
              return ActionChip(
                label: Text(r,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.gold,
                    )),
                onPressed: () => onTapRef(r),
                backgroundColor: BrandColors.gold.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: BrandColors.gold.withValues(alpha: 0.35)),
                ),
              );
            }).toList(),
          ),
          if (day.reflection.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandColors.cream.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, size: 18, color: BrandColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day.reflection,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
