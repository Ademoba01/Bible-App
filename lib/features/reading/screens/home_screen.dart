import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../data/books.dart';
import '../../../data/models.dart';
import '../../../data/translations.dart';
import '../../../state/providers.dart';
import '../../../theme.dart';
import '../../../data/book_descriptions.dart';
import '../../bookmarks/bookmarks_screen.dart';
import '../../listen/listen_screen.dart';
import '../../search/similar_verses_screen.dart';
import '../../settings/settings_screen.dart';
import '../../study/bible_maps_screen.dart';
import '../../study/study_screen.dart';
import 'reading_screen.dart';

/// Adult-mode shell: bottom nav + "Home" tab with a warm greeting card.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const _DashboardTab();
      case 1:
        return const ReadingScreen();
      case 2:
        return const StudyScreen();
      case 3:
        return const BookmarksScreen();
      default:
        return const _DashboardTab();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    return Scaffold(
      body: _buildTab(index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(tabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Read'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerStatefulWidget {
  const _DashboardTab();

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searchActive = false;
  bool _searchLoading = false;
  List<({VerseRef ref, String text})> _searchResults = const [];

  // Voice search
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _voiceText = '';

  /// Returns a deterministic "verse of the day" based on the current date.
  /// Each entry: (reference, text, wordOfTheDay).
  static const _dailyVerses = [
    ('Philippians 4:13', 'I can do all things through Christ who strengthens me.', 'Strength'),
    ('Jeremiah 29:11', '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."', 'Purpose'),
    ('Psalm 23:1', 'The LORD is my shepherd; I shall not want.', 'Providence'),
    ('Proverbs 3:5', 'Trust in the LORD with all your heart, and do not lean on your own understanding.', 'Trust'),
    ('Romans 8:28', 'And we know that all things work together for good to those who love God, to those who are the called according to his purpose.', 'Sovereignty'),
    ('Isaiah 41:10', 'Do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.', 'Courage'),
    ('Joshua 1:9', 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the LORD your God will be with you wherever you go.', 'Boldness'),
    ('Psalm 46:1', 'God is our refuge and strength, an ever-present help in trouble.', 'Refuge'),
    ('Matthew 11:28', 'Come to me, all you who are weary and burdened, and I will give you rest.', 'Rest'),
    ('2 Timothy 1:7', 'For God has not given us a spirit of fear, but of power and of love and of a sound mind.', 'Power'),
    ('Psalm 27:1', 'The LORD is my light and my salvation; whom shall I fear? The LORD is the strength of my life; of whom shall I be afraid?', 'Light'),
    ('John 3:16', 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.', 'Love'),
    ('Romans 12:2', 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.', 'Renewal'),
    ('Psalm 119:105', 'Your word is a lamp for my feet, a light on my path.', 'Guidance'),
    ('Galatians 5:22', 'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.', 'Fruit'),
    ('Ephesians 6:10', 'Finally, be strong in the Lord and in his mighty power.', 'Armor'),
    ('1 Peter 5:7', 'Cast all your anxiety on him because he cares for you.', 'Peace'),
    ('Hebrews 11:1', 'Now faith is confidence in what we hope for and assurance about what we do not see.', 'Faith'),
    ('Psalm 37:4', 'Take delight in the LORD, and he will give you the desires of your heart.', 'Delight'),
    ('Matthew 6:33', 'But seek first his kingdom and his righteousness, and all these things will be given to you as well.', 'Priority'),
    ('Isaiah 40:31', 'But those who hope in the LORD will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.', 'Hope'),
    ('Psalm 34:8', 'Taste and see that the LORD is good; blessed is the one who takes refuge in him.', 'Goodness'),
    ('Colossians 3:23', 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.', 'Devotion'),
    ('2 Corinthians 5:17', 'Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!', 'Transformation'),
    ('Psalm 91:1', 'Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty.', 'Shelter'),
    ('James 1:5', 'If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault, and it will be given to you.', 'Wisdom'),
    ('Deuteronomy 31:6', 'Be strong and courageous. Do not be afraid or terrified because of them, for the LORD your God goes with you; he will never leave you nor forsake you.', 'Perseverance'),
    ('Psalm 139:14', 'I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well.', 'Wonder'),
    ('1 Corinthians 10:13', 'No temptation has overtaken you except what is common to mankind. And God is faithful; he will not let you be tempted beyond what you can bear.', 'Faithfulness'),
    ('Nahum 1:7', 'The LORD is good, a refuge in times of trouble. He cares for those who trust in him.', 'Grace'),
    ('Lamentations 3:22-23', 'Because of the LORD\'s great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.', 'Mercy'),
  ];

  (String, String, String) get _verseOfTheDay {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _dailyVerses[dayOfYear % _dailyVerses.length];
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              // Trigger search with voice result
              if (_voiceText.isNotEmpty) {
                _searchCtrl.text = _voiceText;
                _searchActive = true;
                _runSearch();
              }
            }
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice search not available on this device. Please type instead.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _isListening = true;
      _searchActive = true;
      _voiceText = '';
      _searchCtrl.clear();
    });
    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _voiceText = result.recognizedWords;
            _searchCtrl.text = _voiceText;
            _searchCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _voiceText.length),
            );
          });
          // Auto-search when confidence is high enough
          if (result.finalResult && _voiceText.isNotEmpty) {
            _runSearch();
          }
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = const [];
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    final repo = ref.read(bibleRepositoryProvider);

    // Search across ALL available translations
    final allResults = <({VerseRef ref, String text})>[];
    final availableTranslations = kTranslations.where((t) => t.available).toList();

    for (final t in availableTranslations) {
      final results = await repo.search(q, translationId: t.id, limit: 50);
      for (final r in results) {
        // Avoid duplicate refs from different translations
        if (!allResults.any((existing) => existing.ref.id == r.ref.id)) {
          allResults.add(r);
        }
      }
      if (allResults.length >= 100) break;
    }

    if (!mounted) return;
    setState(() {
      _searchResults = allResults.take(100).toList();
      _searchLoading = false;
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    if (_isListening) _speech.stop();
    setState(() {
      _searchActive = false;
      _searchResults = const [];
      _searchLoading = false;
      _isListening = false;
      _voiceText = '';
    });
    FocusScope.of(context).unfocus();
  }

  /// Shows translation picker bottom sheet (triggered by tapping hero image).
  void _showTranslationPicker() {
    final s = ref.read(settingsProvider);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            Text('Switch Translation',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...kTranslations.map((t) => ListTile(
                  enabled: t.available,
                  leading: Icon(
                    t.id == s.translation ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: t.available ? theme.colorScheme.primary : Colors.grey,
                  ),
                  title: Text(
                    t.name + (t.available ? '' : '  (coming soon)'),
                    style: GoogleFonts.lora(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(t.description, style: GoogleFonts.lora(fontSize: 12)),
                  onTap: t.available
                      ? () {
                          ref.read(settingsProvider.notifier).setTranslation(t.id);
                          Navigator.pop(context);
                        }
                      : null,
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(readingLocationProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final currentTranslation = translationById(settings.translation);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width < 400 ? 14 : 20,
          20,
          MediaQuery.of(context).size.width < 400 ? 14 : 20,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Compact hero card with integrated streak badge ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4E342E),
                    BrandColors.brown,
                    Color(0xFF6D4C41),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.brown.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: greeting left, settings gear + streak fire badge right
                  Row(
                    children: [
                      Text(
                        _greeting(),
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const Spacer(),
                      // Streak fire badge
                      Consumer(builder: (context, ref, _) {
                        final streak = ref.watch(streakProvider);
                        return GestureDetector(
                          onTap: () => _showStreakSheet(context, streak),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: streak.currentStreak > 0
                                  ? BrandColors.gold.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  streak.currentStreak > 0 ? '\u{1F525}' : '\u{1F4D6}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  streak.currentStreak > 0
                                      ? '${streak.currentStreak}'
                                      : '0',
                                  style: GoogleFonts.lora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      // Settings gear — proper 44px touch target
                      IconButton(
                        icon: Icon(Icons.settings_outlined,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.7)),
                        tooltip: 'Settings',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Row 2: "Continue: Book Chapter" tappable button with arrow
                  GestureDetector(
                    onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: BrandColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 20, color: BrandColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Continue: ${loc.book} ${loc.chapter}',
                              style: GoogleFonts.lora(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Translation switcher small text button
                  GestureDetector(
                    onTap: _showTranslationPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentTranslation.name,
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.swap_vert, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Inline search bar + results bubble ──
            Material(
              borderRadius: BorderRadius.circular(16),
              elevation: _searchActive ? 3 : 1,
              child: Column(
                children: [
                  // Voice listening indicator
                  if (_isListening)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.graphic_eq, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _voiceText.isEmpty
                                  ? 'Listening\u2026 speak a verse or topic'
                                  : '"$_voiceText"',
                              style: GoogleFonts.lora(
                                fontSize: 13,
                                fontStyle: _voiceText.isEmpty ? FontStyle.italic : FontStyle.normal,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _stopListening,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.stop, color: Colors.red, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: _searchCtrl,
                    onTap: () => setState(() => _searchActive = true),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _runSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search or speak a verse\u2026',
                      hintStyle: GoogleFonts.lora(fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mic button
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : theme.colorScheme.primary,
                              size: 22,
                            ),
                            tooltip: _isListening ? 'Stop listening' : 'Voice search',
                            onPressed: _isListening ? _stopListening : _startListening,
                          ),
                          // Clear button (only when search active)
                          if (_searchActive)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _clearSearch,
                            ),
                        ],
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  // ── Search results bubble ──
                  if (_searchActive && (_searchLoading || _searchResults.isNotEmpty))
                    Container(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: _searchLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                              itemBuilder: (_, i) {
                                final r = _searchResults[i];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.format_quote, size: 18, color: theme.colorScheme.primary),
                                  title: Text(
                                    r.ref.id,
                                    style: GoogleFonts.lora(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    r.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lora(fontSize: 12, height: 1.4),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Find similar — proper 44px touch target
                                      IconButton(
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                        onPressed: () {
                                          _clearSearch();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SimilarVersesScreen(
                                                sourceRef: r.ref,
                                                sourceText: r.text,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.auto_awesome, size: 18,
                                            color: theme.colorScheme.secondary),
                                        tooltip: 'Find similar verses',
                                      ),
                                      Icon(Icons.chevron_right, size: 16,
                                          color: theme.colorScheme.outline),
                                    ],
                                  ),
                                  onTap: () {
                                    ref.read(readingLocationProvider.notifier).setBook(r.ref.book);
                                    ref.read(readingLocationProvider.notifier).setChapter(r.ref.chapter);
                                    ref.read(tabIndexProvider.notifier).state = 1;
                                    _clearSearch();
                                  },
                                );
                              },
                            ),
                    ),

                  // "No results" message
                  if (_searchActive &&
                      !_searchLoading &&
                      _searchResults.isEmpty &&
                      _searchCtrl.text.trim().length > 2)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No verses found for "${_searchCtrl.text}"',
                        style: GoogleFonts.lora(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions — adjustable tiles (moved ABOVE verse of the day)
            _AdjustableQuickTiles(ref: ref, onBookPicker: () => _showBookPicker(context, ref)),
            const SizedBox(height: 16),

            // ── Verse of the Day — compact inline card ──
            GestureDetector(
              onTap: () {
                // Navigate to the verse in context
                final verseRef = VerseRef.tryParse(
                  _verseOfTheDay.$1.replaceAll(RegExp(r'-\d+$'), ''),
                );
                if (verseRef != null) {
                  ref.read(readingLocationProvider.notifier).setBook(verseRef.book);
                  ref.read(readingLocationProvider.notifier).setChapter(verseRef.chapter);
                  ref.read(tabIndexProvider.notifier).state = 1;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  border: Border.all(
                    color: BrandColors.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Word of the day badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: BrandColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 14, color: BrandColors.gold),
                          const SizedBox(height: 2),
                          Text(
                            _verseOfTheDay.$3.toUpperCase(),
                            style: GoogleFonts.lora(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: BrandColors.gold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Verse text + reference
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _verseOfTheDay.$2,
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '— ${_verseOfTheDay.$1}',
                            style: GoogleFonts.lora(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: BrandColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Find similar — secondary action
                    GestureDetector(
                      onTap: () {
                        final verseRef = VerseRef.tryParse(
                          _verseOfTheDay.$1.replaceAll(RegExp(r'-\d+$'), ''),
                        );
                        if (verseRef != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SimilarVersesScreen(
                                sourceRef: verseRef,
                                sourceText: _verseOfTheDay.$2,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BrandColors.gold.withValues(alpha: 0.12),
                        ),
                        child: Icon(Icons.auto_awesome, size: 16, color: BrandColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: BrandColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Recent bookmarks',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bookmarks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_border, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap any verse while reading to save it here.',
                          style: GoogleFonts.lora(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...bookmarks.take(5).map(
                    (id) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                        title: Text(id, style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ref.read(tabIndexProvider.notifier).state = 3,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showStreakSheet(BuildContext context, dynamic streak) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                streak.currentStreak > 0 ? '\u{1F525}' : '\u{1F4D6}',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                '${streak.currentStreak} day streak',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                streak.currentStreak > 0
                    ? 'Keep it going! Read today to maintain your streak.'
                    : 'Start reading today to begin your streak!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StreakStat(
                    label: 'Current',
                    value: '${streak.currentStreak}',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 32),
                  _StreakStat(
                    label: 'Longest',
                    value: '${streak.longestStreak}',
                    icon: Icons.emoji_events,
                    color: BrandColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// Full-screen book picker with search, testament tabs, and chapter grid.
  void _showBookPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookPickerSheet(ref: ref),
    );
  }
}

/// Bottom-sheet book + chapter picker with instant search.
class _BookPickerSheet extends StatefulWidget {
  const _BookPickerSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends State<_BookPickerSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _filter = '';
  String? _selectedBook;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _filter = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BookInfo> _filtered(String? testament) {
    final books = testament == null
        ? kAllBooks
        : kAllBooks.where((b) => b.testament == testament).toList();
    if (_filter.isEmpty) return books;
    return books.where((b) => b.name.toLowerCase().contains(_filter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBook != null) return _buildChapterGrid(context);
    return _buildBookList(context);
  }

  Widget _buildBookList(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Text('Choose a Book',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Type to filter…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_filter.isNotEmpty) ...[
            Expanded(child: _bookListView(null, scrollCtrl)),
          ] else ...[
            TabBar(
              controller: _tabCtrl,
              labelColor: theme.colorScheme.primary,
              tabs: const [Tab(text: 'Old Testament'), Tab(text: 'New Testament')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _bookListView('OT', scrollCtrl),
                  _bookListView('NT', scrollCtrl),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bookListView(String? testament, ScrollController scrollCtrl) {
    final books = _filtered(testament);
    if (books.isEmpty) {
      return Center(
        child: Text('No books match "${_searchCtrl.text}"',
            style: GoogleFonts.lora(color: Colors.grey)),
      );
    }
    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final b = books[i];
        final theme = Theme.of(context);
        return ListTile(
          title: Text(b.name, style: GoogleFonts.lora(fontWeight: FontWeight.w500)),
          subtitle: Text(
            kBookDescriptions[b.name] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lora(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _selectedBook = b.name),
        );
      },
    );
  }

  Widget _buildChapterGrid(BuildContext context) {
    final chapCount = _chapterCount(_selectedBook!);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedBook = null),
              ),
              Expanded(
                child: Text(_selectedBook!,
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text('Choose a chapter', style: GoogleFonts.lora(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 400 ? 4 : MediaQuery.of(context).size.width < 600 ? 5 : 7, mainAxisSpacing: 10, crossAxisSpacing: 10,
              ),
              itemCount: chapCount,
              itemBuilder: (_, i) {
                final ch = i + 1;
                final theme = Theme.of(context);
                return Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      widget.ref.read(readingLocationProvider.notifier).setBook(_selectedBook!);
                      widget.ref.read(readingLocationProvider.notifier).setChapter(ch);
                      widget.ref.read(tabIndexProvider.notifier).state = 1;
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text('$ch',
                          style: GoogleFonts.lora(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _chapterCount(String book) {
    const counts = <String, int>{
      'Genesis': 50, 'Exodus': 40, 'Leviticus': 27, 'Numbers': 36,
      'Deuteronomy': 34, 'Joshua': 24, 'Judges': 21, 'Ruth': 4,
      '1 Samuel': 31, '2 Samuel': 24, '1 Kings': 22, '2 Kings': 25,
      '1 Chronicles': 29, '2 Chronicles': 36, 'Ezra': 10, 'Nehemiah': 13,
      'Esther': 10, 'Job': 42, 'Psalms': 150, 'Proverbs': 31,
      'Ecclesiastes': 12, 'Song of Solomon': 8, 'Isaiah': 66, 'Jeremiah': 52,
      'Lamentations': 5, 'Ezekiel': 48, 'Daniel': 12, 'Hosea': 14,
      'Joel': 3, 'Amos': 9, 'Obadiah': 1, 'Jonah': 4, 'Micah': 7,
      'Nahum': 3, 'Habakkuk': 3, 'Zephaniah': 3, 'Haggai': 2,
      'Zechariah': 14, 'Malachi': 4,
      'Matthew': 28, 'Mark': 16, 'Luke': 24, 'John': 21, 'Acts': 28,
      'Romans': 16, '1 Corinthians': 16, '2 Corinthians': 13,
      'Galatians': 6, 'Ephesians': 6, 'Philippians': 4, 'Colossians': 4,
      '1 Thessalonians': 5, '2 Thessalonians': 3, '1 Timothy': 6,
      '2 Timothy': 4, 'Titus': 3, 'Philemon': 1, 'Hebrews': 13,
      'James': 5, '1 Peter': 5, '2 Peter': 3, '1 John': 5, '2 John': 1,
      '3 John': 1, 'Jude': 1, 'Revelation': 22,
    };
    return counts[book] ?? 1;
  }
}

/// Adjustable quick-action tiles: tap the ⚙ to toggle between compact (row)
/// and expanded (grid) modes. Long-press any tile to reorder.
class _AdjustableQuickTiles extends StatefulWidget {
  const _AdjustableQuickTiles({required this.ref, required this.onBookPicker});
  final WidgetRef ref;
  final VoidCallback onBookPicker;

  @override
  State<_AdjustableQuickTiles> createState() => _AdjustableQuickTilesState();
}

class _AdjustableQuickTilesState extends State<_AdjustableQuickTiles> {
  bool _expanded = false; // false = compact row, true = larger grid

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _TileData(Icons.school, 'Study', const Color(0xFF5D4037),
          () => widget.ref.read(tabIndexProvider.notifier).state = 2),
      _TileData(Icons.headphones, 'Listen', Colors.teal,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ListenScreen()))),
      _TileData(Icons.menu_book, 'All Books', Colors.indigo,
          widget.onBookPicker),
      _TileData(Icons.map_outlined, 'Maps', const Color(0xFF2E7D32),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BibleMapsScreen()))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Size toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: BrandColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Quick actions',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
              ],
            ),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _expanded ? Icons.grid_view : Icons.view_stream,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Large' : 'Compact',
                      style: GoogleFonts.lora(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,

          // Compact: wrapping row so all tiles are visible without scrolling
          firstChild: LayoutBuilder(
            builder: (context, constraints) {
              // On narrow screens use smaller tiles, otherwise standard size
              final tileWidth = constraints.maxWidth < 380 ? 60.0 : 72.0;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tiles
                    .map((t) => SizedBox(
                          width: tileWidth,
                          child: _QuickTile(
                            icon: t.icon,
                            label: t.label,
                            color: t.color,
                            onTap: t.onTap,
                          ),
                        ))
                    .toList(),
              );
            },
          ),

          // Expanded: 3-column grid with bigger tiles
          secondChild: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: tiles
                .map((t) => _QuickTileLarge(
                      icon: t.icon,
                      label: t.label,
                      color: t.color,
                      onTap: t.onTap,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _TileData(this.icon, this.label, this.color, this.onTap);
}

/// Larger version of the quick tile for expanded grid mode.
class _QuickTileLarge extends StatelessWidget {
  const _QuickTileLarge({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
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


class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
