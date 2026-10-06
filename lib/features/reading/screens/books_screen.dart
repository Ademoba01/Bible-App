import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/books.dart';
import '../../../data/models.dart';
import '../../../state/providers.dart';
import '../../../theme.dart';

/// Verse-selection result handed back up the picker stack:
///   • Tap a book, keep walking → bubbles {book, chapter, verse}.
///   • Tap "Chapter 1" shortcut on the chapter grid → {book, chapter, 1}.
/// Null means the user backed out before picking.
typedef VersePickResult = ({String book, int chapter, int verse});

/// Entry point of the Book → Chapter → Verse flow. User feedback was
/// that the previous flow (book list → pop → separately pick chapter
/// → verse 1) felt disjointed; now it's one directed walk and the
/// result always carries a specific verse so the reader can scroll +
/// highlight on arrival.
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ot = kAllBooks.where((b) => b.testament == 'OT').toList();
    final nt = kAllBooks.where((b) => b.testament == 'NT').toList();
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pick a passage'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor:
                theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            tabs: const [Tab(text: 'Old Testament'), Tab(text: 'New Testament')],
          ),
        ),
        body: TabBarView(
          children: [_BookList(ot), _BookList(nt)],
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList(this.books);
  final List<BookInfo> books;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final b = books[i];
        return ListTile(
          title: Text(b.name, style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            // Push the chapter picker for this book. The chapter picker
            // (and the verse picker it pushes) return a VersePickResult
            // up through this handler; we pop BooksScreen with the same
            // result so the reader opens exactly where the user picked.
            final result = await Navigator.of(context).push<VersePickResult>(
              MaterialPageRoute(
                builder: (_) => _ChapterPickerScreen(book: b.name),
              ),
            );
            if (result != null && context.mounted) {
              Navigator.of(context).pop(result);
            }
          },
        );
      },
    );
  }
}

/// Stage 2: a chapter grid for a single book. User can either tap a
/// chapter number (walks on to the verse picker) or tap the "Read from
/// verse 1" shortcut below the grid (jumps straight into the chapter).
class _ChapterPickerScreen extends ConsumerStatefulWidget {
  const _ChapterPickerScreen({required this.book});
  final String book;

  @override
  ConsumerState<_ChapterPickerScreen> createState() =>
      _ChapterPickerScreenState();
}

class _ChapterPickerScreenState extends ConsumerState<_ChapterPickerScreen> {
  int? _chapterCount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapterCount();
  }

  Future<void> _loadChapterCount() async {
    try {
      final repo = ref.read(bibleRepositoryProvider);
      final translation = ref.read(settingsProvider).translation;
      final chapters =
          await repo.loadBook(widget.book, translationId: translation);
      if (!mounted) return;
      setState(() => _chapterCount = chapters.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text("Couldn't load ${widget.book}: $_error"),
        ),
      );
    }
    if (_chapterCount == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final count = _chapterCount!;
    final width = MediaQuery.of(context).size.width;
    final cols = width < 400 ? 5 : width < 600 ? 6 : 8;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.menu_book, size: 18, color: BrandColors.brownDeep),
              const SizedBox(width: 8),
              Text(
                'Chapter',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.brownDeep,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: count,
            itemBuilder: (_, i) {
              final c = i + 1;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  // Push the verse picker. If it returns a verse number,
                  // bubble the full tuple up.
                  final result = await Navigator.of(context).push<int>(
                    MaterialPageRoute(
                      builder: (_) => _VersePickerScreen(
                        book: widget.book,
                        chapter: c,
                      ),
                    ),
                  );
                  if (result != null && mounted) {
                    Navigator.of(context).pop<VersePickResult>(
                      (book: widget.book, chapter: c, verse: result),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$c',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.brownDeep,
                    ),
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

/// Stage 3: a verse list for one chapter. Shows every verse number
/// with a short preview of its text so the user can recognize the
/// one they want. Tap pops just the verse number back; the chapter
/// screen above wraps it into the full tuple.
///
/// A "Read whole chapter" tile at the top is the escape hatch for
/// users who don't want to pick a specific verse — it returns 1,
/// which the reader interprets as "scroll to top, no highlight".
class _VersePickerScreen extends ConsumerStatefulWidget {
  const _VersePickerScreen({required this.book, required this.chapter});
  final String book;
  final int chapter;

  @override
  ConsumerState<_VersePickerScreen> createState() => _VersePickerScreenState();
}

class _VersePickerScreenState extends ConsumerState<_VersePickerScreen> {
  List<String>? _verseTexts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    try {
      final repo = ref.read(bibleRepositoryProvider);
      final translation = ref.read(settingsProvider).translation;
      final chapters =
          await repo.loadBook(widget.book, translationId: translation);
      final chapter = chapters[(widget.chapter - 1).clamp(0, chapters.length - 1)];
      if (!mounted) return;
      setState(() => _verseTexts = chapter.verses.map((v) => v.text).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book} ${widget.chapter}'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text("Couldn't load verses: $_error"),
        ),
      );
    }
    final texts = _verseTexts;
    if (texts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: texts.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i == 0) {
          // Top row shortcut: open the chapter at verse 1 (no highlight)
          return ListTile(
            leading: Icon(Icons.auto_stories, color: BrandColors.gold),
            title: Text(
              'Read whole chapter',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${widget.book} ${widget.chapter} from the top'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pop(1),
          );
        }
        final verseNum = i; // because top row shifted
        final text = texts[verseNum - 1];
        return ListTile(
          leading: SizedBox(
            width: 28,
            child: Text(
              '$verseNum',
              textAlign: TextAlign.right,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BrandColors.gold,
              ),
            ),
          ),
          title: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lora(fontSize: 14, height: 1.4),
          ),
          onTap: () => Navigator.of(context).pop(verseNum),
        );
      },
    );
  }
}
