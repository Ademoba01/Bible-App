import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/codex/codex_screen.dart';
import '../features/listen/listen_screen.dart';
import '../features/personalization/preach_topic_screen.dart';
import '../features/personalization/reading_plan_screen.dart';
import '../features/prayer/prayer_wall_screen.dart';
import '../features/study/bible_maps_screen.dart';
import '../state/providers.dart';
import 'page_transitions.dart';

/// Push a sub-route AND mark it as the current sub-route in
/// SharedPreferences. On Web, refreshing the page restarts the Flutter app
/// from scratch — without this, you'd always land back on the Home tab.
/// With this, [restoreSubRouteIfAny] (called from the home shell's first
/// frame) re-opens whichever sub-screen you were on.
///
/// Pop is auto-tracked via the future on push: when the route returns
/// (back button, Navigator.pop), we clear the persisted marker.
Future<T?> pushSubRoute<T>(
  BuildContext context,
  WidgetRef ref, {
  required SubRoute route,
  required Widget Function(BuildContext) builder,
  bool fadeSlide = true,
}) async {
  ref.read(lastSubRouteProvider.notifier).enter(route);
  final result = await Navigator.push<T>(
    context,
    fadeSlide
        ? FadeSlideRoute<T>(page: Builder(builder: builder))
        : MaterialPageRoute<T>(builder: builder),
  );
  // After pop, mark "no sub-route active" so the next refresh lands on
  // the bottom-tab shell normally.
  ref.read(lastSubRouteProvider.notifier).clear();
  return result;
}

/// Called from the home shell's first frame (post-frame callback). If a
/// sub-route was persisted from the previous session, re-pushes it so the
/// user lands where they left off.
///
/// Safe to call on every home build — only does work the FIRST time the
/// shell mounts in this session (guards via [restored]).
void restoreSubRouteIfAny(BuildContext context, WidgetRef ref) {
  if (_restoredOnce) return;
  _restoredOnce = true;
  final route = ref.read(lastSubRouteProvider);
  if (route == SubRoute.none) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    switch (route) {
      case SubRoute.maps:
        pushSubRoute(context, ref,
            route: SubRoute.maps,
            builder: (_) => const BibleMapsScreen());
        break;
      case SubRoute.codex:
        pushSubRoute(context, ref,
            route: SubRoute.codex,
            fadeSlide: false,
            builder: (_) => const CodexScreen());
        break;
      case SubRoute.prayer:
        pushSubRoute(context, ref,
            route: SubRoute.prayer,
            builder: (_) => const PrayerWallScreen());
        break;
      case SubRoute.readingPlan:
        pushSubRoute(context, ref,
            route: SubRoute.readingPlan,
            builder: (_) => const ReadingPlanScreen());
        break;
      case SubRoute.preachTopic:
        pushSubRoute(context, ref,
            route: SubRoute.preachTopic,
            builder: (_) => const PreachTopicScreen());
        break;
      case SubRoute.listen:
        pushSubRoute(context, ref,
            route: SubRoute.listen,
            builder: (_) => const ListenScreen());
        break;
      case SubRoute.none:
        break;
    }
  });
}

bool _restoredOnce = false;
