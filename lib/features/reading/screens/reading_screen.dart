import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models.dart';
import '../../../data/redletter_service.dart';
import '../../../data/strongs_service.dart';
import '../../../data/translations.dart';
import '../../../state/codex_provider.dart';
import '../../../state/providers.dart';
import '../../../theme.dart';
import '../../cross_references/cross_references_sheet.dart';
import '../../settings/settings_screen.dart';
import '../../study/strongs_sheet.dart';
import '../../study/my_lexicon_screen.dart';
import '../../listen/listen_screen.dart';
import '../../search/similar_verses_screen.dart';
import '../../share/verse_card_renderer.dart';
import '../../share/animated_story_share.dart';
import '../../../utils/page_transitions.dart';
import '../../../utils/sub_route_navigation.dart';
import '../../../widgets/rhema_title.dart';
import '../../study/bible_maps_screen.dart';
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
  // GlobalKey for accessing _VerseListState from the chapter bar's
  // "Select" IconButton — needed because the chapter bar lives in this
  // _ReadingScreenState while selection-mode state lives in
  // _VerseListState. Same-file private state access via GlobalKey is
  // legal and avoids a state-lifting refactor.
  final GlobalKey<_VerseListState> _verseListKey = GlobalKey<_VerseListState>();
  // Pinch-to-zoom font size tracking
  double _baseFontSize = 18;
  // Mirror of _VerseListState._selectionMode for the chapter bar — the
  // bar's icon needs to render filled/unfilled based on this. Updated
  // via [_onSelectionChanged] callback which _VerseListState invokes.
  bool _selectionActive = false;

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
    // Reduce Motion (Tier 4 a11y): instead of the 3-second gold-fade
    // animation, jump straight to a brief static highlight then clear.
    // Users with vestibular sensitivity see no flashing.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _highlightAnimController.value = 0.6;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _highlightAnimController.value = 0.0;
      });
    } else {
      _highlightAnimController.forward();
    }

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

  /// In-read translation picker. Opens a tidy bottom sheet listing every
  /// available translation grouped by Local (offline) vs Online. Tapping
  /// a row updates settingsProvider.translation, which causes the
  /// `currentBookChaptersProvider` watcher in [build] to re-fetch the
  /// chapters in the chosen translation — same flow as Settings →
  /// Translation, just one tap away from the read screen.
  Future<void> _showTranslationPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final current = ref.read(settingsProvider).translation;
    final available = kTranslations.where((t) => t.available).toList();
    final local = available.where((t) => t.isLocal).toList();
    final online = available.where((t) => !t.isLocal).toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        Widget tile(Translation t) {
          final isCurrent = t.id == current;
          return ListTile(
            leading: Icon(
              isCurrent ? Icons.check_circle : Icons.menu_book_rounded,
              color:
                  isCurrent ? BrandColors.gold : BrandColors.brownMid,
            ),
            title: Text(
              t.name,
              style: GoogleFonts.lora(
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              t.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: t.isLocal
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          BrandColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Offline',
                      style: GoogleFonts.lora(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.brownDeep,
                      ),
                    ),
                  )
                : null,
            onTap: () => Navigator.pop(sheetCtx, t.id),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BrandColors.brownMid.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'Switch translation',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Local translations work offline. Online ones need a connection but cover more languages.',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (local.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text('Offline',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: BrandColors.brownMid,
                      )),
                ),
                ...local.map(tile),
              ],
              if (online.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text('Online',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: BrandColors.brownMid,
                      )),
                ),
                ...online.map(tile),
              ],
            ],
          ),
        );
      },
    );

    if (picked != null && picked != current && mounted) {
      await ref
          .read(settingsProvider.notifier)
          .setTranslation(picked);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Switched to ${translationById(picked).name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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

    return Shortcuts(
      // ── iPad / hardware-keyboard shortcuts ──
      // I3 a11y review: previously no keyboard support for font sizing.
      // ⌘+ / ⌘= bumps font up, ⌘− down, ⌘0 resets. Voice Control "tap"
      // verbosity also benefits since Shortcuts surfaces named actions
      // to AT. Ctrl+= matches Material desktop convention too.
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.equal, meta: true):
            _IncreaseFontIntent(),
        SingleActivator(LogicalKeyboardKey.equal, control: true):
            _IncreaseFontIntent(),
        SingleActivator(LogicalKeyboardKey.numpadAdd, meta: true):
            _IncreaseFontIntent(),
        SingleActivator(LogicalKeyboardKey.minus, meta: true):
            _DecreaseFontIntent(),
        SingleActivator(LogicalKeyboardKey.minus, control: true):
            _DecreaseFontIntent(),
        SingleActivator(LogicalKeyboardKey.numpadSubtract, meta: true):
            _DecreaseFontIntent(),
        SingleActivator(LogicalKeyboardKey.digit0, meta: true):
            _ResetFontIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _IncreaseFontIntent: CallbackAction<_IncreaseFontIntent>(
            onInvoke: (_) {
              final cur = ref.read(settingsProvider).fontSize;
              ref
                  .read(settingsProvider.notifier)
                  .setFontSize((cur + 2).clamp(14.0, 28.0));
              return null;
            },
          ),
          _DecreaseFontIntent: CallbackAction<_DecreaseFontIntent>(
            onInvoke: (_) {
              final cur = ref.read(settingsProvider).fontSize;
              ref
                  .read(settingsProvider.notifier)
                  .setFontSize((cur - 2).clamp(14.0, 28.0));
              return null;
            },
          ),
          _ResetFontIntent: CallbackAction<_ResetFontIntent>(
            onInvoke: (_) {
              ref.read(settingsProvider.notifier).setFontSize(18.0);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // Compact RhemaTitle on the reading screen — the chapter bar below
        // already shows "BookName / Chapter / N" prominently, so the
        // wordmark would just compete for space and overflow on narrow
        // phones (which the user reported as the "OVERFLOWED BY" yellow
        // tape on iOS). Compact mode = icon only, still taps to home.
        title: const RhemaTitle(compact: true),
        // Compact leading — just the book name (no chapter; the chapter
        // is huge in the bar below). Halves the width budget so the
        // RhemaTitle icon stays cleanly centered.
        leadingWidth: 96,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    loc.book,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16),
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
          // Record streak + codex AFTER the build completes — modifying
          // providers synchronously during build throws a Riverpod
          // "Tried to modify a provider while the widget tree was
          // building" exception (this caused the iOS Read-tab red screen).
          // Post-frame defer makes it safe and the writes still happen
          // on the same frame the chapter data resolved.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ref.read(streakProvider.notifier).recordToday();
            ref
                .read(codexProvider.notifier)
                .markChapterRead(loc.book, loc.chapter);
          });

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
                translationId: ref.watch(
                    settingsProvider.select((s) => s.translation)),
                onPickTranslation: () => _showTranslationPicker(context),
                onEnterSelectionMode: () {
                  _verseListKey.currentState
                      ?._enterSelectionModeFromBar();
                  setState(() => _selectionActive = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Tap each verse to add — drag for a range'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                selectionActive: _selectionActive,
                scholarMode: ref.watch(
                    settingsProvider.select((s) => s.scholarMode)),
                onToggleScholar: () {
                  final wasOn = ref.read(settingsProvider).scholarMode;
                  ref
                      .read(settingsProvider.notifier)
                      .setScholarMode(!wasOn);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(wasOn
                          ? 'Word study turned off'
                          : 'Word study on — tap any underlined word for Greek/Hebrew'),
                      duration: const Duration(seconds: 3),
                      action: !wasOn
                          ? SnackBarAction(
                              label: 'My Lexicon',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MyLexiconScreen(),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
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
                        key: _verseListKey,
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
                        onSelectionModeChanged: (active) {
                          if (_selectionActive != active) {
                            setState(() => _selectionActive = active);
                          }
                        },
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
                                    onTap: () async {
                                      final ctx = returnContext;
                                      _dismissBackChip();
                                      ref
                                          .read(highlightVerseProvider
                                              .notifier)
                                          .state = null;
                                      if (ctx == 'map') {
                                        // Maps was popped when we
                                        // navigated to the verse — push
                                        // it again. The screen reads
                                        // mapReturnPlaceProvider on init
                                        // and re-opens that info card.
                                        ref
                                            .read(returnContextProvider
                                                .notifier)
                                            .state = null;
                                        await pushSubRoute(
                                          context,
                                          ref,
                                          route: SubRoute.maps,
                                          builder: (_) =>
                                              const BibleMapsScreen(),
                                        );
                                      } else {
                                        Navigator.of(context).maybePop();
                                      }
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
        ), // close Scaffold
        ), // close Focus
      ), // close Actions
    ); // close Shortcuts
  }
}

