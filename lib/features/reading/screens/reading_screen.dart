import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models.dart';
import '../../../data/translations.dart';
import '../../../state/codex_provider.dart';
import '../../../state/providers.dart';
import '../../../theme.dart';
import '../../cross_references/cross_references_sheet.dart';
import '../../listen/listen_screen.dart';
import '../../search/similar_verses_screen.dart';
import '../../share/verse_card_renderer.dart';
import '../../../utils/page_transitions.dart';
import '../../../widgets/rhema_title.dart';
import '../../study/chapter_quiz_screen.dart';
import 'books_screen.dart';
import '../../../widgets/shimmer_placeholder.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _highlightAnimController;
  late Animation<double> _highlightAnim;
  int? _activeHighlightVerse;
  // Back chip stays visible until dismissed (no auto-fade)
  bool _backChipVisible = true;
  // GlobalKeys for pixel-accurate verse scrolling
  final Map<int, GlobalKey> _verseKeys = {};
  // Pinch-to-zoom font size tracking
  double _baseFontSize = 18;

  @override
  void initState() {
    super.initState();
    _highlightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _highlightAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _highlightAnimController, curve: Curves.easeOut),
    );
    _highlightAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _activeHighlightVerse = null);
        ref.read(highlightVerseProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightAnimController.dispose();
    super.dispose();
  }

  void _handleHighlight(int verseNumber) {
    setState(() => _activeHighlightVerse = verseNumber);
    _highlightAnimController.reset();
    _highlightAnimController.forward();

    // Pixel-accurate scroll using GlobalKey
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _verseKeys[verseNumber];
      if (key != null && key.currentContext != null) {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null && _scrollController.hasClients) {
          final offset = renderBox.localToGlobal(Offset.zero,
              ancestor: context.findRenderObject());
          final scrollTarget = _scrollController.offset + offset.dy - 120;
          _scrollController.animateTo(
            scrollTarget.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      } else {
        // Fallback: approximate offset
        final targetOffset = (verseNumber - 1) * 60.0;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _revealBackChip() {
    setState(() => _backChipVisible = true);
  }

  void _dismissBackChip() {
    setState(() => _backChipVisible = false);
    ref.read(returnContextProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(readingLocationProvider);
    final chaptersAsync = ref.watch(currentBookChaptersProvider);
    final fontSize = ref.watch(settingsProvider.select((s) => s.fontSize));
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);
    // Watch providers to trigger rebuilds (values used by ref.listen below)
    ref.watch(highlightVerseProvider);
    final returnContext = ref.watch(returnContextProvider);

    // React to highlight verse changes
    ref.listen<int?>(highlightVerseProvider, (prev, next) {
      if (next != null && next != prev) {
        _handleHighlight(next);
      }
    });

    // React to return context changes — show chip (persists until dismissed)
    ref.listen<String?>(returnContextProvider, (prev, next) {
      if (next != null && next != prev) {
        _revealBackChip();
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // Centered Rhema mark — taps to home. Replaces the book/chapter label
        // that was awkwardly left-aligned. Book picker still accessible via
        // the chapter bar below the AppBar.
        title: const RhemaTitle(),
        // Book/chapter pill on the leading side keeps quick book switching.
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () async {
              final picked = await Navigator.push<String>(
                context,
                FadeSlideRoute(page: const BooksScreen()),
              );
              if (picked != null) {
                ref.read(readingLocationProvider.notifier).setBook(picked);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${loc.book} ${loc.chapter}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
            tooltip: 'Quiz me on this chapter',
            onPressed: () {
              Navigator.push(
                context,
                FadeSlideRoute(
                  page: ChapterQuizScreen(
                    book: loc.book,
                    chapter: loc.chapter,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const ReadingShimmer(),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (chapters) {
          // Record streak when chapter data loads
          ref.read(streakProvider.notifier).recordToday();
          // Mark this chapter read in the Codex (chapter milestones, book
          // completion seals). markChapterRead is idempotent per chapter.
          ref
              .read(codexProvider.notifier)
              .markChapterRead(loc.book, loc.chapter);

          if (chapters.isEmpty) {
            return const Center(child: Text('No chapters found.'));
          }
          final maxChapter = chapters.length;
          final current = loc.chapter.clamp(1, maxChapter);

          return Column(
            children: [
              _ChapterBar(
                book: loc.book,
                chapter: current,
                max: maxChapter,
                onPick: (c) => ref.read(readingLocationProvider.notifier).setChapter(c),
                onPrev: () => ref.read(readingLocationProvider.notifier).prev(),
                onNext: () => ref.read(readingLocationProvider.notifier).next(maxChapter),
                onListen: () => Navigator.push(
                  context,
                  FadeSlideRoute(page: const ListenScreen()),
                ),
              ),
              // Decorative divider with gold accent
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      BrandColors.gold.withValues(alpha: 0.4),
                      BrandColors.gold.withValues(alpha: 0.6),
                      BrandColors.gold.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
              Expanded(
                // ── Swipe left/right to change chapters + pinch-to-zoom ──
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity! < -300 && current < maxChapter) {
                      // Swipe left → next chapter
                      ref.read(readingLocationProvider.notifier).next(maxChapter);
                    } else if (details.primaryVelocity! > 300 && current > 1) {
                      // Swipe right → previous chapter
                      ref.read(readingLocationProvider.notifier).prev();
                    }
                  },
                  onScaleStart: (_) {
                    _baseFontSize = ref.read(settingsProvider).fontSize;
                  },
                  onScaleUpdate: (details) {
                    if (details.pointerCount < 2) return;
                    final newSize = (_baseFontSize * details.scale)
                        .clamp(14.0, 28.0)
                        .roundToDouble();
                    if (newSize != ref.read(settingsProvider).fontSize) {
                      ref.read(settingsProvider.notifier).setFontSize(newSize);
                    }
                  },
                  child: Stack(
                    children: [
                      _VerseList(
                        chapter: chapters[current - 1],
                        book: loc.book,
                        chapterNum: current,
                        fontSize: fontSize,
                        bookmarks: bookmarks,
                        ref: ref,
                        scrollController: _scrollController,
                        highlightVerse: _activeHighlightVerse,
                        highlightAnim: _highlightAnim,
                        verseKeys: _verseKeys,
                      ),
                      // ── Floating "Back to" chip — persists until dismissed ──
                      if (returnContext != null && _backChipVisible)
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6, right: 4),
                              decoration: BoxDecoration(
                                color: BrandColors.brown.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: BrandColors.brown.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _dismissBackChip();
                                      ref.read(highlightVerseProvider.notifier).state = null;
                                      Navigator.of(context).maybePop();
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          returnContext == 'similar_verses'
                                              ? 'Back to Similar Verses'
                                              : returnContext == 'map'
                                                  ? 'Back to Map'
                                                  : 'Back',
                                          style: GoogleFonts.lora(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Dismiss button
                                  GestureDetector(
                                    onTap: _dismissBackChip,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerseList extends StatefulWidget {
  const _VerseList({
    required this.chapter,
    required this.book,
    required this.chapterNum,
    required this.fontSize,
    required this.bookmarks,
    required this.ref,
    this.scrollController,
    this.highlightVerse,
    this.verseKeys,
    this.highlightAnim,
  });

  final Chapter chapter;
  final String book;
  final int chapterNum;
  final double fontSize;
  final List<String> bookmarks;
  final WidgetRef ref;
  final ScrollController? scrollController;
  final int? highlightVerse;
  final Animation<double>? highlightAnim;
  final Map<int, GlobalKey>? verseKeys;

  @override
  State<_VerseList> createState() => _VerseListState();
}

class _VerseListState extends State<_VerseList> {
  // Multi-verse selection state
  final Set<int> _selectedVerses = {}; // verse numbers currently selected
  bool _selectionMode = false;

  void _toggleVerse(int verseNumber) {
    setState(() {
      if (_selectedVerses.contains(verseNumber)) {
        _selectedVerses.remove(verseNumber);
        if (_selectedVerses.isEmpty) _selectionMode = false;
      } else {
        _selectedVerses.add(verseNumber);
      }
    });
  }

  void _startSelection(int verseNumber) {
    setState(() {
      _selectionMode = true;
      _selectedVerses.clear();
      _selectedVerses.add(verseNumber);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedVerses.clear();
    });
  }

  /// Build the "2 Corinthians 4:2-6 (WEB)" style reference for selected verses
  String _buildRangeRef() {
    if (_selectedVerses.isEmpty) return '';
    final sorted = _selectedVerses.toList()..sort();
    final translation = widget.ref.read(settingsProvider).translation;
    final versionName = translationById(translation).name;

    // Build verse range groups (e.g., 2-4, 7, 9-11)
    final ranges = <String>[];
    int start = sorted.first;
    int end = start;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = sorted[i];
        end = start;
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');

    return '${widget.book} ${widget.chapterNum}:${ranges.join(",")} ($versionName)';
  }

  /// Combine selected verse texts
  String _buildSelectedText() {
    final sorted = _selectedVerses.toList()..sort();
    return sorted.map((vn) {
      final verse = widget.chapter.verses.firstWhere((v) => v.number == vn);
      return verse.text;
    }).join(' ');
  }

  void _copySelected() {
    final rangeRef = _buildRangeRef();
    final text = _buildSelectedText();
    final copyText = '$rangeRef\n$text\n\n— Rhema Study Bible\nhttps://rhemabibles.com';
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedVerses.length} verse${_selectedVerses.length > 1 ? "s" : ""} copied'), duration: const Duration(seconds: 2)),
    );
    _clearSelection();
  }

  void _shareSelected() {
    final rangeRef = _buildRangeRef();
    final text = _buildSelectedText();
    VerseCardRenderer.shareVerseCard(
      context: context,
      verseText: text,
      reference: rangeRef,
    );
    _clearSelection();
  }

  void _openCrossRefs() {
    if (_selectedVerses.isEmpty) return;
    final firstVerse = (_selectedVerses.toList()..sort()).first;
    final source = VerseRef(widget.book, widget.chapterNum, firstVerse);
    _clearSelection();
    showCrossReferencesSheet(context, widget.ref, source);
  }

  @override
  Widget build(BuildContext context) {
    // Alias widget properties for less verbose access
    final chapter = widget.chapter;
    final book = widget.book;
    final chapterNum = widget.chapterNum;
    final fontSize = widget.fontSize;
    final bookmarks = widget.bookmarks;
    final ref = widget.ref;
    final scrollController = widget.scrollController;
    final highlightVerse = widget.highlightVerse;
    final highlightAnim = widget.highlightAnim;
    final verseKeys = widget.verseKeys;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlights = ref.watch(highlightsProvider);
    // Lazy GlobalKey cache — only create keys for new verse numbers
    if (verseKeys != null) {
      for (final v in chapter.verses) {
        verseKeys!.putIfAbsent(v.number, () => GlobalKey());
      }
    }
    return Stack(
      children: [
        Container(
      color: isDark ? const Color(0xFF2B1E19) : BrandColors.parchment,
      child: ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 400 ? 14 : 20,
        20,
        MediaQuery.of(context).size.width < 400 ? 14 : 20,
        16,
      ),
      itemCount: chapter.verses.length + 1, // +1 for quiz CTA at end
      itemBuilder: (context, i) {
        // Quiz CTA at the end of the chapter
        if (i == chapter.verses.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Material(
              color: BrandColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    FadeSlideRoute(
                      page: ChapterQuizScreen(
                        book: book,
                        chapter: chapterNum,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Icon(Icons.quiz, color: BrandColors.gold, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test your knowledge',
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quiz yourself on $book $chapterNum',
                              style: GoogleFonts.lora(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: BrandColors.gold),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final v = chapter.verses[i];
        final ref0 = VerseRef(book, chapterNum, v.number).id;
        final isMarked = bookmarks.contains(ref0);
        final highlightColorIndex = highlights[ref0];
        final isNavHighlighted = highlightVerse == v.number && highlightAnim != null;
        final verseKey = verseKeys?[v.number];
        final isSelected = _selectedVerses.contains(v.number);

        // Drop cap for the first verse — with watermark chapter number
        if (i == 0 && v.text.isNotEmpty) {
          final firstLetter = v.text[0];
          final restOfText = v.text.length > 1 ? v.text.substring(1) : '';
          Widget dropCapWidget = Padding(
            key: verseKey,
            padding: const EdgeInsets.only(bottom: 6),
            child: Stack(
              children: [
                // Watermark chapter number
                Positioned(
                  right: 0,
                  top: -8,
                  child: Text(
                    '$chapterNum',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      color: (isDark ? Colors.white : BrandColors.brown)
                          .withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Container(
              decoration: isSelected
                  ? BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: BrandColors.gold.withValues(alpha: 0.5), width: 1.5),
                    )
                  : highlightColorIndex != null
                      ? BoxDecoration(
                          color: HighlightsNotifier.colors[highlightColorIndex]
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        )
                      : null,
              padding: (isSelected || highlightColorIndex != null)
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                  : EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  if (_selectionMode) {
                    _toggleVerse(v.number);
                  } else {
                    HapticFeedback.lightImpact();
                    _showVerseSheet(context, ref0, v, theme);
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _startSelection(v.number);
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${v.number} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: fontSize,
                        ),
                      ),
                      TextSpan(
                        text: firstLetter,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: fontSize * 2.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? BrandColors.gold : BrandColors.goldDark,
                          height: 0.85,
                        ),
                      ),
                      TextSpan(
                        text: restOfText,
                        style: GoogleFonts.lora(
                          fontSize: fontSize,
                          height: 1.7,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isMarked)
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.bookmark, size: 16, color: theme.colorScheme.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
              ], // close Stack children
            ), // close Stack
          );
          if (isNavHighlighted) {
            return AnimatedBuilder(
              animation: highlightAnim!,
              builder: (context, child) => Container(
                decoration: BoxDecoration(
                  color: BrandColors.gold.withValues(alpha: highlightAnim!.value * 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              ),
              child: dropCapWidget,
            );
          }
          return dropCapWidget;
        }

        Widget verseWidget = Padding(
          key: verseKey,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: BrandColors.gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BrandColors.gold.withValues(alpha: 0.5), width: 1.5),
                  )
                : highlightColorIndex != null
                    ? BoxDecoration(
                        color: HighlightsNotifier.colors[highlightColorIndex]
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
            padding: (isSelected || highlightColorIndex != null)
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                : EdgeInsets.zero,
            child: InkWell(
              onTap: () {
                if (_selectionMode) {
                  _toggleVerse(v.number);
                } else {
                  HapticFeedback.lightImpact();
                  _showVerseSheet(context, ref0, v, theme);
                }
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _startSelection(v.number);
              },
              child: RichText(
                text: TextSpan(
                  // Literata for Bible verses — designed for long-form
                  // devotional reading. Tighter letter spacing, taller
                  // line height than Lora.
                  style: BrandColors.verseStyle(
                    size: fontSize,
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '${v.number}  ',
                      style: BrandColors.verseNumberStyle(
                        color: BrandColors.brownMid,
                      ).copyWith(fontSize: fontSize - 4),
                    ),
                    TextSpan(text: v.text),
                    if (isMarked)
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.bookmark, size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        if (isNavHighlighted) {
          return AnimatedBuilder(
            animation: highlightAnim!,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: highlightAnim!.value * 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: child,
            ),
            child: verseWidget,
          );
        }
        return verseWidget;
      },
    ),
    ),
        // ── Floating selection action bar ──
        if (_selectionMode && _selectedVerses.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BrandColors.brown.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Selection count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedVerses.length} verse${_selectedVerses.length > 1 ? "s" : ""}',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Cross-references (uses lowest-numbered selected verse)
                  IconButton(
                    icon: const Icon(Icons.alt_route, size: 20, color: Colors.white),
                    tooltip: 'Cross-references',
                    onPressed: _openCrossRefs,
                  ),
                  // Copy
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.white),
                    tooltip: 'Copy',
                    onPressed: _copySelected,
                  ),
                  // Share
                  IconButton(
                    icon: const Icon(Icons.share, size: 20, color: Colors.white),
                    tooltip: 'Share',
                    onPressed: _shareSelected,
                  ),
                  // Close
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                    tooltip: 'Cancel',
                    onPressed: _clearSelection,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showVerseSheet(BuildContext context, String refId, Verse v, ThemeData theme) {
    final isMarked = widget.ref.read(bookmarksProvider).contains(refId);
    final parsedRef = VerseRef.tryParse(refId);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (sheetContext) => Center(
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BrandColors.gold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(refId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text(v.text, style: BrandColors.verseStyle(size: 17)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                  label: const Text('Copy'),
                  onPressed: () {
                    final translation = widget.ref.read(settingsProvider).translation;
                    final versionName = translationById(translation).name;
                    final copyText = '$refId ($versionName)\n${v.text}\n\n— Rhema Study Bible\nhttps://rhemabibles.com';
                    Clipboard.setData(ClipboardData(text: copyText));
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verse copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.share, color: theme.colorScheme.primary),
                  label: const Text('Share'),
                  onPressed: () {
                    final translation = widget.ref.read(settingsProvider).translation;
                    final versionName = translationById(translation).name;
                    Navigator.pop(sheetContext);
                    VerseCardRenderer.shareVerseCard(
                      context: context,
                      verseText: v.text,
                      reference: '$refId ($versionName)',
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(isMarked ? Icons.bookmark : Icons.bookmark_border,
                      color: theme.colorScheme.primary),
                  label: Text(isMarked ? 'Bookmarked' : 'Bookmark'),
                  onPressed: () {
                    widget.ref.read(bookmarksProvider.notifier).toggle(refId);
                    Navigator.pop(sheetContext);
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
                  label: const Text('Find similar'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    if (parsedRef != null) {
                      Navigator.push(
                        context,
                        FadeSlideRoute(
                          page: SimilarVersesScreen(
                            sourceRef: parsedRef,
                            sourceText: v.text,
                          ),
                        ),
                      );
                    }
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.alt_route, color: theme.colorScheme.primary),
                  label: const Text('Cross-references'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    if (parsedRef != null) {
                      showCrossReferencesSheet(context, widget.ref, parsedRef);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Highlight color picker — Wrap prevents overflow on narrow screens
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text('Highlight:',
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant)),
                ...List.generate(HighlightsNotifier.colors.length, (i) {
                  final isSelected =
                      widget.ref.read(highlightsProvider)[refId] == i;
                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        widget.ref
                            .read(highlightsProvider.notifier)
                            .removeHighlight(refId);
                      } else {
                        widget.ref
                            .read(highlightsProvider.notifier)
                            .highlight(refId, i);
                      }
                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HighlightsNotifier.colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              size: 18, color: theme.colorScheme.primary)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
          ),
        ),
      ),
    );
  }
}

class _ChapterBar extends StatelessWidget {
  const _ChapterBar({
    required this.book,
    required this.chapter,
    required this.max,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
    required this.onListen,
  });

  final String book;
  final int chapter;
  final int max;
  final ValueChanged<int> onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous chapter',
            onPressed: chapter > 1 ? onPrev : null,
          ),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDialog<int>(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (_) => Center(
                      child: Container(
                        width: 380,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: BrandColors.gold.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          child: GridView.count(
                            shrinkWrap: true,
                      crossAxisCount: MediaQuery.of(context).size.width < 400 ? 4 : MediaQuery.of(context).size.width < 600 ? 5 : 7,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (var c = 1; c <= max; c++)
                          InkWell(
                            onTap: () => Navigator.pop(context, c),
                            child: Card(
                              color: c == chapter
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              elevation: c == chapter ? 2 : 0,
                              child: Center(
                                child: Text('$c',
                                    style: TextStyle(
                                      fontWeight: c == chapter ? FontWeight.bold : FontWeight.normal,
                                      color: c == chapter
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    )),
                              ),
                            ),
                          ),
                      ],
                    ),
                        ),
                      ),
                    ),
                  );
                  if (picked != null) onPick(picked);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Chapter $chapter / $max',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.grid_view, size: 16),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next chapter',
            onPressed: chapter < max ? onNext : null,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onListen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BrandColors.goldLight, BrandColors.gold],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headphones, size: 16, color: Color(0xFF3E2723)),
                  SizedBox(width: 4),
                  Text('Listen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3E2723),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
