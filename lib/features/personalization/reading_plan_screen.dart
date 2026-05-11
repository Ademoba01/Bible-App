import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/featured_plans_service.dart';
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
  /// Active filter chip on the Featured Plans rail. null = "All".
  String? _featuredCategory;

  /// Start a hand-curated plan (no AI call). Saves the FeaturedPlan's
  /// pre-built schedule directly via personalizationService and
  /// invalidates the active-plan provider so the UI flips to the
  /// schedule view.
  Future<void> _startFeatured(FeaturedPlan fp) async {
    final plan = fp.toReadingPlan();
    await ref.read(personalizationServiceProvider).saveActivePlan(plan);
    ref.invalidate(activePlanProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${fp.title}” started — ${fp.days} days'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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

          // ── Featured Plans (curated, no AI required) ──
          // Pre-curated YouVersion-style plans live in
          // assets/data/featured_plans.json. Tapping a card calls
          // _startFeatured which saves the schedule directly via
          // personalizationService — no Gemini round-trip, works
          // offline. Categories surface as filter chips above.
          _FeaturedPlansSection(
            selectedCategory: _featuredCategory,
            onCategorySelected: (c) =>
                setState(() => _featuredCategory = c),
            onStart: _startFeatured,
          ),
          const SizedBox(height: 28),

          // Divider between curated and AI custom
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR BUILD YOUR OWN',
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ],
          ),
          const SizedBox(height: 20),

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

// ───────────────────────────────────────────────────────────────────
// FEATURED PLANS — YouVersion-style curated cards
// ───────────────────────────────────────────────────────────────────

const _categoryLabels = {
  'couples': 'Couples',
  'family': 'Family',
  'prayer': 'Prayer',
  'anxiety': 'Anxiety',
  'newbeliever': 'New Believers',
  'grief': 'Grief',
  'discipline': 'Disciplines',
  'discipleship': 'Discipleship',
};

const _categoryIcons = {
  'couples': Icons.favorite,
  'family': Icons.family_restroom,
  'prayer': Icons.front_hand,
  'anxiety': Icons.self_improvement,
  'newbeliever': Icons.auto_stories,
  'grief': Icons.healing,
  'discipline': Icons.self_improvement,
  'discipleship': Icons.school,
};

/// Featured-plans rail rendered above the AI form on the empty state.
/// Loads from FeaturedPlansService (lazy JSON), filters by category
/// chip, and exposes a tap handler that saves the schedule into the
/// active-plan store.
class _FeaturedPlansSection extends ConsumerWidget {
  const _FeaturedPlansSection({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onStart,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<FeaturedPlan> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(featuredPlansServiceProvider);

    return FutureBuilder<void>(
      future: svc.init(),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent(context, svc.all);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<FeaturedPlan> all) {
    if (all.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    // Distinct categories present in the data, in canonical order.
    final categories = _categoryLabels.keys
        .where((c) => all.any((p) => p.category == c))
        .toList();
    final filtered = selectedCategory == null
        ? all
        : all.where((p) => p.category == selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bookmark_added,
                size: 20, color: BrandColors.gold),
            const SizedBox(width: 8),
            Text(
              'Featured Plans',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hand-curated by Rhema. No AI required — works offline.',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Category filter chips (horizontal scroll)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: 'All',
                icon: Icons.apps,
                selected: selectedCategory == null,
                onTap: () => onCategorySelected(null),
              ),
              for (final cat in categories)
                _CategoryChip(
                  label: _categoryLabels[cat] ?? cat,
                  icon: _categoryIcons[cat] ?? Icons.bookmark,
                  selected: selectedCategory == cat,
                  onTap: () => onCategorySelected(cat),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Plan cards (vertical list)
        ...filtered.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlanCard(plan: plan, onStart: () => onStart(plan)),
            )),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? BrandColors.gold.withValues(alpha: 0.25)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? BrandColors.gold
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: selected
                        ? BrandColors.brownDeep
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? BrandColors.brownDeep
                        : Theme.of(context).colorScheme.onSurface,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onStart});
  final FeaturedPlan plan;
  final VoidCallback onStart;

  IconData _iconFor(String name) {
    switch (name) {
      case 'favorite':
        return Icons.favorite;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'front_hand':
        return Icons.front_hand;
      case 'healing':
        return Icons.healing;
      case 'school':
        return Icons.school;
      default:
        return Icons.bookmark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(plan.color);

    return Material(
      color: BrandColors.warmWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPreview(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.30),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(plan.icon),
                    color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        height: 1.35,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${plan.days} days',
                        style: GoogleFonts.lora(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.brownDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(plan.color);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.20),
                    accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accent.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Icon(_iconFor(plan.icon), color: accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            )),
                        Text(plan.subtitle,
                            style: GoogleFonts.lora(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheet);
                  onStart();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text('Start ${plan.days}-day plan',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
            const SizedBox(height: 18),
            Text('Schedule preview',
                style: GoogleFonts.lora(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...plan.schedule.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: theme.dividerColor
                              .withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Text('${d.day}',
                                  style: GoogleFonts.lora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: BrandColors.brownDeep,
                                  )),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(d.theme,
                                  style: GoogleFonts.lora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: d.verseRefs
                              .map((r) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: BrandColors.gold
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(r,
                                        style: GoogleFonts.lora(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: BrandColors.brownDeep,
                                        )),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