/// Keyboard-shortcut Intent for ⌘+ / Ctrl+= "increase font size".
class _IncreaseFontIntent extends Intent {
  const _IncreaseFontIntent();
}

class _DecreaseFontIntent extends Intent {
  const _DecreaseFontIntent();
}

class _ResetFontIntent extends Intent {
  const _ResetFontIntent();
}

class _VerseList extends StatefulWidget {
  const _VerseList({
    super.key,
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
    this.onSelectionModeChanged,
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
  /// Notifies the parent (_ReadingScreenState) whenever selection mode
  /// flips. Lets the chapter bar's "Select" icon update its filled state
  /// without lifting all selection state up.
  final ValueChanged<bool>? onSelectionModeChanged;

  @override
  State<_VerseList> createState() => _VerseListState();
}

class _VerseListState extends State<_VerseList> {
  // Multi-verse selection state
  final Set<int> _selectedVerses = {}; // verse numbers currently selected
  bool _selectionMode = false;

  /// Verse # the long-press drag started on. Used for "drag down to select
  /// multiple verses" — Claude/iOS-style extend-by-drag. While the user
  /// keeps their finger down after long-press, sliding to another verse
  /// extends the selection range from this anchor to wherever the finger
  /// currently is.
  int? _dragSelectionAnchor;

  /// Tap-recognisers we hand out to RichText. We hold them on the State so
  /// they can be disposed when the chapter/verse list rebuilds.
  final List<TapGestureRecognizer> _tapRecognizers = [];

  @override
  void dispose() {
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    _tapRecognizers.clear();
    super.dispose();
  }

  /// Reset and re-allocate recognisers. Called every build so the recogniser
  /// pool exactly matches the rendered taps. Cheap — there are only ever a
  /// few hundred per chapter.
  void _resetTapRecognizers() {
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    _tapRecognizers.clear();
  }

  TapGestureRecognizer _newRecognizer(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _tapRecognizers.add(r);
    return r;
  }

  /// Build the inline text spans for a verse. When [scholarMode] is on and
  /// Strong's data is available for this verse, each English word becomes
  /// individually tappable and reveals the lexicon sheet on tap.
  ///
  /// When Scholar Mode is off (or data isn't loaded), we fall back to a
  /// single plain TextSpan — exactly the previous behaviour.
  List<InlineSpan> _buildVerseSpans({
    required Verse verse,
    required String book,
    required int chapterNum,
    required ThemeData theme,
    required double fontSize,
    required bool scholarMode,
    required List<StrongsWord> strongs,
    required RedLetterEntry redLetter,
    required bool redLetterMode,
    required bool blueLetterMode,
    TextStyle? baseStyle,
    String? skipFirstLetter, // e.g. "I" — already rendered as the drop-cap
  }) {
    final hasRedLetters = redLetterMode && redLetter.red.isNotEmpty;
    final hasBlueLetters = blueLetterMode && redLetter.blue.isNotEmpty;
    final hasColor = hasRedLetters || hasBlueLetters;

    // Recycle tap recognizers each rebuild — without this they leak per
    // chapter scroll and accumulate hundreds in long sessions (perf
    // review A2). _newRecognizer() will allocate fresh ones below as
    // tokens get rendered. Idempotent + cheap.
    _resetTapRecognizers();

    if (!scholarMode && !hasColor) {
      // Fast path — single span exactly like the old code.
      final text = skipFirstLetter == null
          ? verse.text
          : (verse.text.length > 1 ? verse.text.substring(1) : '');
      return [TextSpan(text: text, style: baseStyle)];
    }

    // Index Strong's words by surface form so we can match them as we walk
    // the visible verse text. Multiple words can share a Strong's number; we
    // pop from the queue per surface form to honour reading order.
    final queues = <String, List<StrongsWord>>{};
    if (scholarMode) {
      for (final w in strongs) {
        final key = _surfaceKey(w.word);
        if (key.isEmpty) continue;
        queues.putIfAbsent(key, () => []).add(w);
      }
    }

    // Walk the verse as whitespace-delimited words to match the build-time
    // tokenization in scripts/build_redletter.py. Word indices are 0-based
    // and ALWAYS counted from the start of verse.text, not the skipped-
    // drop-cap variant — so the lookup table aligns regardless of whether
    // the drop cap is omitted from this render.
    final fullText = verse.text;
    final raw = skipFirstLetter == null
        ? fullText
        : (fullText.length > 1 ? fullText.substring(1) : '');
    // Offset between full and rendered text (1 char if drop cap skipped).
    final renderOffset = skipFirstLetter == null ? 0 : 1;

    // Pre-compute word index at each character of fullText. Whitespace runs
    // share the index of the previous word; this matches the build script.
    final wordIdxAtChar = List<int>.filled(fullText.length + 1, 0);
    int wIdx = -1;
    bool inWord = false;
    for (int i = 0; i < fullText.length; i++) {
      final isSpace = fullText[i] == ' ' || fullText[i] == '\n' || fullText[i] == '\t';
      if (!isSpace && !inWord) {
        wIdx += 1;
        inWord = true;
      } else if (isSpace) {
        inWord = false;
      }
      wordIdxAtChar[i] = wIdx < 0 ? 0 : wIdx;
    }
    wordIdxAtChar[fullText.length] = wIdx < 0 ? 0 : wIdx;

    Color? colorFor(int charInRaw) {
      if (!hasColor) return null;
      final fullChar = charInRaw + renderOffset;
      if (fullChar < 0 || fullChar >= wordIdxAtChar.length) return null;
      final w = wordIdxAtChar[fullChar];
      if (hasRedLetters && redLetter.isRed(w)) return BrandColors.redLetter;
      if (hasBlueLetters && redLetter.isBlue(w)) return BrandColors.blueLetter;
      return null;
    }

    final spans = <InlineSpan>[];
    final tokenRe = RegExp(r"[A-Za-z][A-Za-z'’]*");

    // Append a run of contiguous same-color characters as ONE TextSpan
    // (instead of per-character). The previous per-char emission broke
    // CanvasKit's text shaper at every word boundary — kerning collapsed,
    // ligatures dropped, and characters near soft-wrap points went
    // missing on web. This run-coalescer emits one span per color
    // transition, preserving glyph shaping while keeping correct red/
    // blue coloring on punctuation/whitespace adjacent to colored words.
    void emitRun(int start, int end) {
      if (start >= end) return;
      int runStart = start;
      Color? runColor = colorFor(start);
      for (int c = start + 1; c <= end; c++) {
        final col = c < end ? colorFor(c) : null;
        if (c == end || col != runColor) {
          final style = runColor == null
              ? baseStyle
              : (baseStyle ?? const TextStyle()).copyWith(color: runColor);
          spans.add(TextSpan(text: raw.substring(runStart, c), style: style));
          runStart = c;
          runColor = col;
        }
      }
    }

    int cursor = 0;
    for (final m in tokenRe.allMatches(raw)) {
      if (m.start > cursor) {
        emitRun(cursor, m.start);
      }
      final tok = m.group(0)!;
      final tokColor = colorFor(m.start);
      final key = _surfaceKey(tok);
      final queue = queues[key];
      StrongsWord? hit;
      if (queue != null && queue.isNotEmpty) {
        hit = queue.removeAt(0);
      }

      var tokStyle = baseStyle ?? const TextStyle();
      if (tokColor != null) tokStyle = tokStyle.copyWith(color: tokColor);

      if (hit != null && hit.strongs != null) {
        spans.add(TextSpan(
          text: tok,
          style: tokStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: BrandColors.gold.withValues(alpha: 0.45),
            decorationThickness: 1.2,
          ),
          recognizer: _newRecognizer(() {
            HapticFeedback.selectionClick();
            _openStrongs(hit!, verseRef: '$book $chapterNum:${verse.number}');
          }),
        ));
      } else {
        spans.add(TextSpan(text: tok, style: tokStyle));
      }
      cursor = m.end;
    }
    if (cursor < raw.length) {
      emitRun(cursor, raw.length);
    }
    return spans;
  }

  /// Strip punctuation and lowercase a token to match the build-time word
  /// keys (which preserved trailing commas and case). The Strong's tagging
  /// keeps trailing punctuation on the word — we tolerate that here.
  String _surfaceKey(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z']"), '')
        .trim();
  }

  void _openStrongs(StrongsWord w, {String? verseRef}) {
    final svc = widget.ref.read(strongsServiceProvider);
    final entry = svc.lookupStrong(w.strongs);
    final occ = svc.occurrencesOf(w.strongs);
    showStrongsSheet(
      context,
      word: w,
      entry: entry,
      occurrences: occ,
      sourceVerseRef: verseRef,
    );
  }

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
      _dragSelectionAnchor = verseNumber;
    });
    widget.onSelectionModeChanged?.call(true);
  }

  /// Extend the selection range from the long-press anchor to the verse
  /// currently under the user's finger. Used by the drag-to-select flow:
  /// long-press a verse → keep your finger down → slide DOWN over more
  /// verses → all verses between the anchor and your finger are selected.
  /// Like iOS Mail multi-select or text selection in Claude/Notes.
  void _extendDragSelectionTo(Offset globalPosition) {
    final anchor = _dragSelectionAnchor;
    if (anchor == null) return;
    final hitVerse = _verseAtGlobalY(globalPosition.dy);
    if (hitVerse == null) return;
    final lo = anchor < hitVerse ? anchor : hitVerse;
    final hi = anchor > hitVerse ? anchor : hitVerse;
    setState(() {
      _selectedVerses
        ..clear()
        ..addAll([for (int v = lo; v <= hi; v++) v]);
    });
  }

  /// Hit-test verse keys vs a global Y coordinate.
  /// Returns the verse number whose render-box vertically contains [y],
  /// or null if no verse is at that position (gap between verses, etc.).
  int? _verseAtGlobalY(double y) {
    final keys = widget.verseKeys;
    if (keys == null) return null;
    for (final entry in keys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      if (y >= topLeft.dy && y <= topLeft.dy + box.size.height) {
        return entry.key;
      }
    }
    return null;
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedVerses.clear();
      _dragSelectionAnchor = null;
    });
    widget.onSelectionModeChanged?.call(false);
  }

  /// Web/desktop entry to drag-select. Mobile users get the same flow via
  /// long-press, but on a mouse the 500-ms hold required by long-press
  /// feels broken — desktop users expect immediate click-and-drag like
  /// text selection. The verse-modal "Select multiple" action calls this
  /// to seed selection mode so subsequent click-drags extend the range
  /// (handled by the Listener around the ListView, see [build]).
  void _enterSelectionFromModal(int verseNumber) {
    setState(() {
      _selectionMode = true;
      _selectedVerses
        ..clear()
        ..add(verseNumber);
      _dragSelectionAnchor = verseNumber;
    });
    widget.onSelectionModeChanged?.call(true);
  }

  /// Chapter-bar entry to selection mode — used by the new "Select"
  /// IconButton in [_ChapterBar]. No anchor verse: user just taps
  /// individual verses to toggle them in/out of the selection. Bypasses
  /// the long-press requirement entirely, which is the path that's been
  /// flaky on web mouse + iOS-sim mouse + some Android variants. Drag-
  /// to-extend stays available for power users via the existing long-
  /// press lifecycle, but this is the reliable common path.
  void _enterSelectionModeFromBar() {
    setState(() {
      _selectionMode = true;
      _selectedVerses.clear();
      _dragSelectionAnchor = null;
    });
    widget.onSelectionModeChanged?.call(true);
    HapticFeedback.lightImpact();
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

  /// Animated 9:16 export — same selection rules as [_shareSelected],
  /// but routes through the animated-story sheet instead of the static
  /// verse-card flow.
  void _shareSelectedAsStory() {
    final rangeRef = _buildRangeRef();
    final text = _buildSelectedText();
    showAnimatedStorySheet(
      context,
      reference: rangeRef,
      verseText: text,
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
    final scholarMode = ref.watch(settingsProvider.select((s) => s.scholarMode));
    final redLetterMode =
        ref.watch(settingsProvider.select((s) => s.redLetterMode));
    final blueLetterMode =
        ref.watch(settingsProvider.select((s) => s.blueLetterMode));
    // Trigger Strong's load in the background as soon as Scholar Mode is on.
    if (scholarMode) {
      ref.watch(strongsServiceProvider);
    }
    // Trigger red-letter dataset load if either color mode is on.
    final redLetterSvc = (redLetterMode || blueLetterMode)
        ? ref.watch(redLetterServiceProvider)
        : null;
    // Tap recognisers are owned by State; rebuild allocates fresh ones to
    // match the new spans. (Cheap — recognisers are tiny.)
    _resetTapRecognizers();
    // Lazy GlobalKey cache — only create keys for new verse numbers
    if (verseKeys != null) {
      for (final v in chapter.verses) {
        verseKeys!.putIfAbsent(v.number, () => GlobalKey());
      }
    }
    return Listener(
      // ── Web/desktop click-and-drag selection ──
      // On touch the existing onLongPressMoveUpdate handles drag-extend.
      // On web/desktop, that gesture requires holding the mouse still for
      // 500 ms before moving — unnatural for a text-selection-style
      // interaction. Listener fires on every PointerMove regardless of
      // hold duration. We only react when the user is already in
      // selection mode (entered via long-press OR the modal's "Select
      // multiple" affordance) AND a primary button is held, so this
      // never interferes with normal scroll.
      behavior: HitTestBehavior.translucent,
      onPointerMove: (event) {
        if (!_selectionMode) return;
        if (event.buttons & kPrimaryButton == 0) return;
        if (_dragSelectionAnchor == null) return;
        _extendDragSelectionTo(event.position);
      },
      // ── SelectionArea ──
      // User-reported: drag-to-select a few words to copy was almost
      // impossible. The custom multi-verse selection mode only does
      // whole verses; partial-text copy (the single most common Bible-
      // study action) had no good path.
      //
      // SelectionArea (Flutter 3.7+) hands selection back to the
      // platform: native click+drag on web/desktop, native long-press +
      // drag handles on iOS/Android, system Copy / Look Up / Translate
      // menu out-of-the-box. ⌘C / Ctrl+C / right-click → Copy work.
      // Standard pattern matched by every modern reading app
      // (Pocket, Substack, Medium, Books.app).
      //
      // Multi-verse Select mode (✓ icon in chapter bar) is unchanged
      // — that flow still does whole-verse selection with reference
      // attribution, exactly as before.
      child: SelectionArea(
        child: Stack(
        // Tight constraints — same fix class as home_screen Stack. Without
        // fit:expand, the inner ListView gets unbounded vertical and can't
        // compute its viewport.
        fit: StackFit.expand,
        children: [
          Container(
        color: isDark ? const Color(0xFF2B1E19) : BrandColors.parchment,
        child: ListView.builder(
      controller: scrollController,
      // BouncingScrollPhysics: iOS-style fling + edge bounce on swipe.
      // AlwaysScrollableScrollPhysics keeps the surface interactive
      // when the chapter is short (e.g. 3 John has 14 verses).
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
          // ── Trojan horse: drop-cap is the front door to Strong's ──
          // Even when scholarMode is OFF, tapping the ornate drop-cap opens
          // the lexicon for the verse's first significant word. The tile
          // is the most attention-grabbing element on the page; binding
          // it to the lookup means users discover the feature visually
          // rather than via Settings spelunking. The recognizer on the
          // TextSpan wins over the parent InkWell when tapped directly.
          final dropCapStrongs = ref
              .read(strongsServiceProvider)
              .wordsForVerse(book, chapterNum, v.number);
          StrongsWord? dropCapHit;
          for (final w in dropCapStrongs) {
            if (w.strongs != null && w.strongs!.isNotEmpty) {
              dropCapHit = w;
              break;
            }
          }
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
                          // Drop cap inherits red/blue color when the
                          // first word of the verse is colored — keeps
                          // the visual consistency of red-letter Bibles
                          // (the drop cap is part of the spoken word).
                          // Otherwise falls back to the gold accent.
                          color: () {
                            if (redLetterSvc != null) {
                              final entry = redLetterSvc.forVerse(
                                  book, chapterNum, v.number);
                              if (redLetterMode && entry.isRed(0)) {
                                return BrandColors.redLetter;
                              }
                              if (blueLetterMode && entry.isBlue(0)) {
                                return BrandColors.blueLetter;
                              }
                            }
                            return isDark
                                ? BrandColors.gold
                                : BrandColors.goldDark;
                          }(),
                          height: 0.85,
                        ),
                        recognizer: dropCapHit == null
                            ? null
                            : _newRecognizer(() {
                                HapticFeedback.selectionClick();
                                _openStrongs(
                                  dropCapHit!,
                                  verseRef:
                                      '$book $chapterNum:${v.number}',
                                );
                              }),
                      ),
                      ..._buildVerseSpans(
                        verse: v,
                        book: book,
                        chapterNum: chapterNum,
                        theme: theme,
                        fontSize: fontSize,
                        scholarMode: scholarMode,
                        strongs: scholarMode
                            ? ref
                                .read(strongsServiceProvider)
                                .wordsForVerse(book, chapterNum, v.number)
                            : const [],
                        redLetter: redLetterSvc?.forVerse(
                                book, chapterNum, v.number) ??
                            const RedLetterEntry(),
                        redLetterMode: redLetterMode,
                        blueLetterMode: blueLetterMode,
                        baseStyle: GoogleFonts.lora(
                          fontSize: fontSize,
                          height: 1.7,
                          color: theme.colorScheme.onSurface,
                        ),
                        skipFirstLetter: firstLetter,
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
            // ── Drag-to-select with VoiceOver-friendly action ──
            // I3 a11y review: previously the drag gesture had no
            // alternative path for Switch Control / Voice Control
            // users. Wrap in Semantics with `customSemanticsActions`
            // exposing "Add to selection" so AT users can invoke it
            // without performing the long-press-and-drag gesture.
            child: Semantics(
              customSemanticsActions: {
                CustomSemanticsAction(label: 'Add to selection'):
                    () => _toggleVerse(v.number),
              },
              child: GestureDetector(
              // Long-press LIFECYCLE so we can track drag-to-extend.
              // onLongPressStart: enter selection mode + capture anchor.
              // onLongPressMoveUpdate: as user slides finger, extend
              //   selection to whichever verse is currently under the
              //   pointer (Claude/iOS Mail-style multi-select).
              // onLongPressEnd: keep the selection but stop tracking.
              behavior: HitTestBehavior.translucent,
              onLongPressStart: (details) {
                HapticFeedback.mediumImpact();
                _startSelection(v.number);
              },
              onLongPressMoveUpdate: (details) {
                _extendDragSelectionTo(details.globalPosition);
              },
              onLongPressEnd: (_) {
                _dragSelectionAnchor = null;
              },
              child: InkWell(
              onTap: () {
                if (_selectionMode) {
                  _toggleVerse(v.number);
                } else {
                  HapticFeedback.lightImpact();
                  _showVerseSheet(context, ref0, v, theme);
                }
              },
              child: RichText(
                // Honour iOS Dynamic Type + Android font scaling (WCAG
                // 1.4.4) by reading the system text-scale and passing it
                // through to verseStyle. Without this, low-vision users
                // see no change when they bump system text size up.
                textScaler: MediaQuery.textScalerOf(context),
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
                      // goldDark passes WCAG AA contrast on cream
                      // (~4.7:1); the plain `gold` would fail.
                      style: BrandColors.verseNumberStyle(
                        color: BrandColors.goldDark,
                      ).copyWith(fontSize: fontSize - 4),
                    ),
                    ..._buildVerseSpans(
                      verse: v,
                      book: book,
                      chapterNum: chapterNum,
                      theme: theme,
                      fontSize: fontSize,
                      scholarMode: scholarMode,
                      strongs: scholarMode
                          ? ref
                              .read(strongsServiceProvider)
                              .wordsForVerse(book, chapterNum, v.number)
                          : const [],
                      redLetter: redLetterSvc?.forVerse(
                              book, chapterNum, v.number) ??
                          const RedLetterEntry(),
                      redLetterMode: redLetterMode,
                      blueLetterMode: blueLetterMode,
                      baseStyle: BrandColors.verseStyle(
                        size: fontSize,
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
              ), // closes inner InkWell
            ),
            ), // closes Semantics customSemanticsActions wrapper
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
                  // Animated 9:16 story
                  IconButton(
                    icon: const Icon(Icons.movie_filter, size: 20, color: Colors.white),
                    tooltip: 'Share as story',
                    onPressed: _shareSelectedAsStory,
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
      ),
      ), // close SelectionArea
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
            const SizedBox(height: 18),
            // ── Primary CTA: Original language ──
            // E1 review identified choice paralysis from 9 equal-weight
            // actions. The single highest-value moment when a user taps
            // a verse is the curiosity that drives word-study; promoting
            // it to a gold pill button (vs one-of-nine TextButton) makes
            // the "aha" path obvious in one tap. Helper subtext explains
            // the action since "Original language" is jargon-adjacent.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.translate, size: 18),
                label: const Text('See the original Greek / Hebrew'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.gold,
                  foregroundColor: const Color(0xFF3E2723),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final wasOn =
                      widget.ref.read(settingsProvider).scholarMode;
                  if (!wasOn) {
                    widget.ref
                        .read(settingsProvider.notifier)
                        .setScholarMode(true);
                  }
                  Navigator.pop(sheetContext);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(wasOn
                          ? 'Tap any underlined word for Greek/Hebrew'
                          : 'Word study turned on — tap any underlined word'),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'My Lexicon',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyLexiconScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // ── Common secondary actions ──
            // Copy / Share / Bookmark / Find similar / Cross-references —
            // the operations a user performs most often per verse.
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
                // ── More overflow ──
                // 9:16 animated story + Select multiple are powerful but
                // less frequent. Tucking them behind a "More" overflow
                // (PopupMenuButton) keeps the primary surface clean
                // while still offering full power for users who want it.
                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  icon: Icon(Icons.more_horiz,
                      color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (action) {
                    Navigator.pop(sheetContext);
                    if (action == 'story') {
                      final translation =
                          widget.ref.read(settingsProvider).translation;
                      final versionName =
                          translationById(translation).name;
                      showAnimatedStorySheet(
                        context,
                        reference: '$refId ($versionName)',
                        verseText: v.text,
                      );
                    } else if (action == 'select') {
                      _enterSelectionFromModal(v.number);
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Drag down or tap verses to add'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'story',
                      child: ListTile(
                        leading: Icon(Icons.movie_filter),
                        title: Text('Animated story (9:16)'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'select',
                      child: ListTile(
                        leading: Icon(Icons.checklist),
                        title: Text('Select multiple verses'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
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
    required this.scholarMode,
    required this.onToggleScholar,
    required this.translationId,
    required this.onPickTranslation,
    required this.onEnterSelectionMode,
    required this.selectionActive,
  });

  final String book;
  final int chapter;
  final int max;
  final ValueChanged<int> onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onListen;
  /// Current Scholar-Mode (Strong's) state — drives the toggled appearance
  /// of the translate icon so the user can tell at a glance whether word-
  /// tapping is active.
  final bool scholarMode;
  /// Flips Scholar Mode and shows a one-line snackbar so first-time users
  /// learn what just happened. Persistent on-screen affordance => the most
  /// important discoverability fix from the UX review.
  final VoidCallback onToggleScholar;
  /// Currently selected Bible translation id (e.g. "kjv", "web", "BSB").
  /// Drives the label on the translation chip in the bar.
  final String translationId;
  /// Opens the translation picker. The user could already do this via
  /// Settings → Translation, but that's 3 taps from the read screen and
  /// most users want quick A/B comparison while reading. This shortcut
  /// lands them on the picker in one tap.
  final VoidCallback onPickTranslation;
  /// Enters selection mode without requiring a long-press. Tapped via the
  /// "Select" icon in the chapter bar. Once entered, subsequent verse
  /// taps toggle into the selection — same UX as iOS Mail / Files Edit.
  final VoidCallback onEnterSelectionMode;
  /// Whether selection mode is currently active — toggles the "Select"
  /// icon's filled state so users see they're in selection mode.
  final bool selectionActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reported overflow on narrow phones (iPhone 17 sim, 393 px wide):
    // Chapter label was colliding with the translation chip because the
    // Row content totaled ~494 px. Compact mode shrinks chevrons/kebab,
    // drops the "Chapter " prefix, and trims paddings to fit comfortably
    // on phones ≤400 px wide. ≥400 px keeps the spacious layout.
    final isNarrow = MediaQuery.of(context).size.width < 420;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 4 : 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous chapter',
            visualDensity:
                isNarrow ? VisualDensity.compact : VisualDensity.standard,
            onPressed: chapter > 1 ? onPrev : null,
          ),
          Expanded(
            child: Center(
              child: TextButton(
                style: isNarrow
                    ? TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      )
                    : null,
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
                    Text(
                      // Drop the "Chapter " prefix on narrow phones —
                      // saves ~55 px which the translation chip needs.
                      // On wide screens keep the full label for clarity.
                      isNarrow
                          ? '$chapter / $max'
                          : 'Chapter $chapter / $max',
                      style: TextStyle(
                          fontSize: isNarrow ? 14 : 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.grid_view, size: isNarrow ? 14 : 16),
                  ],
                ),
              ),
            ),
          ),
          // ── Translation switcher ──
          // Prominent chip that shows the current translation (KJV, WEB,
          // NIV, etc.) and opens the picker on tap. Previously users had
          // to dive into Settings → Translation to switch — now it's a
          // one-tap action while reading. Useful for A/B comparing
          // translations on the same verse, which preachers and study-
          // group leaders do constantly.
          InkWell(
            onTap: onPickTranslation,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 10,
                  vertical: isNarrow ? 4 : 5),
              decoration: BoxDecoration(
                color: BrandColors.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BrandColors.gold.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drop the leading book icon on narrow screens — the
                  // gold chip is already visually distinct enough.
                  if (!isNarrow) ...[
                    Icon(Icons.menu_book_rounded,
                        size: 13, color: BrandColors.brownDeep),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    translationById(translationId).name,
                    style: TextStyle(
                      fontSize: isNarrow ? 11 : 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: BrandColors.brownDeep,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.unfold_more,
                      size: isNarrow ? 12 : 14,
                      color: BrandColors.brownDeep),
                ],
              ),
            ),
          ),
          SizedBox(width: isNarrow ? 2 : 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next chapter',
            visualDensity:
                isNarrow ? VisualDensity.compact : VisualDensity.standard,
            onPressed: chapter < max ? onNext : null,
          ),
          // ── Word-study toggle (always visible discovery affordance) ──
          // Even users who never open Settings will see this icon while
          // reading. Tooltip + snackbar do the explaining; the toggled
          // gold pill confirms the state. Replaces "Scholar Mode" jargon
          // with an icon pattern users already recognise (Google
          // Translate, etc.).
          // ── Reading menu (kebab) ──
          // User feedback: chapter bar overflowed on iOS — too many
          // standalone icons (translate, select, settings) competing
          // with chevrons + chapter picker + translation chip + Listen.
          // Consolidating the three secondary actions into a single
          // PopupMenuButton saves ~96 px and keeps the bar tidy on
          // narrow phones, while the primary actions stay one-tap.
          PopupMenuButton<String>(
            tooltip: 'Reading menu',
            padding: EdgeInsets.zero,
            iconSize: isNarrow ? 20 : 24,
            icon: Icon(
              Icons.more_vert,
              color: (scholarMode || selectionActive)
                  ? BrandColors.goldDark
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (action) {
              switch (action) {
                case 'scholar':
                  onToggleScholar();
                case 'select':
                  onEnterSelectionMode();
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'scholar',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.translate,
                      color: scholarMode ? BrandColors.goldDark : null),
                  title: Text(scholarMode
                      ? 'Word study  ✓'
                      : 'Word study (Greek/Hebrew)'),
                ),
              ),
              PopupMenuItem(
                value: 'select',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selectionActive
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color:
                        selectionActive ? BrandColors.goldDark : null,
                  ),
                  title: Text(selectionActive
                      ? 'Selecting verses…'
                      : 'Select multiple verses'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.tune),
                  title: Text('Reading settings'),
                ),
              ),
            ],
          ),
          SizedBox(width: isNarrow ? 0 : 2),
          GestureDetector(
            onTap: onListen,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 10,
                  vertical: isNarrow ? 5 : 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BrandColors.goldLight, BrandColors.gold],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headphones,
                      size: isNarrow ? 14 : 16,
                      color: const Color(0xFF3E2723)),
                  const SizedBox(width: 4),
                  Text('Listen',
                      style: TextStyle(
                        fontSize: isNarrow ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3E2723),
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
