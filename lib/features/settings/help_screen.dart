import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme.dart';

// ─── FAQ Data ────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;
  final String category;
  const _FaqItem(this.question, this.answer, this.icon, this.category);
}

const _faqs = <_FaqItem>[
  // Translations
  _FaqItem(
    'What translations are available?',
    'We have 14+ translations in 10 languages. KJV and WEB are available '
        'offline (bundled in the app). All others stream from the internet — '
        'look for the cloud icon (☁️) vs the offline pin (📌) in the translation picker.\n\n'
        'To switch translations, tap the Bible image on the Home screen or go to '
        'Settings → Translation.',
    Icons.translate,
    'Translations',
  ),
  _FaqItem(
    'Which translations work offline?',
    'KJV (King James Version) and WEB (World English Bible) work completely '
        'offline with no internet needed. They are bundled inside the app.\n\n'
        'All other translations (BSB, Hindi IRV, Arabic NAV, etc.) require an '
        'internet connection and stream from the Bible API. They are marked with '
        'a cloud icon in the translation picker.',
    Icons.offline_pin,
    'Translations',
  ),
  _FaqItem(
    'Can I read the Bible in my language?',
    'Yes! We support Arabic, Hindi, Bengali, Amharic, Tibetan, Belarusian, '
        'Assamese, Azerbaijani, Hebrew, and Ancient Greek — plus English. '
        'More languages are being added.\n\n'
        'Go to Settings → Translation and scroll down to see all available languages.',
    Icons.language,
    'Translations',
  ),

  // Reading & Listening
  _FaqItem(
    'How do I listen to the Bible?',
    'Tap the headphones icon (🎧) in the bottom navigation bar to open the '
        'Listen screen. Choose a book and chapter, then tap Play.\n\n'
        'You can adjust the speed from 0.5× to 2×, and choose from different '
        'voices in the Voice settings.',
    Icons.headphones,
    'Reading & Listening',
  ),
  _FaqItem(
    'How do I change the narrator voice?',
    'Go to the Listen screen and tap the voice icon (🗣️) in the top right, '
        'or go to Settings → Voice.\n\n'
        'We recommend using Premium or Enhanced voices for the most natural '
        'reading experience. You can preview each voice before selecting it.\n\n'
        '💡 Tip: Download additional premium voices from your device Settings → '
        'Accessibility → Spoken Content (iOS) or Settings → Language & Input → '
        'Text-to-Speech (Android).',
    Icons.record_voice_over,
    'Reading & Listening',
  ),
  _FaqItem(
    'How do I make the text bigger or smaller?',
    'Go to Settings and use the Font Size slider. You can set it anywhere '
        'from 14 to 28.',
    Icons.format_size,
    'Reading & Listening',
  ),

  // Study Features
  _FaqItem(
    'What study features are available?',
    'Rhema Study Bible includes:\n'
        '• AI-powered quizzes on any chapter\n'
        '• Similar verse discovery (find thematically related verses)\n'
        '• Study notes you can write for any verse\n'
        '• Reading plans (7-day, 30-day, custom)\n'
        '• Interactive Bible maps with 56+ locations\n'
        '• Journey playback — watch biblical journeys animate on the map\n'
        '• Bookmarks and highlights (5 colors)\n'
        '• Reading streaks to track consistency',
    Icons.school,
    'Study Features',
  ),
  _FaqItem(
    'How do Bible Maps work?',
    'Go to the Study tab and tap Bible Maps. You\'ll see 56+ biblical locations '
        'on an interactive map.\n\n'
        '• Tap any marker to see its history and related verses\n'
        '• Use the journey chips to trace biblical journeys (Abraham, Exodus, Paul, etc.)\n'
        '• Press the Play button to watch an animated journey playback\n'
        '• Filter by era (Patriarchs, Jesus, Early Church, etc.)\n'
        '• Toggle satellite view with the satellite icon',
    Icons.map,
    'Study Features',
  ),
  _FaqItem(
    'How do AI features work?',
    'AI features use Google Gemini for smarter quizzes and verse discovery. '
        'There are two modes:\n\n'
        '• **Offline** — uses built-in keyword matching, no internet needed\n'
        '• **Online** — uses AI for deeper understanding (requires free API key)\n\n'
        'To set up online AI: Settings → Advanced → paste your free Gemini API key '
        'from ai.google.dev',
    Icons.auto_awesome,
    'Study Features',
  ),

  // Kids Mode
  _FaqItem(
    'What is Kids Mode?',
    'Kids Mode transforms the app into a fun, colorful Bible experience for '
        'children ages 6+. It includes:\n\n'
        '• 20 animated Bible stories with emoji illustrations\n'
        '• "Read to Me" narration with a friendly voice\n'
        '• Bright, engaging design with the Fredoka font\n'
        '• Moral lessons at the end of each story\n\n'
        'Toggle it in Settings → Kids Mode.',
    Icons.child_care,
    'Kids Mode',
  ),

  // Account & Data
  _FaqItem(
    'Is my data saved?',
    'All your data (bookmarks, highlights, notes, reading progress, streaks) '
        'is saved locally on your device. Nothing is sent to any server.\n\n'
        'Bible text from online translations is fetched fresh each time — '
        'it is not stored permanently on your device.',
    Icons.save,
    'Data & Privacy',
  ),
  _FaqItem(
    'Is the app free?',
    'Yes! Rhema Study Bible is completely free with no ads, no subscriptions, '
        'and no in-app purchases. All features are available to everyone.',
    Icons.volunteer_activism,
    'Data & Privacy',
  ),
];

