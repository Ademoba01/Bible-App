import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bible_repository.dart';
import '../data/models.dart';

final bibleRepositoryProvider = Provider<BibleRepository>((ref) => BibleRepository());

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Currently-viewed book + chapter (1-based).
class ReadingLocation {
  final String book;
  final int chapter;
  const ReadingLocation(this.book, this.chapter);

  ReadingLocation copyWith({String? book, int? chapter}) =>
      ReadingLocation(book ?? this.book, chapter ?? this.chapter);
}

class ReadingLocationNotifier extends StateNotifier<ReadingLocation> {
  ReadingLocationNotifier() : super(const ReadingLocation('John', 1));

  void setBook(String book) => state = ReadingLocation(book, 1);
  void setChapter(int chapter) => state = state.copyWith(chapter: chapter);
  void next(int max) {
    if (state.chapter < max) state = state.copyWith(chapter: state.chapter + 1);
  }
  void prev() {
    if (state.chapter > 1) state = state.copyWith(chapter: state.chapter - 1);
  }
}

final readingLocationProvider =
    StateNotifierProvider<ReadingLocationNotifier, ReadingLocation>(
        (ref) => ReadingLocationNotifier());

/// Loads chapters for the current book in the current translation.
final currentBookChaptersProvider = FutureProvider<List<Chapter>>((ref) async {
  final loc = ref.watch(readingLocationProvider);
  final repo = ref.watch(bibleRepositoryProvider);
  final translationId = ref.watch(settingsProvider).translation;
  return repo.loadBook(loc.book, translationId: translationId);
});

// ---------- Bookmarks ----------

class BookmarksNotifier extends StateNotifier<List<String>> {
  BookmarksNotifier(this._prefs) : super(_prefs?.getStringList('bookmarks') ?? []);
  final SharedPreferences? _prefs;

  Future<void> toggle(String ref) async {
    final next = [...state];
    if (next.contains(ref)) {
      next.remove(ref);
    } else {
      next.add(ref);
    }
    state = next;
    await _prefs?.setStringList('bookmarks', next);
  }

  bool contains(String ref) => state.contains(ref);
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).asData?.value;
  return BookmarksNotifier(prefs);
});

// ---------- Settings ----------

class AppSettings {
  final double fontSize;
  final bool darkMode;
  final String translation;
  final bool kidsMode;
  final bool onboarded;
  const AppSettings({
    this.fontSize = 18,
    this.darkMode = false,
    this.translation = 'web',
    this.kidsMode = false,
    this.onboarded = false,
  });

  AppSettings copyWith({
    double? fontSize,
    bool? darkMode,
    String? translation,
    bool? kidsMode,
    bool? onboarded,
  }) =>
      AppSettings(
        fontSize: fontSize ?? this.fontSize,
        darkMode: darkMode ?? this.darkMode,
        translation: translation ?? this.translation,
        kidsMode: kidsMode ?? this.kidsMode,
        onboarded: onboarded ?? this.onboarded,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs)
      : super(AppSettings(
          fontSize: _prefs?.getDouble('fontSize') ?? 18,
          darkMode: _prefs?.getBool('darkMode') ?? false,
          translation: _prefs?.getString('translation') ?? 'web',
          kidsMode: _prefs?.getBool('kidsMode') ?? false,
          onboarded: _prefs?.getBool('onboarded') ?? false,
        ));
  final SharedPreferences? _prefs;

  Future<void> setFontSize(double v) async {
    state = state.copyWith(fontSize: v);
    await _prefs?.setDouble('fontSize', v);
  }

  Future<void> setDarkMode(bool v) async {
    state = state.copyWith(darkMode: v);
    await _prefs?.setBool('darkMode', v);
  }

  Future<void> setTranslation(String v) async {
    state = state.copyWith(translation: v);
    await _prefs?.setString('translation', v);
  }

  Future<void> setKidsMode(bool v) async {
    state = state.copyWith(kidsMode: v);
    await _prefs?.setBool('kidsMode', v);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboarded: true);
    await _prefs?.setBool('onboarded', true);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).asData?.value;
  return SettingsNotifier(prefs);
});

/// Bottom-nav tab index for the main shell.
final tabIndexProvider = StateProvider<int>((ref) => 0);

/// Convenience: current ThemeMode derived from settings.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).darkMode ? ThemeMode.dark : ThemeMode.light;
});
