import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kids_story_data.dart';

/// Loaders for the hand-authored kids content that was previously
/// shipping as dead weight — [assets/kids/stories.json] (5 kid-grade
/// retellings with picture cues, music direction, voice direction,
/// discussion prompts) and [assets/kids/quiz_bank.json] (hand-authored
/// kids questions with explanations).
///
/// Both files were registered in pubspec.yaml and read by zero Dart
/// code. Users were seeing auto-generated fill-blank KJV questions
/// instead of the kid-friendly content sitting on disk — review
/// agent 5 flagged this as the single biggest kids-mode fix available.

/// A single question from quiz_bank.json. Light shape — only the
/// fields the kids quiz screen needs to replace an auto-generated
/// question. Field names match the JSON exactly for cheap decode.
class AuthoredKidsQuestion {
  final String id;
  final String type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String verseRef;
  final String? explanation;

  const AuthoredKidsQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.verseRef,
    this.explanation,
  });

  factory AuthoredKidsQuestion.fromJson(Map<String, dynamic> j) =>
      AuthoredKidsQuestion(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'multipleChoice',
        question: j['question'] as String,
        options: (j['options'] as List).cast<String>(),
        correctAnswer: j['correctAnswer'] as String,
        verseRef: j['verseRef'] as String? ?? '',
        explanation: j['explanation'] as String?,
      );
}

/// Load the authored kids story bank and return as IllustratedStory
/// objects so the existing list/card UI can render them without
/// changes. Each authored story collapses its single-paragraph
/// retelling into one StoryPage — the format pre-dates the paginated
/// IllustratedStory schema. Picture cue becomes an emoji fallback
/// (no illustrations yet; Priority 1 of the Illuminations brief).
Future<List<IllustratedStory>> loadAuthoredStories() async {
  final raw = await rootBundle.loadString('assets/kids/stories.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final rawStories = (data['stories'] as List).cast<Map<String, dynamic>>();
  return rawStories.map((j) {
    // Pick an emoji that at least loosely matches the story. Falls
    // back to a scroll glyph. These are placeholder until the
    // illustrator deliverable lands.
    final emojiByTitle = <String, String>{
      'ruth picks naomi': '👭',
      'the roof came off': '🏠',
      'the axe that floated': '🪓',
      'the small coins': '🪙',
      'the sheep that wandered': '🐑',
    };
    final titleKey = (j['title'] as String).toLowerCase();
    final emoji = emojiByTitle[titleKey] ?? '📖';
    final paragraph = j['story'] as String;
    return IllustratedStory(
      title: j['title'] as String,
      emoji: emoji,
      bibleReference: j['verseRef'] as String? ?? '',
      // Soft parchment amber for every authored story so they visually
      // group together on the list — tells the user "these are the new
      // hand-crafted ones".
      color: 0xFFD4A843,
      moralLesson: j['oneQuestion'] as String? ?? '',
      pages: [
        StoryPage(
          text: paragraph,
          emoji: emoji,
          backgroundColor: 0xFFFFF8E1,
        ),
      ],
    );
  }).toList();
}

/// Load the authored kids question bank.
Future<List<AuthoredKidsQuestion>> loadAuthoredKidsQuestions() async {
  final raw = await rootBundle.loadString('assets/kids/quiz_bank.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final list = (data['questions'] as List).cast<Map<String, dynamic>>();
  return list.map(AuthoredKidsQuestion.fromJson).toList();
}

/// FutureProvider wrapping the authored story loader. Null-safe — if
/// the asset fails to parse we just return an empty list so the UI
/// falls back to the existing kIllustratedStories only.
final authoredKidsStoriesProvider =
    FutureProvider<List<IllustratedStory>>((ref) async {
  try {
    return await loadAuthoredStories();
  } catch (_) {
    return const [];
  }
});

/// FutureProvider wrapping the authored kids questions.
final authoredKidsQuestionsProvider =
    FutureProvider<List<AuthoredKidsQuestion>>((ref) async {
  try {
    return await loadAuthoredKidsQuestions();
  } catch (_) {
    return const [];
  }
});
