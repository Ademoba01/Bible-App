import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme.dart';
import 'kids_story_data.dart';

class KidsAnimatedStoryScreen extends StatefulWidget {
  final IllustratedStory story;
  const KidsAnimatedStoryScreen({super.key, required this.story});

  @override
  State<KidsAnimatedStoryScreen> createState() => _KidsAnimatedStoryScreenState();
}

class _KidsAnimatedStoryScreenState extends State<KidsAnimatedStoryScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _emojiController;
  late final AnimationController _sparkleController;
  late final AnimationController _celebrationController;
  final FlutterTts _tts = FlutterTts();
  int _currentPage = 0; // 0 = intro, 1..n = story pages, n+1 = ending
  bool _isSpeaking = false;

  int get _totalPages => widget.story.pages.length + 2; // intro + pages + ending

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _emojiController.forward();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    // 0.55 ≈ 1.1× — natural lively pace for kids; 0.4 was sluggish.
    await _tts.setSpeechRate(0.55);
    await _tts.setPitch(1.15);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emojiController.dispose();
    _sparkleController.dispose();
    _celebrationController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _onPageChanged(int page) {
    _tts.stop();
    setState(() {
      _currentPage = page;
      _isSpeaking = false;
    });
    _emojiController.reset();
    _emojiController.forward();
    if (page == _totalPages - 1) {
      _celebrationController.reset();
      _celebrationController.forward();
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              if (index == 0) return _buildIntroPage();
              if (index == _totalPages - 1) return _buildEndingPage();
              return _buildStoryPage(index - 1);
            },
          ),
          // Progress bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildProgressBar(),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () {
                _tts.stop();
                Navigator.pop(context);
              },
            ),
          ),
          // Floating sparkles
          ..._buildSparkles(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalPages > 1 ? _currentPage / (_totalPages - 1) : 0.0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(BrandColors.gold),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(widget.story.color),
            Color(widget.story.color).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouncing emoji
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _emojiController,
                  curve: Curves.elasticOut,
                ),
                child: Text(
                  widget.story.emoji,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.story.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.story.bibleReference,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(widget.story.color),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.auto_stories, size: 28),
                label: Text(
                  'Begin Story',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Swipe to turn pages',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPage(int pageIndex) {
    final page = widget.story.pages[pageIndex];
    final bgColor = Color(page.backgroundColor);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor, bgColor.withValues(alpha: 0.6)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated emoji illustration
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _emojiController,
                  curve: Curves.elasticOut,
                ),
                child: Text(
                  page.emoji,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
              const SizedBox(height: 32),
              // Story text
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _emojiController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    page.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3E2723),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Read to Me button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _isSpeaking
                      ? Colors.red[400]
                      : Color(widget.story.color),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                label: Text(
                  _isSpeaking ? 'Stop' : 'Read to Me',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => _speak(page.text),
              ),
              const Spacer(),
              // Page number
              Text(
                '${pageIndex + 1} of ${widget.story.pages.length}',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndingPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(widget.story.color),
            Color(widget.story.color).withValues(alpha: 0.6),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration emojis
              AnimatedBuilder(
                animation: _celebrationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _celebrationController.value.clamp(0.0, 1.0),
                    child: const Text('🎉 ⭐ 🎉', style: TextStyle(fontSize: 60)),
                  );
                },
              ),
              const SizedBox(height: 16),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _celebrationController,
                  curve: Curves.elasticOut,
                ),
                child: Text(
                  'The End!',
                  style: GoogleFonts.fredoka(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Moral lesson
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      '💡 What we learned:',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(widget.story.color),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.story.moralLesson,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        height: 1.4,
                        color: const Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.story.bibleReference,
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.replay),
                    label: Text('Read Again',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w500)),
                    onPressed: () {
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(widget.story.color),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.home),
                    label: Text('Done',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final random = Random(42);
    return List.generate(8, (i) {
      final left = random.nextDouble() * (MediaQuery.of(context).size.width - 30);
      final top = random.nextDouble() * (MediaQuery.of(context).size.height - 30);
      final delay = random.nextDouble();
      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (_, __) {
            final t = ((_sparkleController.value + delay) % 1.0);
            final opacity = (sin(t * pi * 2) * 0.5 + 0.5) * 0.4;
            final scale = 0.5 + sin(t * pi * 2) * 0.3;
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: const Text('✨', style: TextStyle(fontSize: 16)),
              ),
            );
          },
        ),
      );
    });
  }
}
