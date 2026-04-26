import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/providers.dart';
import '../theme.dart';
import 'rhema_title.dart';

/// iOS-style large collapsing title — the Settings/Mail/Notes pattern.
///
/// Returns a [SliverAppBar] for use in [CustomScrollView] / [NestedScrollView].
/// Expanded: large serif title bottom-left. Collapsed (pinned): centered
/// compact [RhemaTitle] icon. Cross-fade is handled by [FlexibleSpaceBar].
///
/// Theme-aware: in classic theme, uses Cormorant Garamond + parchment +
/// brownDeep; in modern theme, uses Space Grotesk + scaffold bg + onSurface
/// (no gold). Both variants stay readable in dark mode.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: CustomScrollView(slivers: [
///     LargeTitleAppBar(title: 'Your Codex'),
///     SliverList(...),
///   ]),
/// )
/// ```
///
/// For screens with a TabBar, pass it via [bottom]; the `pinned` slot keeps
/// it visible after collapse.
class LargeTitleAppBar extends ConsumerWidget {
  const LargeTitleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.expandedHeight = 100,
    this.bottom,
    this.backgroundColor,
  });

  /// Large title text shown bottom-left when expanded. e.g. "Your Codex".
  final String title;

  /// Right-side icon buttons in the collapsed bar.
  final List<Widget>? actions;

  /// Total expanded height in dp. Default 100 — comfortable for one-line
  /// 36pt serif titles. Bump to 130+ if you also pass a [bottom] TabBar.
  final double expandedHeight;

  /// Optional bottom widget (e.g. TabBar). Stays pinned after collapse.
  final PreferredSizeWidget? bottom;

  /// Override the bar background. Defaults to scaffold color per theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isClassic = ref.watch(
          settingsProvider.select((s) => s.themeStyle),
        ) ==
        ThemeStyle.classic;

    final bg = backgroundColor ??
        (isClassic
            ? (isDark ? BrandColors.darkDeep : BrandColors.parchment)
            : theme.scaffoldBackgroundColor);

    final fg = isClassic
        ? (isDark ? Colors.white : BrandColors.brownDeep)
        : (theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface);

    final largeStyle = isClassic
        ? GoogleFonts.cormorantGaramond(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : BrandColors.brownDeep,
            letterSpacing: -0.5,
          )
        : GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.6,
          );

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: expandedHeight,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: fg,
      iconTheme: IconThemeData(color: fg),
      centerTitle: true,
      // Compact RhemaTitle (icon only) for the collapsed state — taps to home.
      title: RhemaTitle(color: fg, compact: true),
      actions: actions,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: bg),
        titlePadding: const EdgeInsetsDirectional.only(
          start: 20,
          bottom: 14,
          end: 20,
        ),
        // No scaling — we want the large size at expanded, small size at
        // collapsed (provided by the AppBar's own `title:` prop).
        expandedTitleScale: 1.0,
        title: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Text(
            title,
            style: largeStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
