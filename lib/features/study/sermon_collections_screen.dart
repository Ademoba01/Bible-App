import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/providers.dart';
import '../../theme.dart';

/// Sermon Notes — the pastor's primary surface for collecting Strong's
/// insights into named series ("Easter 2026", "Series on Love"). Each
/// collection is an ordered list of [SermonInsight]s captured from the
/// "Add to sermon" affordance in the Strong's sheet.
///
/// This screen lists collections and pushes [SermonCollectionDetailScreen]
/// on tap. Pull-up shows a "+" FAB to create a new collection.
class SermonCollectionsScreen extends ConsumerWidget {
  const SermonCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collections = ref.watch(sermonCollectionsProvider);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        title: Text('Sermon Notes',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCollection(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New series'),
        backgroundColor: BrandColors.gold,
        foregroundColor: const Color(0xFF3E2723),
      ),
      body: collections.isEmpty
          ? _Empty(theme: theme)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: collections.length,
              itemBuilder: (context, i) {
                final c = collections[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SermonCollectionDetailScreen(collectionId: c.id),
                        ),
                      ),
                      onLongPress: () =>
                          _collectionMenu(context, ref, c.id, c.title),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    BrandColors.gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.menu_book_rounded,
                                  color: BrandColors.brownDeep, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c.insights.length} ${c.insights.length == 1 ? "insight" : "insights"}',
                                    style: GoogleFonts.lora(
                                      fontSize: 12,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _createCollection(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New sermon series'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. "Easter 2026" or "Series on Love"',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (title == null) return;
    await ref
        .read(sermonCollectionsProvider.notifier)
        .createCollection(title);
  }

  Future<void> _collectionMenu(
      BuildContext context, WidgetRef ref, String id, String title) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () => Navigator.pop(context, 'rename')),
            ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(context, 'delete')),
          ],
        ),
      ),
    );
    if (action == 'rename') {
      final controller = TextEditingController(text: title);
      final next = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Rename series'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, controller.text.trim()),
                child: const Text('Save')),
          ],
        ),
      );
      if (next != null && next.isNotEmpty) {
        await ref
            .read(sermonCollectionsProvider.notifier)
            .renameCollection(id, next);
      }
    } else if (action == 'delete') {
      await ref
          .read(sermonCollectionsProvider.notifier)
          .deleteCollection(id);
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              'No sermon series yet',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create one. While studying a verse, tap a word and "Add to sermon" to drop the insight here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail screen — lists every [SermonInsight] inside a collection. Each
/// row shows the original word, the verse ref, and the pastor's note.
/// Long-press a row to delete; "Export" emits a plain-text dump that can
/// be shared via share_plus (PDF/image rendering is a follow-up).
class SermonCollectionDetailScreen extends ConsumerWidget {
  const SermonCollectionDetailScreen({super.key, required this.collectionId});
  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collections = ref.watch(sermonCollectionsProvider);
    final c = collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => SermonCollection(
          id: '', title: '—', insights: const [], createdAt: DateTime.now()),
    );
    if (c.id.isEmpty) {
      // Collection was deleted — bounce back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : BrandColors.parchment,
      appBar: AppBar(
        title: Text(c.title,
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          if (c.insights.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export',
              onPressed: () => _export(context, c),
            ),
        ],
      ),
      body: c.insights.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'No insights yet.\nTap a word in any verse and choose "Add to sermon" to drop it here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: c.insights.length,
              itemBuilder: (context, i) {
                final insight = c.insights[i];
                return Dismissible(
                  key: ValueKey('${insight.strongsId}-${insight.createdAt}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ref
                      .read(sermonCollectionsProvider.notifier)
                      .removeInsight(c.id, i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: BrandColors.gold
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                insight.strongsId,
                                style: GoogleFonts.lora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BrandColors.brownDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              insight.verseRef,
                              style: GoogleFonts.lora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '"${insight.word}"',
                              style: GoogleFonts.lora(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (insight.note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            insight.note,
                            style: GoogleFonts.lora(
                              fontSize: 14,
                              height: 1.4,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _export(BuildContext context, SermonCollection c) {
    final buffer = StringBuffer();
    buffer.writeln('${c.title} — Sermon Notes');
    buffer.writeln('${c.insights.length} ${c.insights.length == 1 ? "insight" : "insights"}');
    buffer.writeln('');
    for (final i in c.insights) {
      buffer.writeln('${i.verseRef} — "${i.word}" (${i.strongsId})');
      if (i.note.isNotEmpty) buffer.writeln(i.note);
      buffer.writeln('');
    }
    buffer.writeln('— Rhema Study Bible');
    Share.share(buffer.toString(), subject: c.title);
  }
}
