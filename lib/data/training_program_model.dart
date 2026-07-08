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
  final String? sportName;

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
    required this.coachName,
    this.description,
    this.levelTarget,
    this.ratingAvg,
    this.ratingCount = 0,
    this.enrollmentCount = 0,
    this.sportName,
  });

  factory TrainingProgramModel.fromEnrollmentJson(Map<String, dynamic> json) {
    final program = json['program'] as Map<String, dynamic>? ?? {};

    return TrainingProgramModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'].toString())
          : null,
      title: program['title']?.toString() ?? 'Untitled Program',
      goal: program['goal']?.toString() ?? 'general',
      durationWeeks: int.tryParse(program['duration']?.toString() ?? '') ?? 0,
      coverImage: program['cover']?.toString(),
      coachName: program['coach']?.toString() ?? 'Unknown Coach',
    );
  }

  factory TrainingProgramModel.fromProgramJson(Map<String, dynamic> json) {
    return TrainingProgramModel(
      id: json['id']?.toString() ?? '',
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
