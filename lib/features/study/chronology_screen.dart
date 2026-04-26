import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../data/bible_maps_data.dart';
import '../../theme.dart';
import '../../widgets/rhema_title.dart';
import '../share/animated_story_share.dart';

/// "Bible Timeline" — a chronological walk through biblical history.
///
/// Renders each era from `BiblicalEra` (the same enum that powers Bible Maps
/// filters) as a vertical card with a mini-map of the era's heartland, year
/// range, period of books, and a one-tap TTS narration. Tapping the
/// "Open in Maps" chip jumps to the Bible Maps screen filtered to that era.
class ChronologyScreen extends StatefulWidget {
  const ChronologyScreen({super.key});

  @override
  State<ChronologyScreen> createState() => _ChronologyScreenState();
}

class _ChronologyScreenState extends State<ChronologyScreen> {
  final FlutterTts _tts = FlutterTts();
  String? _speakingEra;

  /// Augments BiblicalEra with descriptive metadata + a representative
  /// center for the mini-map. Order is canonical biblical chronology.
  static final List<_TimelineEra> _entries = [
    _TimelineEra(
      era: BiblicalEra.patriarchs,
      title: 'Creation & Patriarchs',
      period: 'Genesis 1–50',
      years: 'Creation – ~1700 BC',
      description:
          "God creates the world. Adam and Eve, Noah's flood, Babel. "
          "Then Abraham, Isaac, Jacob, and Joseph — God's covenant people begin.",
      center: LatLng(31.5, 35.2), // Hebron / Canaan
    ),
    _TimelineEra(
      era: BiblicalEra.exodus,
      title: 'Exodus & The Law',
      period: 'Exodus – Deuteronomy',
      years: '~1446 – 1406 BC',
      description:
          "Moses leads Israel out of Egypt. The Red Sea parts. "
          "God gives the Ten Commandments at Mount Sinai.",
      center: LatLng(28.5392, 34.0126), // Sinai
    ),
    _TimelineEra(
      era: BiblicalEra.conquest,
      title: 'Conquest & Judges',
      period: 'Joshua – Ruth',
      years: '~1406 – 1050 BC',
      description:
          "Joshua leads Israel into the Promised Land. "
          "Era of judges — Deborah, Gideon, Samson, and Ruth.",
      center: LatLng(31.870, 35.444), // Jordan crossing
    ),
    _TimelineEra(
      era: BiblicalEra.kingdom,
      title: 'United Kingdom',
      period: '1 Samuel – 1 Kings 11',
      years: '~1050 – 931 BC',
      description:
          "Saul, David, and Solomon. Israel reaches its golden age. "
          "Solomon builds the first Temple in Jerusalem.",
      center: LatLng(31.7683, 35.2137), // Jerusalem
    ),
    _TimelineEra(
      era: BiblicalEra.prophets,
      title: 'Divided Kingdom & Prophets',
      period: '1 Kings 12 – 2 Chronicles',
      years: '~931 – 586 BC',
      description:
          "Israel and Judah split. Prophets confront kings: "
          "Isaiah, Jeremiah, Elijah, Hosea, Amos.",
      center: LatLng(32.0, 35.0), // Samaria/Jerusalem region
    ),
    _TimelineEra(
      era: BiblicalEra.exile,
      title: 'Exile & Return',
      period: 'Daniel, Ezra, Nehemiah',
      years: '~586 – 400 BC',
      description:
          "Babylon destroys Jerusalem. Daniel serves in Babylon. "
          "Ezra and Nehemiah return to rebuild the Temple and walls.",
      center: LatLng(32.5365, 44.4207), // Babylon
    ),
    _TimelineEra(
      era: BiblicalEra.jesus,
      title: 'Life of Jesus',
      period: 'Matthew – John',
      years: '~4 BC – 30 AD',
      description:
          "Birth in Bethlehem. Childhood in Nazareth. "
          "Ministry in Galilee. Crucifixion and resurrection in Jerusalem.",
      center: LatLng(31.7054, 35.2003), // Bethlehem
    ),
    _TimelineEra(
      era: BiblicalEra.earlyChurch,
      title: 'Early Church',
      period: 'Acts – Jude',
      years: '~30 – 100 AD',
      description:
          "The Spirit comes at Pentecost. The gospel spreads from "
          "Jerusalem to Antioch to Greece to Rome through Paul's journeys.",
      center: LatLng(41.9028, 12.4964), // Rome
    ),
    _TimelineEra(
      era: BiblicalEra.revelation,
      title: 'Revelation & Eternity',
      period: 'Revelation',
      years: 'Future fulfillment',
      description:
          "John on Patmos sees the consummation. "
          "Christ returns. New heaven, new earth, every tear wiped away.",
      center: LatLng(37.3083, 26.5479), // Patmos
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tts.awaitSpeakCompletion(true);
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.50); // 1.0× — natural narration speed
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingEra = null);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  /// Launch the 9:16 animated-story sheet for this era. The era's center
  /// LatLng becomes the Bible-Maps mini-map background; era color drives
  /// the accent rule and confetti hue.
  void _shareEraAsStory(_TimelineEra entry) {
    showAnimatedStorySheet(
      context,
      reference: entry.title,
      verseText: entry.description,
      center: entry.center,
      accentColor: Color(entry.era.color),
    );
  }

