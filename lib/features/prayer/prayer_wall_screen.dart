import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme.dart';
import '../../widgets/rhema_title.dart';
import 'models/prayer_request.dart';
import 'prayer_service.dart';

/// Private Prayer Wall — the user's personal devotional ledger.
/// Two tabs: Open (active intercessions) and Answered (a running log of
/// God's faithfulness).
class PrayerWallScreen extends ConsumerStatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  ConsumerState<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends ConsumerState<PrayerWallScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openAsync = ref.watch(openPrayersProvider);
    final answeredAsync = ref.watch(answeredPrayersProvider);

    final openCount = openAsync.asData?.value.length ?? 0;
    final answeredCount = answeredAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: BrandColors.parchment,
      appBar: AppBar(
        centerTitle: true,
        title: const RhemaTitle(),
        actions: [
          IconButton(
            tooltip: 'New prayer',
            icon: const Icon(Icons.add),
            onPressed: _openAddSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelStyle: GoogleFonts.lora(
              fontWeight: FontWeight.w700, fontSize: 15),
          unselectedLabelStyle:
              GoogleFonts.lora(fontWeight: FontWeight.w500, fontSize: 15),
          indicatorColor: BrandColors.gold,
          indicatorWeight: 3,
          // High-contrast labels against the brown AppBar — was previously
          // BrandColors.brown which was invisible on its own background.
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.62),
          tabs: const [
            Tab(text: 'Open • Active'),
            Tab(text: 'Answered • Logged'),
          ],
        ),
      ),
      body: Column(
        children: [
          _StatsStrip(open: openCount, answered: answeredCount),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PrayerList(
                  asyncList: openAsync,
                  empty: 'No open prayers — tap + to add your first.',
                  onTap: _openDetail,
                ),
                _PrayerList(
                  asyncList: answeredAsync,
                  empty:
                      "Answered prayers appear here — a running log of God's faithfulness.",
                  onTap: _openDetail,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: BrandColors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    final created = await showModalBottomSheet<PrayerRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddPrayerSheet(),
    );
    if (created != null) {
      await ref.read(prayerServiceProvider).add(created);
      bumpPrayerRefresh(ref);
    }
  }

  Future<void> _openDetail(PrayerRequest r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PrayerDetailScreen(prayerId: r.id)),
    );
    // Detail screen mutates via the service; bumping refresh ensures lists
    // pick up edits/deletes when we pop back.
    bumpPrayerRefresh(ref);
  }
}

// ---------------------------------------------------------------------------
// Stats strip
// ---------------------------------------------------------------------------

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.open, required this.answered});
  final int open;
  final int answered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BrandColors.gold.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: BrandColors.gold.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.volunteer_activism,
              color: BrandColors.brown, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$open open, $answered answered.',
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BrandColors.brown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List + cards
// ---------------------------------------------------------------------------

class _PrayerList extends StatelessWidget {
  const _PrayerList({
    required this.asyncList,
    required this.empty,
    required this.onTap,
  });
  final AsyncValue<List<PrayerRequest>> asyncList;
  final String empty;
  final ValueChanged<PrayerRequest> onTap;

