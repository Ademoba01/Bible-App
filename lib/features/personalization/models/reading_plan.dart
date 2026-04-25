import 'dart:convert';

/// A single day in a generated reading plan.
class PlanDay {
  int day;
  List<String> verseRefs;
  String theme;
  String reflection;
  bool? completed;
  DateTime? completedAt;

  PlanDay({
    required this.day,
    required this.verseRefs,
    required this.theme,
    required this.reflection,
    this.completed,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'verseRefs': verseRefs,
        'theme': theme,
        'reflection': reflection,
        if (completed != null) 'completed': completed,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final refs = (json['verseRefs'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final completedAtStr = json['completedAt']?.toString();
    return PlanDay(
      day: (json['day'] as num?)?.toInt() ?? 0,
      verseRefs: refs,
      theme: json['theme']?.toString() ?? '',
      reflection: json['reflection']?.toString() ?? '',
      completed: json['completed'] as bool?,
      completedAt: completedAtStr != null && completedAtStr.isNotEmpty
          ? DateTime.tryParse(completedAtStr)
          : null,
    );
  }
}

/// A persistent multi-day Bible reading plan keyed by goal + life context.
class ReadingPlan {
  String id;
  String goal;
  DateTime createdAt;
  int days;
  List<PlanDay> schedule;
  String? lifeContext;

  ReadingPlan({
    required this.id,
    required this.goal,
    required this.createdAt,
    required this.days,
    required this.schedule,
    this.lifeContext,
  });

  /// Mint a new ID using microseconds since epoch (per spec).
  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'createdAt': createdAt.toIso8601String(),
        'days': days,
        'schedule': schedule.map((d) => d.toJson()).toList(),
        if (lifeContext != null) 'lifeContext': lifeContext,
      };

  String toJsonString() => json.encode(toJson());

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    final scheduleRaw = json['schedule'] as List<dynamic>? ?? const [];
    return ReadingPlan(
      id: json['id']?.toString() ?? newId(),
      goal: json['goal']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      days: (json['days'] as num?)?.toInt() ?? scheduleRaw.length,
      schedule: scheduleRaw
          .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      lifeContext: json['lifeContext']?.toString(),
    );
  }

  factory ReadingPlan.fromJsonString(String raw) =>
      ReadingPlan.fromJson(json.decode(raw) as Map<String, dynamic>);
}
