import 'dart:convert';

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
  ReadingLocationNotifier(this._prefs)
      : super(ReadingLocation(
          _prefs?.getString('reading_book') ?? 'John',
          _prefs?.getInt('reading_chapter') ?? 1,
        ));

  final SharedPreferences? _prefs;

  void setBook(String book) {
    state = ReadingLocation(book, 1);
    _persist();
  }

  void setChapter(int chapter) {
    state = state.copyWith(chapter: chapter);
    _persist();
  }

  void next(int max) {
    if (state.chapter < max) {
      state = state.copyWith(chapter: state.chapter + 1);
      _persist();
    }
  }

  void prev() {
    if (state.chapter > 1) {
      state = state.copyWith(chapter: state.chapter - 1);
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs?.setString('reading_book', state.book);
    await _prefs?.setInt('reading_chapter', state.chapter);
  }
}

final readingLocationProvider =
    StateNotifierProvider<ReadingLocationNotifier, ReadingLocation>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).asData?.value;
  return ReadingLocationNotifier(prefs);
});

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

// ---------- Highlights ----------

/// Maps verse ID (e.g., "John 3:16") to a highlight color index.
/// Colors: 0=yellow, 1=green, 2=blue, 3=pink, 4=orange
class HighlightsNotifier extends StateNotifier<Map<String, int>> {
  HighlightsNotifier() : super({}) {
    _load();
  }

  static const _key = 'verse_highlights';
  static const colors = [
    Color(0xFFFFF176), // yellow
    Color(0xFFA5D6A7), // green
    Color(0xFF90CAF9), // blue
    Color(0xFFF48FB1), // pink
    Color(0xFFFFCC80), // orange
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final map = Map<String, dynamic>.from(json.decode(raw));
      state = map.map((k, v) => MapEntry(k, v as int));
    }
  }

  Future<void> highlight(String verseId, int colorIndex) async {
    state = {...state, verseId: colorIndex};
    await _persist();
  }

  Future<void> removeHighlight(String verseId) async {
    state = Map.from(state)..remove(verseId);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state));
  }
}

final highlightsProvider =
    StateNotifierProvider<HighlightsNotifier, Map<String, int>>((ref) {
  return HighlightsNotifier();
});

// ---------- Settings ----------

class AppSettings {
  final double fontSize;
  final bool darkMode;
  final String translation;
  final bool kidsMode;
  final bool onboarded;
  final String voiceName;
  const AppSettings({
    this.fontSize = 18,
    this.darkMode = false,
    this.translation = 'web',
    this.kidsMode = false,
    this.onboarded = false,
    this.voiceName = '',
  });

  AppSettings copyWith({
    double? fontSize,
    bool? darkMode,
    String? translation,
    bool? kidsMode,
    bool? onboarded,
    String? voiceName,
  }) =>
      AppSettings(
        fontSize: fontSize ?? this.fontSize,
        darkMode: darkMode ?? this.darkMode,
        translation: translation ?? this.translation,
        kidsMode: kidsMode ?? this.kidsMode,
        onboarded: onboarded ?? this.onboarded,
        voiceName: voiceName ?? this.voiceName,
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
          voiceName: _prefs?.getString('voiceName') ?? '',
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

  Future<void> setVoiceName(String v) async {
    state = state.copyWith(voiceName: v);
    await _prefs?.setString('voiceName', v);
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

// ---------- Study / Reading Plans ----------

/// Tracks which plan is active and which days are completed.
class StudyProgress {
  final String? activePlanId;
  final Set<int> completedDays; // 1-based day numbers
  final DateTime? startDate;

  const StudyProgress({
    this.activePlanId,
    this.completedDays = const {},
    this.startDate,
  });

  StudyProgress copyWith({
    String? activePlanId,
    Set<int>? completedDays,
    DateTime? startDate,
  }) =>
      StudyProgress(
        activePlanId: activePlanId ?? this.activePlanId,
        completedDays: completedDays ?? this.completedDays,
        startDate: startDate ?? this.startDate,
      );

  double get progressPercent {
    if (completedDays.isEmpty) return 0;
    // We don't know total here — the UI calculates it
    return 0;
  }
}

class StudyProgressNotifier extends StateNotifier<StudyProgress> {
  StudyProgressNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static StudyProgress _load(SharedPreferences? prefs) {
    if (prefs == null) return const StudyProgress();
    final planId = prefs.getString('study_planId');
    final days = prefs.getStringList('study_completedDays') ?? [];
    final startMs = prefs.getInt('study_startDate');
    return StudyProgress(
      activePlanId: planId,
      completedDays: days.map(int.parse).toSet(),
      startDate: startMs != null ? DateTime.fromMillisecondsSinceEpoch(startMs) : null,
    );
  }

  Future<void> startPlan(String planId) async {
    state = StudyProgress(
      activePlanId: planId,
      completedDays: {},
      startDate: DateTime.now(),
    );
    await _persist();
  }

  Future<void> toggleDay(int day) async {
    final days = Set<int>.from(state.completedDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(completedDays: days);
    await _persist();
  }

  Future<void> clearPlan() async {
    state = const StudyProgress();
    await _prefs?.remove('study_planId');
    await _prefs?.remove('study_completedDays');
    await _prefs?.remove('study_startDate');
  }

  Future<void> _persist() async {
    await _prefs?.setString('study_planId', state.activePlanId ?? '');
    await _prefs?.setStringList(
      'study_completedDays',
      state.completedDays.map((d) => d.toString()).toList(),
    );
    if (state.startDate != null) {
      await _prefs?.setInt('study_startDate', state.startDate!.millisecondsSinceEpoch);
    }
  }
}

final studyProgressProvider =
    StateNotifierProvider<StudyProgressNotifier, StudyProgress>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).asData?.value;
  return StudyProgressNotifier(prefs);
});
