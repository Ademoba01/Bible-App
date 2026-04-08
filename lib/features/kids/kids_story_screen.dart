import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/providers.dart';
import 'kids_stories.dart';

class KidsStoryScreen extends ConsumerStatefulWidget {
  const KidsStoryScreen({super.key, required this.story});
  final KidsStory story;

  @override
  ConsumerState<KidsStoryScreen> createState() => _KidsStoryScreenState();
}

class _KidsStoryScreenState extends ConsumerState<KidsStoryScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _play(String text) async {
    setState(() => _playing = true);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.05);
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final translationId = ref.watch(settingsProvider).translation;
    final repo = ref.watch(bibleRepositoryProvider);
    final cardColor = Color(s.color);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: Colors.white,
        title: Text(s.title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder(
        future: repo.loadBook(s.book, translationId: translationId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapters = snap.data!;
          final chapter = chapters[(s.chapter - 1).clamp(0, chapters.length - 1)];
          final verses = chapter.verses
              .where((v) => v.number >= s.startVerse && v.number <= s.endVerse)
              .toList();
          final fullText = verses.map((v) => v.text).join(' ');

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: cardColor,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 64)),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: verses.length,
                  itemBuilder: (_, i) {
                    final v = verses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            height: 1.55,
                            color: Theme.of(context).colorScheme.onSurface,
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
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: cardColor),
                      icon: Icon(_playing ? Icons.stop : Icons.volume_up),
                      label: Text(_playing ? 'Stop' : 'Read this story to me'),
                      onPressed: _playing ? _stop : () => _play(fullText),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
