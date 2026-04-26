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

  /// Typography helpers — call these instead of inline GoogleFonts so the
  /// app's verse rendering is consistent and easy to retune in one place.
  ///
  /// To honor iOS Dynamic Type / Android font scaling (WCAG 1.4.4), pass
  /// the active textScaler from MediaQuery via [scale]. Default 1.0 means
  /// "ignore system scaling" — use only when the caller already wraps
  /// the text in a MediaQuery override.
  static TextStyle verseStyle({
    double size = 19.5,
    Color? color,
    double scale = 1.0,
  }) {
    // Literata: a serif designed for long-form digital reading. Slightly
    // taller line height + tight letter spacing produces the calm cadence
    // that distinguishes Scripture from UI text.
    return GoogleFonts.literata(
      fontSize: size * scale,
      height: 1.75,
      letterSpacing: -0.2,
      color: color,
    );
  }

  /// Verse number style. Defaults to [goldDark] which passes WCAG AA on
  /// the cream background (~4.7:1 contrast). The plain [gold] hex sits
  /// at ~2.1:1 which is below the 4.5:1 requirement for body text.
  static TextStyle verseNumberStyle({Color? color, double scale = 1.0}) {
    return GoogleFonts.literata(
      fontSize: 13 * scale,
      fontWeight: FontWeight.w700,
      color: color ?? goldDark,
      height: 1.0,
    );
  }

  // Kids palette — brighter, cheerful
  static const kidsBlue = Color(0xFF42A5F5);
  static const kidsYellow = Color(0xFFFFCA28);
  static const kidsGreen = Color(0xFF66BB6A);
  static const kidsPink = Color(0xFFEC407A);
  static const kidsPurple = Color(0xFFAB47BC);

  // Modern theme — clean sans-serif aesthetic, blue accent (no gold).
  // Used by `buildModernTheme` when the user opts out of the classic
  // parchment/gold look in Settings → Theme style.
  static const modernBlue = Color(0xFF6CA0FF);          // dark-mode accent
  static const modernBlueDeep = Color(0xFF2563EB);      // light-mode accent
  static const modernScaffoldDark = Color(0xFF0F1115);  // near-black scaffold
  static const modernSurfaceDark = Color(0xFF181B22);   // card / surface
  static const modernScaffoldLight = Color(0xFFFAFAFA); // clean white
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

/// Modern theme — the alternative aesthetic for users who find the classic
/// parchment/Cormorant/gold look too churchy. Mirrors [buildAdultTheme]'s
/// structure (so existing screens rebuild cleanly under either) but swaps:
///   - Body type: Lora → Inter (clean, neutral sans)
///   - Display type: Playfair → Space Grotesk (distinctive, not devotional)
///   - Surfaces: parchment/cream → near-black or clean white
///   - Accent: gold → blue
///   - Card radius: 20 → 12 (less ornate)
///   - Button radius: 24 (pill) → 8 (sharp)
///   - AppBar: solid brownDeep → transparent flat
ThemeData buildModernTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? BrandColors.modernBlue : BrandColors.modernBlueDeep;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  // Inter for body, Space Grotesk for display headings — both load via
  // google_fonts. Inter is the de-facto modern UI sans; Space Grotesk
  // adds a tiny bit of character without the spiritual weight of Playfair.
  final baseTextTheme = isDark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.displayLarge),
    displayMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.displayMedium),
    displaySmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.displaySmall),
    headlineLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineLarge),
    headlineMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineMedium),
    headlineSmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineSmall),
    titleLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleLarge),
  );
  final scaffoldBg = isDark
      ? BrandColors.modernScaffoldDark
      : BrandColors.modernScaffoldLight;
  final surfaceColor = isDark
      ? BrandColors.modernSurfaceDark
      : Colors.white;
  final accent = isDark ? BrandColors.modernBlue : BrandColors.modernBlueDeep;
  final onAccent = Colors.white;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      // Modern flat: transparent + 0 elevation. The scaffold's bg shows
      // through, no chunky brown bar.
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black87,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),
    cardTheme: CardThemeData(
      // Lower elevation + tighter radius than classic — modern UI standard.
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      color: surfaceColor,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Sharp 8 radius — definitively NOT pill. Reads as utility, not
        // marketing-CTA flourish.
        backgroundColor: accent,
        foregroundColor: onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.6), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: onAccent,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: surfaceColor,
      indicatorColor: accent.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
      thickness: 0.6,
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