  @override
  Widget build(BuildContext context) {
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load prayers.\n$e',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) return _EmptyState(text: empty);
        return ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = items[i];
            return _PrayerCard(
              prayer: r,
              onTap: () => onTap(r),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism,
                size: 64, color: BrandColors.brown.withValues(alpha: 0.45)),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: BrandColors.brown,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.prayer, required this.onTap});
  final PrayerRequest prayer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = prayer.isAnswered
        ? 'Answered ${_relative(prayer.answeredAt!)}'
        : _relative(prayer.createdAt);

    return Material(
      color: BrandColors.warmWhite,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: BrandColors.gold.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (prayer.isAnswered) ...[
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      prayer.title,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brown,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (prayer.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  prayer.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.brown.shade800,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaPill(
                    icon: Icons.schedule,
                    label: dateLabel,
                  ),
                  if (prayer.scriptureRef != null &&
                      prayer.scriptureRef!.isNotEmpty)
                    _MetaPill(
                      icon: Icons.menu_book_outlined,
                      label: prayer.scriptureRef!,
                      tinted: true,
                    ),
                  for (final t in prayer.tags.take(3))
                    _TagChip(label: t),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.tinted = false,
  });
  final IconData icon;
  final String label;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final bg = tinted
        ? BrandColors.gold.withValues(alpha: 0.18)
        : BrandColors.brown.withValues(alpha: 0.06);
    final fg = tinted ? BrandColors.goldDark : BrandColors.brown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: BrandColors.brown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: GoogleFonts.lora(
          fontSize: 11,
          color: BrandColors.brownMid,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add bottom sheet
// ---------------------------------------------------------------------------

class _AddPrayerSheet extends StatefulWidget {
  const _AddPrayerSheet();

  @override
  State<_AddPrayerSheet> createState() => _AddPrayerSheetState();
}

class _AddPrayerSheetState extends State<_AddPrayerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _bodyCtl = TextEditingController();
  final _scriptureCtl = TextEditingController();
  final _tagInputCtl = TextEditingController();
  final List<String> _tags = [];
  static const _suggestedTags = [
    'family',
    'healing',
    'work',
    'guidance',
    'thanks',
  ];

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    _scriptureCtl.dispose();
    _tagInputCtl.dispose();
    super.dispose();
  }

  void _toggleSuggested(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final t = _tagInputCtl.text.trim().toLowerCase();
    if (t.isEmpty) return;
    if (!_tags.contains(t)) {
      setState(() => _tags.add(t));
    }
    _tagInputCtl.clear();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final r = PrayerRequest.create(
      title: _titleCtl.text.trim(),
      body: _bodyCtl.text.trim(),
      scriptureRef: _scriptureCtl.text.trim().isEmpty
          ? null
          : _scriptureCtl.text.trim(),
      tags: List<String>.from(_tags),
    );
    Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: BrandColors.brown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'New prayer',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.brown,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtl,
                maxLength: 80,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                style: GoogleFonts.lora(fontSize: 16),
                decoration: _decoration('Title', 'A short headline'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyCtl,
                maxLength: 500,
                maxLines: 5,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                style: GoogleFonts.lora(fontSize: 15, height: 1.4),
                decoration: _decoration(
                    'Details', 'What are you bringing to the Lord?'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Details required' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _scriptureCtl,
                style: GoogleFonts.lora(fontSize: 15),
                decoration: _decoration(
                    'Scripture (optional)', 'e.g. Philippians 4:6'),
              ),
              const SizedBox(height: 16),
              Text('Tags',
                  style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.brown)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _suggestedTags)
                    FilterChip(
                      label: Text('#$tag', style: GoogleFonts.lora()),
                      selected: _tags.contains(tag),
                      onSelected: (_) => _toggleSuggested(tag),
                      selectedColor:
                          BrandColors.gold.withValues(alpha: 0.35),
                      backgroundColor:
                          BrandColors.brown.withValues(alpha: 0.06),
                      side: BorderSide(
                        color: BrandColors.brown.withValues(alpha: 0.2),
                      ),
                    ),
                  for (final tag in _tags
                      .where((t) => !_suggestedTags.contains(t)))
                    InputChip(
                      label: Text('#$tag', style: GoogleFonts.lora()),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      backgroundColor:
                          BrandColors.gold.withValues(alpha: 0.35),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputCtl,
                      style: GoogleFonts.lora(fontSize: 14),
                      decoration: _decoration('Custom tag', 'add your own')
                          .copyWith(counterText: ''),
                      onSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: BrandColors.brown,
                    onPressed: _addCustomTag,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text('Save prayer',
                      style: GoogleFonts.lora(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.lora(color: BrandColors.brown),
        hintStyle: GoogleFonts.lora(
            color: BrandColors.brown.withValues(alpha: 0.45)),
        filled: true,
        fillColor: BrandColors.parchment,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: BrandColors.gold.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: BrandColors.gold.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.brown, width: 2),
        ),
      );
}

// ---------------------------------------------------------------------------
// Detail screen
// ---------------------------------------------------------------------------

class _PrayerDetailScreen extends ConsumerStatefulWidget {
  const _PrayerDetailScreen({required this.prayerId});
  final String prayerId;

  @override
  ConsumerState<_PrayerDetailScreen> createState() =>
      _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends ConsumerState<_PrayerDetailScreen> {
  PrayerRequest? _prayer;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final svc = ref.read(prayerServiceProvider);
    await svc.init();
    if (!mounted) return;
    setState(() => _prayer = svc.getById(widget.prayerId));
  }

  @override
  Widget build(BuildContext context) {
    final p = _prayer;
    return Scaffold(
      backgroundColor: BrandColors.parchment,
      appBar: AppBar(
        title: Text(
          p?.isAnswered == true ? 'Answered prayer' : 'Prayer',
          style: GoogleFonts.lora(fontWeight: FontWeight.w700),
        ),
        actions: p == null
            ? const []
            : [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(p),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(p),
                ),
              ],
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: GoogleFonts.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.brown,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaPill(
                        icon: Icons.schedule,
                        label: 'Added ${_relative(p.createdAt)}',
                      ),
                      if (p.isAnswered)
                        _MetaPill(
                          icon: Icons.check_circle,
                          label: 'Answered ${_relative(p.answeredAt!)}',
                          tinted: true,
                        ),
                      if (p.scriptureRef != null &&
                          p.scriptureRef!.isNotEmpty)
                        _MetaPill(
                          icon: Icons.menu_book_outlined,
                          label: p.scriptureRef!,
                          tinted: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (p.body.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BrandColors.warmWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: BrandColors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        p.body,
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          height: 1.55,
                          color: Colors.brown.shade900,
                        ),
                      ),
                    ),
                  if (p.tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          p.tags.map((t) => _TagChip(label: t)).toList(),
                    ),
                  ],
                  if (p.isAnswered) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Reflection',
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BrandColors.gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: BrandColors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        (p.answerNote != null && p.answerNote!.isNotEmpty)
                            ? p.answerNote!
                            : 'No reflection added.',
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          height: 1.5,
                          fontStyle: (p.answerNote == null ||
                                  p.answerNote!.isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: BrandColors.brown,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: p == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: p.isAnswered
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrandColors.brown,
                          side: BorderSide(
                              color: BrandColors.brown
                                  .withValues(alpha: 0.5)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text('Reopen prayer',
                            style: GoogleFonts.lora(
                                fontWeight: FontWeight.w600)),
                        onPressed: () => _reopen(p),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandColors.brown,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: Text('Mark answered',
                            style: GoogleFonts.lora(
                                fontWeight: FontWeight.w600)),
                        onPressed: () => _markAnswered(p),
                      ),
              ),
            ),
    );
  }

  Future<void> _edit(PrayerRequest p) async {
    final updated = await showModalBottomSheet<PrayerRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditPrayerSheet(initial: p),
    );
    if (updated != null) {
      await ref.read(prayerServiceProvider).update(updated);
      bumpPrayerRefresh(ref);
      await _reload();
    }
  }

  Future<void> _delete(PrayerRequest p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete prayer?',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.lora()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(prayerServiceProvider).delete(p.id);
      bumpPrayerRefresh(ref);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _markAnswered(PrayerRequest p) async {
    final note = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final ctl = TextEditingController();
        return AlertDialog(
          backgroundColor: BrandColors.warmWhite,
          title: Text('Mark as answered',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a reflection (optional) — how did the Lord answer?',
                style: GoogleFonts.lora(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                maxLines: 4,
                maxLength: 500,
                style: GoogleFonts.lora(fontSize: 15, height: 1.4),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'A short note of thanks...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.brown),
              onPressed: () => Navigator.pop(ctx, ctl.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (note == null) return; // cancelled
    await ref
        .read(prayerServiceProvider)
        .markAnswered(p.id, answerNote: note.isEmpty ? null : note);
    bumpPrayerRefresh(ref);
    await _reload();
  }

  Future<void> _reopen(PrayerRequest p) async {
    await ref.read(prayerServiceProvider).reopen(p.id);
    bumpPrayerRefresh(ref);
    await _reload();
  }
}

// ---------------------------------------------------------------------------
// Edit sheet — shares look/feel with _AddPrayerSheet but pre-populates fields.
// ---------------------------------------------------------------------------

class _EditPrayerSheet extends StatefulWidget {
  const _EditPrayerSheet({required this.initial});
  final PrayerRequest initial;

  @override
  State<_EditPrayerSheet> createState() => _EditPrayerSheetState();
}

class _EditPrayerSheetState extends State<_EditPrayerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtl;
  late final TextEditingController _bodyCtl;
  late final TextEditingController _scriptureCtl;
  late final TextEditingController _tagInputCtl;
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.initial.title);
    _bodyCtl = TextEditingController(text: widget.initial.body);
    _scriptureCtl =
        TextEditingController(text: widget.initial.scriptureRef ?? '');
    _tagInputCtl = TextEditingController();
    _tags = List<String>.from(widget.initial.tags);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    _scriptureCtl.dispose();
    _tagInputCtl.dispose();
    super.dispose();
  }

  void _addCustomTag() {
    final t = _tagInputCtl.text.trim().toLowerCase();
    if (t.isEmpty) return;
    if (!_tags.contains(t)) {
      setState(() => _tags.add(t));
    }
    _tagInputCtl.clear();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.initial.copyWith(
      title: _titleCtl.text.trim(),
      body: _bodyCtl.text.trim(),
      scriptureRef: _scriptureCtl.text.trim().isEmpty
          ? null
          : _scriptureCtl.text.trim(),
      clearScriptureRef: _scriptureCtl.text.trim().isEmpty,
      tags: List<String>.from(_tags),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: BrandColors.brown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Edit prayer',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.brown,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtl,
                maxLength: 80,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                style: GoogleFonts.lora(fontSize: 16),
                decoration: _decoration('Title', 'A short headline'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title required'
                    : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyCtl,
                maxLength: 500,
                maxLines: 5,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                style: GoogleFonts.lora(fontSize: 15, height: 1.4),
                decoration: _decoration('Details',
                    'What are you bringing to the Lord?'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Details required'
                    : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _scriptureCtl,
                style: GoogleFonts.lora(fontSize: 15),
                decoration: _decoration(
                    'Scripture (optional)', 'e.g. Philippians 4:6'),
              ),
              const SizedBox(height: 16),
              Text('Tags',
                  style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.brown)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map((tag) => InputChip(
                          label: Text('#$tag', style: GoogleFonts.lora()),
                          onDeleted: () =>
                              setState(() => _tags.remove(tag)),
                          backgroundColor:
                              BrandColors.gold.withValues(alpha: 0.35),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputCtl,
                      style: GoogleFonts.lora(fontSize: 14),
                      decoration: _decoration('Add tag', 'tag name')
                          .copyWith(counterText: ''),
                      onSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: BrandColors.brown,
                    onPressed: _addCustomTag,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save),
                  label: Text('Save changes',
                      style: GoogleFonts.lora(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.lora(color: BrandColors.brown),
        hintStyle: GoogleFonts.lora(
            color: BrandColors.brown.withValues(alpha: 0.45)),
        filled: true,
        fillColor: BrandColors.parchment,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: BrandColors.gold.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: BrandColors.gold.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.brown, width: 2),
        ),
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _relative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m mins ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return w == 1 ? '1 week ago' : '$w weeks ago';
  }
  if (diff.inDays < 365) {
    final mo = (diff.inDays / 30).floor();
    return mo == 1 ? '1 month ago' : '$mo months ago';
  }
  final y = (diff.inDays / 365).floor();
  return y == 1 ? '1 year ago' : '$y years ago';
}
