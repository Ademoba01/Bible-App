import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../data/bible_repository.dart';
import '../../../data/books.dart';
import '../../../data/models.dart';
import '../../../data/translations.dart';
import '../../../services/auth_service.dart';
import '../../../state/providers.dart';
import '../../../theme.dart';
import '../../../data/book_descriptions.dart';
import '../../auth/auth_screen.dart';
import '../../bookmarks/bookmarks_screen.dart';
import '../../listen/listen_screen.dart';
import '../../search/similar_verses_screen.dart';
import '../../settings/help_screen.dart';
import '../../settings/settings_screen.dart';
import '../../study/bible_maps_screen.dart';
import '../../study/study_screen.dart';
import '../../../utils/kids_portal_transition.dart';
import '../../../utils/page_transitions.dart';
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
      body: Stack(
        children: [
          _buildTab(index),
          // Inline chat overlay
          const _InlineChatOverlay(),
        ],
      ),
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

/// Inline expandable chat overlay — bubble expands into a chat panel within the screen.
class _InlineChatOverlay extends StatefulWidget {
  const _InlineChatOverlay();

  @override
  State<_InlineChatOverlay> createState() => _InlineChatOverlayState();
}

class _InlineChatOverlayState extends State<_InlineChatOverlay>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMsg>[
    const _ChatMsg(
      'Hi! I\'m the Rhema assistant. 👋\n\n'
          'Ask me anything about translations, voice settings, '
          'study features, kids mode, and more!',
      false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _isOpen = !_isOpen);

  void _send([String? text]) {
    final msg = (text ?? _controller.text).trim();
    if (msg.isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(msg, true));
      _messages.add(_ChatMsg(_findChatResponse(msg), false));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static const _responses = <String, String>{
    'hello': 'Hello! 👋 How can I help you with Rhema Study Bible?',
    'hi': 'Hi there! 👋 What would you like to know?',
    'hey': 'Hey! 👋 Ask me anything about the app!',
    'help': 'I can help with:\n\n📖 Translations & offline reading\n🎧 Listening & voice\n📚 Study features & maps\n👶 Kids Mode\n⚙️ Settings',
    'offline': 'KJV and WEB work offline — bundled in the app. Others stream from the internet (cloud icon ☁️).',
    'translation': 'Tap the Bible image on Home or go to Settings → Translation. 14+ translations in 10 languages! KJV & WEB work offline.',
    'language': 'We support English, Hindi, Arabic, Bengali, Amharic, Tibetan, and more. Settings → Translation to browse by language.',
    'voice': 'Go to Listen → voice icon 🗣️. Premium voices sound most natural. Download more from your device\'s Accessibility settings.',
    'narrator': 'For the best narrator: Listen → Voice icon → look for "Premium" (gold badge). Preview before selecting.',
    'speed': 'Adjust reading speed on the Listen screen: 0.5× to 2×.',
    'map': 'Study → Bible Maps: 56+ locations, era filters, animated journeys, satellite view. Tap markers for history & verses.',
    'quiz': 'Study → Quiz: AI-powered quizzes on any chapter. Works offline (keyword) or online (Gemini AI).',
    'bookmark': 'Long-press any verse to bookmark or highlight it (5 colors). Find them in the Saved tab.',
    'highlight': 'Long-press a verse → choose from 5 highlight colors: yellow, green, blue, pink, orange.',
    'notes': 'Tap a verse → notes icon to add study notes. Saved locally on your device.',
    'streak': 'Your reading streak tracks consecutive days. Read any chapter daily to keep it going!',
    'kids': 'Settings → Kids Mode: 20 animated Bible stories with narration, emoji illustrations, and moral lessons for ages 6+.',
    'dark': 'Toggle dark mode in Settings → Dark mode.',
    'font': 'Adjust font size in Settings (14–28). You can also pinch-to-zoom while reading.',
    'free': 'Yes! 100% free with no ads, no subscriptions.',
    'ai': 'AI uses Google Gemini. Get a free key at ai.google.dev → paste in Settings → Advanced.',
    'plan': 'Study → Reading Plans: 7-day, 30-day, or custom plans.',
    'data': 'All data stored locally on your device. Nothing sent to servers.',
  };

  static String _findChatResponse(String query) {
    final lower = query.toLowerCase().trim();

    // First check for topic/verse-related queries
    final topicVerses = BibleRepository.getTopicVerses(lower);
    if (topicVerses != null) {
      final versesStr = topicVerses.take(6).map((v) => '📖 $v').join('\n');
      // Try to identify the topic word
      String topic = lower;
      for (final word in lower.split(RegExp(r'\s+'))) {
        if (BibleRepository.getTopicVerses(word) != null) {
          topic = word;
          break;
        }
      }
      return 'Here are key verses on "$topic":\n\n$versesStr\n\nTry searching "$topic" in the search bar to read the full verses!';
    }

    // Then check app-related responses
    for (final entry in _responses.entries) {
      if (lower == entry.key || lower.contains(entry.key)) return entry.value;
    }
    final words = lower.split(RegExp(r'\s+'));
    String? best;
    int bestScore = 0;
    for (final entry in _responses.entries) {
      int score = 0;
      for (final w in words) {
        if (entry.key.contains(w) || entry.value.toLowerCase().contains(w)) score++;
      }
      if (score > bestScore) { bestScore = score; best = entry.value; }
    }
    if (best != null && bestScore >= 1) return best;
    return 'I can help with Bible topics (try "honesty", "patience", "forgiveness") or app features (translations, voice, maps, quizzes, kids mode, settings)!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 16,
      bottom: 8 + bottomPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Expanded chat panel ──
          if (_isOpen)
            Container(
              width: 320,
              height: MediaQuery.of(context).size.height * 0.55,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BrandColors.gold.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [BrandColors.goldLight, BrandColors.gold],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Color(0xFF3E2723), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Rhema Assistant',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3E2723),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HelpScreen()),
                            ),
                            child: Icon(Icons.open_in_full, size: 18, color: const Color(0xFF3E2723).withValues(alpha: 0.6)),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _toggle,
                            child: const Icon(Icons.close, size: 20, color: Color(0xFF3E2723)),
                          ),
                        ],
                      ),
                    ),
                    // Suggestion chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          _chip('Offline?', theme),
                          _chip('Change voice', theme),
                          _chip('Languages', theme),
                          _chip('Maps', theme),
                          _chip('Kids mode', theme),
                          _chip('Quizzes', theme),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          return Align(
                            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 250,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(msg.isUser ? 14 : 4),
                                  bottomRight: Radius.circular(msg.isUser ? 4 : 14),
                                ),
                              ),
                              child: Text(
                                msg.text,
                                style: GoogleFonts.lora(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: msg.isUser
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Input bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              style: GoogleFonts.lora(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ask a question...',
                                hintStyle: GoogleFonts.lora(fontSize: 13),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: _send,
                            icon: const Icon(Icons.send, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: BrandColors.gold,
                              foregroundColor: const Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // ── Chat bubble button ──
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [BrandColors.goldLight, BrandColors.gold],
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.gold.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isOpen ? Icons.keyboard_arrow_down : Icons.chat_bubble_outline,
                color: const Color(0xFF3E2723),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: GoogleFonts.lora(fontSize: 11, color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        visualDensity: VisualDensity.compact,
        onPressed: () => _send(text),
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  const _ChatMsg(this.text, this.isUser);
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
  List<String> _topicSuggestions = const []; // topic-based verse refs

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
    final currentTranslation = ref.read(settingsProvider).translation;

    // Check for topic-based suggestions
    final topics = BibleRepository.getTopicVerses(q) ?? const [];

    // Smart search with synonym expansion — searches current translation
    // and cross-references KJV/WEB for terms that differ between versions
    final results = await repo.search(
      q,
      translationId: currentTranslation,
      limit: 100,
    );

    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _topicSuggestions = topics;
      _searchLoading = false;
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    if (_isListening) _speech.stop();
    setState(() {
      _searchActive = false;
      _searchResults = const [];
      _topicSuggestions = const [];
      _searchLoading = false;
      _isListening = false;
      _voiceText = '';
    });
    FocusScope.of(context).unfocus();
  }

  /// Shows a centered verse preview popup with copy, share, read full chapter.
  void _showVersePreview(VerseRef verseRef, String text, ThemeData theme) {
    final translation = ref.read(settingsProvider).translation;
    final versionName = translationById(translation).name;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BrandColors.gold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verse reference + version
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${verseRef.id} ($versionName)',
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Verse text
                  Text(
                    text,
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.copy, size: 18, color: theme.colorScheme.primary),
                        label: Text('Copy', style: GoogleFonts.lora(fontSize: 13)),
                        onPressed: () {
                          final copyText = '${verseRef.id} ($versionName)\n$text\n\n— Rhema Study Bible\nhttps://rhemabibles.com';
                          Clipboard.setData(ClipboardData(text: copyText));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verse copied to clipboard'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.share, size: 18, color: theme.colorScheme.primary),
                        label: Text('Share', style: GoogleFonts.lora(fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          // Share functionality would go here
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.secondary),
                        label: Text('Similar', style: GoogleFonts.lora(fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearSearch();
                          Navigator.push(
                            context,
                            FadeSlideRoute(
                              page: SimilarVersesScreen(
                                sourceRef: verseRef,
                                sourceText: text,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Read full chapter button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: Text(
                        'Read full chapter',
                        style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(readingLocationProvider.notifier).setBook(verseRef.book);
                        ref.read(readingLocationProvider.notifier).setChapter(verseRef.chapter);
                        ref.read(highlightVerseProvider.notifier).state = verseRef.verse;
                        ref.read(tabIndexProvider.notifier).state = 1;
                        _clearSearch();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows translation picker (triggered by tapping hero image).
  void _showTranslationPicker() {
    final s = ref.read(settingsProvider);
    final theme = Theme.of(context);
    final grouped = translationsByLanguage();
    final langOrder = grouped.keys.toList();
    // Put English first
    langOrder.remove('English');
    langOrder.insert(0, 'English');

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          width: 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BrandColors.gold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Switch Translation',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final lang in langOrder) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Icon(Icons.language, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(lang,
                                  style: GoogleFonts.lora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  )),
                            ],
                          ),
                        ),
                        ...grouped[lang]!.map((t) => ListTile(
                              enabled: t.available,
                              leading: Icon(
                                t.id == s.translation
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: t.available
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    t.name,
                                    style: GoogleFonts.lora(fontWeight: FontWeight.w600),
                                  ),
                                  if (t.isLocal) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('offline',
                                          style: GoogleFonts.lora(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.primary)),
                                    ),
                                  ],
                                  if (!t.isLocal && t.available) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.cloud_outlined,
                                        size: 14,
                                        color: theme.colorScheme.outline),
                                  ],
                                ],
                              ),
                              subtitle: Text(t.description,
                                  style: GoogleFonts.lora(fontSize: 12)),
                              onTap: t.available
                                  ? () {
                                      ref
                                          .read(settingsProvider.notifier)
                                          .setTranslation(t.id);
                                      Navigator.pop(ctx);
                                    }
                                  : null,
                            )),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

    // Cache screen dimensions once per build
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isNarrow = screenWidth < 400;
    final isShort = screenHeight < 700;
    final hPad = isNarrow ? 14.0 : 20.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Greeting row: greeting left, streak + settings right ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _greeting(),
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Rhema Study Bible',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: BrandColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // Streak fire badge
                  Consumer(builder: (context, ref, _) {
                    final streak = ref.watch(streakProvider);
                    return GestureDetector(
                      onTap: () => _showStreakSheet(context, streak),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: streak.currentStreak > 0
                              ? BrandColors.gold.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
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
                              '${streak.currentStreak}',
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Settings',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    onPressed: () => Navigator.push(
                      context,
                      FadeSlideRoute(page: const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Continue reading CTA — separated from greeting ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2B1610),
                    BrandColors.brown,
                    Color(0xFF6D4C41),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: BrandColors.gold.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  // Tight shadow
                  BoxShadow(
                    color: BrandColors.brown.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  // Diffuse shadow
                  BoxShadow(
                    color: BrandColors.brown.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BrandColors.gold.withValues(alpha: 0.2),
                          ),
                          child: Icon(Icons.play_arrow_rounded, size: 24, color: BrandColors.gold),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Continue Reading',
                                style: GoogleFonts.lora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${loc.book} ${loc.chapter}',
                                style: GoogleFonts.lora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Translation chip
                        GestureDetector(
                          onTap: _showTranslationPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              currentTranslation.name,
                              style: GoogleFonts.lora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

                  // ── Topic suggestions ──
                  if (_searchActive && !_searchLoading && _topicSuggestions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      decoration: BoxDecoration(
                        color: BrandColors.gold.withOpacity(0.08),
                        borderRadius: _searchResults.isEmpty
                            ? const BorderRadius.vertical(bottom: Radius.circular(16))
                            : BorderRadius.zero,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 16, color: BrandColors.gold),
                              const SizedBox(width: 6),
                              Text(
                                'Key verses on this topic:',
                                style: GoogleFonts.lora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: BrandColors.gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _topicSuggestions.take(8).map((ref) {
                              return ActionChip(
                                label: Text(ref, style: GoogleFonts.lora(fontSize: 11, fontWeight: FontWeight.w600)),
                                avatar: const Icon(Icons.menu_book, size: 14),
                                backgroundColor: BrandColors.gold.withOpacity(0.12),
                                side: BorderSide(color: BrandColors.gold.withOpacity(0.3)),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  // Parse "Book chapter:verse" and navigate
                                  final parsed = VerseRef.tryParse(ref);
                                  if (parsed != null) {
                                    this.ref.read(readingLocationProvider.notifier).setBook(parsed.book);
                                    this.ref.read(readingLocationProvider.notifier).setChapter(parsed.chapter);
                                    this.ref.read(highlightVerseProvider.notifier).state = parsed.verse;
                                    this.ref.read(tabIndexProvider.notifier).state = 1;
                                    _clearSearch();
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                        ],
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
                                  trailing: Icon(Icons.chevron_right, size: 16,
                                      color: theme.colorScheme.outline),
                                  onTap: () => _showVersePreview(r.ref, r.text, theme),
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

            // ── Verse of the Day — prominent card ──
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
                // Gentle sign-up nudge for unauthenticated users
                _maybeShowSignUpNudge(context, ref);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BrandColors.gold.withValues(alpha: 0.12),
                      BrandColors.gold.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: BrandColors.gold.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.gold.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row — badge + find similar
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: BrandColors.gold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BrandColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 20, color: BrandColors.gold),
                              const SizedBox(width: 8),
                              Text(
                                _verseOfTheDay.$3.toUpperCase(),
                                style: GoogleFonts.lora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: BrandColors.gold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Verse of the Day',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BrandColors.brownMid,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Verse text — full display, no truncation
                    Text(
                      '\u201C${_verseOfTheDay.$2}\u201D',
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reference + find similar
                    Row(
                      children: [
                        Text(
                          '— ${_verseOfTheDay.$1}',
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.gold,
                          ),
                        ),
                        const Spacer(),
                        // Find similar action
                        GestureDetector(
                          onTap: () {
                            final verseRef = VerseRef.tryParse(
                              _verseOfTheDay.$1.replaceAll(RegExp(r'-\d+$'), ''),
                            );
                            if (verseRef != null) {
                              Navigator.push(
                                context,
                                FadeSlideRoute(
                                  page: SimilarVersesScreen(
                                    sourceRef: verseRef,
                                    sourceText: _verseOfTheDay.$2,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: BrandColors.gold.withValues(alpha: 0.12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 16, color: BrandColors.gold),
                                const SizedBox(width: 6),
                                Text(
                                  'Find similar',
                                  style: GoogleFonts.lora(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: BrandColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  int _nudgeCount = 0;

  /// Show a gentle sign-up prompt after the user interacts with daily study.
  /// Only shows once every 3 taps, and only if not signed in.
  void _maybeShowSignUpNudge(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) return;
    _nudgeCount++;
    if (_nudgeCount % 3 != 1) return; // Show on 1st, 4th, 7th... interaction

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Center(
            child: Container(
              width: 340,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BrandColors.gold.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border, size: 48, color: BrandColors.gold),
                    const SizedBox(height: 12),
                    Text(
                      'Save Your Progress',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a free account to save your reading progress, '
                      'bookmarks, and notes across devices.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: BrandColors.brownMid,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.gold,
                          foregroundColor: const Color(0xFF3E2723),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Create Free Account',
                            style: GoogleFonts.lora(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Not now',
                          style: GoogleFonts.lora(
                              fontSize: 14, color: BrandColors.brownMid)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _showStreakSheet(BuildContext context, dynamic streak) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Center(
          child: Container(
            width: 340,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BrandColors.gold.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          value: '${streak.bestStreak}',
                          icon: Icons.emoji_events,
                          color: BrandColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Close',
                          style: GoogleFonts.lora(
                              fontSize: 14, color: BrandColors.brownMid)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Container(
          width: 420,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BrandColors.gold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _BookPickerSheet(ref: ref),
            ),
          ),
        ),
      ),
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
              FadeSlideRoute(page: const ListenScreen()))),
      _TileData(Icons.menu_book, 'All Books', Colors.indigo,
          widget.onBookPicker),
      _TileData(Icons.map_outlined, 'Maps', const Color(0xFF2E7D32),
          () => Navigator.push(context,
              FadeSlideRoute(page: const BibleMapsScreen()))),
      _TileData(Icons.child_care, 'Kids', Colors.pink,
          () => showKidsPortal(context, () {
            widget.ref.read(settingsProvider.notifier).setKidsMode(true);
          })),
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
              final tileWidth = constraints.maxWidth < 380 ? 68.0 : 80.0;
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
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Larger filled circle icon badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filled circle icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.25),
                        color.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
