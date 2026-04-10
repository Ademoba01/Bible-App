import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models.dart';
import '../../state/providers.dart';

/// A quiz question for kids mode.
class _KidsQuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;

  const _KidsQuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}

class KidsQuizScreen extends ConsumerStatefulWidget {
  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final Color themeColor;

  const KidsQuizScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.themeColor,
  });

  @override
  ConsumerState<KidsQuizScreen> createState() => _KidsQuizScreenState();
}

class _KidsQuizScreenState extends ConsumerState<KidsQuizScreen>
    with TickerProviderStateMixin {
  List<_KidsQuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _loading = true;
  String? _error;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _resultEmojiController;
  late Animation<double> _resultEmojiAnimation;

  // Confetti-like star burst for perfect score
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;

  static const _encourageCorrect = [
    "You're amazing!",
    'Great job!',
    'Wow, you got it!',
    'Super smart!',
    'Awesome!',
  ];

  static const _encourageWrong = [
    'Almost! Good try!',
    "Don't worry, you'll get it!",
    'Nice try! Keep going!',
    "That's okay! You're learning!",
  ];

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _resultEmojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _resultEmojiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _resultEmojiController, curve: Curves.elasticOut),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    _loadQuestions();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _resultEmojiController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final repo = ref.read(bibleRepositoryProvider);
      final translationId = ref.read(settingsProvider).translation;
      final chapters =
          await repo.loadBook(widget.book, translationId: translationId);
      final chapterIndex =
          (widget.chapter - 1).clamp(0, chapters.length - 1);
      final chapter = chapters[chapterIndex];

      final verses = chapter.verses
          .where((v) =>
              v.number >= widget.startVerse &&
              v.number <= widget.endVerse)
          .toList();

      if (verses.isEmpty) {
        setState(() {
          _error = 'No verses found for this story.';
          _loading = false;
        });
        return;
      }

      final questions = _generateKidsQuestions(verses);
      setState(() {
        _questions = questions;
        _loading = false;
      });
      _bounceController.forward();
    } catch (e) {
      setState(() {
        _error = 'Oops! Could not load the quiz.';
        _loading = false;
      });
    }
  }

  List<_KidsQuizQuestion> _generateKidsQuestions(List<Verse> verses) {
    final random = Random();
    final questions = <_KidsQuizQuestion>[];

    final shuffled = List<Verse>.from(verses)..shuffle(random);
    final selected = shuffled.take(min(3, verses.length)).toList();

    for (final verse in selected) {
      final text = verse.text;
      // Kids only get 3 question types, simpler wording
      final strategy = random.nextInt(3);

      switch (strategy) {
        case 0: // Fill in the blank (kid-friendly)
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
                  .take(2)
                  .toList();
              while (wrongWords.length < 2) {
                wrongWords.add('something');
              }
              questions.add(_KidsQuizQuestion(
                question:
                    'Can you find the missing word?\n"$blanked"',
                correctAnswer: blankWord,
                options: [blankWord, ...wrongWords]..shuffle(random),
              ));
            }
          }
          break;

        case 1: // True or False (kid-friendly)
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
          questions.add(_KidsQuizQuestion(
            question:
                'Is this right?\n"${displayText.length > 80 ? '${displayText.substring(0, 80)}...' : displayText}"',
            correctAnswer: isTrue ? 'Yes!' : 'Nope!',
            options: ['Yes!', 'Nope!'],
          ));
          break;

        case 2: // Complete the verse (kid-friendly)
          final words = text.split(' ');
          if (words.length >= 6) {
            final cutPoint = words.length ~/ 2;
            final firstHalf = words.sublist(0, cutPoint).join(' ');
            final secondHalf = words.sublist(cutPoint).join(' ');
            final wrongAnswers = verses
                .where((v) => v != verse)
                .take(2)
                .map((v) {
              final w = v.text.split(' ');
              return w.length > cutPoint
                  ? w.sublist(cutPoint).join(' ')
                  : v.text;
            }).toList();
            while (wrongAnswers.length < 2) {
              wrongAnswers.add('None of these');
            }
            questions.add(_KidsQuizQuestion(
              question:
                  'What comes next?\n"$firstHalf..."',
              correctAnswer: secondHalf,
              options: [secondHalf, ...wrongAnswers]..shuffle(random),
            ));
          }
          break;
      }
    }

    return questions;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final isCorrect = answer == _questions[_currentIndex].correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) _score++;
    });

    _resultEmojiController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
        _bounceController.forward(from: 0);
      } else {
        setState(() {
          _currentIndex = _questions.length; // score screen
        });
        if (_score == _questions.length) {
          _confettiController.forward(from: 0);
        }
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
    });
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text('Quiz Time!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  CircularProgressIndicator(color: color),
                  const SizedBox(height: 12),
                  Text('Getting your quiz ready...',
                      style: GoogleFonts.fredoka(
                          fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('😢',
                            style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: GoogleFonts.fredoka(fontSize: 18),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: color),
                          onPressed: () => Navigator.pop(context),
                          child: Text('Go back',
                              style: GoogleFonts.fredoka()),
                        ),
                      ],
                    ),
                  ),
                )
              : _questions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📖',
                                style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            Text(
                              'This story is too short for a quiz. Read another story!',
                              style: GoogleFonts.fredoka(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: color),
                              onPressed: () => Navigator.pop(context),
                              child: Text('Go back',
                                  style: GoogleFonts.fredoka()),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _currentIndex >= _questions.length
                      ? _buildScoreScreen(color)
                      : _buildQuestionScreen(color),
    );
  }

  Widget _buildQuestionScreen(Color color) {
    final q = _questions[_currentIndex];
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;
    final random = Random(_currentIndex);
    final isCorrect =
        _answered && _selectedAnswer == q.correctAnswer;

    return ScaleTransition(
      scale: _bounceAnimation.drive(Tween(begin: 0.9, end: 1.0)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: i == _currentIndex ? 32 : 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: i < _currentIndex
                        ? Colors.green
                        : i == _currentIndex
                            ? color
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Question ${_currentIndex + 1} of $total',
                style: GoogleFonts.fredoka(
                    fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 24),

            // Question card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  q.question,
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    height: 1.5,
                    color: Colors.brown.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Answer buttons
            ...q.options.map((option) {
              final optIsCorrect = option == q.correctAnswer;
              final optIsSelected = option == _selectedAnswer;

              Color bgColor = color.withValues(alpha: 0.12);
              Color borderColor = color.withValues(alpha: 0.3);
              Color textColor = Colors.brown.shade800;

              if (_answered) {
                if (optIsCorrect) {
                  bgColor = Colors.green.shade100;
                  borderColor = Colors.green;
                } else if (optIsSelected) {
                  bgColor = Colors.red.shade100;
                  borderColor = Colors.red;
                } else {
                  bgColor = Colors.grey.shade100;
                  borderColor = Colors.grey.shade300;
                  textColor = Colors.grey;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _answered ? null : () => _selectAnswer(option),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.fredoka(
                              fontSize: 17,
                              color: textColor,
                              fontWeight: optIsSelected || (_answered && optIsCorrect)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_answered && optIsCorrect)
                          const Text(' ✅',
                              style: TextStyle(fontSize: 22)),
                        if (_answered && optIsSelected && !optIsCorrect)
                          const Text(' ❌',
                              style: TextStyle(fontSize: 22)),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Result emoji & encouragement
            if (_answered)
              ScaleTransition(
                scale: _resultEmojiAnimation,
                child: Column(
                  children: [
                    Text(
                      isCorrect ? '🎉' : '😊',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCorrect
                          ? _encourageCorrect[
                              random.nextInt(_encourageCorrect.length)]
                          : _encourageWrong[
                              random.nextInt(_encourageWrong.length)],
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isCorrect
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreScreen(Color color) {
    final total = _questions.length;

    // Stars based on score
    String stars;
    String message;
    if (_score == total) {
      stars = List.generate(total, (_) => '⭐').join();
      message = "PERFECT! You're a Bible superstar!";
    } else if (_score == total - 1) {
      stars = List.generate(_score, (_) => '⭐').join();
      message = 'So close! Amazing job!';
    } else if (_score > 0) {
      stars = List.generate(_score, (_) => '⭐').join();
      message = 'Good try! Keep reading!';
    } else {
      stars = '📖';
      message = "Let's read the story again and try!";
    }

    return Stack(
      children: [
        // Confetti-like stars for perfect score
        if (_score == total)
          AnimatedBuilder(
            animation: _confettiAnimation,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _StarBurstPainter(
                  progress: _confettiAnimation.value,
                  color: color,
                ),
              );
            },
          ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stars, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 20),
                Text(
                  '$_score / $total',
                  style: GoogleFonts.fredoka(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    color: Colors.brown.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: const Icon(Icons.refresh, size: 24),
                    label: Text('Try again!',
                        style: GoogleFonts.fredoka(fontSize: 20)),
                    onPressed: _retry,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: color),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 24),
                    label: Text('Back to story',
                        style: GoogleFonts.fredoka(fontSize: 20)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a burst of colorful stars/circles radiating from center.
class _StarBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42); // fixed seed for consistent pattern
    final maxRadius = size.width * 0.6;

    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      color,
    ];

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi + random.nextDouble() * 0.3;
      final dist = maxRadius * progress * (0.5 + random.nextDouble() * 0.5);
      final x = center.dx + cos(angle) * dist;
      final y = center.dy + sin(angle) * dist;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final radius = 4.0 + random.nextDouble() * 6.0;

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Alternate between circles and star-like shapes
      if (i % 3 == 0) {
        // Draw a small star
        final path = Path();
        for (int j = 0; j < 5; j++) {
          final a = (j / 5) * 2 * pi - pi / 2;
          final r = j % 2 == 0 ? radius : radius * 0.4;
          final px = x + cos(a) * r;
          final py = y + sin(a) * r;
          if (j == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter old) =>
      old.progress != progress;
}
