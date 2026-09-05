import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../services/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// A quiz question with its answer options.
class _QuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String verseRef;
  final String? explanation; // AI-generated explanation (null for offline)

  const _QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.verseRef,
    this.explanation,
  });
}

class ChapterQuizScreen extends ConsumerStatefulWidget {
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  const ChapterQuizScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });

  @override
  ConsumerState<ChapterQuizScreen> createState() => _ChapterQuizScreenState();
}

class _ChapterQuizScreenState extends ConsumerState<ChapterQuizScreen>
    with TickerProviderStateMixin {
  List<_QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _loading = true;
  String? _error;
  bool _isAiQuiz = false;
  /// Per-question answers preserved through to the score screen so the
  /// "View corrections" review can show what the user picked vs what
  /// the correct answer was — the loop that makes quizzes actually
  /// teach ("This is how people learn" — user feedback).
  final List<String?> _userAnswers = [];
  /// The chapter's verses, kept around after _loadQuestions so the
  /// corrections chip can pop up the referenced verse text in place
  /// instead of tearing the user out of the quiz to the Read tab.
  List<Verse> _verses = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _loadQuestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final repo = ref.read(bibleRepositoryProvider);
      final settings = ref.read(settingsProvider);
      final translationId = settings.translation;
      final chapters =
          await repo.loadBook(widget.book, translationId: translationId);
      final chapterIndex =
          (widget.chapter - 1).clamp(0, chapters.length - 1);
      final chapter = chapters[chapterIndex];

      List<Verse> verses = chapter.verses;
      if (widget.startVerse != null && widget.endVerse != null) {
        verses = verses
            .where((v) =>
                v.number >= widget.startVerse! &&
                v.number <= widget.endVerse!)
            .toList();
      }

      if (verses.isEmpty) {
        setState(() {
          _error = 'No verses found for this chapter.';
          _loading = false;
        });
        return;
      }

      // Held for the corrections chip popup — see _openReference.
      _verses = verses;

      // Try AI quiz if online mode is active
      if (settings.useOnlineAi) {
        try {
          final verseTexts = verses.map((v) => v.text).toList();
          final aiQuestions = await AiService.generateQuiz(
            widget.book,
            widget.chapter,
            verseTexts,
          );
          if (aiQuestions.isNotEmpty && mounted) {
            setState(() {
              _isAiQuiz = true;
              _questions = aiQuestions
                  .map((q) => _QuizQuestion(
                        question: q.question,
                        correctAnswer: q.correctAnswer,
                        options: q.options,
                        verseRef: q.verseRef,
                        explanation: q.explanation,
                      ))
                  .toList();
              _loading = false;
            });
            _fadeController.forward();
            return;
          }
        } catch (e) {
          debugPrint('AI quiz generation failed, falling back to offline: $e');
        }
      }

      // Offline fallback
      final questions = _generateQuestions(verses);
      setState(() {
        _isAiQuiz = false;
        _questions = questions;
        _loading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  List<_QuizQuestion> _generateQuestions(List<Verse> verses) {
    final random = Random();
    final questions = <_QuizQuestion>[];

    final shuffled = List<Verse>.from(verses)..shuffle(random);
    final selected = shuffled.take(min(4, verses.length)).toList();

    for (final verse in selected) {
      final text = verse.text;
      final strategy = random.nextInt(4);

      switch (strategy) {
        case 0: // Complete the verse
          final words = text.split(' ');
          if (words.length >= 6) {
            final cutPoint = words.length ~/ 2;
            final firstHalf = words.sublist(0, cutPoint).join(' ');
            final secondHalf = words.sublist(cutPoint).join(' ');
            final wrongAnswers = verses
                .where((v) => v != verse)
                .take(3)
                .map((v) {
              final w = v.text.split(' ');
              return w.length > cutPoint
                  ? w.sublist(cutPoint).join(' ')
                  : v.text;
            }).toList();
            while (wrongAnswers.length < 3) {
              wrongAnswers.add('None of the above');
            }
            questions.add(_QuizQuestion(
              question: 'Complete this verse:\n"$firstHalf..."',
              correctAnswer: secondHalf,
              options: [secondHalf, ...wrongAnswers]..shuffle(random),
              verseRef: '${verse.number}',
            ));
          }
          break;

        case 1: // Which verse says this
          final correctNum = verse.number.toString();
          final wrongNums = verses
              .where((v) => v != verse)
              .take(3)
              .map((v) => v.number.toString())
              .toList();
          while (wrongNums.length < 3) {
            wrongNums.add('${random.nextInt(verses.length) + 1}');
          }
          questions.add(_QuizQuestion(
            question:
                'Which verse number says:\n"${text.length > 80 ? '${text.substring(0, 80)}...' : text}"',
            correctAnswer: 'Verse $correctNum',
            options: [
              'Verse $correctNum',
              ...wrongNums.map((n) => 'Verse $n'),
            ]..shuffle(random),
            verseRef: correctNum,
          ));
          break;

        case 2: // True or False
          final isTrue = random.nextBool();
          String displayText = text;
          if (!isTrue) {
            final words = text.split(' ');
            if (words.length > 3) {
              final swapIndex = random.nextInt(words.length - 2) + 1;
              final otherVerse = verses[random.nextInt(verses.length)];
              final otherWords = otherVerse.text.split(' ');
              if (otherWords.length > swapIndex) {
                words[swapIndex] = otherWords[swapIndex];
              }
              displayText = words.join(' ');
            }
          }
          questions.add(_QuizQuestion(
            question:
                'True or False:\nVerse ${verse.number} says:\n"${displayText.length > 100 ? '${displayText.substring(0, 100)}...' : displayText}"',
            correctAnswer: isTrue ? 'True' : 'False',
            options: ['True', 'False'],
            verseRef: '${verse.number}',
          ));
          break;

        case 3: // Fill in the blank
          final words = text.split(' ');
          if (words.length >= 4) {
            final significantWords =
                words.where((w) => w.length > 3).toList();
            if (significantWords.isNotEmpty) {
              final blankWord =
                  significantWords[random.nextInt(significantWords.length)];
              final blanked = text.replaceFirst(blankWord, '________');
              final wrongWords = verses
                  .expand((v) => v.text.split(' '))
                  .where((w) => w.length > 3 && w != blankWord)
                  .toSet()
                  .take(3)
                  .toList();
              while (wrongWords.length < 3) {
                wrongWords.add('something');
              }
              questions.add(_QuizQuestion(
                question: 'Fill in the blank:\n"$blanked"',
                correctAnswer: blankWord,
                options: [blankWord, ...wrongWords]..shuffle(random),
                verseRef: '${verse.number}',
              ));
            }
          }
          break;
      }
    }

    return questions;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      // Preserve this answer for the corrections review page.
      while (_userAnswers.length <= _currentIndex) {
        _userAnswers.add(null);
      }
      _userAnswers[_currentIndex] = answer;
      if (answer == _questions[_currentIndex].correctAnswer) {
        _score++;
        _scaleController.forward().then((_) => _scaleController.reverse());
      } else {
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    });

    // Auto-advance after a delay (longer for AI quizzes with explanations)
    final delay = _isAiQuiz
        ? const Duration(milliseconds: 3500)
        : const Duration(milliseconds: 1500);
    Future.delayed(delay, () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
        _fadeController.forward(from: 0);
      } else {
        setState(() {
          _currentIndex = _questions.length; // triggers score screen
        });
      }
    });
  }

  void _retry() {
    setState(() {
      _loading = true;
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _questions = [];
      _isAiQuiz = false;
      _userAnswers.clear();
    });
    _loadQuestions();
  }

  /// Jump to the next chapter of the same book on the Read tab so users
  /// can keep progressing after a quiz. Uses the existing deep-link
  /// pattern (setBook + setChapter + tabIndex + popUntil root).
  void _goToNextChapter() {
    ref.read(readingLocationProvider.notifier).setBook(widget.book);
    ref.read(readingLocationProvider.notifier).setChapter(widget.chapter + 1);
    ref.read(highlightVerseProvider.notifier).state = 1;
    ref.read(tabIndexProvider.notifier).set(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Open the corrections review sheet — shows every question with the
  /// user's answer (green/red), the correct answer, and a tappable
  /// verse-reference chip that opens the reference chapter with the
  /// verse highlighted. The learning loop the user asked for.
  void _showCorrections() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctrl) => _CorrectionsSheet(
          questions: _questions,
          userAnswers: _userAnswers,
          scrollController: ctrl,
          book: widget.book,
          chapter: widget.chapter,
          onOpenRef: (ref0) => _openReference(sheetCtx, ref0),
        ),
      ),
    );
  }

  /// Pop up the referenced verse's text right on top of the
  /// corrections sheet. User feedback: navigating to the Read tab tore
  /// them out of their study loop; they want the verse RIGHT THERE
  /// while they're reviewing what they missed, then to keep scrolling
  /// through the other corrections.
  ///
  /// The chip's `verseRef` is stored as a bare verse number ("17") in
  /// the standard offline quiz (see the QuizQuestion constructors) —
  /// the AI quiz may emit a full "Book Ch:V" reference. Handle both.
  /// If the referenced verse isn't in the currently-loaded chapter
  /// (e.g. an AI quiz that cites a cross-book reference), fall back
  /// to the old deep-link behavior — the popup can't help without
  /// the verse text.
  void _openReference(BuildContext sheetCtx, String verseRef) {
    String targetBook = widget.book;
    int targetChapter = widget.chapter;
    int? targetVerse;

    final full = VerseRef.tryParse(verseRef);
    if (full != null) {
      targetBook = full.book;
      targetChapter = full.chapter;
      targetVerse = full.verse;
    } else {
      final digits = RegExp(r'\d+').firstMatch(verseRef)?.group(0);
      if (digits == null) return;
      targetVerse = int.tryParse(digits);
      if (targetVerse == null) return;
    }

    // In-chapter case: look up the verse text and pop up. Cross-book
    // or cross-chapter case: no local text available, deep-link like
    // before so the user still gets somewhere useful.
    final inThisChapter = targetBook == widget.book &&
        targetChapter == widget.chapter;
    if (inThisChapter) {
      Verse? verse;
      for (final v in _verses) {
        if (v.number == targetVerse) {
          verse = v;
          break;
        }
      }
      if (verse != null) {
        _showVersePopup(
          '${widget.book} ${widget.chapter}:${verse.number}',
          verse.text,
        );
        return;
      }
    }

    // Fallback deep-link (AI-generated cross-refs, or a verse number
    // that isn't in the loaded list).
    ref.read(readingLocationProvider.notifier).setBook(targetBook);
    ref.read(readingLocationProvider.notifier).setChapter(targetChapter);
    ref.read(highlightVerseProvider.notifier).state = targetVerse;
    ref.read(tabIndexProvider.notifier).set(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Small verse popup shown on top of the corrections sheet. Matches
  /// the visual language of the reading-screen verse dialog (parchment
  /// card, gold hairline) but stripped down: reference header, verse
  /// text, one close button. Deliberately no Copy/Share/Highlight
  /// actions — this is a study peek, not a full verse-action menu; if
  /// the user wants those, they can hit "Back to reading" and tap the
  /// verse in the Read tab.
  void _showVersePopup(String reference, String verseText) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Center(
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BrandColors.gold.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book,
                          size: 18, color: BrandColors.brownDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reference,
                          style: GoogleFonts.lora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.brownDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verseText,
                    style: BrandColors.verseStyle(size: 16),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: BrandColors.brownDeep),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBrown = const Color(0xFF5D4037);
    final gold = const Color(0xFFFFC107);
    final cream = isDark ? const Color(0xFF2B1E19) : const Color(0xFFFFF8E1);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.book} ${widget.chapter} Quiz',
          style: GoogleFonts.lora(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_loading && _questions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isAiQuiz
                    ? BrandColors.gold.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAiQuiz ? Icons.auto_awesome : Icons.edit_note,
                    size: 14,
                    color: _isAiQuiz ? BrandColors.goldLight : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAiQuiz ? 'AI Quiz' : 'Standard',
                    style: GoogleFonts.lora(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isAiQuiz ? BrandColors.goldLight : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBrown),
                  const SizedBox(height: 16),
                  Text('Generating questions...',
                      style: GoogleFonts.lora(
                          fontSize: 16, color: primaryBrown)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!,
                        style: GoogleFonts.lora(fontSize: 16),
                        textAlign: TextAlign.center),
                  ),
                )
              : _questions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline,
                                size: 48, color: primaryBrown),
                            const SizedBox(height: 16),
                            Text(
                              'Not enough verse content to generate questions for this chapter.',
                              style: GoogleFonts.lora(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: primaryBrown),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Go back'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _currentIndex >= _questions.length
                      ? _buildScoreScreen(
                          primaryBrown, gold, cream, isDark)
                      : _buildQuestionScreen(
                          primaryBrown, gold, cream, isDark),
    );
  }

  Widget _buildQuestionScreen(
      Color primaryBrown, Color gold, Color cream, bool isDark) {
    final q = _questions[_currentIndex];
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            Row(
              children: [
                Text(
                  'Question ${_currentIndex + 1} of $total',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryBrown,
                  ),
                ),
                const Spacer(),
                Text(
                  'Score: $_score',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: gold.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: primaryBrown.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(gold),
              ),
            ),
            const SizedBox(height: 28),

            // Question card
            SlideTransition(
              position: _shakeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Card(
                  elevation: 3,
                  color: isDark ? const Color(0xFF3E2723) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      q.question,
                      style: GoogleFonts.lora(
                        fontSize: 17,
                        height: 1.5,
                        color: isDark ? Colors.white : primaryBrown,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer options
            ...q.options.map((option) {
              final isCorrect = option == q.correctAnswer;
              final isSelected = option == _selectedAnswer;
              Color cardColor;
              Color textColor;
              if (_answered) {
                if (isCorrect) {
                  cardColor = Colors.green.shade100;
                  textColor = Colors.green.shade900;
                } else if (isSelected) {
                  cardColor = Colors.red.shade100;
                  textColor = Colors.red.shade900;
                } else {
                  cardColor =
                      isDark ? const Color(0xFF3E2723) : Colors.white;
                  textColor = isDark
                      ? Colors.white70
                      : primaryBrown.withValues(alpha: 0.5);
                }
              } else {
                cardColor =
                    isDark ? const Color(0xFF3E2723) : Colors.white;
                textColor = isDark ? Colors.white : primaryBrown;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: _answered ? null : () => _selectAnswer(option),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _answered && isCorrect
                            ? Colors.green
                            : _answered && isSelected
                                ? Colors.red
                                : primaryBrown.withValues(alpha: 0.2),
                        width: _answered && (isCorrect || isSelected)
                            ? 2
                            : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: isSelected || (_answered && isCorrect)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_answered && isCorrect)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 24),
                        if (_answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (_answered) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _selectedAnswer == q.correctAnswer
                      ? 'Correct! (Verse ${q.verseRef})'
                      : 'The answer was from Verse ${q.verseRef}',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _selectedAnswer == q.correctAnswer
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (q.explanation != null && q.explanation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: BrandColors.gold.withValues(alpha: 0.1),
                      border: Border.all(
                        color: BrandColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16, color: BrandColors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.explanation!,
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white70 : primaryBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreScreen(
      Color primaryBrown, Color gold, Color cream, bool isDark) {
    final total = _questions.length;
    final percent = total > 0 ? (_score / total * 100).round() : 0;
    String message;
    if (_score == total) {
      message = 'Perfect score! You really know this chapter!';
    } else if (_score >= total * 0.75) {
      message = 'Great job! You know this chapter well!';
    } else if (_score >= total * 0.5) {
      message = 'Good effort! Keep studying!';
    } else {
      message = 'Keep reading and try again!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _score == total
                  ? Icons.emoji_events
                  : _score >= total * 0.5
                      ? Icons.thumb_up
                      : Icons.menu_book,
              size: 72,
              color: gold,
            ),
            const SizedBox(height: 24),
            Text(
              '$_score / $total',
              style: GoogleFonts.lora(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            Text(
              '$percent% correct',
              style: GoogleFonts.lora(
                fontSize: 18,
                color: primaryBrown.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : primaryBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // ── View corrections (primary study action) ──
            // Sits ABOVE "Try again" per user feedback: "This is how
            // people learn" — see which questions you missed, what
            // the correct answer was, and tap the verse chip to open
            // the reference chapter with the verse highlighted.
            SizedBox(
              width: 260,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: primaryBrown),
                icon: const Icon(Icons.fact_check),
                label: const Text('View corrections'),
                onPressed: _questions.isEmpty ? null : _showCorrections,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 260,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: primaryBrown),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                onPressed: _retry,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 260,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: primaryBrown),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to reading'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 8),
            // ── Next chapter (progression button, per user request) ──
            SizedBox(
              width: 260,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: primaryBrown),
                icon: const Icon(Icons.chevron_right),
                label: Text('Next chapter (${widget.book} ${widget.chapter + 1})'),
                onPressed: _goToNextChapter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet review of every quiz question with green/red feedback
/// on the user's answer, the correct answer surfaced, and a tappable
/// verse-reference chip that opens the source chapter. The teaching
/// loop the user asked for.
class _CorrectionsSheet extends StatelessWidget {
  const _CorrectionsSheet({
    required this.questions,
    required this.userAnswers,
    required this.scrollController,
    required this.onOpenRef,
    required this.book,
    required this.chapter,
  });

  final List<_QuizQuestion> questions;
  final List<String?> userAnswers;
  final ScrollController scrollController;
  final ValueChanged<String> onOpenRef;
  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBrown = const Color(0xFF5D4037);
    final correctCount = questions.where((q) {
      final i = questions.indexOf(q);
      return i < userAnswers.length && userAnswers[i] == q.correctAnswer;
    }).length;

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Icon(Icons.fact_check, color: BrandColors.gold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Corrections',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: primaryBrown,
                  ),
                ),
              ),
              Text(
                '$correctCount / ${questions.length} correct',
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: questions.length,
            itemBuilder: (_, i) {
              final q = questions[i];
              final chose = i < userAnswers.length ? userAnswers[i] : null;
              final wasRight = chose == q.correctAnswer;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: wasRight
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                          : const Color(0xFFE57373).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: wasRight
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE57373),
                            ),
                            child: Icon(
                              wasRight ? Icons.check : Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Question ${i + 1}',
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q.question,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (chose == null) ...[
                        Text(
                          'Not answered',
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else if (!wasRight) ...[
                        _AnswerRow(
                          label: 'You picked',
                          text: chose,
                          color: const Color(0xFFE57373),
                          icon: Icons.close,
                        ),
                        const SizedBox(height: 4),
                      ],
                      _AnswerRow(
                        label: 'Correct answer',
                        text: q.correctAnswer,
                        color: const Color(0xFF4CAF50),
                        icon: Icons.check,
                      ),
                      if (q.explanation != null &&
                          q.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BrandColors.gold.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: BrandColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 14, color: BrandColors.gold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  q.explanation!,
                                  style: GoogleFonts.lora(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    color: primaryBrown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (q.verseRef.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        // ── Verse-reference chip → opens the chapter ──
                        // Label is the full canonical reference so it
                        // is obvious where the tap goes ("Ecclesiastes
                        // 3:17" rather than a bare "17" — previous
                        // version was a mystery number).
                        Builder(
                          builder: (_) {
                            final chipLabel = q.verseRef.contains(':')
                                ? q.verseRef
                                : '$book $chapter:${q.verseRef}';
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => onOpenRef(q.verseRef),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      BrandColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: BrandColors.gold
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.menu_book,
                                        size: 14,
                                        color: BrandColors.brownDeep),
                                    const SizedBox(width: 6),
                                    Text(
                                      chipLabel,
                                      style: GoogleFonts.lora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: BrandColors.brownDeep,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
  });
  final String label;
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: GoogleFonts.lora(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lora(
                fontSize: 13,
                color: const Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
