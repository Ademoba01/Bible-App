import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette. Warm, parchment-like, welcoming.
class BrandColors {
  static const brown = Color(0xFF5D4037);      // primary seed
  static const brownMid = Color(0xFF8D6E63);
  static const cream = Color(0xFFFFF8E1);
  static const gold = Color(0xFFFFC107);
  static const dark = Color(0xFF3E2723);

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
  final textTheme = GoogleFonts.loraTextTheme(
    isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? const Color(0xFF1B120F) : BrandColors.cream,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.lora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? const Color(0xFF2B1E19) : Colors.white,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF241814) : Colors.white,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.lora(fontSize: 12, fontWeight: FontWeight.w600),
      ),
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
