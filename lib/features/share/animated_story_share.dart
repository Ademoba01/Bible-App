import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme.dart';
import 'animated_story_renderer.dart';
import 'verse_card_templates.dart';

/// Public entrypoint — show the "Share as story" bottom sheet.
///
/// The sheet renders a looping live preview at ~32% scale (fits comfortably
/// on phone screens), lets the user pick from 5 visual styles, then on
/// "Save to Photos" captures the animation as an animated GIF and routes
/// it through the platform share sheet so the user can save to camera roll
/// or post directly to Instagram / TikTok / WhatsApp.
Future<void> showAnimatedStorySheet(
  BuildContext context, {
  required String reference,
  required String verseText,
  LatLng? center,
  Color? accentColor,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _AnimatedStorySheet(
      initialConfig: StoryConfig(
        reference: reference,
        verseText: verseText,
        center: center,
        accentColor: accentColor,
      ),
    ),
  );
}

class _AnimatedStorySheet extends StatefulWidget {
  const _AnimatedStorySheet({required this.initialConfig});
  final StoryConfig initialConfig;

  @override
  State<_AnimatedStorySheet> createState() => _AnimatedStorySheetState();
}

class _AnimatedStorySheetState extends State<_AnimatedStorySheet>
    with TickerProviderStateMixin {
  late StoryConfig _config;
  late AnimationController _previewController;
  late AnimationController _confettiController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _previewController = AnimationController(
      vsync: this,
      duration: StoryGeometry.totalDuration,
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Drive a continuous loop with a brief pause at the end so users see
    // the final composed frame before it restarts.
    _previewController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) {
            _previewController.forward(from: 0);
            _confettiController.forward(from: 0);
          }
        });
      }
    });
    _previewController.addListener(() {
      // Fire confetti when reference appears (~75% of the way through).
      if (_previewController.value >= 0.75 &&
          _confettiController.status == AnimationStatus.dismissed) {
        _confettiController.forward(from: 0);
      }
    });
    _previewController.forward();
  }

  @override
  void dispose() {
    _previewController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _selectStyle(VerseCardStyle style) {
    setState(() => _config = _config.copyWith(style: style));
    _previewController.forward(from: 0);
    _confettiController.reset();
  }

  Future<void> _onSavePressed() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 30),
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Rendering your story...'),
          ],
        ),
      ),
    );

    try {
      final bytes = await AnimatedStoryExporter.renderGif(
        context: context,
        config: _config,
      );
      messenger.hideCurrentSnackBar();
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not create story. Sharing as text instead.')),
        );
        await Share.share(
          '${_config.reference}\n${_config.verseText}\n\n— Rhema Study Bible\nhttps://rhemabibles.com',
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final safeRef = _config.reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/rhema_story_${safeRef}_$ts.gif');
      await file.writeAsBytes(bytes, flush: true);

      // share_plus on iOS routes through the system share sheet — user
      // can tap "Save Image" to drop the GIF straight into Photos.
      // On Android the same sheet exposes "Save to gallery" via most
      // file-handler apps (Files, Photos, etc.).
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/gif', name: 'rhema_story_$safeRef.gif')],
        text: '${_config.reference}\n\nFrom Rhema Study Bible — https://rhemabibles.com',
        subject: 'A verse from Rhema Study Bible',
      );
    } catch (e) {
      debugPrint('Animated story export failed: $e');
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Story export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share as story',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '9:16 animated — ready for IG / TikTok / WhatsApp',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                // Live preview — animated 9:16 frame at 32% scale.
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: StoryGeometry.width * StoryGeometry.previewScale,
                      height: StoryGeometry.height * StoryGeometry.previewScale,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: AnimatedBuilder(
                          animation: _previewController,
                          builder: (_, __) => AnimatedStoryFrame(
                            config: _config,
                            progress: _previewController.value,
                            lottieController: _confettiController,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Style chips (same 5 palettes used by the static verse-card share).
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: VerseCardStyle.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final style = VerseCardStyle.values[i];
                      final spec = VerseCardStyleSpec.forStyle(style);
                      final selected = _config.style == style;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _selectStyle(style),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: spec.gradientBegin,
                              end: spec.gradientEnd,
                              colors: spec.gradient,
                            ),
                            border: Border.all(
                              color: selected
                                  ? BrandColors.goldDeep
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spec.label,
                                style: TextStyle(
                                  color: spec.textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                // Save button.
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _onSavePressed,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share, size: 22),
                  label: Text(
                    _isExporting ? 'Rendering...' : 'Save to Photos',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.goldDeep,
                    foregroundColor: BrandColors.darkDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: From the share sheet, choose "Save Image" to drop it in your camera roll.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Captures the animated story to an animated GIF.
///
/// Implementation notes — why GIF, not MP4:
///   * MP4 from Flutter without ffmpeg means platform-specific native
///     plugins (AVFoundation on iOS, MediaCodec on Android), each adding
///     several MB to the bundle. The `image` package (already used by
///     `tools/make_brand_assets.dart`) ships with a pure-Dart GIF encoder
///     and adds zero native deps.
///   * iOS Photos accepts animated GIFs and treats them as Live-Photo-like
///     loops. Instagram / TikTok / WhatsApp all post-process GIFs into MP4
///     server-side, so the end-user experience matches "real" video.
///
/// We render at 540x960 (half resolution) to keep file size reasonable —
/// 12 fps × 2.4s = 30 frames, roughly 1.5–3 MB per export.
class AnimatedStoryExporter {
  static const int _exportWidth = 540;
  static const int _exportHeight = 960;
  static const int _frameCount = 30; // 12 fps over 2.5s
  static const int _frameDelayCs = 8; // 8 centiseconds = 80ms ≈ 12 fps
  static const double _exportPixelRatio = 1.0; // 540 * 1.0 == 540 px wide

  /// Render the animated story to GIF bytes, or null on failure.
  static Future<Uint8List?> renderGif({
    required BuildContext context,
    required StoryConfig config,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final boundaryKey = GlobalKey();
    // We control progress imperatively so we can scrub through frames.
    final progressNotifier = ValueNotifier<double>(0.0);
    final lottieController = AnimationController(
      vsync: _TickerProviderShim(),
      duration: const Duration(milliseconds: 1200),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        // Render at the export resolution so the captured frames match
        // the output without expensive 1080-wide rasterisation we'd just
        // resize down anyway. FittedBox(fit: BoxFit.fill) scales the
        // 1080x1920 [AnimatedStoryFrame] down to a 540x960 canvas before
        // [RenderRepaintBoundary.toImage] rasterises.
        return Positioned(
          left: -_exportWidth - 200,
          top: -_exportHeight - 200,
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (_, p, __) => RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox(
                    width: _exportWidth.toDouble(),
                    height: _exportHeight.toDouble(),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: AnimatedStoryFrame(
                        config: config,
                        progress: p,
                        lottieController: lottieController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      // Wait until the off-screen tree has laid out + fonts have arrived.
      await _waitForFrame();
      await GoogleFonts.pendingFonts();
      await _waitForFrame();
      await _waitForFrame();
      // Lottie compositions need a frame after first build to be ready.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Build the GIF frame-by-frame.
      final gif = img.GifEncoder(
        repeat: 0, // 0 = loop forever
        delay: _frameDelayCs,
      );

      for (int i = 0; i < _frameCount; i++) {
        final t = i / (_frameCount - 1);
        progressNotifier.value = t;
        // Drive the confetti Lottie in lock-step. Refprogress kicks in at
        // t=0.75 so we map [0.75..1.0] → [0..1] for the confetti timeline.
        lottieController.value = ((t - 0.75) / 0.25).clamp(0.0, 1.0);

        // Two frames so the new progress + Lottie state actually paints.
        await _waitForFrame();
        await _waitForFrame();

        final boundary = boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) return null;
        if (boundary.debugNeedsPaint) {
          await _waitForFrame();
        }

        final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        if (byteData == null) return null;

        // Convert RGBA → image package's Image, downsize if needed.
        final raw = byteData.buffer.asUint8List();
        final width = (_exportWidth * _exportPixelRatio).round();
        final height = (_exportHeight * _exportPixelRatio).round();
        final frame = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: raw.buffer,
          numChannels: 4,
          order: img.ChannelOrder.rgba,
        );

        // GIF only supports 256 colours — image package quantises internally
        // when we add the frame.
        gif.addFrame(frame);
      }

      final encoded = gif.finish();
      return encoded; // Uint8List? directly from image package.
    } catch (e, st) {
      debugPrint('GIF render error: $e\n$st');
      return null;
    } finally {
      lottieController.dispose();
      progressNotifier.dispose();
      entry.remove();
    }
  }

  static Future<void> _waitForFrame() {
    final c = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }
}

/// Minimal TickerProvider for AnimationControllers we drive imperatively
/// during off-screen capture. The exporter never calls `.forward()` on the
/// Lottie controller — it sets `.value` per frame — so we don't need a
/// real ticker, but the API requires a vsync.
class _TickerProviderShim implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) =>
      Ticker(onTick, debugLabel: 'animated_story_capture');
}
