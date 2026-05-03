import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One person/king/patriarch in a chronology (e.g. one row in the
/// "Kings of Judah" timeline). The optional fields cover the variation
/// across genealogies — patriarchs have ages, kings have regnal years
/// + dates, apostles have neither.
class ChronologyEntry {
  /// Display name (e.g. "Hezekiah", "Adam", "Caiaphas").
  final String name;
  /// Alternate / Hebrew / nickname (e.g. "Cephas", "Joseph").
  final String? alias;
  /// Primary verse reference linking to the canonical introduction.
  final String verseRef;
  /// Additional verse refs to surface as chips.
  final List<String> refs;
  /// Conventional dating ("c. 970–931 BC", "AD 14–37") — nullable for
  /// patriarchs etc. where we use lifespan/age instead.
  final String? dates;
  /// Years reigned (kings + judges).
  final int? regnal;
  /// Age at fathering the named son (Genesis 5/11 patriarchs only).
  final int? ageAtFathering;
  /// Total lifespan in years (patriarchs + select figures).
  final int? lifespan;
  /// Free-text notes — historical context, nicknames, fates.
  final String? notes;

  const ChronologyEntry({
    required this.name,
    this.alias,
    required this.verseRef,
    this.refs = const [],
    this.dates,
    this.regnal,
    this.ageAtFathering,
    this.lifespan,
    this.notes,
  });

  factory ChronologyEntry.fromJson(Map<String, dynamic> j) =>
      ChronologyEntry(
        name: j['name'] as String,
        alias: j['alias'] as String?,
        verseRef: j['verseRef'] as String,
        refs: (j['refs'] as List?)?.cast<String>() ?? const [],
        dates: j['dates'] as String?,
        regnal: j['regnal'] as int?,
        ageAtFathering: j['ageAtFathering'] as int?,
        lifespan: j['lifespan'] as int?,
        notes: j['notes'] as String?,
      );
}

/// One named chronology — e.g. "Patriarchs Before the Flood" or "Kings
/// of Judah". Holds the full ordered list of [ChronologyEntry]s plus
/// presentation metadata (icon, color, era).
class Chronology {
  /// Stable id used as JSON key (e.g. "patriarchs_pre_flood").
  final String id;
  /// Headline (e.g. "Patriarchs Before the Flood").
  final String title;
  /// Subtitle / range (e.g. "Adam → Noah · 10 generations").
  final String subtitle;
  /// Where this data is sourced in Scripture (e.g. "Genesis 5").
  final String source;
  /// Lottie / Material icon name suggestion ("scroll", "crown", "shield").
  final String icon;
  /// Hex accent color used for the chronology card + timeline lines.
  final int color;
  /// Era key tying the chronology to the existing era timeline ("kingdom",
  /// "exile", "newtestament", "patriarchs", "judges", "various").
  final String era;
  final List<ChronologyEntry> entries;

  const Chronology({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.icon,
    required this.color,
    required this.era,
    required this.entries,
  });

  factory Chronology.fromJson(String id, Map<String, dynamic> j) =>
      Chronology(
        id: id,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        source: j['source'] as String,
        icon: j['icon'] as String? ?? 'scroll',
        color: int.tryParse(
                ((j['color'] as String?) ?? '#8B4513').replaceFirst('#', '0xFF')) ??
            0xFF8B4513,
        era: j['era'] as String? ?? 'various',
        entries: (j['entries'] as List)
            .map((e) => ChronologyEntry.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Lazy-loaded singleton serving every chronology baked into
/// `assets/data/chronologies.json`. Asset is small (~30 KB) so we hold
/// the parsed list in memory.
class ChronologiesService {
  ChronologiesService._();
  static final ChronologiesService instance = ChronologiesService._();

  List<Chronology>? _list;
  Future<void>? _loading;

  bool get isReady => _list != null;
  List<Chronology> get all => _list ?? const [];

  Future<void> init() {
    if (isReady) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/chronologies.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final out = <Chronology>[];
      decoded.forEach((id, value) {
        if (id.startsWith('_')) return; // skip _meta etc.
        out.add(Chronology.fromJson(id, Map<String, dynamic>.from(value)));
      });
      _list = out;
    } catch (e, st) {
      debugPrint('ChronologiesService load failed: $e\n$st');
      _list = const [];
    } finally {
      _loading = null;
    }
  }

  Chronology? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Riverpod provider for the singleton. Triggers async load on first read.
final chronologiesServiceProvider = Provider<ChronologiesService>((ref) {
  final svc = ChronologiesService.instance;
  svc.init();
  return svc;
});
