import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../../state/providers.dart';
import '../../theme.dart';

// ---------------------------------------------------------------------------
// Study Notes — personal note-taking tied to Bible study.
// ---------------------------------------------------------------------------

/// A single study note.
class StudyNote {
  final int id; // millisecondsSinceEpoch
  final String title;
  final String content;
  final DateTime date;
  final String? relatedVerse; // e.g. "John 3:16"

  const StudyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.relatedVerse,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'relatedVerse': relatedVerse,
      };

  factory StudyNote.fromJson(Map<String, dynamic> j) => StudyNote(
        id: j['id'] as int,
        title: j['title'] as String,
        content: j['content'] as String,
        date: DateTime.parse(j['date'] as String),
        relatedVerse: j['relatedVerse'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

const _kNotesKey = 'study_notes';

Future<List<StudyNote>> _loadNotes(SharedPreferences prefs) async {
  final raw = prefs.getString(_kNotesKey);
  if (raw == null || raw.isEmpty) return [];
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((e) => StudyNote.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> _saveNotes(SharedPreferences prefs, List<StudyNote> notes) async {
  final json = jsonEncode(notes.map((n) => n.toJson()).toList());
  await prefs.setString(_kNotesKey, json);
}

// ---------------------------------------------------------------------------
// StudyNotesScreen
// ---------------------------------------------------------------------------

class StudyNotesScreen extends ConsumerStatefulWidget {
  const StudyNotesScreen({super.key});

  @override
  ConsumerState<StudyNotesScreen> createState() => _StudyNotesScreenState();
}

class _StudyNotesScreenState extends ConsumerState<StudyNotesScreen> {
  List<StudyNote> _notes = [];
  bool _loading = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _notes = await _loadNotes(_prefs!);
    _notes.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addOrEditNote({StudyNote? existing}) async {
    final result = await showDialog<StudyNote>(
      context: context,
      builder: (_) => _NoteEditorDialog(note: existing),
    );
    if (result == null) return;

    setState(() {
      if (existing != null) {
        _notes.removeWhere((n) => n.id == existing.id);
      }
      _notes.insert(0, result);
      _notes.sort((a, b) => b.date.compareTo(a.date));
    });
    await _saveNotes(_prefs!, _notes);
  }

  Future<void> _deleteNote(StudyNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Note', style: GoogleFonts.lora()),
        content: Text('Are you sure you want to delete "${note.title}"?',
            style: GoogleFonts.lora()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await _saveNotes(_prefs!, _notes);
  }

  void _navigateToVerse(String verseRef) {
    // Parse "Book Chapter:Verse" — we navigate to the book & chapter.
    final match = RegExp(r'^(.+?)\s+(\d+)').firstMatch(verseRef);
    if (match == null) return;
    final book = match.group(1)!;
    final chapter = int.tryParse(match.group(2)!) ?? 1;
    ref.read(readingLocationProvider.notifier).setBook(book);
    ref.read(readingLocationProvider.notifier).setChapter(chapter);
    ref.read(tabIndexProvider.notifier).set(1); // switch to Read tab
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Notes', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrandColors.brown,
        foregroundColor: BrandColors.cream,
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1F4DD}', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: GoogleFonts.lora(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? BrandColors.cream : BrandColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to capture your first insight',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          color: BrandColors.brownMid,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return _NoteCard(
                      note: note,
                      isDark: isDark,
                      onTap: () => _addOrEditNote(existing: note),
                      onDelete: () => _deleteNote(note),
                      onVerseTap: note.relatedVerse != null
                          ? () => _navigateToVerse(note.relatedVerse!)
                          : null,
                    );
                  },
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note Card
// ---------------------------------------------------------------------------

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    this.onVerseTap,
  });

  final StudyNote note;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onVerseTap;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${note.date.month}/${note.date.day}/${note.date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B1E19) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: BrandColors.brownMid.withValues(alpha: isDark ? 0.15 : 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.brown.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + delete
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? BrandColors.cream : BrandColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20,
                      color: BrandColors.brownMid.withValues(alpha: 0.5)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Date
            Text(
              dateStr,
              style: GoogleFonts.lora(
                fontSize: 12,
                color: BrandColors.brownMid.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            // Content preview
            Text(
              note.content,
              style: GoogleFonts.lora(
                fontSize: 14,
                color: isDark
                    ? BrandColors.cream.withValues(alpha: 0.75)
                    : BrandColors.dark.withValues(alpha: 0.8),
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Related verse chip
            if (note.relatedVerse != null && note.relatedVerse!.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onVerseTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BrandColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 14,
                          color: BrandColors.gold.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text(
                        note.relatedVerse!,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.gold.withValues(alpha: 0.9),
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
}

// ---------------------------------------------------------------------------
// Note Editor Dialog
// ---------------------------------------------------------------------------

class _NoteEditorDialog extends ConsumerStatefulWidget {
  const _NoteEditorDialog({this.note});
  final StudyNote? note;

  @override
  ConsumerState<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<_NoteEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _verseCtrl;

  // Verse scanner state
  List<({VerseRef ref, String text})> _suggestedVerses = [];
  bool _scanning = false;
  Timer? _scanDebounce;

  static const _stopWords = <String>{
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'to', 'of', 'in', 'for',
    'and', 'but', 'or', 'not', 'with', 'this', 'that', 'it', 'be', 'as',
    'at', 'by', 'from', 'on', 'i', 'my', 'we', 'our', 'they', 'he', 'she',
    'his', 'her', 'do', 'does', 'did', 'have', 'has', 'had', 'will',
    'would', 'can', 'could', 'should', 'may', 'might', 'about', 'what',
    'when', 'where', 'how', 'who', 'which', 'been', 'being', 'also',
    'just', 'like', 'than', 'then', 'into', 'over', 'some', 'such',
    'them', 'there', 'these', 'those', 'very', 'your', 'more',
  };

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _verseCtrl =
        TextEditingController(text: widget.note?.relatedVerse ?? '');
  }

  @override
  void dispose() {
    _scanDebounce?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _verseCtrl.dispose();
    super.dispose();
  }

  /// Scans note text for keywords and finds related Bible verses.
  Future<List<({VerseRef ref, String text})>> _scanForRelatedVerses(
      String noteText) async {
    if (noteText.trim().length < 10) return [];
    final repo = ref.read(bibleRepositoryProvider);

    // Extract key words (remove common/short words)
    final words = noteText
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3 && !_stopWords.contains(w))
        .toSet()
        .take(5)
        .toList();

    if (words.isEmpty) return [];

    final results = <({VerseRef ref, String text})>[];
    for (final word in words) {
      final found = await repo.search(word, limit: 3);
      for (final r in found) {
        if (!results.any((x) => x.ref.id == r.ref.id)) {
          results.add(r);
        }
      }
      if (results.length >= 10) break;
    }
    return results;
  }

  void _onContentChanged(String text) {
    _scanDebounce?.cancel();
    if (text.trim().length < 10) {
      setState(() => _suggestedVerses = []);
      return;
    }
    _scanDebounce = Timer(const Duration(milliseconds: 800), () {
      _triggerScan();
    });
  }

  Future<void> _triggerScan() async {
    final text = _contentCtrl.text;
    if (text.trim().length < 10) return;
    setState(() => _scanning = true);
    try {
      final results = await _scanForRelatedVerses(text);
      if (mounted) {
        setState(() {
          _suggestedVerses = results;
          _scanning = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _addSuggestedVerse(({VerseRef ref, String text}) verse) {
    final current = _verseCtrl.text.trim();
    final verseId = verse.ref.id;
    // Avoid duplicates
    if (current.contains(verseId)) return;
    if (current.isEmpty) {
      _verseCtrl.text = verseId;
    } else {
      _verseCtrl.text = '$current, $verseId';
    }
    setState(() {});
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    final verse = _verseCtrl.text.trim();
    final note = StudyNote(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      content: content,
      date: DateTime.now(),
      relatedVerse: verse.isEmpty ? null : verse,
    );
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.note != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: isDark ? const Color(0xFF2B1E19) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Note' : 'New Note',
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? BrandColors.cream : BrandColors.dark,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.lora(
                  color: isDark ? BrandColors.cream : BrandColors.dark,
                ),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.lora(color: BrandColors.brownMid),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BrandColors.brown, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Content
              TextField(
                controller: _contentCtrl,
                maxLines: 6,
                onChanged: _onContentChanged,
                style: GoogleFonts.lora(
                  color: isDark ? BrandColors.cream : BrandColors.dark,
                ),
                decoration: InputDecoration(
                  labelText: 'Your thoughts...',
                  alignLabelWithHint: true,
                  labelStyle: GoogleFonts.lora(color: BrandColors.brownMid),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BrandColors.brown, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Scan for verses button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _scanning ? null : _triggerScan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    _scanning ? 'Scanning...' : 'Scan for verses',
                    style: GoogleFonts.lora(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ),
              // Suggested verses section
              if (_suggestedVerses.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('\u2728', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Related verses found',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _suggestedVerses.map((v) {
                        final alreadyAdded =
                            _verseCtrl.text.contains(v.ref.id);
                        return Tooltip(
                          message: v.text.length > 80
                              ? '${v.text.substring(0, 80)}...'
                              : v.text,
                          child: ActionChip(
                            avatar: Icon(
                              alreadyAdded
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              size: 16,
                              color: alreadyAdded
                                  ? Colors.green
                                  : BrandColors.gold,
                            ),
                            label: Text(
                              v.ref.id,
                              style: GoogleFonts.lora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? BrandColors.cream
                                    : BrandColors.dark,
                              ),
                            ),
                            backgroundColor: alreadyAdded
                                ? Colors.green.withValues(alpha: 0.1)
                                : BrandColors.gold.withValues(alpha: 0.12),
                            side: BorderSide(
                              color: alreadyAdded
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : BrandColors.gold.withValues(alpha: 0.3),
                            ),
                            onPressed: alreadyAdded
                                ? null
                                : () => _addSuggestedVerse(v),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Related verse
              TextField(
                controller: _verseCtrl,
                style: GoogleFonts.lora(
                  color: isDark ? BrandColors.cream : BrandColors.dark,
                ),
                decoration: InputDecoration(
                  labelText: 'Related verse (optional)',
                  hintText: 'e.g. John 3:16',
                  hintStyle: GoogleFonts.lora(
                    color: BrandColors.brownMid.withValues(alpha: 0.5),
                  ),
                  labelStyle: GoogleFonts.lora(color: BrandColors.brownMid),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BrandColors.brown, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: GoogleFonts.lora(color: BrandColors.brownMid)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.brown,
                      foregroundColor: BrandColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isEditing ? 'Save' : 'Create',
                        style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
