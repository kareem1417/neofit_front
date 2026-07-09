class NextWorkoutModel {
  final String? sessionId;
  final String? sessionName;
  final int dayOffset;
  final int? estimatedDurationMinutes;
  final DateTime? scheduledDate;
  final List<WorkoutExerciseModel> exercises;
  final String? message;
  final bool isProgramComplete;

  const NextWorkoutModel({
    this.sessionId,
    this.sessionName,
    required this.dayOffset,
    this.estimatedDurationMinutes,
    this.scheduledDate,
    required this.exercises,
    this.message,
    required this.isProgramComplete,
  });

  factory NextWorkoutModel.fromJson(Map<String, dynamic> json) {
    final nextWorkout = json['next_workout'];

    if (nextWorkout == null && json.containsKey('next_workout')) {
      return NextWorkoutModel(
        sessionId: null,
        sessionName: null,
        dayOffset: 0,
        estimatedDurationMinutes: null,
        scheduledDate: null,
        exercises: const [],
        message: json['message']?.toString(),
        isProgramComplete: true,
      );
    }

    return NextWorkoutModel(
      sessionId: json['session_id']?.toString(),
      sessionName: json['session_name']?.toString(),
      dayOffset: int.tryParse(json['day_offset']?.toString() ?? '') ?? 0,
      estimatedDurationMinutes: int.tryParse(
        json['estimated_duration_minutes']?.toString() ?? '',
      ),
      scheduledDate:
          DateTime.tryParse(json['scheduled_date']?.toString() ?? ''),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map(
            (e) => WorkoutExerciseModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      message: json['message']?.toString(),
      isProgramComplete: false,
    );
  }
}

class WorkoutExerciseModel {
  final String id;
  final String name;
  final int orderIndex;
  final int sets;
  final String reps;
  final int restSeconds;

  const WorkoutExerciseModel({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Exercise',
      orderIndex: int.tryParse(json['order_index']?.toString() ?? '') ?? 0,
      sets: int.tryParse(json['sets']?.toString() ?? '') ?? 0,
      reps: json['reps']?.toString() ?? '',
      restSeconds: int.tryParse(json['rest_seconds']?.toString() ?? '') ?? 0,
    );
  }
}
