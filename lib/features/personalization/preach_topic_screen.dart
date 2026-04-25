import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Streams a 60-90s mini-sermon on a user-supplied topic.
class PreachTopicScreen extends ConsumerStatefulWidget {
  const PreachTopicScreen({super.key});

  @override
  ConsumerState<PreachTopicScreen> createState() => _PreachTopicScreenState();
}

class _PreachTopicScreenState extends ConsumerState<PreachTopicScreen>
    with SingleTickerProviderStateMixin {
  static const _suggestions = ['Anxiety', 'Forgiveness', 'Doubt', 'Calling', 'Loss'];
  static const _kSavedSermons = 'saved_sermons';

  final _topicCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  StreamSubscription<String>? _sub;
  String _accumulated = '';
  String _topic = '';
  bool _streaming = false;
  bool _saved = false;
  String? _error;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _topicCtrl.dispose();
    _scrollCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _start(String rawTopic) async {
    final topic = rawTopic.trim();
    if (topic.isEmpty) return;
    final settings = ref.read(settingsProvider);
    if (!settings.useOnlineAi) {
      setState(() => _error =
          'This needs AI. Add a Gemini key in Settings to use this.');
      return;
    }
    await _sub?.cancel();
    setState(() {
      _topic = topic;
      _accumulated = '';
      _streaming = true;
      _saved = false;
      _error = null;
    });
    final stream = AiService.preachAboutTopic(topic: topic);
    _sub = stream.listen(
      (chunk) {
        if (!mounted) return;
        setState(() => _accumulated += chunk);
        // Auto-scroll on new content
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _streaming = false;
          _error = 'Stream error. Try again.';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _streaming = false);
      },
    );
  }

  Future<void> _saveToFavorites() async {
    if (_accumulated.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedSermons) ?? <String>[];
    final entry = json.encode({
      'topic': _topic,
      'text': _accumulated,
      'savedAt': DateTime.now().toIso8601String(),
    });
    raw.insert(0, entry);
    await prefs.setStringList(_kSavedSermons, raw);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to favorites', style: GoogleFonts.lora()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    if (_accumulated.trim().isEmpty) return;
    final body = 'On "$_topic" \u2014\n\n$_accumulated\n\n\u2014 from Rhema Study Bible';
    await Share.share(body, subject: 'A word on $_topic');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = _accumulated.isNotEmpty;
    final canAct = !_streaming && hasContent;
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        title: Text('Preach to Me',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What do you need a word about?',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: _topicCtrl,
                style: GoogleFonts.cormorantGaramond(fontSize: 18, height: 1.45),
                onSubmitted: _start,
                decoration: InputDecoration(
                  hintText: 'Type a topic\u2026',
                  hintStyle: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  prefixIcon: const Icon(Icons.record_voice_over),
                  suffixIcon: IconButton(
                    icon: Icon(_streaming ? Icons.stop_circle : Icons.send),
                    color: BrandColors.gold,
                    onPressed: _streaming
                        ? () {
                            _sub?.cancel();
                            setState(() => _streaming = false);
                          }
                        : () => _start(_topicCtrl.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: BrandColors.gold.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: BrandColors.gold, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions
                    .map((s) => ActionChip(
                          label: Text(s,
                              style: GoogleFonts.lora(
                                fontWeight: FontWeight.w600,
                                color: BrandColors.gold,
                              )),
                          onPressed: () {
                            _topicCtrl.text = s;
                            _start(s);
                          },
                          backgroundColor: BrandColors.gold.withValues(alpha: 0.10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: BrandColors.gold.withValues(alpha: 0.35)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              color: Colors.red.shade700,
                            )),
                      ),
                    ],
                  ),
                ),

              // Sermon surface
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BrandColors.gold.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColors.gold.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: hasContent || _streaming
                      ? SingleChildScrollView(
                          controller: _scrollCtrl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_topic.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'On "$_topic"',
                                    style: GoogleFonts.lora(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: BrandColors.gold,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                              SelectableText(
                                _accumulated,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 19,
                                  height: 1.55,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (_streaming) ...[
                                const SizedBox(height: 8),
                                _TypingDots(controller: _dotsCtrl),
                              ],
                            ],
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Pick a topic above and I\u2019ll write you something to sit with.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canAct ? _saveToFavorites : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            _saved ? Colors.green.shade700 : BrandColors.gold,
                        side: BorderSide(
                          color: _saved
                              ? Colors.green.shade400
                              : BrandColors.gold.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
                      label: Text(
                        _saved ? 'Saved' : 'Save',
                        style: GoogleFonts.lora(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canAct ? _share : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.ios_share),
                      label: Text('Share',
                          style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three pulsing dots — visual cue while streaming.
class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (t + i * 0.2) % 1.0;
              final scale = 0.6 + 0.6 * (1 - (phase - 0.5).abs() * 2).clamp(0, 1);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: BrandColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
