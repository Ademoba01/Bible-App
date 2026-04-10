import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/providers.dart';
import '../../theme.dart';
import 'study_quiz.dart';

// ---------------------------------------------------------------------------
// Quiz Screen — beautiful card-based quiz with cross-references.
// ---------------------------------------------------------------------------

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, this.book, this.chapter});

  /// Optional filters. If null, shows random questions from the full bank.
  final String? book;
  final int? chapter;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late List<StudyQuestion> _questions;
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _attempted = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    if (widget.book != null && widget.chapter != null) {
      _questions = getQuestionsForReading(widget.book!, widget.chapter!);
    } else if (widget.book != null) {
      _questions = getQuestionsForBook(widget.book!);
    } else {
      _questions = List<StudyQuestion>.from(kStudyQuestions);
    }
    _questions.shuffle(Random());
    if (_questions.isEmpty) {
      _questions = List<StudyQuestion>.from(kStudyQuestions)..shuffle(Random());
    }
  }

  StudyQuestion get _current => _questions[_currentIndex % _questions.length];

  void _revealAnswer() {
    setState(() {
      _showAnswer = true;
      _attempted++;
    });
  }

  void _markCorrect() {
    setState(() {
      _correct++;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _showAnswer = false;
    });
  }

  void _navigateToVerse(String verseRef) {
    final match = RegExp(r'^(.+?)\s+(\d+)').firstMatch(verseRef);
    if (match == null) return;
    final book = match.group(1)!;
    final chapter = int.tryParse(match.group(2)!) ?? 1;
    ref.read(readingLocationProvider.notifier).setBook(book);
    ref.read(readingLocationProvider.notifier).setChapter(chapter);
    ref.read(tabIndexProvider.notifier).state = 1;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _current;
    final questionNum = (_currentIndex % _questions.length) + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bible Quiz', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_correct / $_attempted',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: BrandColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Question $questionNum of ${_questions.length}',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.gold.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3E2723)
                        : BrandColors.cream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BrandColors.brownMid.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    q.book,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.brownMid,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3E2723), const Color(0xFF2B1E19)]
                      : [Colors.white, BrandColors.cream.withValues(alpha: 0.5)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: BrandColors.gold.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.brown.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('\u{2753}', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Question text
                  Text(
                    q.question,
                    style: GoogleFonts.lora(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Answer section (revealed)
            if (_showAnswer) ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B1E19) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Answer',
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q.answer,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        color: isDark ? BrandColors.cream : BrandColors.dark,
                        height: 1.5,
                      ),
                    ),
                    if (q.relatedVerses.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Related Verses',
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.brownMid,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: q.relatedVerses.map((v) {
                          return GestureDetector(
                            onTap: () => _navigateToVerse(v),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: BrandColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: BrandColors.gold.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book_rounded,
                                      size: 13,
                                      color: BrandColors.gold
                                          .withValues(alpha: 0.85)),
                                  const SizedBox(width: 5),
                                  Text(
                                    v,
                                    style: GoogleFonts.lora(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? BrandColors.gold
                                          : BrandColors.brown,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Self-assessment buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text('Missed It',
                          style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _markCorrect,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text('Got It!',
                          style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show Answer button
              FilledButton.icon(
                onPressed: _revealAnswer,
                icon: const Icon(Icons.visibility_rounded, size: 20),
                label: Text('Show Answer',
                    style: GoogleFonts.lora(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.brown,
                  foregroundColor: BrandColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Skip button (always visible when answer not shown)
            if (!_showAnswer)
              Center(
                child: TextButton(
                  onPressed: _nextQuestion,
                  child: Text(
                    'Skip Question',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: BrandColors.brownMid,
                      decoration: TextDecoration.underline,
                      decorationColor: BrandColors.brownMid.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