// ─── Predefined chat responses ───────────────────────────────────

const _chatResponses = <String, String>{
  // Greetings
  'hello': 'Hello! 👋 I\'m the Rhema assistant. How can I help you today? You can ask me about translations, reading modes, study features, or anything else about the app.',
  'hi': 'Hi there! 👋 How can I help you with Rhema Study Bible?',
  'hey': 'Hey! 👋 What would you like to know about the app?',
  'help': 'I\'m here to help! You can ask me about:\n\n📖 Translations & offline reading\n🎧 Listening & voice settings\n📚 Study features & maps\n👶 Kids Mode\n⚙️ Settings & customization\n\nJust type your question!',

  // Translations
  'offline': 'KJV and WEB work completely offline — they\'re bundled in the app. All other translations (BSB, Hindi, Arabic, etc.) need an internet connection and are marked with a cloud icon ☁️.',
  'translation': 'To switch translations, tap the Bible image on the Home screen or go to Settings → Translation. We have 14+ translations in 10 languages! KJV and WEB work offline.',
  'language': 'We support English, Hindi, Arabic, Bengali, Amharic, Tibetan, Belarusian, Assamese, Azerbaijani, Hebrew, and Ancient Greek. Go to Settings → Translation to browse by language.',
  'bsb': 'The Berean Standard Bible (BSB) is available! It streams from the internet. Select it in Settings → Translation under English.',
  'kjv': 'The King James Version (KJV) is bundled in the app and works completely offline. It\'s one of the two default translations.',
  'arabic': 'We have two Arabic translations: NAV (New Arabic Version) and VDV (Van Dyck Bible). Go to Settings → Translation and look under Arabic.',
  'hindi': 'The Hindi Indian Revised Version (IRV) is available! Go to Settings → Translation and look under Hindi.',

  // Voice / TTS
  'voice': 'To change the narrator voice, go to the Listen screen and tap the voice icon 🗣️ in the top right. We recommend Premium voices for the most natural sound.\n\n💡 Download more premium voices from your device Settings → Accessibility → Spoken Content.',
  'narrator': 'The narrator uses your device\'s text-to-speech voices. For the most human-like experience:\n\n1. Go to Listen → Voice icon\n2. Look for voices marked "Premium" (gold badge)\n3. Preview them before selecting\n\nYou can also download better voices from your device settings.',
  'speed': 'Adjust reading speed on the Listen screen using the speed controls (0.5× to 2×). Tap the speed label to see all options.',
  'sound': 'Make sure your device volume is up and not on silent mode. The app uses the media volume channel. If voices aren\'t working, try selecting a different voice in Listen → Voice settings.',

  // Study
  'map': 'Bible Maps shows 56+ locations across all eras. Go to Study → Bible Maps. You can:\n• Filter by era (Patriarchs, Jesus, etc.)\n• Play animated journey routes\n• Tap markers for history & verses\n• Toggle satellite view',
  'quiz': 'AI Quizzes test your knowledge of any chapter. Go to Study → Quiz. You can use offline mode (keyword-based) or online mode (Gemini AI) for smarter questions.',
  'bookmark': 'Long-press any verse while reading to bookmark it. Find all bookmarks in the Bookmarks tab. You can also highlight verses in 5 different colors!',
  'highlight': 'While reading, long-press a verse to highlight it. Choose from 5 colors: yellow, green, blue, pink, or orange.',
  'notes': 'Tap a verse while reading, then tap the notes icon to add a study note. Your notes are saved locally on your device.',
  'streak': 'Your reading streak tracks consecutive days of Bible reading. Open the app and read any chapter to maintain your streak!',
  'plan': 'Reading plans guide you through the Bible systematically. Go to Study → Reading Plans to start a 7-day, 30-day, or custom plan.',

  // Kids
  'kids': 'Kids Mode transforms the app for children ages 6+. Toggle it in Settings → Kids Mode. It includes 20 animated Bible stories with "Read to Me" narration and emoji illustrations!',
  'stories': 'There are 20 animated Bible stories in Kids Mode — from Creation to Jesus Rises. Each has page-by-page illustrations, a "Read to Me" button, and a moral lesson at the end.',

  // Technical
  'dark': 'Toggle dark mode in Settings → Dark mode. It works in both adult and kids modes.',
  'font': 'Adjust font size in Settings using the Font Size slider (14–28).',
  'data': 'All your data is stored locally on your device. Nothing is sent to external servers. Online translations are streamed but not permanently stored.',
  'free': 'Yes! Rhema Study Bible is 100% free with no ads, no subscriptions, and no in-app purchases.',
  'ai': 'AI features use Google Gemini for smarter quizzes and verse discovery. Set up a free API key at ai.google.dev, then paste it in Settings → Advanced.',
  'gemini': 'To use Gemini AI:\n1. Get a free API key at ai.google.dev\n2. Go to Settings → AI Features → Advanced\n3. Paste your key and tap ✓\n4. Test the connection\n\nOnline AI gives smarter quizzes and better verse discovery.',
};

