import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Opens the voice-settings dialog.
void showVoiceSettings(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Center(
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
          child: const _VoiceSettingsSheet(),
        ),
      ),
    ),
  );
}

/// Quality tier for a TTS voice.
enum VoiceQuality { premium, enhanced, standard }

class _VoiceSettingsSheet extends ConsumerStatefulWidget {
  const _VoiceSettingsSheet();

  @override
  ConsumerState<_VoiceSettingsSheet> createState() =>
      _VoiceSettingsSheetState();
}

class _VoiceSettingsSheetState extends ConsumerState<_VoiceSettingsSheet> {
  final FlutterTts _tts = FlutterTts();
  List<Map<String, String>> _voices = [];
  bool _loading = true;
  String _selectedVoice = '';
  String? _previewingVoice;

  // Gender heuristics based on common TTS voice naming conventions.
  static const _maleHints = [
    'male', 'daniel', 'james', 'tom', 'aaron', 'albert', 'bruce', 'fred',
    'ralph', 'junior', 'oliver', 'liam', 'arthur', 'gordon', 'rishi',
    'jacques', 'jorge', 'grandpa', 'eddy', 'reed', 'rocko', 'otis',
    'evan', 'alex',
  ];
  static const _femaleHints = [
    'female', 'samantha', 'karen', 'kate', 'moira', 'fiona', 'tessa',
    'victoria', 'allison', 'ava', 'susan', 'zoe', 'alice', 'kathy',
    'nicky', 'veena', 'joana', 'ellen', 'grandma', 'bells', 'cellos',
    'shelley', 'trinoids', 'superstar', 'organ', 'siri',
  ];

  // Premium/Enhanced voice name hints (Apple Siri, Google Neural, etc.)
  static const _premiumHints = [
    'premium', 'neural', 'siri', 'wavenet', 'journey',
  ];
  static const _enhancedHints = [
    'enhanced', 'compact', 'eloquence',
  ];

  // Recommended voices that sound particularly natural for Bible reading
  static const _recommendedVoices = [
    // Apple premium voices
    'com.apple.voice.premium.en-US.Zoe',
    'com.apple.voice.premium.en-US.Ava',
    'com.apple.voice.premium.en-GB.Daniel',
    'com.apple.voice.premium.en-AU.Karen',
    'com.apple.speech.synthesis.voice.Samantha',
    // Common high-quality names
    'Daniel', 'Samantha', 'Karen', 'Moira', 'Fiona',
  ];

  String _categorize(String name) {
    final lower = name.toLowerCase();
    for (final h in _femaleHints) {
      if (lower.contains(h)) return 'Female';
    }
    for (final h in _maleHints) {
      if (lower.contains(h)) return 'Male';
    }
    return 'Default';
  }

  VoiceQuality _getQuality(String name) {
    final lower = name.toLowerCase();
    for (final h in _premiumHints) {
      if (lower.contains(h)) return VoiceQuality.premium;
    }
    for (final h in _enhancedHints) {
      if (lower.contains(h)) return VoiceQuality.enhanced;
    }
    return VoiceQuality.standard;
  }

