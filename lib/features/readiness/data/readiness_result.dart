class ReadinessResult {
  final String id;
  final String? userId;
  final String? enrollmentId;
  final String? programSessionId;

  final int score;
  final int? baseScore;

  final String status;
  final String recommendation;
  final int intensityAdjustment;

  final double sleepHours;
  final int fatigue;
  final int soreness;
  final int stress;

  final ReadinessHistoryContext? historyContext;
  final ReadinessAiAdvice? aiAdvice;

  final DateTime? createdAt;

  const ReadinessResult({
    required this.id,
    this.userId,
    this.enrollmentId,
    this.programSessionId,
    required this.score,
    this.baseScore,
    required this.status,
    required this.recommendation,
    required this.intensityAdjustment,
    required this.sleepHours,
    required this.fatigue,
    required this.soreness,
    required this.stress,
    this.historyContext,
    this.aiAdvice,
    this.createdAt,
  });

  factory ReadinessResult.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['history_context'];
    final aiAdviceRaw = json['ai_advice'];

    return ReadinessResult(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      enrollmentId: json['enrollment_id']?.toString(),
      programSessionId: json['program_session_id']?.toString(),
      score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
      baseScore: json['base_score'] == null
          ? null
          : int.tryParse(json['base_score'].toString()),
      status: json['status']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      intensityAdjustment:
          int.tryParse(json['intensity_adjustment']?.toString() ?? '') ?? 0,
      sleepHours: double.tryParse(json['sleep_hours']?.toString() ?? '') ?? 0,
      fatigue: int.tryParse(json['fatigue']?.toString() ?? '') ?? 0,
      soreness: int.tryParse(json['soreness']?.toString() ?? '') ?? 0,
      stress: int.tryParse(json['stress']?.toString() ?? '') ?? 0,
      historyContext: historyRaw is Map
          ? ReadinessHistoryContext.fromJson(
              Map<String, dynamic>.from(historyRaw),
            )
          : null,
      aiAdvice: aiAdviceRaw is Map
          ? ReadinessAiAdvice.fromJson(
              Map<String, dynamic>.from(aiAdviceRaw),
            )
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ReadinessHistoryContext {
  final int? sevenDayAverage;
  final int? yesterdayScore;
  final int? previousWorkoutRpe;
  final int? previousWorkoutDurationMinutes;
  final int? daysSinceLastWorkout;

  const ReadinessHistoryContext({
    this.sevenDayAverage,
    this.yesterdayScore,
    this.previousWorkoutRpe,
    this.previousWorkoutDurationMinutes,
    this.daysSinceLastWorkout,
  });

  factory ReadinessHistoryContext.fromJson(Map<String, dynamic> json) {
    return ReadinessHistoryContext(
      sevenDayAverage:
          int.tryParse(json['seven_day_average']?.toString() ?? ''),
      yesterdayScore: int.tryParse(json['yesterday_score']?.toString() ?? ''),
      previousWorkoutRpe:
          int.tryParse(json['previous_workout_rpe']?.toString() ?? ''),
      previousWorkoutDurationMinutes: int.tryParse(
        json['previous_workout_duration_minutes']?.toString() ?? '',
      ),
      daysSinceLastWorkout:
          int.tryParse(json['days_since_last_workout']?.toString() ?? ''),
    );
  }
}

class ReadinessAiAdvice {
  final String summary;
  final String explanation;
  final String advice;
  final String safetyNote;
  final List<String> sources;

  const ReadinessAiAdvice({
    required this.summary,
    required this.explanation,
    required this.advice,
    required this.safetyNote,
    required this.sources,
  });

  factory ReadinessAiAdvice.fromJson(Map<String, dynamic> json) {
    return ReadinessAiAdvice(
      summary: json['summary']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
      safetyNote: json['safety_note']?.toString() ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((source) => source.toString())
              .toList() ??
          const [],
    );
  }

  bool get hasAnyContent =>
      summary.trim().isNotEmpty ||
      explanation.trim().isNotEmpty ||
      advice.trim().isNotEmpty ||
      safetyNote.trim().isNotEmpty;
}