/// Find the best matching response for a user query.
String _findResponse(String query) {
  final lower = query.toLowerCase().trim();

  // Direct keyword match
  for (final entry in _chatResponses.entries) {
    if (lower == entry.key || lower.contains(entry.key)) {
      return entry.value;
    }
  }

  // Fuzzy matching — check if query words match any key
  final words = lower.split(RegExp(r'\s+'));
  String? bestMatch;
  int bestScore = 0;
  for (final entry in _chatResponses.entries) {
    int score = 0;
    for (final word in words) {
      if (entry.key.contains(word) || entry.value.toLowerCase().contains(word)) {
        score++;
      }
    }
    if (score > bestScore) {
      bestScore = score;
      bestMatch = entry.value;
    }
  }

  if (bestMatch != null && bestScore >= 1) return bestMatch;

  return 'I\'m not sure about that. Try asking about:\n\n'
      '• Translations & offline reading\n'
      '• Voice & narrator settings\n'
      '• Study features (maps, quizzes, notes)\n'
      '• Kids Mode\n'
      '• Settings & customization\n\n'
      'Or scroll down to browse the FAQ!';
}

// ─── Help Screen ─────────────────────────────────────────────────

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & FAQ',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Ask'),
            Tab(icon: Icon(Icons.help_outline), text: 'FAQ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ChatTab(),
          _FaqTab(),
        ],
      ),
    );
  }
}

// ─── Chat Tab ────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage(this.text, this.isUser);
}

class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      'Hi! I\'m the Rhema assistant. 👋\n\n'
          'Ask me anything about the app — translations, voice settings, '
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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text, true));
      _messages.add(_ChatMessage(_findResponse(text), false));
    });

    _controller.clear();

    // Scroll to bottom
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Quick suggestion chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _suggestionChip('What works offline?', theme),
              _suggestionChip('How to change voice?', theme),
              _suggestionChip('What languages?', theme),
              _suggestionChip('How do maps work?', theme),
              _suggestionChip('Kids mode?', theme),
            ],
          ),
        ),
        const Divider(height: 1),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _buildMessage(_messages[i], theme),
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: GoogleFonts.lora(fontSize: 14),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    style: GoogleFonts.lora(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionChip(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text,
            style: GoogleFonts.lora(
                fontSize: 12, color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        onPressed: () {
          _controller.text = text;
          _send();
        },
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, ThemeData theme) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.lora(
            fontSize: 14,
            height: 1.5,
            color: msg.isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── FAQ Tab ─────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Group FAQs by category
    final categories = <String, List<_FaqItem>>{};
    for (final faq in _faqs) {
      categories.putIfAbsent(faq.category, () => []).add(faq);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in categories.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(_categoryIcon(entry.key),
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map((faq) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Icon(faq.icon, size: 20, color: BrandColors.brownMid),
                  title: Text(
                    faq.question,
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faq.answer,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Translations':
        return Icons.translate;
      case 'Reading & Listening':
        return Icons.headphones;
      case 'Study Features':
        return Icons.school;
      case 'Kids Mode':
        return Icons.child_care;
      case 'Data & Privacy':
        return Icons.security;
      default:
        return Icons.help_outline;
    }
  }
}
