import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/reading_plans.dart' show kChapterCounts;
import 'providers.dart' show sharedPrefsProvider;

/// Qualifying actions that count toward a daily streak. The first such action
/// each calendar day (UTC) triggers the streak update; subsequent actions on
/// the same day are still recorded but do not advance the streak counter.
enum CodexAction {
  chapterRead,
  listened3Min,
  quizCompleted,
  aiStudyAsked,
}

/// Immutable snapshot of the user's streak / codex progress.
class CodexState {
  final int current;
  final int longest;
  final DateTime? lastQualifiedUtc;
  final int freezesAvailable;
  final Set<String> chaptersRead; // "Book C" format, e.g. "Romans 8"
  final Set<String> booksCompleted;

  const CodexState({
    this.current = 0,
    this.longest = 0,
    this.lastQualifiedUtc,
    this.freezesAvailable = 0,
    this.chaptersRead = const {},
    this.booksCompleted = const {},
  });

  CodexState copyWith({
    int? current,
    int? longest,
    DateTime? lastQualifiedUtc,
    bool clearLastQualified = false,
    int? freezesAvailable,
    Set<String>? chaptersRead,
    Set<String>? booksCompleted,
  }) =>
      CodexState(
        current: current ?? this.current,
        longest: longest ?? this.longest,
        lastQualifiedUtc: clearLastQualified
            ? null
            : (lastQualifiedUtc ?? this.lastQualifiedUtc),
        freezesAvailable: freezesAvailable ?? this.freezesAvailable,
        chaptersRead: chaptersRead ?? this.chaptersRead,
        booksCompleted: booksCompleted ?? this.booksCompleted,
      );
}

class CodexNotifier extends StateNotifier<CodexState> {
  CodexNotifier(Ref ref)
      : _ref = ref,
        super(_loadFromPrefs(_readPrefs(ref)));

  final Ref _ref;

  // ─── SharedPreferences keys ──────────────────────────────────
  static const _kCurrent = 'streak_current';
  static const _kLongest = 'streak_longest';
  static const _kLastDay = 'streak_last_day'; // YYYY-MM-DD UTC
  static const _kFreezes = 'streak_freezes';
  static const _kChapters = 'streak_chapters';
  static const _kBooks = 'streak_books';

  static SharedPreferences? _readPrefs(Ref ref) =>
      ref.read(sharedPrefsProvider).asData?.value;

  SharedPreferences? get _prefs => _readPrefs(_ref);

  static CodexState _loadFromPrefs(SharedPreferences? prefs) {
    if (prefs == null) return const CodexState();
    final lastDayStr = prefs.getString(_kLastDay);
    DateTime? lastDay;
    if (lastDayStr != null && lastDayStr.isNotEmpty) {
      lastDay = DateTime.tryParse(lastDayStr);
    }
    return CodexState(
      current: prefs.getInt(_kCurrent) ?? 0,
      longest: prefs.getInt(_kLongest) ?? 0,
      lastQualifiedUtc: lastDay,
      freezesAvailable: prefs.getInt(_kFreezes) ?? 0,
      chaptersRead: (prefs.getStringList(_kChapters) ?? const []).toSet(),
      booksCompleted: (prefs.getStringList(_kBooks) ?? const []).toSet(),
    );
  }

  // ─── Public API ───────────────────────────────────────────────

  /// Records a streak-qualifying action. If the user has already qualified
  /// today, the streak counter is unchanged. Subsequent calls on the same
  /// day are no-ops for the counter. The [action] is included in the API
  /// for future per-action analytics; today it only gates streak progression.
  void markQualified(CodexAction action) {
    final today = _utcDay(DateTime.now().toUtc());
    final last = state.lastQualifiedUtc == null
        ? null
        : _utcDay(state.lastQualifiedUtc!.toUtc());

    if (last != null && _sameDay(last, today)) {
      // Already qualified today — no-op for streak.
      return;
    }

    int next;
    if (last != null && _sameDay(today, last.add(const Duration(days: 1)))) {
      // Consecutive day.
      next = state.current + 1;
    } else {
      // Either first time, or a gap. Fresh streak of 1.
      next = 1;
    }

    final longest = next > state.longest ? next : state.longest;
    state = state.copyWith(
      current: next,
      longest: longest,
      lastQualifiedUtc: today,
    );
    _persist();
  }

  /// Mark a chapter as read. Adds the "Book C" id to [CodexState.chaptersRead];
  /// if every chapter of [book] has now been read, [book] is added to
  /// [CodexState.booksCompleted]. Always also calls [markQualified] with
  /// [CodexAction.chapterRead].
  void markChapterRead(String book, int chapter) {
    final id = '$book $chapter';
    final newChapters = {...state.chaptersRead, id};

    final newBooks = {...state.booksCompleted};
    final total = kChapterCounts[book];
    if (total != null) {
      var allRead = true;
      for (var c = 1; c <= total; c++) {
        if (!newChapters.contains('$book $c')) {
          allRead = false;
          break;
        }
      }
      if (allRead) newBooks.add(book);
    }

    state = state.copyWith(
      chaptersRead: newChapters,
      booksCompleted: newBooks,
    );
    _persist();

    markQualified(CodexAction.chapterRead);
  }

  /// Consumes a freeze to bridge a single missed day, advancing
  /// [CodexState.lastQualifiedUtc] to yesterday so today's qualifying
  /// action will continue rather than reset the streak.
  void useFreeze() {
    if (state.freezesAvailable <= 0) return;
    final yesterday = _utcDay(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    state = state.copyWith(
      freezesAvailable: state.freezesAvailable - 1,
      lastQualifiedUtc: yesterday,
    );
    _persist();
  }

  /// Reset all streak data — primarily for testing.
  void reset() {
    state = const CodexState();
    final p = _prefs;
    if (p != null) {
      p.remove(_kCurrent);
      p.remove(_kLongest);
      p.remove(_kLastDay);
      p.remove(_kFreezes);
      p.remove(_kChapters);
      p.remove(_kBooks);
    }
  }

  // ─── Internals ────────────────────────────────────────────────

  static DateTime _utcDay(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _persist() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt(_kCurrent, state.current);
    await p.setInt(_kLongest, state.longest);
    if (state.lastQualifiedUtc != null) {
      final iso =
          state.lastQualifiedUtc!.toUtc().toIso8601String().substring(0, 10);
      await p.setString(_kLastDay, iso);
    } else {
      await p.remove(_kLastDay);
    }
    await p.setInt(_kFreezes, state.freezesAvailable);
    await p.setStringList(_kChapters, state.chaptersRead.toList());
    await p.setStringList(_kBooks, state.booksCompleted.toList());
  }
}

final codexProvider = StateNotifierProvider<CodexNotifier, CodexState>(
  (ref) {
    // Re-create the notifier whenever SharedPreferences becomes available so
    // we always hydrate from disk once prefs are ready.
    ref.watch(sharedPrefsProvider);
    return CodexNotifier(ref);
  },
);
