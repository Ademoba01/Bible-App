import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme.dart';
import 'kids_stories.dart';
import 'kids_stories_nt.dart';

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

class _Badge {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  const _Badge({
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class KidsParentDashboard extends ConsumerStatefulWidget {
  const KidsParentDashboard({super.key});

  @override
  ConsumerState<KidsParentDashboard> createState() =>
      _KidsParentDashboardState();
}

class _KidsParentDashboardState extends ConsumerState<KidsParentDashboard> {
  bool _loaded = false;
  List<String> _storiesRead = [];
  int _totalMinutes = 0;
  Map<String, int> _weeklyMinutes = {};
  List<_Badge> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Stories read
    final storiesJson = prefs.getString('kids_stories_read');
    List<String> stories = [];
    if (storiesJson != null) {
      stories = List<String>.from(jsonDecode(storiesJson) as List);
    }

    // Total reading time
    final totalMin = prefs.getInt('kids_total_reading_minutes') ?? 0;

    // Weekly minutes — collect last 7 days
    final now = DateTime.now();
    final weekly = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final key = 'kids_daily_minutes_$dateStr';
      weekly[dateStr] = prefs.getInt(key) ?? 0;
    }

    // Determine badges
    final allStories = [...kKidsStories, ...kKidsStoriesNT];
    final readSet = stories.toSet();

    // Check testament coverage
    bool hasOT = false;
    bool hasNT = false;
    for (final story in allStories) {
      if (readSet.contains(story.title)) {
        if (_otBooks.contains(story.book)) {
          hasOT = true;
        } else {
          hasNT = true;
        }
      }
    }

    // Check 7-day streak
    bool hasStreak = true;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final key = 'kids_daily_minutes_$dateStr';
      if ((prefs.getInt(key) ?? 0) <= 0) {
        hasStreak = false;
        break;
      }
    }

    final badges = <_Badge>[
      _Badge(
        emoji: '\u{1F31F}',
        title: 'First Story',
        description: 'Read 1 story',
        unlocked: stories.length >= 1,
      ),
      _Badge(
        emoji: '\u{1F4DA}',
        title: 'Bookworm',
        description: 'Read 5 stories',
        unlocked: stories.length >= 5,
      ),
      _Badge(
        emoji: '\u{1F3C6}',
        title: 'Bible Explorer',
        description: 'Read 15 stories',
        unlocked: stories.length >= 15,
      ),
      _Badge(
        emoji: '\u{1F3AF}',
        title: 'Both Testaments',
        description: 'Read from OT and NT',
        unlocked: hasOT && hasNT,
      ),
      _Badge(
        emoji: '\u{1F525}',
        title: '7-Day Streak',
        description: '7 consecutive days',
        unlocked: hasStreak,
      ),
    ];

    setState(() {
      _storiesRead = stories;
      _totalMinutes = totalMin;
      _weeklyMinutes = weekly;
      _badges = badges;
      _loaded = true;
    });
  }

  String get _favoriteTestament {
    if (_storiesRead.isEmpty) return 'N/A';
    final allStories = [...kKidsStories, ...kKidsStoriesNT];
    int otCount = 0;
    int ntCount = 0;
    for (final story in allStories) {
      if (_storiesRead.contains(story.title)) {
        if (_otBooks.contains(story.book)) {
          otCount++;
        } else {
          ntCount++;
        }
      }
    }
    if (otCount == 0 && ntCount == 0) return 'N/A';
    if (otCount > ntCount) return 'Old Testament';
    if (ntCount > otCount) return 'New Testament';
    return 'Both equally';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        backgroundColor: BrandColors.kidsPurple,
        foregroundColor: Colors.white,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildReadingStatsCard(),
                const SizedBox(height: 16),
                _buildWeeklyActivityChart(),
                const SizedBox(height: 16),
                _buildAchievementBadges(),
                const SizedBox(height: 16),
                _buildContentControls(context),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // ── Reading Stats Card ──

  Widget _buildReadingStatsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrandColors.kidsBlue, BrandColors.kidsBlue.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BrandColors.kidsBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text('Reading Stats',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  '${_storiesRead.length}',
                  'Stories Read',
                  Icons.menu_book,
                  BrandColors.kidsYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  '$_totalMinutes',
                  'Minutes',
                  Icons.timer,
                  BrandColors.kidsGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  _favoriteTestament == 'Old Testament'
                      ? 'OT'
                      : _favoriteTestament == 'New Testament'
                          ? 'NT'
                          : _favoriteTestament == 'Both equally'
                              ? 'Both'
                              : '—',
                  'Favorite',
                  Icons.favorite,
                  BrandColors.kidsPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              )),
        ],
      ),
    );
  }

  // ── Weekly Activity Chart ──

  Widget _buildWeeklyActivityChart() {
    final entries = _weeklyMinutes.entries.toList();
    final maxMinutes =
        entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    final chartMax = maxMinutes > 0 ? maxMinutes : 1;

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: BrandColors.kidsGreen, size: 24),
              const SizedBox(width: 10),
              Text('This Week',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.brown,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BrandColors.kidsGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entries.fold<int>(0, (s, e) => s + e.value)} min total',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.kidsGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(entries.length, (i) {
                final minutes = entries[i].value;
                final barHeight = (minutes / chartMax) * 100;
                final date = DateTime.parse(entries[i].key);
                final dayLabel = dayLabels[date.weekday - 1];

                // Cycle colors
                final barColors = [
                  BrandColors.kidsBlue,
                  BrandColors.kidsGreen,
                  BrandColors.kidsYellow,
                  BrandColors.kidsPink,
                  BrandColors.kidsPurple,
                  BrandColors.kidsBlue,
                  BrandColors.kidsGreen,
                ];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          minutes > 0 ? '$minutes' : '',
                          style: GoogleFonts.fredoka(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: minutes > 0 ? barHeight.clamp(8, 100) : 4,
                          decoration: BoxDecoration(
                            color: minutes > 0
                                ? barColors[i % barColors.length]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Achievement Badges ──

  Widget _buildAchievementBadges() {
    final unlockedCount = _badges.where((b) => b.unlocked).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: BrandColors.kidsYellow, size: 24),
              const SizedBox(width: 10),
              Text('Achievements',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.brown,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BrandColors.kidsYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unlockedCount / ${_badges.length}',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _badges.map((badge) => _badgeTile(badge)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(_Badge badge) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: badge.unlocked
            ? BrandColors.kidsYellow.withValues(alpha: 0.15)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? BrandColors.kidsYellow.withValues(alpha: 0.4)
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            badge.emoji,
            style: TextStyle(
              fontSize: 28,
              color: badge.unlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badge.unlocked ? BrandColors.brown : Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 9,
              color: badge.unlocked ? Colors.black54 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // ── Content Controls ──

  Widget _buildContentControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.kidsPurple.withValues(alpha: 0.1),
            BrandColors.kidsPink.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.kidsPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: BrandColors.kidsPurple, size: 24),
              const SizedBox(width: 10),
              Text('Content Controls',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.brown,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Adjust reading speed, voice settings, and text size for your child.',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.kidsPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.settings),
              label: Text('Open Kids Settings',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
              onPressed: () {
                // Pop back to home screen with a result that tells it
                // to open the settings sheet.
                Navigator.pop(context, 'open_settings');
              },
            ),
          ),
        ],
      ),
    );
  }
}
