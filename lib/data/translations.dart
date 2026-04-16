/// Registry of translations the app knows about.
///
/// Translations can be loaded from:
///   - Local assets (assets/bibles/<id>/) — works offline
///   - HelloAO Bible API (https://bible.helloao.org) — requires internet
///   - API.Bible (https://rest.api.bible) — for Yoruba, Hausa, Igbo, etc.
class Translation {
  final String id;          // folder name or API translation ID
  final String name;        // short label (e.g. "WEB")
  final String description; // human description
  final bool available;     // false → shown as "coming soon"
  final bool isLocal;       // true → loaded from assets; false → from API
  final String language;    // language code for display grouping
  final String languageName; // display name for the language
  final String source;      // 'local', 'helloao', or 'apibible'

  const Translation({
    required this.id,
    required this.name,
    required this.description,
    required this.available,
    this.isLocal = false,
    this.language = 'en',
    this.languageName = 'English',
    this.source = 'helloao',
  });
}

const List<Translation> kTranslations = [
  // ─── Local (offline) translations ──────────────────────────────
  Translation(
    id: 'kjv',
    name: 'KJV',
    description: 'King James Version — classic English (1611)',
    available: true,
    isLocal: true,
    source: 'local',
  ),
  Translation(
    id: 'web',
    name: 'WEB',
    description: 'World English Bible — modern public domain',
    available: true,
    isLocal: true,
    source: 'local',
  ),

  // ─── Online English translations ───────────────────────────────
  Translation(
    id: 'BSB',
    name: 'BSB',
    description: 'Berean Standard Bible — formal equivalence (NASB-style)',
    available: true,
  ),
  Translation(
    id: 'ENGWEBP',
    name: 'WEBP',
    description: 'World English Bible (Protestant) — online edition',
    available: true,
  ),

  // ─── Hindi ────────────────────────────────────────────────────
  Translation(
    id: 'HINIRV',
    name: 'IRV',
    description: 'Hindi Indian Revised Version',
    available: true,
    language: 'hi',
    languageName: 'Hindi',
  ),

  // ─── Arabic ───────────────────────────────────────────────────
  Translation(
    id: 'ARBNAV',
    name: 'NAV',
    description: 'New Arabic Version (الكتاب المقدس)',
    available: true,
    language: 'ar',
    languageName: 'Arabic',
  ),
  Translation(
    id: 'arb_vdv',
    name: 'VDV',
    description: 'Arabic Van Dyck Bible',
    available: true,
    language: 'ar',
    languageName: 'Arabic',
  ),

  // ─── Bengali ──────────────────────────────────────────────────
  Translation(
    id: 'ben_irv',
    name: 'IRV',
    description: 'Bengali Indian Revised Version',
    available: true,
    language: 'bn',
    languageName: 'Bengali',
  ),

  // ─── Amharic ──────────────────────────────────────────────────
  Translation(
    id: 'amh_amh',
    name: 'AMH',
    description: 'Amharic New Testament',
    available: true,
    language: 'am',
    languageName: 'Amharic',
  ),

  // ─── Tibetan ──────────────────────────────────────────────────
  Translation(
    id: 'bod_ntb',
    name: 'NTB',
    description: 'New Tibetan Bible',
    available: true,
    language: 'bo',
    languageName: 'Tibetan',
  ),

  // ─── Belarusian ───────────────────────────────────────────────
  Translation(
    id: 'bel_njo',
    name: 'NJO',
    description: 'Belarusian Bible — NT and OT',
    available: true,
    language: 'be',
    languageName: 'Belarusian',
  ),

  // ─── Assamese ─────────────────────────────────────────────────
  Translation(
    id: 'asm_irv',
    name: 'IRV',
    description: 'Assamese Indian Revised Version',
    available: true,
    language: 'as',
    languageName: 'Assamese',
  ),

  // ─── Yoruba ────────────────────────────────────────────────────
  Translation(
    id: 'OYCB',
    name: 'OYCB',
    description: 'Bíbélì Mímọ́ ní Èdè Yorùbá Òde-Òní — Yoruba Contemporary Bible',
    available: true,
    language: 'yo',
    languageName: 'Yorùbá',
    source: 'apibible',
  ),

  // ─── Hausa ────────────────────────────────────────────────────
  Translation(
    id: 'OHCB',
    name: 'OHCB',
    description: 'Littafi Mai Tsarki — Hausa Contemporary Bible',
    available: true,
    language: 'ha',
    languageName: 'Hausa',
    source: 'apibible',
  ),

  // ─── Igbo ─────────────────────────────────────────────────────
  Translation(
    id: 'OICB',
    name: 'OICB',
    description: 'Baịbụl Nsọ — Igbo Contemporary Bible',
    available: true,
    language: 'ig',
    languageName: 'Igbo',
    source: 'apibible',
  ),

  // ─── Ancient languages ────────────────────────────────────────
  Translation(
    id: 'HBOMAS',
    name: 'MAS',
    description: 'Hebrew Masoretic Old Testament',
    available: true,
    language: 'he',
    languageName: 'Hebrew',
  ),
  Translation(
    id: 'GHTG',
    name: 'GHTG',
    description: 'Greek Hyper-literal Translation',
    available: true,
    language: 'grc',
    languageName: 'Greek (Ancient)',
  ),

  // ─── Azerbaijani ──────────────────────────────────────────────
  Translation(
    id: 'azb_bsa',
    name: 'BSA',
    description: 'Azerbaijani Bible',
    available: true,
    language: 'az',
    languageName: 'Azerbaijani',
  ),
];

Translation translationById(String id) =>
    kTranslations.firstWhere((t) => t.id == id, orElse: () => kTranslations.first);

/// Group translations by language for display.
Map<String, List<Translation>> translationsByLanguage() {
  final map = <String, List<Translation>>{};
  for (final t in kTranslations) {
    if (!t.available) continue;
    map.putIfAbsent(t.languageName, () => []).add(t);
  }
  return map;
}
