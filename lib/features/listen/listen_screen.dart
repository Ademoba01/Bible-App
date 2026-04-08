import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../state/providers.dart';

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
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

  Future<void> _play() async {
    final loc = ref.read(readingLocationProvider);
    final chapters = await ref.read(currentBookChaptersProvider.future);
    if (chapters.isEmpty) return;
    final ch = chapters[(loc.chapter - 1).clamp(0, chapters.length - 1)];
    final text = ch.verses.map((v) => '${v.number}. ${v.text}').join(' ');
    setState(() => _playing = true);
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(readingLocationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.headphones, size: 96, color: Colors.brown),
            const SizedBox(height: 16),
            Text('${loc.book} ${loc.chapter}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
              label: Text(_playing ? 'Stop' : 'Play chapter'),
              onPressed: _playing ? _stop : _play,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
