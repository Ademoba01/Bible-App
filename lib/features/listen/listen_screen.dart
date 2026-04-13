import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/books.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../settings/voice_settings.dart';

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _playing = false;
  bool _paused = false;
  double _speechRate = 0.75; // 0.0–1.0 range; 0.75 = 1.5× speed (default)
  List<Verse> _verses = [];
  int _currentVerseIndex = 0;
  int _resumeFromVerse = 0; // track where to resume after pause or speed change
  final ScrollController _scrollController = ScrollController();

  // Preset speed labels (non-const because double keys)
  static final _speeds = <double, String>{
    0.25: '0.5×',
    0.38: '0.75×',
    0.50: '1×',
    0.62: '1.25×',
    0.75: '1.5×',
    0.88: '2×',
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tts.stop();
    _scrollController.dispose();
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

    // Ensure sentences end clearly with a space for natural pacing
    text = text.replaceAll(RegExp(r'\.(?=\S)'), '. ');

    // Add natural pauses after commas that are too close
    text = text.replaceAll(RegExp(r',(?=\S)'), ', ');

    // Replace em-dashes and long dashes with comma (natural pause)
    text = text.replaceAll(RegExp(r'[—–]'), ', ');

    // Expand common abbreviations for clearer speech
    text = text.replaceAll('LORD', 'Lord');
    text = text.replaceAll('GOD', 'God');

    // Clean up multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Remove quotation marks that confuse TTS
    text = text.replaceAll(RegExp(r'["""''`]'), '');

    // Remove parentheses but keep content
    text = text.replaceAll(RegExp(r'[()]'), '');

    // Remove brackets (often editorial additions)
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');

    return text.trim();
  }

  Future<void> _play({int startFromVerse = 0}) async {
    final loc = ref.read(readingLocationProvider);
    final chapters = await ref.read(currentBookChaptersProvider.future);
    if (chapters.isEmpty) return;
    final ch = chapters[(loc.chapter - 1).clamp(0, chapters.length - 1)];
    final verses = ch.verses;

    final voiceName = ref.read(settingsProvider).voiceName;
    if (voiceName.isNotEmpty) {
      await _tts.setVoice({"name": voiceName, "locale": "en-US"});
    }
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(1.0);

    setState(() {
      _playing = true;
      _paused = false;
      _verses = verses;
      _currentVerseIndex = startFromVerse;
    });

    // Read verse by verse with natural pauses
    for (int i = startFromVerse; i < verses.length; i++) {
      if (!_playing) break;

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

      final completer = Completer<void>();
      _tts.setCompletionHandler(() {
        completer.complete();
      });

      await _tts.speak(verseText);
      await completer.future;

      if (!_playing) break;

      // Natural pause between verses — longer after sentences ending with period
      final endsWithPeriod = verseText.endsWith('.');
      await Future.delayed(
          Duration(milliseconds: endsWithPeriod ? 400 : 200));
    }

    if (mounted) {
      setState(() {
        _playing = false;
        _paused = false;
      });
    }
  }

  Future<void> _pause() async {
    await _tts.stop();
    setState(() {
      _playing = false;
      _paused = true;
      // _resumeFromVerse already tracks current position
    });
  }

  Future<void> _resume() async {
    _play(startFromVerse: _resumeFromVerse);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() {
      _playing = false;
      _paused = false;
      _resumeFromVerse = 0;
    });
  }

  void _setSpeed(double rate) async {
    setState(() => _speechRate = rate);
    if (_playing) {
      // Remember current position, stop, and resume from same verse
      final resumeAt = _currentVerseIndex;
      await _tts.stop();
      setState(() => _playing = false);
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
        title: const Text('Listen'),
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
              // ── Headphone icon ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                ),
                child: Icon(Icons.headphones, size: 60, color: theme.colorScheme.primary),
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
                      onPressed: _speechRate > 0.25 ? _decreaseSpeed : null,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),

                    // Speed label
                    GestureDetector(
                      onTap: () => _showSpeedPicker(context, theme),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, size: 18, color: theme.colorScheme.primary),
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

                    const SizedBox(width: 4),

                    // Increase speed
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      tooltip: 'Faster',
                      onPressed: _speechRate < 0.88 ? _increaseSpeed : null,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Speech speed',
                style: GoogleFonts.lora(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),

              const SizedBox(height: 24),

              // ── Prev / Play / Next row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 32),
                    tooltip: 'Previous chapter',
                    onPressed: loc.chapter > 1
                        ? () {
                            _stop();
                            ref.read(readingLocationProvider.notifier).prev();
                          }
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
                    tooltip: 'Next chapter',
                    onPressed: () {
                      _stop();
                      ref.read(readingLocationProvider.notifier).next(150);
                    },
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

              // Show verses being read with current verse highlighted
              if (_verses.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _verses.length,
                    itemBuilder: (context, i) {
                      final isCurrent = (_playing || _paused) && i == _currentVerseIndex;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrent
                              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                              : null,
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${i + 1} ',
                                style: GoogleFonts.lora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: _verses[i].text,
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
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
