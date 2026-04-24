/// Domain model for a single private prayer request stored in the user's
/// devotional ledger (Prayer Wall). Persisted locally as JSON via
/// SharedPreferences — no network I/O.
class PrayerRequest {
  /// Stable ID. We avoid adding a uuid dep by using microsecond timestamps
  /// (collisions are virtually impossible for human-driven additions).
  final String id;

  /// Short headline, max 80 chars (UI enforces this).
  final String title;

  /// Body / details, max 500 chars (UI enforces this).
  final String body;

  /// When the user first added the prayer.
  final DateTime createdAt;

  /// When the user marked the prayer answered. `null` means still open.
  final DateTime? answeredAt;

  /// Optional reflection captured at the moment the prayer was answered.
  final String? answerNote;

  /// Optional tied scripture e.g. "Philippians 4:6".
  final String? scriptureRef;

  /// Optional user-defined tags (e.g. ["healing", "family"]).
  final List<String> tags;

  const PrayerRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.answeredAt,
    this.answerNote,
    this.scriptureRef,
    this.tags = const [],
  });

  /// Convenience: a prayer is "answered" when `answeredAt` is non-null.
  bool get isAnswered => answeredAt != null;

  /// Generates a fresh PrayerRequest with a microsecond-based ID.
  factory PrayerRequest.create({
    required String title,
    required String body,
    String? scriptureRef,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return PrayerRequest(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: now,
      scriptureRef: scriptureRef,
      tags: tags,
    );
  }

  PrayerRequest copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? answeredAt,
    String? answerNote,
    String? scriptureRef,
    List<String>? tags,
    bool clearAnswered = false,
    bool clearAnswerNote = false,
    bool clearScriptureRef = false,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: clearAnswered ? null : (answeredAt ?? this.answeredAt),
      answerNote: clearAnswerNote ? null : (answerNote ?? this.answerNote),
      scriptureRef:
          clearScriptureRef ? null : (scriptureRef ?? this.scriptureRef),
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'answeredAt': answeredAt?.toIso8601String(),
        'answerNote': answerNote,
        'scriptureRef': scriptureRef,
        'tags': tags,
      };

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      answeredAt: (json['answeredAt'] as String?) != null
          ? DateTime.tryParse(json['answeredAt'] as String)
          : null,
      answerNote: json['answerNote'] as String?,
      scriptureRef: json['scriptureRef'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}