  Future<void> _toggleSpeak(_TimelineEra entry) async {
    if (_speakingEra == entry.title) {
      await _tts.stop();
      setState(() => _speakingEra = null);
      return;
    }
    setState(() => _speakingEra = entry.title);
    await _tts.stop();
    await _tts.speak(
      '${entry.title}. ${entry.years}. ${entry.description}',
    );
    if (mounted) setState(() => _speakingEra = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.parchment,
      appBar: AppBar(
        centerTitle: true,
        title: const RhemaTitle(),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _entries.length + 1, // +1 for the header card
        itemBuilder: (_, i) {
          if (i == 0) return const _IntroCard();
          final entry = _entries[i - 1];
          final isSpeaking = _speakingEra == entry.title;
          return _EraCard(
            entry: entry,
            isSpeaking: isSpeaking,
            isLast: i == _entries.length,
            onSpeakTap: () => _toggleSpeak(entry),
            onStoryTap: () => _shareEraAsStory(entry),
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bible Timeline',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: BrandColors.brownDeep,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Walk through Scripture in order — from Creation '
            'to the New Heaven and New Earth.',
            style: GoogleFonts.lora(
              fontSize: 15,
              color: BrandColors.brown.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EraCard extends StatelessWidget {
  const _EraCard({
    required this.entry,
    required this.isSpeaking,
    required this.isLast,
    required this.onSpeakTap,
    required this.onStoryTap,
  });
  final _TimelineEra entry;
  final bool isSpeaking;
  final bool isLast;
  final VoidCallback onSpeakTap;
  final VoidCallback onStoryTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(entry.era.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: BrandColors.warmWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BrandColors.brown.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mini-map header — non-interactive (gestures off) so the
                // user can tap-through to the speak/details below.
                SizedBox(
                  height: 130,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: entry.center,
                            initialZoom: 5.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.rhemabibles.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: entry.center,
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.location_on,
                                    color: color,
                                    size: 38,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Era badge top-left
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.era.emoji}  ${entry.era.label}',
                            style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.brownDeep,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            entry.period,
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.brownMid,
                            ),
                          ),
                          Text(
                            '·',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              color: BrandColors.brownMid,
                            ),
                          ),
                          Text(
                            entry.years,
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.description,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          height: 1.55,
                          color: BrandColors.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          // Speak / Stop button
                          OutlinedButton.icon(
                            onPressed: onSpeakTap,
                            icon: Icon(
                              isSpeaking
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded,
                              size: 18,
                              color: isSpeaking
                                  ? Colors.white
                                  : color,
                            ),
                            label: Text(
                              isSpeaking ? 'Stop' : 'Listen',
                              style: GoogleFonts.lora(
                                fontWeight: FontWeight.w600,
                                color: isSpeaking ? Colors.white : color,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  isSpeaking ? color : Colors.transparent,
                              side: BorderSide(color: color, width: 1.4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          // Share as 9:16 story — exports the era's
                          // mini-map + descriptive narration as an
                          // animated GIF for IG/TikTok/WhatsApp.
                          OutlinedButton.icon(
                            onPressed: onStoryTap,
                            icon: Icon(
                              Icons.movie_filter,
                              size: 18,
                              color: color,
                            ),
                            label: Text(
                              'Share story',
                              style: GoogleFonts.lora(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(color: color, width: 1.4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Connector line between cards (except after the last)
          if (!isLast)
            Container(
              width: 2,
              height: 16,
              color: color.withValues(alpha: 0.4),
            ),
        ],
      ),
    );
  }
}

/// Display data for one era card. Wraps the BiblicalEra enum (used by
/// the Maps screen) and adds dating + descriptive prose + map center.
class _TimelineEra {
  final BiblicalEra era;
  final String title;
  final String period;
  final String years;
  final String description;
  final LatLng center;

  const _TimelineEra({
    required this.era,
    required this.title,
    required this.period,
    required this.years,
    required this.description,
    required this.center,
  });
}
