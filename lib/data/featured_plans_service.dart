import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/personalization/models/reading_plan.dart';

/// Curated YouVersion-style reading plans baked into
/// `assets/data/featured_plans.json`. Unlike the AI-generated plans
/// in ReadingPlanScreen, these are hand-curated by category — the
/// user picks one and starts immediately, no Gemini call needed.
class FeaturedPlan {
  /// Stable id used as JSON key (e.g. "love_talk").
  final String id;
  final String title;
  final String subtitle;
  /// Filter category — one of ["couples", "family", "prayer",
  /// "anxiety", "newbeliever", "grief", "discipline", "discipleship"].
  final String category;
  final int days;
  /// Material icon name suggestion ("favorite", "front_hand", etc.).
  final String icon;
  /// Hex accent color for the plan card + day-row dots.
  final int color;
  final String source;
  final List<PlanDay> schedule;

  const FeaturedPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.days,
    required this.icon,
    required this.color,
    required this.source,
    required this.schedule,
  });

  factory FeaturedPlan.fromJson(String id, Map<String, dynamic> j) {
    return FeaturedPlan(
      id: id,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String,
      category: j['category'] as String? ?? 'discipleship',
      days: (j['days'] as num?)?.toInt() ?? 7,
      icon: j['icon'] as String? ?? 'auto_stories',
      color: int.tryParse(((j['color'] as String?) ?? '#5D4037')
              .replaceFirst('#', '0xFF')) ??
          0xFF5D4037,
      source: j['source'] as String? ?? 'Curated',
      schedule: ((j['schedule'] as List?) ?? const [])
          .map((e) => PlanDay(
                day: ((e as Map)['day'] as num).toInt(),
                verseRefs:
                    (e['verseRefs'] as List).map((v) => v.toString()).toList(),
                theme: e['theme']?.toString() ?? '',
                reflection: e['reflection']?.toString() ?? '',
                completed: false,
              ))
          .toList(),
    );
  }

  /// Convert to a ReadingPlan ready for personalizationService.saveActivePlan.
  ReadingPlan toReadingPlan() {
    return ReadingPlan(
      id: ReadingPlan.newId(),
      goal: title,
      createdAt: DateTime.now(),
      days: days,
      schedule: schedule
          .map((d) => PlanDay(
                day: d.day,
                verseRefs: d.verseRefs,
                theme: d.theme,
                reflection: d.reflection,
                completed: false,
              ))
          .toList(),
      lifeContext: subtitle,
    );
  }
}

/// Lazy-loaded singleton serving the curated plans library.
class FeaturedPlansService {
  FeaturedPlansService._();
  static final FeaturedPlansService instance = FeaturedPlansService._();

  List<FeaturedPlan>? _list;
  Future<void>? _loading;

  bool get isReady => _list != null;
  List<FeaturedPlan> get all => _list ?? const [];

  Future<void> init() {
    if (isReady) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/featured_plans.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final out = <FeaturedPlan>[];
      decoded.forEach((id, value) {
        if (id.startsWith('_')) return;
        out.add(FeaturedPlan.fromJson(id, Map<String, dynamic>.from(value)));
      });
      _list = out;
    } catch (e, st) {
      debugPrint('FeaturedPlansService load failed: $e\n$st');
      _list = const [];
    } finally {
      _loading = null;
    }
  }
}

/// Riverpod provider triggers async load on first read.
final featuredPlansServiceProvider =
    Provider<FeaturedPlansService>((ref) {
  final svc = FeaturedPlansService.instance;
  svc.init();
  return svc;
});
