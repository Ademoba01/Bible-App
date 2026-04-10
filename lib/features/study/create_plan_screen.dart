import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/reading_plans.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'plan_detail_screen.dart';

class CreatePlanScreen extends ConsumerStatefulWidget {
  final PlanTemplate template;

  const CreatePlanScreen({super.key, required this.template});

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  late double _selectedDays;
  late int _totalChapters;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.template.defaultDays.toDouble();
    _totalChapters = _computeTotalChapters();
  }

  int _computeTotalChapters() {
    int total = 0;
    for (final book in widget.template.booksIncluded) {
      total += kChapterCounts[book] ?? 0;
    }
    return total;
  }

  double get _chaptersPerDay => _totalChapters / _selectedDays;

  String get _paceDescription {
    final cpd = _chaptersPerDay;
    if (cpd < 2) return 'A gentle, reflective pace';
    if (cpd <= 4) return 'A comfortable daily rhythm';
    if (cpd <= 8) return 'An ambitious but doable challenge';
    return "An intensive deep dive \u2014 you've got this!";
  }

  String get _readerType {
    final cpd = _chaptersPerDay;
    if (cpd < 2) return 'morning readers';
    if (cpd <= 4) return 'steady devotional readers';
    if (cpd <= 8) return 'dedicated scholars';
    return 'intensive Bible marathoners';
  }

  String _finishDate() {
    final finish = DateTime.now().add(Duration(days: _selectedDays.round()));
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[finish.month]} ${finish.day}, ${finish.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customize Your Plan',
          style: GoogleFonts.lora(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Plan Header ──────────────────────────────────
            _PlanHeaderCard(template: widget.template, isDark: isDark),
            const SizedBox(height: 24),

            // ── 2. Duration Picker ──────────────────────────────
            _buildDurationPicker(theme, isDark),
            const SizedBox(height: 24),

            // ── 3. What You'll Read ─────────────────────────────
            _buildBooksList(theme, isDark),
            const SizedBox(height: 24),

            // ── 4. AI Summary Card ──────────────────────────────
            _buildAISummaryCard(theme, isDark),
            const SizedBox(height: 32),

            // ── 5. Start Plan Button ────────────────────────────
            _buildStartButton(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Duration Picker ─────────────────────────────────────────────

  Widget _buildDurationPicker(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many days?',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Default: ${widget.template.defaultDays} days',
              style: GoogleFonts.lora(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Current value display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: BrandColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: BrandColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${_selectedDays.round()} days',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: BrandColors.brown,
                inactiveTrackColor: BrandColors.brownMid.withValues(alpha: 0.25),
                thumbColor: BrandColors.gold,
                overlayColor: BrandColors.gold.withValues(alpha: 0.2),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: _selectedDays,
                min: 7,
                max: 365,
                divisions: 358,
                onChanged: (v) => setState(() => _selectedDays = v),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('7 days', style: GoogleFonts.lora(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                Text('365 days', style: GoogleFonts.lora(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 16),

            // Quick presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetChip('1 month', 30),
                _presetChip('3 months', 90),
                _presetChip('6 months', 180),
                _presetChip('1 year', 365),
              ],
            ),
            const SizedBox(height: 16),

            // Live preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? BrandColors.brown.withValues(alpha: 0.15)
                    : BrandColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_stories_rounded,
                      size: 20, color: BrandColors.brownMid),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "That's about ${_chaptersPerDay.toStringAsFixed(1)} chapters per day",
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
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

  Widget _presetChip(String label, int days) {
    final isActive = _selectedDays.round() == days;
    final chipTheme = Theme.of(context);
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.lora(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : chipTheme.colorScheme.primary,
        ),
      ),
      backgroundColor: isActive ? BrandColors.brown : BrandColors.brownMid.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? BrandColors.brown : BrandColors.brownMid.withValues(alpha: 0.3),
        ),
      ),
      onPressed: () => setState(() => _selectedDays = days.toDouble()),
    );
  }

  // ─── Books List ──────────────────────────────────────────────────

  Widget _buildBooksList(ThemeData theme, bool isDark) {
    final books = widget.template.booksIncluded;
    final totalBooks = books.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What you'll read",
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: books.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: BrandColors.brownMid.withValues(alpha: 0.12),
                ),
                itemBuilder: (context, i) {
                  final book = books[i];
                  final chapters = kChapterCounts[book] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(widget.template.color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(widget.template.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            book,
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$chapters ${chapters == 1 ? 'chapter' : 'chapters'}',
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(widget.template.color).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalBooks ${totalBooks == 1 ? 'book' : 'books'}, $_totalChapters total chapters',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(widget.template.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Summary Card ─────────────────────────────────────────────

  Widget _buildAISummaryCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF3E2723).withValues(alpha: 0.9),
                  const Color(0xFF4E342E).withValues(alpha: 0.8),
                ]
              : [
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFE0B2),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.gold.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your personalized plan',
                  style: GoogleFonts.lora(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? BrandColors.cream : BrandColors.dark,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('\u2728', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            _summaryRow(
              Icons.menu_book_rounded,
              '${_chaptersPerDay.toStringAsFixed(1)} chapters per day on average',
            ),
            const SizedBox(height: 14),
            _summaryRow(
              Icons.calendar_today_rounded,
              "You'll finish by ${_finishDate()}",
            ),
            const SizedBox(height: 14),
            _summaryRow(
              Icons.person_rounded,
              'Best for: $_readerType',
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BrandColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded,
                      size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _paceDescription,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: isDark ? BrandColors.cream : BrandColors.dark,
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

  Widget _summaryRow(IconData icon, String text) {
    final rowIsDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: BrandColors.brownMid),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: rowIsDark ? BrandColors.cream : BrandColors.dark,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Start Button ────────────────────────────────────────────────

  Widget _buildStartButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.gold,
          foregroundColor: BrandColors.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: BrandColors.gold.withValues(alpha: 0.4),
          textStyle: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          final days = _selectedDays.round();
          final planId = '${widget.template.id}_${days}d';
          ref.read(studyProgressProvider.notifier).startPlan(planId);

          // Generate the plan and navigate to it
          final plan = PlanGenerator.generate(widget.template, customDays: days);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Plan started! Let\u2019s go \uD83C\uDF89',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600),
              ),
              backgroundColor: BrandColors.brown,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          // Pop back to study screen, then push plan detail
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanDetailScreen(plan: plan),
            ),
          );
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 26),
            SizedBox(width: 10),
            Text('Start This Plan'),
          ],
        ),
      ),
    );
  }
}

// ─── Plan Header Card ──────────────────────────────────────────────

class _PlanHeaderCard extends StatelessWidget {
  final PlanTemplate template;
  final bool isDark;

  const _PlanHeaderCard({required this.template, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final planColor = Color(template.color);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              planColor.withValues(alpha: isDark ? 0.25 : 0.08),
              planColor.withValues(alpha: isDark ? 0.12 : 0.03),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: planColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                template.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: planColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      height: 1.4,
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
