import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'verse_card_templates.dart';

/// Renders [VerseCardTemplate] widgets to PNG bytes and shares them through
/// the platform share sheet via `share_plus`.
///
/// We render the card off-screen by attaching it (wrapped in a
/// [RepaintBoundary] keyed by a [GlobalKey]) to a transient [Overlay]. After
/// one frame, [RenderRepaintBoundary.toImage] gives us pixel-perfect bytes
/// independent of the visible UI.
class VerseCardRenderer {
  /// Builds the verse card off-screen and returns PNG bytes. Returns `null`
  /// if rendering fails (e.g. the boundary never lays out).
  static Future<Uint8List?> render({
    required BuildContext context,
    required String verseText,
    required String reference,
    required VerseCardStyle style,
    double pixelRatio = 3.0,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final boundaryKey = GlobalKey();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        // Render the card off-screen but laid out at its native 1080x1080
        // size. `IgnorePointer` keeps it inert; `Offstage` would skip layout,
        // so we instead position it well outside the viewport.
        return Positioned(
          left: -VerseCardTemplate.cardSize - 100,
          top: -VerseCardTemplate.cardSize - 100,
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: boundaryKey,
                child: VerseCardTemplate().build(
                  ctx,
                  verseText: verseText,
                  reference: reference,
                  style: style,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      // Wait for the overlay to be laid out and any GoogleFonts assets to
      // finish loading before we capture pixels.
      await _waitForFrame();
      await GoogleFonts.pendingFonts();
      // Second frame to ensure fonts that just loaded are painted.
      await _waitForFrame();

      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // If the boundary still needs paint, give it one more frame.
      if (boundary.debugNeedsPaint) {
        await _waitForFrame();
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      entry.remove();
    }
  }

  /// Shows a bottom sheet of style choices, renders the chosen card to PNG,
  /// writes it to a temp file and triggers the platform share sheet.
  static Future<void> shareVerseCard({
    required BuildContext context,
    required String verseText,
    required String reference,
  }) async {
    final picked = await _pickStyle(context);
    if (picked == null) return;
    if (!context.mounted) return;

    // Show a brief progress indicator while we render.
    final messenger = ScaffoldMessenger.of(context);
    final progress = messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Creating verse card...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    final bytes = await render(
      context: context,
      verseText: verseText,
      reference: reference,
      style: picked,
    );
    progress.close();

    if (bytes == null) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not create verse card. Sharing as text instead.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Fallback: plain text share so the user is never stuck.
      await Share.share(
        '$reference\n$verseText\n\n— Rhema Study Bible\nhttps://rhemabibles.com',
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final safeRef = reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final file = File('${dir.path}/rhema_verse_${safeRef}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'rhema_$safeRef.png')],
        text: '$reference\n\nFrom Rhema Study Bible — https://rhemabibles.com',
        subject: 'A verse from Rhema Study Bible',
      );
    } catch (_) {
      // Fallback to text share if file IO or platform share fails.
      await Share.share(
        '$reference\n$verseText\n\n— Rhema Study Bible\nhttps://rhemabibles.com',
      );
    }
  }

  static Future<VerseCardStyle?> _pickStyle(BuildContext context) {
    return showModalBottomSheet<VerseCardStyle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Choose a card style',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Share as a beautiful image',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: VerseCardStyle.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      final style = VerseCardStyle.values[i];
                      final spec = VerseCardStyleSpec.forStyle(style);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(sheetCtx).pop(style),
                        child: SizedBox(
                          width: 120,
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: spec.gradientBegin,
                                    end: spec.gradientEnd,
                                    colors: spec.gradient,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.format_quote,
                                  size: 36,
                                  color: spec.textColor.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                spec.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _waitForFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
