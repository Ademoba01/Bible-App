import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette. Warm, parchment-like, welcoming.
///
/// Two browns and two golds give a layered hierarchy:
///   - `brown` is the Material seed (drives ColorScheme — keep stable)
///   - `brownDeep` is for AppBars + dramatic overlays (richer, sacred)
///   - `gold` is the everyday accent
///   - `goldDeep` is for primary CTAs (warmer, slightly more saturated)
class BrandColors {
  // Browns
  static const brown = Color(0xFF5D4037);       // primary seed (ColorScheme)
  static const brownDeep = Color(0xFF4A2C1F);   // AppBar / dramatic overlay
  static const brownMid = Color(0xFF8D6E63);
  static const dark = Color(0xFF3E2723);
  static const darkDeep = Color(0xFF2C1A12);    // night-mode scaffold

  // Golds
  static const gold = Color(0xFFD4A843);        // everyday accent
  static const goldDeep = Color(0xFFD4A017);    // primary CTAs (warmer)
  static const goldDark = Color(0xFFA07B28);    // WCAG AA on light bg
  static const goldLight = Color(0xFFFFC107);   // bright accents

  // Surfaces
  static const cream = Color(0xFFFFF8E1);
  static const parchment = Color(0xFFFDF6EC);   // reading background
  static const warmWhite = Color(0xFFFFFBF5);   // card background
  static const verseBeige = Color(0xFFEDE4D5);  // highlighted verse bg

  // Kids palette — brighter, cheerful
  static const kidsBlue = Color(0xFF42A5F5);
  static const kidsYellow = Color(0xFFFFCA28);
  static const kidsGreen = Color(0xFF66BB6A);
  static const kidsPink = Color(0xFFEC407A);
  static const kidsPurple = Color(0xFFAB47BC);
}

ThemeData buildAdultTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.brown,
    brightness: brightness,
  );
  // Body text stays Lora (brand-defining biblical voice). Display headings
  // use Playfair Display for a more spiritual nav/AppBar feel — adopted from
  // the user's proposed AppTheme review.
  final textTheme = GoogleFonts.loraTextTheme(
    isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? BrandColors.darkDeep : BrandColors.cream,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      // Use brownDeep instead of scheme.primary — gives the nav a richer,
      // more sacred feel without disturbing the rest of the ColorScheme.
      backgroundColor: BrandColors.brownDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      // Centered by default — was per-screen, now baked into the theme.
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      // Subtle elevation gives depth without floating-card noise.
      elevation: 2,
      shadowColor: BrandColors.brown.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? const Color(0xFF2C1F18) : BrandColors.warmWhite,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Pill-shaped (radius 24) — softer, friendlier; matches the
        // marketing landing's CTA aesthetic.
        backgroundColor: BrandColors.goldDeep,
        foregroundColor: BrandColors.darkDeep,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.goldDeep,
        foregroundColor: BrandColors.darkDeep,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.brownDeep,
        side: const BorderSide(color: BrandColors.brownDeep, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.lora(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.goldDeep,
      foregroundColor: BrandColors.darkDeep,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF2C1F18)
          : BrandColors.warmWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: BrandColors.gold.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: BrandColors.gold.withValues(alpha: 0.3)),
      ),
      // Gold focus ring — distinctive and matches the brand accent.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: BrandColors.goldDeep, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: isDark ? const Color(0xFF241814) : Colors.white,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: BrandColors.brown.withValues(alpha: 0.1),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.lora(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: BrandColors.gold.withValues(alpha: 0.15),
      thickness: 0.8,
    ),
  );
}

ThemeData buildKidsTheme({required Brightness brightness}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.kidsBlue,
    brightness: brightness,
  );
  final base = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  final textTheme = GoogleFonts.fredokaTextTheme(base);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF0E1B2E)
        : const Color(0xFFFFFBF0),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.fredoka(
        fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );
}
