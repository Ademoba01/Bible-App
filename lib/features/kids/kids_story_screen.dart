import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../../state/providers.dart';
import '../settings/voice_settings.dart';
import 'kids_quiz_screen.dart';
import 'kids_stories.dart';

class KidsStoryScreen extends ConsumerStatefulWidget {
  const KidsStoryScreen({super.key, required this.story});
  final KidsStory story;

  @override
  ConsumerState<KidsStoryScreen> createState() => _KidsStoryScreenState();
}

class _KidsStoryScreenState extends ConsumerState<KidsStoryScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _playing = false;
  int _currentVerseIndex = -1;
  final ScrollController _verseScrollController = ScrollController();

  // Animation controllers
  late final AnimationController _emojiBounceController;
  late final Animation<Offset> _emojiBounceAnimation;

  late final AnimationController _slideUpController;
  late final Animation<Offset> _slideUpAnimation;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  // Verse fade-in controllers built dynamically when data loads
  final List<AnimationController> _verseFadeControllers = [];
  final List<Animation<double>> _verseFadeAnimations = [];
  int _lastVerseCount = 0;

  @override
  void initState() {
    super.initState();
    // Make _tts.speak() actually await — fixes the verse-1-only stop bug
    // also seen on the adult Listen screen (see listen_screen.dart:initState).
    _tts.awaitSpeakCompletion(true);
    // Max TTS volume so kid stories aren't quiet even at full system volume.
    _tts.setVolume(1.0);
    // 1) Bouncing emoji — gentle continuous bounce
    _emojiBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _emojiBounceAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(
      parent: _emojiBounceController,
      curve: Curves.easeInOut,
    ));

    // 4) Slide-up for story content
    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideUpController,
      curve: Curves.easeOut,
    ));

    // 3) Glowing play button — pulsing opacity for shadow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  /// Build verse fade controllers when verse count is known.
  void _ensureVerseFadeControllers(int count) {
    if (count == _lastVerseCount) return;
    // Dispose old controllers
    for (final c in _verseFadeControllers) {
      c.dispose();
    }
    _verseFadeControllers.clear();
    _verseFadeAnimations.clear();

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _verseFadeControllers.add(controller);
      _verseFadeAnimations.add(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }
    _lastVerseCount = count;

    // Kick off staggered fade-ins and the slide-up
    _slideUpController.forward(from: 0);
    _triggerStaggeredFadeIn();
  }

  void _triggerStaggeredFadeIn() {
    for (int i = 0; i < _verseFadeControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted && i < _verseFadeControllers.length) {
          _verseFadeControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _verseScrollController.dispose();
    _emojiBounceController.dispose();
    _slideUpController.dispose();
    _glowController.dispose();
    for (final c in _verseFadeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Processes Bible text for more natural TTS reading.
  String _processTextForSpeech(String rawText) {
    var text = rawText;

    // Remove verse numbers (patterns like "1 ", "23 " at start of verses)
    text = text.replaceAll(RegExp(r'^\d+\s+', multiLine: true), '');

    // Replace semicolons with period (longer pause)
    text = text.replaceAll(';', '.');

    // Replace colons in speech (not verse refs like 3:16) with comma for short pause
    text = text.replaceAll(RegExp(r':(?!\d)'), ',');

    // Ensure sentences end clearly
    text = text.replaceAll(RegExp(r'\.(?=\S)'), '. ');

    // Clean up multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Remove quotation marks that confuse TTS
    text = text.replaceAll(RegExp(r'["""]'), '');

    return text.trim();
  }

  Future<void> _playVerses(List<Verse> verses) async {
    final voiceName = ref.read(settingsProvider).voiceName;
    if (voiceName.isNotEmpty) {
      await _tts.setVoice({"name": voiceName, "locale": "en-US"});
    }
    // 0.55 ≈ 1.1× — natural, lively but still clear for ages 5-10.
    // 0.42 was about 0.85× which felt sluggish.
    await _tts.setSpeechRate(0.55);
    await _tts.setPitch(1.15);

    setState(() {
      _playing = true;
      _currentVerseIndex = 0;
    });

    for (int i = 0; i < verses.length; i++) {
      if (!_playing) break;

      setState(() => _currentVerseIndex = i);

      // Auto-scroll to current verse
      if (_verseScrollController.hasClients) {
        _verseScrollController.animateTo(
          i * 80.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      final verseText = _processTextForSpeech(verses[i].text);

      // awaitSpeakCompletion(true) was set in initState; speak() awaits.
      await _tts.speak(verseText);

      if (!_playing) break;

      // Natural pause between verses
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (mounted) {
      setState(() {
        _playing = false;
        _currentVerseIndex = -1;
      });
      // Track story completion
      _trackStoryRead(widget.story.title);
    }
  }

  /// Record that this story was read/listened to for parent dashboard
  Future<void> _trackStoryRead(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('kids_stories_read') ?? '[]';
    final List<String> stories = List<String>.from(json.decode(raw));
    if (!stories.contains(title)) {
      stories.add(title);
      await prefs.setString('kids_stories_read', json.encode(stories));
    }
    // Track daily minutes (rough estimate: 2 min per story)
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'kids_daily_minutes_$today';
    final currentMinutes = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentMinutes + 2);
    // Total reading minutes
    final total = prefs.getInt('kids_total_reading_minutes') ?? 0;
    await prefs.setInt('kids_total_reading_minutes', total + 2);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() {
      _playing = false;
      _currentVerseIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final translationId = ref.watch(settingsProvider.select((s) => s.translation));
    final repo = ref.watch(bibleRepositoryProvider);
    final cardColor = Color(s.color);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: Colors.white,
        title: Text(s.title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Voice',
            onPressed: () => showVoiceSettings(context),
          ),
        ],
      ),
      body: FutureBuilder(
        future: repo.loadBook(s.book, translationId: translationId),
        builder: (context, snap) {
          // Error state
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Oops! Could not load this story.',
                        style: GoogleFonts.fredoka(fontSize: 18),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {}), // retrigger FutureBuilder
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Loading state
          if (!snap.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bouncing emoji even while loading
                  SlideTransition(
                    position: _emojiBounceAnimation,
                    child: Text(s.emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text('Loading story...',
                      style: GoogleFonts.fredoka(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final chapters = snap.data!;
          final chapter = chapters[(s.chapter - 1).clamp(0, chapters.length - 1)];
          final verses = chapter.verses
              .where((v) => v.number >= s.startVerse && v.number <= s.endVerse)
              .toList();

          // Ensure verse fade controllers match the verse count
          _ensureVerseFadeControllers(verses.length);

          return SlideTransition(
            position: _slideUpAnimation,
            child: Column(
              children: [
                // Header with bouncing emoji
                Container(
                  width: double.infinity,
                  color: cardColor,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlideTransition(
                        position: _emojiBounceAnimation,
                        child: Text(s.emoji, style: const TextStyle(fontSize: 36)),
                      ),
                      Text(
                        s.blurb,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${s.book} ${s.chapter}:${s.startVerse}-${s.endVerse}',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // Verses with staggered fade-in and current verse highlighting
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _verseScrollController,
                        // Bottom padding leaves room for the "Tap the button
                        // below" hint overlay so the last verse stays readable
                        // and isn't masked by the hint's gradient fade.
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                        itemCount: verses.length,
                        itemBuilder: (_, i) {
                          final v = verses[i];
                          final isCurrent = _playing && i == _currentVerseIndex;
                          return FadeTransition(
                            opacity: i < _verseFadeAnimations.length
                                ? _verseFadeAnimations[i]
                                : const AlwaysStoppedAnimation(1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? cardColor.withValues(alpha: 0.15)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                border: isCurrent
                                    ? Border.all(color: cardColor, width: 2.5)
                                    : null,
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: cardColor.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Playing indicator
                                  if (isCurrent)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8, top: 4),
                                      child: Icon(Icons.volume_up, size: 20, color: cardColor),
                                    ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.fredoka(
                                          fontSize: 22,
                                          height: 1.55,
                                          color: isCurrent
                                              ? Theme.of(context).colorScheme.onSurface
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: _playing ? 0.5 : 1.0),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${v.number}  ',
                                            style: TextStyle(color: cardColor, fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: v.text),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Audio-first prompt overlay — shown when not playing and just loaded.
                      // Uses a TALL gradient so the fade fully obscures any verse
                      // text behind it, then a centered hint chip on solid bg
                      // so the message reads cleanly on every device size.
                      if (!_playing && _currentVerseIndex == -1)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tall fade so verse text dissolves into the
                                // background before the hint chip.
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Theme.of(context)
                                            .scaffoldBackgroundColor
                                            .withValues(alpha: 0),
                                        Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ),
                                ),
                                // Hint chip on solid bg
                                Container(
                                  width: double.infinity,
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 8),
                                  child: Center(
                                    child: Text(
                                      '\u{1F3A7} Tap the button below to hear the story!',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        color: cardColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Glowing play button + Quiz button
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _playing
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: cardColor.withValues(
                                            alpha: 0.25 + 0.35 * _glowAnimation.value,
                                          ),
                                          blurRadius: 8 + 14 * _glowAnimation.value,
                                          spreadRadius: 1 + 3 * _glowAnimation.value,
                                        ),
                                      ],
                              ),
                              child: child,
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: cardColor),
                              icon: Icon(_playing ? Icons.stop : Icons.volume_up),
                              label: Text(_playing ? 'Stop' : 'Read this story to me'),
                              onPressed: _playing ? _stop : () => _playVerses(verses),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cardColor,
                              side: BorderSide(color: cardColor, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Text('🎉', style: TextStyle(fontSize: 20)),
                            label: Text('Quiz time!',
                                style: GoogleFonts.fredoka(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KidsQuizScreen(
                                    book: s.book,
                                    chapter: s.chapter,
                                    startVerse: s.startVerse,
                                    endVerse: s.endVerse,
                                    themeColor: cardColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
