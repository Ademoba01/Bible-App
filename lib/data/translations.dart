/// Registry of translations the app knows about.
///
/// To add a real translation:
///   1. Drop per-book JSON files into assets/bibles/<id>/
///      (filenames must match those in books.dart)
///   2. Add a Translation entry below with available = true
///   3. (No code changes needed beyond that)
class Translation {
  final String id;          // folder name under assets/bibles/
  final String name;        // short label (e.g. "WEB")
  final String description; // human description
  final bool available;     // false → shown as "coming soon" in settings
  const Translation({
    required this.id,
    required this.name,
    required this.description,
    required this.available,
  });
}

const List<Translation> kTranslations = [
  Translation(
    id: 'web',
    name: 'WEB',
    description: 'World English Bible — public domain modern English',
    available: true,
  ),
  Translation(
    id: 'bsb',
    name: 'BSB',
    description: 'Berean Standard Bible — public domain, formal-equivalence (NASB-style)',
    available: false, // flips to true once assets/bibles/bsb/ is populated
  ),
  Translation(
    id: 'pidgin',
    name: 'Pidgin',
    description: 'Nigerian Pidgin (simplest form) — coming soon',
    available: false,
  ),
  Translation(
    id: 'yoruba',
    name: 'Yoruba',
    description: 'Modern Yoruba — coming soon',
    available: false,
  ),
];

Translation translationById(String id) =>
    kTranslations.firstWhere((t) => t.id == id, orElse: () => kTranslations.first);
