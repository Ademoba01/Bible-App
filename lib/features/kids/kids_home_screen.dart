import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/providers.dart';
import '../../theme.dart';
import '../settings/voice_settings.dart';
import 'kids_stories.dart';
import 'kids_stories_nt.dart';
import 'kids_story_screen.dart';

const _otBooks = <String>{
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
  '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
  'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
  'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah',
  'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
  'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah',
  'Haggai', 'Zechariah', 'Malachi',
};

enum _StoryFilter { all, oldTestament, newTestament }

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});

  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen> {
  _StoryFilter _filter = _StoryFilter.all;

  late final List<KidsStory> allStories = [...kKidsStories, ...kKidsStoriesNT];

  void _showKidsSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _KidsSettingsSheet(),
    );
  }

  void _showParentalGate(BuildContext context, WidgetRef ref) {
    final random = Random();
    final a = random.nextInt(8) + 5; // 5-12
    final b = random.nextInt(8) + 3; // 3-10
    final useMultiply = random.nextBool();
    final answer = useMultiply ? a * b : a + b;
    final question = useMultiply ? '$a \u00d7 $b' : '$a + $b';

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: BrandColors.kidsBlue),
            const SizedBox(width: 10),
            Text('Grown-up check!',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Solve this to switch modes:',
                style: GoogleFonts.fredoka(
                    fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            Text('What is $question = ?',
                style: GoogleFonts.fredoka(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 22),
              decoration: InputDecoration(
                hintText: '?',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.fredoka()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: BrandColors.kidsBlue),
            onPressed: () {
              if (controller.text.trim() == '$answer') {
                Navigator.pop(ctx);
                ref.read(settingsProvider.notifier).setKidsMode(false);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text('Not quite! Try again',
                          style: GoogleFonts.fredoka())),
                );
              }
            },
            child: Text('Check',
                style:
                    GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<KidsStory> get _filteredStories {
    switch (_filter) {
      case _StoryFilter.all:
        return allStories;
      case _StoryFilter.oldTestament:
        return allStories.where((s) => _otBooks.contains(s.book)).toList();
      case _StoryFilter.newTestament:
        return allStories.where((s) => !_otBooks.contains(s.book)).toList();
    }
  }

  int _countFor(_StoryFilter f) {
    switch (f) {
      case _StoryFilter.all:
        return allStories.length;
      case _StoryFilter.oldTestament:
        return allStories.where((s) => _otBooks.contains(s.book)).length;
      case _StoryFilter.newTestament:
        return allStories.where((s) => !_otBooks.contains(s.book)).length;
    }
  }

  String _labelFor(_StoryFilter f) {
    switch (f) {
      case _StoryFilter.all:
        return 'All';
      case _StoryFilter.oldTestament:
        return 'Old Testament';
      case _StoryFilter.newTestament:
        return 'New Testament';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = _filteredStories;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bible Stories',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        backgroundColor: BrandColors.kidsBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Kids Settings',
            onPressed: () => _showKidsSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Prominent "Switch to Adult" banner ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown[700]!, Colors.brown[500]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showParentalGate(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Switch to Adult Mode',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                              const SizedBox(height: 2),
                              Text('Full Bible with all books & chapters',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pick a story!',
                style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Tap any picture — I'll read it to you.",
                style: GoogleFonts.fredoka(fontSize: 15, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),

            // ── Category filter chips ──
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _StoryFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _StoryFilter.values[i];
                  final selected = _filter == f;
                  final count = _countFor(f);
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_labelFor(f)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    labelStyle: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                    selectedColor: BrandColors.kidsBlue,
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: selected
                        ? BorderSide(color: BrandColors.kidsBlue.withValues(alpha: 0.3), width: 2)
                        : BorderSide.none,
                    elevation: selected ? 3 : 0,
                    pressElevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    onSelected: (_) => setState(() => _filter = f),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: stories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 400 ? 2 : MediaQuery.of(context).size.width < 700 ? 3 : 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (_, i) => _StoryCard(story: stories[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final KidsStory story;

  @override
  Widget build(BuildContext context) {
    final color = Color(story.color);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => KidsStoryScreen(story: story)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(story.emoji, style: const TextStyle(fontSize: 36)),
                const Spacer(),
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  story.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
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

// ── Kids Settings Bottom Sheet ──

class _KidsSettingsSheet extends StatefulWidget {
  const _KidsSettingsSheet();

  @override
  State<_KidsSettingsSheet> createState() => _KidsSettingsSheetState();
}

class _KidsSettingsSheetState extends State<_KidsSettingsSheet> {
  double _readingSpeed = 0.42;
  double _voicePitch = 1.2;
  double _textSize = 22;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readingSpeed = prefs.getDouble('kids_readingSpeed') ?? 0.42;
      _voicePitch = prefs.getDouble('kids_voicePitch') ?? 1.2;
      _textSize = prefs.getDouble('kids_textSize') ?? 22;
      _loaded = true;
    });
  }

  Future<void> _save(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.brownMid.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Kids Settings',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BrandColors.brown,
              ),
            ),
            const SizedBox(height: 20),

            // Reading Speed
            _buildSliderSection(
              label: 'Reading Speed',
              icon: Icons.speed,
              value: _readingSpeed,
              min: 0.3,
              max: 0.7,
              displayValue: '${(_readingSpeed * 100).round()}%',
              onChanged: (v) {
                setState(() => _readingSpeed = v);
                _save('kids_readingSpeed', v);
              },
            ),
            const SizedBox(height: 16),

            // Voice Sweetness (pitch)
            _buildSliderSection(
              label: 'Voice Sweetness',
              icon: Icons.music_note,
              value: _voicePitch,
              min: 0.8,
              max: 1.5,
              displayValue: _voicePitch.toStringAsFixed(1),
              onChanged: (v) {
                setState(() => _voicePitch = v);
                _save('kids_voicePitch', v);
              },
            ),
            const SizedBox(height: 16),

            // Text Size
            _buildSliderSection(
              label: 'Text Size',
              icon: Icons.text_fields,
              value: _textSize,
              min: 18,
              max: 30,
              displayValue: '${_textSize.round()}',
              onChanged: (v) {
                setState(() => _textSize = v);
                _save('kids_textSize', v);
              },
            ),
            const SizedBox(height: 20),

            // Voice button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.brown,
                  side: const BorderSide(color: BrandColors.gold, width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.record_voice_over),
                label: Text(
                  'Choose Voice',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showVoiceSettings(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BrandColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.brownMid.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: BrandColors.brown),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.brown,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: BrandColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  displayValue,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.brown,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: BrandColors.gold,
              inactiveTrackColor: BrandColors.brownMid.withValues(alpha: 0.2),
              thumbColor: BrandColors.brown,
              overlayColor: BrandColors.gold.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
