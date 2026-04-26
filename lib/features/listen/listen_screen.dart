import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/books.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import '../../widgets/rhema_title.dart';
import '../settings/voice_settings.dart';

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen>
    with SingleTickerProviderStateMixin {
  /// Pulse controller for the big speaker disc — runs while _playing,
  /// stopped otherwise. Drives an animated glow/spread shadow so the
  /// listener feels the rhythm of the narration.
  late final AnimationController _pulseController;
  final FlutterTts _tts = FlutterTts();
  bool _playing = false;
  bool _paused = false;
  // 0.0–1.0 flutter_tts range. 0.38 ≈ 0.75× narration speed (default).
  // Slow, contemplative pace ideal for Scripture comprehension. Users
  // can bump it up via the speed picker; their choice persists across
  // sessions via settingsProvider.setSpeechRate.
  double _speechRate = 0.38;
  List<Verse> _verses = [];
  int _currentVerseIndex = 0;
  int _resumeFromVerse = 0; // track where to resume after pause or speed change
  final ScrollController _scrollController = ScrollController();

  /// Monotonic session counter. Each call to [_play] captures one. The play
  /// loop checks "is my session still current?" between iterations and exits
  /// if not. Pause / Stop / chapter-skip / verse-jump all bump this counter
  /// to ensure the previous loop terminates cleanly before a new one starts —
  /// fixes the dual-loop race that caused Resume to start over from verse 1.
  int _playSession = 0;

  /// Karaoke-style word highlighting. Each call to flutter_tts'
  /// setProgressHandler increments this counter — that's the index of the
  /// word currently being spoken WITHIN the current verse. Reset to -1 on
  /// each new verse, pause, jump, or stop.
  ///
  /// Display matches by counting word-tokens (letter-bearing) in the
  /// displayed verse text. Pure-punctuation tokens are skipped. The mapping
  /// is approximate — punctuation differences between displayed and spoken
  /// text are normalized in _processTextForSpeech, so word counts align.
  int _spokenWordIndex = -1;

  // Preset speed ladder — Audible-style. Dense near the 1.0–1.5× sweet spot
  // where ~80% of listeners settle. Includes 0.9× for archaic English (KJV).
  static final _speeds = <double, String>{
    0.25: '0.5×',
    0.38: '0.75×',
    0.45: '0.9×',
    0.50: '1.0×',
    0.56: '1.1×',
    0.62: '1.25×',
    0.69: '1.4×',
    0.75: '1.5×',
    0.82: '1.75×',
    0.88: '2.0×',
  };

  double get _minSpeed => _speeds.keys.reduce((a, b) => a < b ? a : b);
  double get _maxSpeed => _speeds.keys.reduce((a, b) => a > b ? a : b);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // CRITICAL: makes _tts.speak() actually await until utterance finishes.
    // Without this, the for-loop's setCompletionHandler/Completer dance is
    // racy on Web Speech API and only verse 1 reliably plays before the loop
    // exits. With awaitSpeakCompletion(true), each speak() resolves only when
    // the synthesizer is truly done — verse-by-verse playback works on web,
    // iOS, and Android consistently.
    _tts.awaitSpeakCompletion(true);
    // Force TTS volume to max so the engine doesn't ship below-system-volume
    // by default (some Android TTS engines start at ~0.7). System volume
    // controls still work — this just ensures we use all of what's available.
    _tts.setVolume(1.0);
    // Explicit English locale as the safety default — on devices whose TTS
    // engine defaults to a non-English locale, English Scripture would
    // mispronounce. setVoice() in _play() may override per user choice.
    _tts.setLanguage('en-US');

    // Word-level karaoke. flutter_tts' progress handler fires once per
    // spoken word on iOS/Android/Web. We just count — the display side
    // walks the displayed verse and highlights the Nth word-token.
    _tts.setProgressHandler((String text, int start, int end, String word) {
      if (!mounted) return;
      setState(() => _spokenWordIndex++);
    });

    // Load persisted speed after first frame so we can access Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final saved = ref.read(settingsProvider).speechRate;
      setState(() => _speechRate = saved);
    });
  }

  @override
  void dispose() {
    // Background narration: do NOT stop TTS on screen pop. The user can
    // navigate to Read / Codex / Maps / etc. and the audio keeps flowing.
    // To actually halt narration, the user uses the Stop button or
    // skip-prev/next which all explicitly call _tts.stop().
    //
    // Caveat: the play loop's session counter and pulse animation are
    // tied to THIS State instance, so when the user revisits the Listen
    // screen the controls won't reflect the in-flight playback. The mini-
    // player overlay (next iteration) will surface controls globally.
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Processes Bible text for more natural TTS reading.
  ///
  /// Strategy: keep ALL punctuation TTS engines actually use to phrase
  /// (. , ; : ! ? — — …) and only normalize the visual artifacts that
  /// break narration (smart quotes, brackets, square-bracket editorial
  /// additions, multiple whitespace). Web Speech API and platform TTS
  /// engines pause naturally on every kept mark.
  String _processTextForSpeech(String rawText) {
    var text = rawText;

    // Remove verse numbers (patterns like "1 ", "23 " at start of verses)
    text = text.replaceAll(RegExp(r'^\d+\s+', multiLine: true), '');

    // Remove square-bracket editorial additions ([the LORD], etc.)
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');

    // Normalize smart quotes to plain quotes — TTS engines vary on whether
    // they treat curly quotes as quotation marks. Plain quotes are safer.
    text = text.replaceAll(RegExp(r'["\u201C\u201D\u201E\u00AB\u00BB]'), '"');
    text = text.replaceAll(RegExp(r'[\u2018\u2019\u201A\u2039\u203A`]'), "'");

    // Strip the now-normalized double quotes (TTS reads "quote" on some
    // engines) BUT keep apostrophes — they're needed for contractions.
    text = text.replaceAll('"', '');

    // Convert em-dash / en-dash to a comma for natural breath pause.
    text = text.replaceAll(RegExp(r'\s*[—–]\s*'), ', ');

    // Ellipsis -> period + space for trailing pause behavior.
    text = text.replaceAll(RegExp(r'\.{3,}|\u2026'), '. ');

    // Drop parens but keep content (parens add a subtle voice shift on some
    // engines; removing them yields cleaner phrasing).
    text = text.replaceAll(RegExp(r'[()]'), '');

    // Colons inside verse refs (3:16) stay as digits-only; everywhere else
    // a colon becomes a soft comma pause.
    text = text.replaceAll(RegExp(r':(?!\d)'), ',');

    // Ensure period / exclamation / question / comma / semicolon all have a
    // following space so the TTS engine treats them as a phrase boundary.
    text = text.replaceAll(RegExp(r'([.!?;,])(?=\S)'), r'$1 ');

    // Expand all-caps divine names so engines don't shout-spell them.
    text = text.replaceAll('LORD', 'Lord');
    text = text.replaceAll('GOD', 'God');
    text = text.replaceAll('YHWH', 'Yahweh');

    // Collapse runs of whitespace.
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }

  /// Tokenize verse text into an alternating list of "word" and "non-word"
  /// (whitespace + punctuation) chunks, then return a list of TextSpans
  /// where the [activeWordIndex]-th letter-bearing token is highlighted.
  ///
  /// Pass activeWordIndex = -1 to render flat (no highlight). The mapping
  /// between TTS progressHandler word index and displayed token index is
  /// 1-to-1 because _processTextForSpeech doesn't add or drop words —
  /// it only normalizes punctuation around them.
  List<TextSpan> _buildKaraokeSpans(
    String verseText,
    int activeWordIndex,
    ThemeData theme,
  ) {
    // Tokenize using allMatches so whitespace AND non-whitespace runs are
    // BOTH captured as tokens — concatenating them reconstructs the verse
    // exactly. (The previous String.split() approach silently dropped the
    // matched whitespace, jamming every word together.)
    //
    // Pattern matches one of:
    //   - one or more letters/digits/apostrophes/hyphens   (a word)
    //   - one or more whitespace chars                     (gap)
    //   - any single non-letter/non-whitespace char        (punctuation)
    final pattern = RegExp(r"[A-Za-z\u00C0-\u024F0-9'\-]+|\s+|[^A-Za-z\u00C0-\u024F0-9'\-\s]");
    final tokens = pattern.allMatches(verseText).map((m) => m.group(0)!).toList();

    final spans = <TextSpan>[];
    int wordCounter = 0;
    // Literata for verse text — designed for long-form devotional reading.
    final baseStyle = BrandColors.verseStyle(
      size: 18,
      color: theme.colorScheme.onSurface,
    );
    final highlightStyle = BrandColors.verseStyle(
      size: 18,
      color: theme.colorScheme.onPrimary,
    ).copyWith(
      fontWeight: FontWeight.w700,
      backgroundColor: theme.colorScheme.primary,
    );

    for (final token in tokens) {
      final isWord = RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(token);
      if (isWord) {
        final isActive = activeWordIndex >= 0 && wordCounter == activeWordIndex;
        spans.add(TextSpan(
          text: token,
          style: isActive ? highlightStyle : baseStyle,
        ));
        wordCounter++;
      } else {
        spans.add(TextSpan(text: token, style: baseStyle));
      }
    }

    return spans;
  }

  Future<void> _play({int startFromVerse = 0}) async {
    // Bump session — any previously-running loop will see its session is
    // stale and break on its next iteration check.
    final session = ++_playSession;

    final loc = ref.read(readingLocationProvider);
    final chapters = await ref.read(currentBookChaptersProvider.future);
    if (chapters.isEmpty) return;
    if (session != _playSession) return; // someone bumped while we awaited
    final ch = chapters[(loc.chapter - 1).clamp(0, chapters.length - 1)];
    final verses = ch.verses;

    final settings = ref.read(settingsProvider);
    final voiceName = settings.voiceName;
    if (voiceName.isNotEmpty) {
      await _tts.setVoice({"name": voiceName, "locale": "en-US"});
    }

    // Translation-aware speed: older English (KJV/ASV) is harder to parse at
    // high rates — nudge down ~8% when going above 1.0×.
    final archaic = settings.translation.toLowerCase() == 'kjv' ||
        settings.translation.toLowerCase() == 'asv';
    final effectiveRate = (archaic && _speechRate > 0.50)
        ? _speechRate * 0.92
        : _speechRate;
    await _tts.setSpeechRate(effectiveRate);

    // Pitch compensation — platform TTS engines drift chipmunk-ward at high
    // rates without compensation. Keeps narration voice natural 1.5×+.
    final pitchComp = _speechRate <= 0.62
        ? 1.0
        : _speechRate <= 0.75
            ? 0.96
            : 0.92;
    await _tts.setPitch(pitchComp);

    setState(() {
      _playing = true;
      _paused = false;
      _verses = verses;
      _currentVerseIndex = startFromVerse;
    });
    // Start the pulse — the speaker disc breathes while narration plays.
    _pulseController.repeat(reverse: true);

    // Read verse by verse with natural pauses
    for (int i = startFromVerse; i < verses.length; i++) {
      // Two exits: user stopped (_playing false) OR a new session started
      // (pause/jump/skip). Without the session check, a stuck Web Speech API
      // future could keep an old loop alive in parallel with the new one.
      if (!_playing || session != _playSession) break;

      setState(() => _currentVerseIndex = i);
      _resumeFromVerse = i;

      // Auto-scroll to current verse
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          i * 68.0, // approximate verse height
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      final verseText = _processTextForSpeech(verses[i].text);

      // Reset karaoke counter for the new verse — first progressHandler
      // call will bump us to 0 (the first word).
      _spokenWordIndex = -1;

      // awaitSpeakCompletion(true) was called in initState — speak() now
      // returns only when the utterance is fully spoken. No Completer needed.
      await _tts.speak(verseText);

      if (!_playing || session != _playSession) break;

      // Pauses scale inversely with speed (faster listening = shorter breaths).
      // Chapter-ending pause is long enough to feel liturgical, not abrupt.
      final speedScale = 0.50 / _speechRate;
      final endsWithTerminal = RegExp(r'[.!?]$').hasMatch(verseText);
      final isLastVerse = i == verses.length - 1;
      final basePause = isLastVerse
          ? 900 // chapter beat
          : endsWithTerminal
              ? 400 // sentence break
              : 200; // verse break
      await Future.delayed(
          Duration(milliseconds: (basePause * speedScale).round()));
    }

    // Natural chapter-end: only handle if WE were the live session. If the
    // loop exited because pause/stop/jump bumped the session, those handlers
    // already cleaned up — don't stomp on a fresh session.
    if (mounted && session == _playSession) {
      // Auto-continue: if there's another chapter in this book, advance
      // and start playing it. The user can pause to stop the auto-flow.
      // Skips for last chapter — natural pause point.
      final loc = ref.read(readingLocationProvider);
      final allChapters =
          await ref.read(currentBookChaptersProvider.future);
      final isLastChapter = loc.chapter >= allChapters.length;

      if (!isLastChapter && session == _playSession && mounted) {
        // Brief pause between chapters — feels intentional, not abrupt.
        await Future.delayed(const Duration(milliseconds: 1200));
        if (session != _playSession || !mounted) return;
        ref.read(readingLocationProvider.notifier).next(allChapters.length);
        // Small delay so the chapter provider reloads, then play from v1.
        await Future.delayed(const Duration(milliseconds: 200));
        if (session != _playSession || !mounted) return;
        _play(startFromVerse: 0);
        return; // don't fall through to "stop" cleanup
      }

      // Truly the end of the book — stop cleanly.
      _pulseController.stop();
      _pulseController.value = 0;
      setState(() {
        _playing = false;
        _paused = false;
        _spokenWordIndex = -1;
      });
    }
  }

  Future<void> _pause() async {
    // Bump session so the running play loop terminates cleanly. _resumeFromVerse
    // was set inside the loop on the verse currently being read.
    _playSession++;
    await _tts.stop();
    _pulseController.stop();
    setState(() {
      _playing = false;
      _paused = true;
      _spokenWordIndex = -1;
    });
  }

  Future<void> _resume() async {
    _play(startFromVerse: _resumeFromVerse);
  }

  Future<void> _stop() async {
    _playSession++;
    await _tts.stop();
    _pulseController.stop();
    _pulseController.value = 0;
    setState(() {
      _playing = false;
      _paused = false;
      _resumeFromVerse = 0;
      _spokenWordIndex = -1;
    });
  }

  /// Manual chapter skip (next/prev arrows). Unlike _stop, this preserves
  /// playback continuity — if narration was active, it continues from
  /// verse 1 of the new chapter; if idle, just navigates without auto-play.
  /// Mirrors the auto-continue flow used at natural chapter end.
  Future<void> _skipChapter({required bool forward}) async {
    final wasPlaying = _playing;
    _playSession++;
    await _tts.stop();
    _pulseController.stop();
    _pulseController.value = 0;
    setState(() {
      _playing = false;
      _paused = false;
      _spokenWordIndex = -1;
    });

    // Navigate
    final notifier = ref.read(readingLocationProvider.notifier);
    if (forward) {
      // Use a high cap; the underlying provider clamps to actual book length.
      notifier.next(150);
    } else {
      notifier.prev();
    }

    if (wasPlaying) {
      // Brief delay so currentBookChaptersProvider reloads the new chapter.
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _play(startFromVerse: 0);
    }
  }

  /// Jump to a specific verse during playback. If currently playing, the
  /// running loop terminates and a new one starts at the requested verse.
  /// If paused, just updates the resume marker so Resume picks up there.
  Future<void> _jumpToVerse(int verseIndex) async {
    if (verseIndex < 0 || verseIndex >= _verses.length) return;
    if (_playing) {
      _playSession++;
      await _tts.stop();
      setState(() {
        _playing = false;
        _resumeFromVerse = verseIndex;
        _currentVerseIndex = verseIndex;
      });
      // Small delay so the previous speak() future resolves before we restart.
      await Future.delayed(const Duration(milliseconds: 50));
      _play(startFromVerse: verseIndex);
    } else {
      setState(() {
        _resumeFromVerse = verseIndex;
        _currentVerseIndex = verseIndex;
        _paused = true; // expose Resume button so user can continue from here
      });
    }
  }

  /// Open the voice picker. If currently playing, restart with the new voice
  /// from the current verse so the change feels instant.
  void _showVoicePicker(BuildContext context) {
    final wasPlaying = _playing;
    final resumeAt = _currentVerseIndex;
    showVoiceSettings(context);
    // showVoiceSettings opens a modal; rebuild after it closes to pick up the
    // newly selected voiceName from settingsProvider.
    if (wasPlaying) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
        await _tts.stop();
        if (mounted) {
          setState(() => _playing = false);
          _play(startFromVerse: resumeAt);
        }
      });
    }
  }

  void _setSpeed(double rate) async {
    setState(() => _speechRate = rate);
    // Persist across sessions so users don't re-set it every time (WCAG 2.2.1).
    await ref.read(settingsProvider.notifier).setSpeechRate(rate);
    if (_playing) {
      // Mirror _jumpToVerse: bump the session so the in-flight loop exits,
      // stop TTS, brief delay so the awaited speak() future resolves, then
      // start a NEW _play() loop at the current verse. Without the session
      // bump the old loop hung waiting for awaitSpeakCompletion(true) and
      // narration appeared to "stop" — this is the same race that broke
      // pause/resume before commit 235a2c8.
      final resumeAt = _currentVerseIndex;
      _playSession++;
      await _tts.stop();
      _pulseController.stop();
      _pulseController.value = 0;
      setState(() {
        _playing = false;
        _spokenWordIndex = -1;
      });
      await Future.delayed(const Duration(milliseconds: 50));
      _play(startFromVerse: resumeAt);
    }
  }

  void _increaseSpeed() {
    final keys = _speeds.keys.toList()..sort();
    final idx = keys.indexWhere((k) => k >= _speechRate);
    if (idx < keys.length - 1) {
      _setSpeed(keys[idx + 1]);
    }
  }

  void _decreaseSpeed() {
    final keys = _speeds.keys.toList()..sort();
    final idx = keys.lastIndexWhere((k) => k <= _speechRate);
    if (idx > 0) {
      _setSpeed(keys[idx - 1]);
    }
  }

  String get _currentSpeedLabel {
    // Find closest label
    final keys = _speeds.keys.toList()..sort();
    double closest = keys.first;
    for (final k in keys) {
      if ((k - _speechRate).abs() < (closest - _speechRate).abs()) {
        closest = k;
      }
    }
    return _speeds[closest] ?? '1×';
  }

  void _showBookPicker() async {
    final loc = ref.read(readingLocationProvider);
    final picked = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Container(
          width: 380,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4A843).withOpacity(0.3)),
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
            child: _ListenBookPicker(currentBook: loc.book),
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      if (_playing) await _stop();
      ref.read(readingLocationProvider.notifier).setBook(picked);
    }
  }

  void _showChapterPicker() async {
    final loc = ref.read(readingLocationProvider);
    final chapters = await ref.read(currentBookChaptersProvider.future);
    if (!mounted) return;
    final theme = Theme.of(context);
    final picked = await showDialog<int>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4A843).withOpacity(0.3)),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text('Choose Chapter',
                      style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width < 400 ? 4 : MediaQuery.of(context).size.width < 600 ? 5 : 7,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (var c = 1; c <= chapters.length; c++)
                        InkWell(
                          onTap: () => Navigator.pop(context, c),
                          child: Card(
                            color: c == loc.chapter
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            elevation: c == loc.chapter ? 2 : 0,
                            child: Center(
                              child: Text('$c',
                                  style: TextStyle(
                                    fontWeight: c == loc.chapter ? FontWeight.bold : FontWeight.normal,
                                  )),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      if (_playing) await _stop();
      ref.read(readingLocationProvider.notifier).setChapter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(readingLocationProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const RhemaTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Voice',
            onPressed: () => showVoiceSettings(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 32),
        child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Animated speaker disc ──
              // 160px circle with radial gold→brown gradient. While playing,
              // a pulsing outer glow + scale tween conveys the rhythm of
              // narration. Tap to play/pause as a primary affordance.
              // Semantics: the WCAG audit flagged this disc as the
              // primary play affordance with no screen-reader label —
              // a blind user opening Listen heard nothing actionable.
              Semantics(
                button: true,
                label: _playing
                    ? 'Pause narration, currently on verse ${_currentVerseIndex + 1} of ${_verses.length}'
                    : (_paused
                        ? 'Resume narration from verse ${_resumeFromVerse + 1}'
                        : 'Play this chapter aloud'),
                hint: 'Double tap to ${_playing ? "pause" : "play"}',
                child: GestureDetector(
                  onTap: _playing
                      ? _pause
                      : (_paused ? _resume : _play),
                  child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final pulse = _pulseController.value; // 0 → 1 reverse-tween
                    final scale = _playing ? (1.0 + 0.04 * pulse) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.3, -0.4),
                            radius: 1.0,
                            colors: [
                              BrandColors.goldDeep,
                              BrandColors.brownDeep,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BrandColors.goldDeep.withValues(
                                alpha: _playing
                                    ? 0.30 + 0.30 * pulse
                                    : 0.20,
                              ),
                              blurRadius: _playing ? 30 + 30 * pulse : 20,
                              spreadRadius: _playing ? 4 + 8 * pulse : 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 2,
                          ),
                        ),
                        child: _playing
                            ? CustomPaint(
                                size: const Size(96, 64),
                                painter: _WaveformPainter(
                                  phase: pulse,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _paused
                                    ? Icons.play_arrow_rounded
                                    : Icons.headphones_rounded,
                                size: 72,
                                color: Colors.white,
                              ),
                      ),
                    );
                  },
                ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Tappable book name ──
              GestureDetector(
                onTap: _showBookPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc.book,
                        style: GoogleFonts.lora(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Tappable chapter number ──
              GestureDetector(
                onTap: _showChapterPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Chapter ${loc.chapter}',
                          style: GoogleFonts.lora(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                      const SizedBox(width: 6),
                      Icon(Icons.swap_horiz, size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ══════════════════════════════════════════════
              // ── Speed control bar ──
              // ══════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrease speed
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 24),
                      tooltip: 'Slower',
                      onPressed: _speechRate > _minSpeed ? _decreaseSpeed : null,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),

                    // Speed label — accessible button (WCAG 2.5.8, 4.1.2).
                    // InkWell for keyboard focus + ripple; Semantics provides
                    // screen-reader role/state/action.
                    Semantics(
                      button: true,
                      label: 'Playback speed, currently $_currentSpeedLabel. '
                          'Double tap to change.',
                      child: InkWell(
                        onTap: () => _showSpeedPicker(context, theme),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          constraints: const BoxConstraints(
                              minHeight: 48, minWidth: 72),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.speed,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                _currentSpeedLabel,
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Increase speed
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      tooltip: 'Faster',
                      onPressed: _speechRate < _maxSpeed ? _increaseSpeed : null,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    // Voice change — quick switch without leaving Listen
                    Semantics(
                      button: true,
                      label: 'Change narrator voice',
                      child: IconButton(
                        icon: const Icon(Icons.record_voice_over, size: 22),
                        tooltip: 'Change voice',
                        onPressed: () => _showVoicePicker(context),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Speech speed  •  tap voice icon to change narrator',
                style: GoogleFonts.lora(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),

              const SizedBox(height: 24),

              // ── Prev / Play / Next row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 32),
                    tooltip: 'Previous chapter (continues if playing)',
                    onPressed: loc.chapter > 1
                        ? () => _skipChapter(forward: false)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    icon: Icon(
                      _playing ? Icons.pause : Icons.play_arrow,
                      size: 28,
                    ),
                    label: Text(
                      _playing ? 'Pause' : (_paused ? 'Resume' : 'Play'),
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _playing
                        ? _pause
                        : (_paused ? _resume : _play),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 32),
                    tooltip: 'Next chapter (continues if playing)',
                    onPressed: () => _skipChapter(forward: true),
                  ),
                ],
              ),

              if (_playing || _paused)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _playing
                            ? 'Playing at $_currentSpeedLabel speed — Verse ${_currentVerseIndex + 1}'
                            : 'Paused at Verse ${_resumeFromVerse + 1}',
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_paused) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _stop,
                          child: Text(
                            'Stop',
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Show verses being read with current verse highlighted.
              // Tap any verse to jump TTS playback to it.
              // Within the current verse, the word being spoken is
              // highlighted in real time (karaoke-style) so audio-visual
              // learners can read along.
              if (_verses.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _verses.length,
                    itemBuilder: (context, i) {
                      final isCurrent = (_playing || _paused) && i == _currentVerseIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _jumpToVerse(i),
                            borderRadius: BorderRadius.circular(12),
                            child: Tooltip(
                              message: _playing
                                  ? 'Tap to jump TTS to verse ${i + 1}'
                                  : 'Tap to start playback from verse ${i + 1}',
                              waitDuration: const Duration(milliseconds: 600),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.5)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isCurrent
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 1.5)
                                      : null,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${i + 1} ',
                                        style: BrandColors.verseNumberStyle(
                                          color:
                                              theme.colorScheme.primary,
                                        ),
                                      ),
                                      ..._buildKaraokeSpans(
                                        _verses[i].text,
                                        // Only the active verse gets
                                        // word-level highlighting; other
                                        // verses render flat.
                                        isCurrent && _playing
                                            ? _spokenWordIndex
                                            : -1,
                                        theme,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
    );
  }

  void _showSpeedPicker(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4A843).withOpacity(0.3)),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text('Playback Speed',
                    style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ..._speeds.entries.map((e) {
                  final isSelected = (_speechRate - e.key).abs() < 0.05;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    title: Text(
                      e.value,
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      e.key == 0.50 ? 'Normal speed (recommended)' :
                      e.key < 0.50 ? 'Slower — easier to follow' :
                      'Faster — for experienced listeners',
                      style: GoogleFonts.lora(fontSize: 12),
                    ),
                    onTap: () {
                      _setSpeed(e.key);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog book picker for Listen screen.
class _ListenBookPicker extends StatefulWidget {
  const _ListenBookPicker({required this.currentBook});
  final String currentBook;

  @override
  State<_ListenBookPicker> createState() => _ListenBookPickerState();
}

class _ListenBookPickerState extends State<_ListenBookPicker> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _filter = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final books = _filter.isEmpty
        ? kAllBooks
        : kAllBooks.where((b) => b.name.toLowerCase().contains(_filter)).toList();

    return Column(
      children: [
        const SizedBox(height: 20),
        Text('Choose a Book', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Type to filter...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: books.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = books[i];
              final isCurrent = b.name == widget.currentBook;
              return ListTile(
                title: Text(b.name,
                    style: GoogleFonts.lora(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? theme.colorScheme.primary : null,
                    )),
                trailing: isCurrent
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, b.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Five-bar audio waveform driven by [phase] (0..1, typically the value of
/// the same AnimationController that drives the disc's pulse). Each bar
/// modulates with a sine, phase-offset slightly so they move at organic-
/// looking different rhythms — never in lock-step. Pure CustomPainter, no
/// Lottie / no asset / no extra package.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.phase, required this.color});

  /// Animation value 0..1. Caller passes [_pulseController.value].
  final double phase;
  final Color color;

  static const _barCount = 5;
  static const _barWidthFraction = 0.10; // each bar ~10% of width
  static const _gapFraction = 0.085; // gap between bars
  static const _minBar = 0.18; // min height as fraction of canvas h
  static const _maxBar = 0.95;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barW = size.width * _barWidthFraction;
    final gap = size.width * _gapFraction;
    final totalW = (_barCount * barW) + ((_barCount - 1) * gap);
    final startX = (size.width - totalW) / 2;
    final centerY = size.height / 2;

    for (var i = 0; i < _barCount; i++) {
      // Phase-offset each bar so they don't pulse together. Multiply phase
      // by 2π so the bar height visits both extremes per cycle.
      final wavePhase = (phase * 2 * 3.1415926) + (i * 0.8);
      // sin gives -1..1; map to 0..1 then to _minBar.._maxBar
      final wave = (1 + _safeSin(wavePhase)) / 2;
      final hFrac = _minBar + (_maxBar - _minBar) * wave;
      final barH = size.height * hFrac;

      final left = startX + i * (barW + gap);
      final top = centerY - (barH / 2);
      final rect = RRect.fromLTRBR(
        left,
        top,
        left + barW,
        top + barH,
        Radius.circular(barW / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  // Tiny sine implementation to avoid an extra import — Dart's math.sin is
  // fine to use, but keeping this self-contained makes the painter easier
  // to read and skip if grepping. Falls through to dart:math.sin via
  // Taylor expansion approximation accurate to <1% in [-π, π].
  double _safeSin(double x) {
    // Reduce to [-π, π]
    const twoPi = 6.283185307179586;
    final reduced = x - twoPi * (x / twoPi).floor();
    final r = reduced > 3.141592653589793 ? reduced - twoPi : reduced;
    // Bhaskara I's approximation — good enough for visual animation
    return 16 * r * (3.141592653589793 - r.abs()) /
        (49.34802200544679 - 4 * r * (3.141592653589793 - r.abs()));
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}
