class TrainingProgramModel {
  final String id;
  final String status;
  final DateTime? startDate;
  final DateTime? completedDate;
  final String title;
  final String goal;
  final int durationWeeks;
  final int sessionsPerWeek;
  final String? coverImage;
  final String coachName;
  final String? description;
  final String? levelTarget;
  final String? ratingAvg;
  final int ratingCount;
  final int enrollmentCount;
  final String? coachPhoto;
  final String? enrollmentId;
  final String? programId;
  final int completedSessionsCount;
  final int totalSessionsCount;
  final double progressPercent;

  final String? sportName;
  final List<Map<String, dynamic>> baselineTests;

  const TrainingProgramModel({
    required this.id,
    required this.status,
    this.startDate,
    this.completedDate,
    required this.title,
    required this.goal,
    required this.durationWeeks,
    this.sessionsPerWeek = 0,
    this.coverImage,
    this.enrollmentId,
    this.programId,
    required this.coachName,
    this.coachPhoto,
    this.description,
    this.levelTarget,
    this.ratingAvg,
    this.ratingCount = 0,
    this.enrollmentCount = 0,
    this.completedSessionsCount = 0,
    this.totalSessionsCount = 0,
    this.progressPercent = 0,
    this.sportName,
    this.baselineTests = const [],
  });

  factory TrainingProgramModel.fromEnrollmentJson(Map<String, dynamic> json) {
    final program = json['program'] as Map<String, dynamic>? ?? {};

    return TrainingProgramModel(
      id: program['id']?.toString() ?? json['id']?.toString() ?? '',
      enrollmentId: json['id']?.toString(),
      programId: program['id']?.toString(),
      status: json['status']?.toString() ?? 'active',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'].toString())
          : null,
      title: program['title']?.toString() ?? 'Untitled Program',
      completedSessionsCount:
          int.tryParse(json['completed_sessions_count']?.toString() ?? '') ?? 0,
      totalSessionsCount:
          int.tryParse(json['total_sessions_count']?.toString() ?? '') ?? 0,
      progressPercent:
          double.tryParse(json['progress_percent']?.toString() ?? '') ?? 0,
      goal: program['goal']?.toString() ?? 'general',
      durationWeeks: int.tryParse(program['duration']?.toString() ?? '') ?? 0,
      coverImage: program['cover']?.toString(),
      coachName: program['coach']?.toString() ?? 'Unknown Coach',
      coachPhoto: json['coach_photo']?.toString(),
      baselineTests: (json['baseline_tests'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  factory TrainingProgramModel.fromProgramJson(Map<String, dynamic> json) {
    return TrainingProgramModel(
      id: json['id']?.toString() ?? '',
      programId: json['id']?.toString(),
      enrollmentId: null,
      status: 'available',
      title: json['title']?.toString() ?? 'Untitled Program',
      description: json['description']?.toString(),
      goal: json['goal_primary']?.toString() ?? 'general',
      levelTarget: json['level_target']?.toString(),
      durationWeeks:
          int.tryParse(json['duration_weeks']?.toString() ?? '') ?? 0,
      sessionsPerWeek:
          int.tryParse(json['sessions_per_week']?.toString() ?? '') ?? 0,
      coverImage: json['cover_image']?.toString(),
      ratingAvg: json['rating_avg']?.toString(),
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '') ?? 0,
      enrollmentCount:
          int.tryParse(json['enrollment_count']?.toString() ?? '') ?? 0,
      coachName: json['coach_name']?.toString() ?? 'Unknown Coach',
      sportName: json['sport_name']?.toString(),
    );
  }
}
