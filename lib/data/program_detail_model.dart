class ProgramDetailModel {
  final String id;
  final String title;
  final String description;
  final int? sportId;

  final String goalPrimary;
  final String? levelTarget;
  final int durationWeeks;
  final int sessionsPerWeek;
  final String? coverImage;
  final String ratingAvg;
  final int ratingCount;
  final int enrollmentCount;
  final ProgramCoach coach;
  final List<ProgramBlockModel> blocks;
  final List<ProgramRatingModel> recentRatings;

  const ProgramDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.goalPrimary,
    this.sportId,
    this.levelTarget,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    this.coverImage,
    required this.ratingAvg,
    required this.ratingCount,
    required this.enrollmentCount,
    required this.coach,
    required this.blocks,
    required this.recentRatings,
  });

  factory ProgramDetailModel.fromJson(Map<String, dynamic> json) {
    return ProgramDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Program',
      description: json['description']?.toString() ?? '',
      sportId: int.tryParse(json['sport_id']?.toString() ?? ''),
      goalPrimary: json['goal_primary']?.toString() ?? 'general',
      levelTarget: json['level_target']?.toString(),
      durationWeeks:
          int.tryParse(json['duration_weeks']?.toString() ?? '') ?? 0,
      sessionsPerWeek:
          int.tryParse(json['sessions_per_week']?.toString() ?? '') ?? 0,
      coverImage: json['cover_image']?.toString(),
      ratingAvg: json['rating_avg']?.toString() ?? '0',
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '') ?? 0,
      enrollmentCount:
          int.tryParse(json['enrollment_count']?.toString() ?? '') ?? 0,
      coach: ProgramCoach.fromJson(
        Map<String, dynamic>.from(json['coach'] ?? {}),
      ),
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((e) => ProgramBlockModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      recentRatings: (json['recent_ratings'] as List<dynamic>? ?? [])
          .map((e) => ProgramRatingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ProgramCoach {
  final String name;
  final String? photo;
  final String bio;

  const ProgramCoach({
    required this.name,
    this.photo,
    required this.bio,
  });

  factory ProgramCoach.fromJson(Map<String, dynamic> json) {
    return ProgramCoach(
      name: json['name']?.toString() ?? 'Unknown Coach',
      photo: json['photo']?.toString(),
      bio: json['bio']?.toString() ?? '',
    );
  }
}

class ProgramBlockModel {
  final String id;
  final String name;
  final String description;
  final int orderIndex;
  final int weekStart;
  final int weekEnd;
  final List<ProgramSessionModel> sessions;

  const ProgramBlockModel({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.weekStart,
    required this.weekEnd,
    required this.sessions,
  });

  factory ProgramBlockModel.fromJson(Map<String, dynamic> json) {
    return ProgramBlockModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Phase',
      description: json['description']?.toString() ?? '',
      orderIndex: int.tryParse(json['order_index']?.toString() ?? '') ?? 0,
      weekStart: int.tryParse(json['week_start']?.toString() ?? '') ?? 0,
      weekEnd: int.tryParse(json['week_end']?.toString() ?? '') ?? 0,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map(
            (e) => ProgramSessionModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class ProgramSessionModel {
  final String id;
  final String name;
  final String description;
  final int dayOffset;
  final int estimatedDurationMinutes;
  final List<ProgramExerciseModel> exercises;

  const ProgramSessionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.dayOffset,
    required this.estimatedDurationMinutes,
    required this.exercises,
  });

  factory ProgramSessionModel.fromJson(Map<String, dynamic> json) {
    return ProgramSessionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Session',
      description: json['description']?.toString() ?? '',
      dayOffset: int.tryParse(json['day_offset']?.toString() ?? '') ?? 0,
      estimatedDurationMinutes: int.tryParse(
            json['estimated_duration_minutes']?.toString() ?? '',
          ) ??
          0,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map(
            (e) => ProgramExerciseModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class ProgramExerciseModel {
  final String id;
  final String exerciseName;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? intensityNote;
  final String? notes;
  final int orderIndex;

  const ProgramExerciseModel({
    required this.id,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.intensityNote,
    this.notes,
    required this.orderIndex,
  });

  factory ProgramExerciseModel.fromJson(Map<String, dynamic> json) {
    return ProgramExerciseModel(
      id: json['id']?.toString() ?? '',
      exerciseName: json['exercise_name']?.toString() ?? 'Exercise',
      sets: int.tryParse(json['sets']?.toString() ?? '') ?? 0,
      reps: json['reps']?.toString() ?? '',
      restSeconds: int.tryParse(json['rest_seconds']?.toString() ?? '') ?? 0,
      intensityNote: json['intensity_note']?.toString(),
      notes: json['notes']?.toString(),
      orderIndex: int.tryParse(json['order_index']?.toString() ?? '') ?? 0,
    );
  }
}

class ProgramRatingModel {
  final int rating;
  final String review;
  final String username;
  final DateTime? date;

  const ProgramRatingModel({
    required this.rating,
    required this.review,
    required this.username,
    this.date,
  });

  factory ProgramRatingModel.fromJson(Map<String, dynamic> json) {
    return ProgramRatingModel(
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      review: json['review']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Anonymous',
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
    );
  }
}
