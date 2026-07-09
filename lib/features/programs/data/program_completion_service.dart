import '../../../core/api/api_client.dart';

class ProgramCompletionService {
  final ApiClient apiClient;

  ProgramCompletionService({required this.apiClient});

  Future<Map<String, dynamic>> completeProgram({
    required String enrollmentId,
    required List<Map<String, dynamic>> posttestTestValues,
  }) async {
    final response = await apiClient.dio.post(
      '/api/programs/complete_enrollment',
      data: {
        'enrollment_id': enrollmentId,
        'posttest_test_values': posttestTestValues,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> rateProgram({
    required String programId,
    required int rating,
    String? review,
  }) async {
    final response = await apiClient.dio.post(
      '/api/programs/rate_program',
      data: {
        'program_id': programId,
        'rating': rating,
        if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}
