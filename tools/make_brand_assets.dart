// Generates brand PNGs for app icon and splash from scratch.
//
// Usage (from repo root):
//   dart run tools/make_brand_assets.dart
//
// Produces:
//   assets/brand/icon.png            1024x1024  — app icon (full bleed)
//   assets/brand/icon_foreground.png 1024x1024  — Android adaptive foreground (transparent bg)
//   assets/brand/splash.png          1024x1024  — native splash logo (transparent bg)
//   assets/brand/hero.png             800x800   — in-app welcome illustration
//
// These are procedurally drawn (no external art). The design is a stylised
// open book with a cross, on a warm brown gradient. You can swap these for
// hand-drawn art later — just keep the filenames the same and re-run
// `flutter pub run flutter_launcher_icons` and
// `flutter pub run flutter_native_splash:create`.

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

const _brown = [0x5D, 0x40, 0x37];      // dark brown
const _brownMid = [0x8D, 0x6E, 0x63];
const _cream = [0xFF, 0xF8, 0xE1];
const _gold = [0xFF, 0xC1, 0x07];

img.Image _transparent(int size) => img.Image(width: size, height: size, numChannels: 4);

void _fillBrownGradient(img.Image image) {
  final w = image.width, h = image.height;
  for (var y = 0; y < h; y++) {
    final t = y / h;
    final r = (_brown[0] * (1 - t) + _brownMid[0] * t).round();
    final g = (_brown[1] * (1 - t) + _brownMid[1] * t).round();
    final b = (_brown[2] * (1 - t) + _brownMid[2] * t).round();
    for (var x = 0; x < w; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

/// Draws a stylised open book centered in the image.
void _drawBook(img.Image image, {required bool filledBackground}) {
  final w = image.width, h = image.height;
  final cx = w ~/ 2, cy = h ~/ 2;

  final bookW = (w * 0.66).round();
  final bookH = (h * 0.46).round();
  final left = cx - bookW ~/ 2;
  final top = cy - bookH ~/ 2;

  // Book body (cream rounded rect)
  img.fillRect(
    image,
    x1: left, y1: top, x2: left + bookW, y2: top + bookH,
    color: img.ColorRgba8(_cream[0], _cream[1], _cream[2], 255),
    radius: (bookH * 0.08).round(),
  );

  // Spine line
  img.drawLine(
    image,
    x1: cx, y1: top + 8, x2: cx, y2: top + bookH - 8,
    color: img.ColorRgba8(_brown[0], _brown[1], _brown[2], 255),
    thickness: math.max(3, bookW ~/ 120),
  );

  // Page lines (left & right)
  final lineColor = img.ColorRgba8(_brownMid[0], _brownMid[1], _brownMid[2], 180);
  final lineThickness = math.max(2, bookW ~/ 180);
  for (var i = 0; i < 5; i++) {
    final y = top + (bookH * (0.28 + i * 0.12)).round();
    img.drawLine(
      image,
      x1: left + bookW ~/ 20, y1: y,
      x2: cx - bookW ~/ 20, y2: y,
      color: lineColor, thickness: lineThickness,
    );
    img.drawLine(
      image,
      x1: cx + bookW ~/ 20, y1: y,
      x2: left + bookW - bookW ~/ 20, y2: y,
      color: lineColor, thickness: lineThickness,
    );
  }

  // Gold cross on top of the book
  final crossColor = img.ColorRgba8(_gold[0], _gold[1], _gold[2], 255);
  final crossH = (bookH * 0.38).round();
  final crossW = (crossH * 0.28).round();
  final crossTop = top - (crossH * 0.55).round();
  // vertical bar
  img.fillRect(
    image,
    x1: cx - crossW ~/ 2, y1: crossTop,
    x2: cx + crossW ~/ 2, y2: crossTop + crossH,
    color: crossColor,
  );
  // horizontal bar
  final hbarY = crossTop + (crossH * 0.25).round();
  final hbarW = (crossW * 2.6).round();
  final hbarH = (crossW * 0.9).round();
  img.fillRect(
    image,
    x1: cx - hbarW ~/ 2, y1: hbarY,
    x2: cx + hbarW ~/ 2, y2: hbarY + hbarH,
    color: crossColor,
  );

  if (!filledBackground) return; // foreground variant doesn't need outer glow
}

Future<void> _writePng(img.Image image, String path) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(img.encodePng(image));
  print('  wrote $path (${image.width}x${image.height})');
}

Future<void> main() async {
  print('Generating brand assets...');

  // 1) App icon — filled brown gradient + book + cross (full bleed)
  final icon = img.Image(width: 1024, height: 1024);
  _fillBrownGradient(icon);
  _drawBook(icon, filledBackground: true);
  await _writePng(icon, 'assets/brand/icon.png');

  // 2) Adaptive foreground — transparent background + book + cross
  final fg = _transparent(1024);
  _drawBook(fg, filledBackground: false);
  await _writePng(fg, 'assets/brand/icon_foreground.png');

  // 3) Splash logo — transparent background (splash plugin draws the brown)
  final splash = _transparent(1024);
  _drawBook(splash, filledBackground: false);
  await _writePng(splash, 'assets/brand/splash.png');

  // 4) Hero illustration for the welcome screen
  final hero = img.Image(width: 800, height: 800);
  _fillBrownGradient(hero);
  _drawBook(hero, filledBackground: true);
  await _writePng(hero, 'assets/brand/hero.png');

  print('\nDone. Next:');
  print('  flutter pub run flutter_launcher_icons');
  print('  flutter pub run flutter_native_splash:create');
}
