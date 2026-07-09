import '../../../core/api/api_client.dart';
import '../../../data/workout_model.dart';

class WorkoutsService {
  final ApiClient apiClient;

  WorkoutsService({required this.apiClient});

  Future<NextWorkoutModel> getNextWorkout({
    String? enrollmentId,
  }) async {
    final response = await apiClient.dio.get(
      '/api/workouts/get_next_workout',
      queryParameters: {
        if (enrollmentId != null && enrollmentId.isNotEmpty)
          'enrollment_id': enrollmentId,
      },
    );

    return NextWorkoutModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<Map<String, dynamic>> logWorkout({
    required String enrollmentId,
    required String sessionId,
    int? rpe,
    int? durationMinutes,
    String? notes,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final response = await apiClient.dio.post(
      '/api/workouts/post_log',
      data: {
        'enrollment_id': enrollmentId,
        'session_id': sessionId,
        if (rpe != null) 'rpe': rpe,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'exercises': exercises,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}
