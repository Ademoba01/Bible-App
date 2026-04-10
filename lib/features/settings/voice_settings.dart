import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Opens the voice-settings bottom sheet.
void showVoiceSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _VoiceSettingsSheet(),
  );
}

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

  // Categories: rough heuristic based on common TTS voice naming conventions.
  static const _maleHints = [
    'male', 'daniel', 'james', 'tom', 'aaron', 'albert', 'bruce', 'fred',
    'ralph', 'junior', 'oliver', 'liam', 'arthur', 'gordon', 'rishi',
    'jacques', 'jorge', 'grandpa', 'eddy', 'reed', 'rocko', 'otis',
    'sandy', 'evan',
  ];
  static const _femaleHints = [
    'female', 'samantha', 'karen', 'kate', 'moira', 'fiona', 'tessa',
    'victoria', 'allison', 'ava', 'susan', 'zoe', 'alice', 'kathy',
    'nicky', 'veena', 'joana', 'ellen', 'grandma', 'bells', 'cellos',
    'shelley', 'sandy', 'trinoids', 'superstar', 'organ',
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
    // Sort alphabetically by name
    parsed.sort((a, b) => a['name']!.compareTo(b['name']!));
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
    await _tts.speak('The Lord is my shepherd, I shall not want');
  }

  Future<void> _selectVoice(String voiceName) async {
    setState(() => _selectedVoice = voiceName);
    await ref.read(settingsProvider.notifier).setVoiceName(voiceName);
  }

  @override
  Widget build(BuildContext context) {
    // Group voices by category
    final Map<String, List<Map<String, String>>> grouped = {
      'Female': [],
      'Male': [],
      'Default': [],
    };
    for (final v in _voices) {
      final cat = _categorize(v['name']!);
      grouped[cat]!.add(v);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BrandColors.brownMid.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Voice Selection',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: BrandColors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a voice for reading',
            style: GoogleFonts.lora(
              fontSize: 13,
              color: BrandColors.brownMid,
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
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in ['Female', 'Male', 'Default'])
                    if (grouped[category]!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              category == 'Female'
                                  ? Icons.face_3
                                  : category == 'Male'
                                      ? Icons.face
                                      : Icons.record_voice_over,
                              size: 18,
                              color: BrandColors.brown,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BrandColors.brown,
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BrandColors.gold.withValues(alpha: 0.15)
                                : BrandColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: BrandColors.gold, width: 1.5)
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
                                  : BrandColors.brownMid.withValues(alpha: 0.4),
                              size: 22,
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: BrandColors.brown,
                              ),
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
      ),
    );
  }
}