  bool _isRecommended(String name) {
    final lower = name.toLowerCase();
    return _recommendedVoices.any((r) => lower.contains(r.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    final currentVoice = ref.read(settingsProvider).voiceName;
    setState(() => _selectedVoice = currentVoice);

    final List<dynamic> rawVoices = await _tts.getVoices;
    final List<Map<String, String>> parsed = [];
    for (final v in rawVoices) {
      if (v is Map) {
        final name = v['name']?.toString() ?? '';
        final locale = v['locale']?.toString() ?? '';
        // Only show English voices for clarity
        if (locale.startsWith('en')) {
          parsed.add({'name': name, 'locale': locale});
        }
      }
    }

    // Sort: premium first, then enhanced, then standard; within each, alphabetical
    parsed.sort((a, b) {
      final qa = _getQuality(a['name']!).index;
      final qb = _getQuality(b['name']!).index;
      if (qa != qb) return qa.compareTo(qb);
      final ra = _isRecommended(a['name']!) ? 0 : 1;
      final rb = _isRecommended(b['name']!) ? 0 : 1;
      if (ra != rb) return ra.compareTo(rb);
      return a['name']!.compareTo(b['name']!);
    });

    if (mounted) {
      setState(() {
        _voices = parsed;
        _loading = false;
      });
    }
  }

  Future<void> _preview(String voiceName, String locale) async {
    setState(() => _previewingVoice = voiceName);
    await _tts.stop();
    await _tts.setVoice({'name': voiceName, 'locale': locale});
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _previewingVoice = null);
    });
    await _tts.speak(
        'The Lord is my shepherd, I shall not want. He makes me lie down in green pastures.');
  }

  Future<void> _selectVoice(String voiceName) async {
    setState(() => _selectedVoice = voiceName);
    await ref.read(settingsProvider.notifier).setVoiceName(voiceName);
  }

  Widget _qualityBadge(VoiceQuality quality) {
    switch (quality) {
      case VoiceQuality.premium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 10, color: Colors.white),
              const SizedBox(width: 2),
              Text('Premium',
                  style: GoogleFonts.lora(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        );
      case VoiceQuality.enhanced:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: BrandColors.brown.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Enhanced',
              style: GoogleFonts.lora(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.brown)),
        );
      case VoiceQuality.standard:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group voices by category
    final Map<String, List<Map<String, String>>> grouped = {
      'Recommended': [],
      'Female': [],
      'Male': [],
      'Default': [],
    };
    for (final v in _voices) {
      final name = v['name']!;
      if (_isRecommended(name) ||
          _getQuality(name) == VoiceQuality.premium) {
        grouped['Recommended']!.add(v);
      }
      final cat = _categorize(name);
      grouped[cat]!.add(v);
    }

    return Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Voice Selection',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: BrandColors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Premium voices sound most natural for Bible reading. '
              'Download enhanced voices in your device Settings → Accessibility → Spoken Content.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 11,
                color: BrandColors.brownMid,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category
                      in ['Recommended', 'Female', 'Male', 'Default'])
                    if (grouped[category]!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              category == 'Recommended'
                                  ? Icons.auto_awesome
                                  : category == 'Female'
                                      ? Icons.face_3
                                      : category == 'Male'
                                          ? Icons.face
                                          : Icons.record_voice_over,
                              size: 18,
                              color: category == 'Recommended'
                                  ? const Color(0xFFD4A843)
                                  : BrandColors.brown,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category == 'Recommended'
                                  ? 'Recommended (Most Natural)'
                                  : category,
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: category == 'Recommended'
                                    ? const Color(0xFFD4A843)
                                    : BrandColors.brown,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: BrandColors.gold.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${grouped[category]!.length}',
                                style: GoogleFonts.lora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: BrandColors.brown,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...grouped[category]!.map((v) {
                        final name = v['name']!;
                        final locale = v['locale']!;
                        final isSelected = _selectedVoice == name;
                        final isPreviewing = _previewingVoice == name;
                        final quality = _getQuality(name);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BrandColors.gold.withValues(alpha: 0.15)
                                : quality == VoiceQuality.premium
                                    ? const Color(0xFFFFF8E1)
                                    : BrandColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: BrandColors.gold, width: 1.5)
                                : quality == VoiceQuality.premium
                                    ? Border.all(
                                        color: const Color(0xFFFFD700)
                                            .withValues(alpha: 0.3))
                                    : Border.all(
                                        color: BrandColors.brownMid
                                            .withValues(alpha: 0.15)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? BrandColors.gold
                                  : BrandColors.brownMid
                                      .withValues(alpha: 0.4),
                              size: 22,
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _friendlyName(name),
                                    style: GoogleFonts.lora(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: BrandColors.brown,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _qualityBadge(quality),
                              ],
                            ),
                            subtitle: Text(
                              locale,
                              style: GoogleFonts.lora(
                                fontSize: 11,
                                color: BrandColors.brownMid,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isPreviewing
                                      ? Icons.stop_circle
                                      : Icons.play_circle_outline,
                                  color: BrandColors.brown,
                                  size: 24,
                                ),
                                tooltip: 'Preview',
                                onPressed: isPreviewing
                                    ? () async {
                                        await _tts.stop();
                                        setState(
                                            () => _previewingVoice = null);
                                      }
                                    : () => _preview(name, locale),
                              ),
                            ),
                            onTap: () => _selectVoice(name),
                          ),
                        );
                      }),
                    ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
    );
  }

  /// Extract a human-friendly display name from the system voice name.
  String _friendlyName(String systemName) {
    // Apple voices: "com.apple.voice.premium.en-US.Ava (Premium)" → "Ava"
    // Or "com.apple.speech.synthesis.voice.Samantha" → "Samantha"
    if (systemName.contains('.')) {
      final parts = systemName.split('.');
      var last = parts.last;
      // Remove parenthetical suffixes like "(Premium)"
      last = last.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
      if (last.isNotEmpty && last != 'voice') return last;
    }
    return systemName;
  }
}
