import '../../../core/api/api_client.dart';
import '../../../data/training_program_model.dart';

class ProgramsService {
  final ApiClient apiClient;

  ProgramsService({required this.apiClient});

  Future<List<TrainingProgramModel>> getActivePrograms() async {
    final response = await apiClient.dio.get(
      '/api/athletes/enrollments',
      queryParameters: {'status': 'active'},
    );

    final responseData = response.data;

    final List<dynamic> data = responseData is Map<String, dynamic>
        ? responseData['data'] as List<dynamic>? ?? []
        : responseData as List<dynamic>? ?? [];

    return data
        .map(
          (json) => TrainingProgramModel.fromEnrollmentJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  Future<List<TrainingProgramModel>> getAvailablePrograms({
    int limit = 5,
    int offset = 0,
  }) async {
    final response = await apiClient.dio.get(
      '/api/programs',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final responseData = response.data;

    final List<dynamic> data = responseData is Map<String, dynamic>
        ? responseData['data'] as List<dynamic>? ?? []
        : responseData as List<dynamic>? ?? [];

    return data
        .map(
          (json) => TrainingProgramModel.fromProgramJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }
}
