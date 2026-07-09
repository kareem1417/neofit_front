import 'package:neofit_app/core/api/api_client.dart';
import 'package:neofit_app/data/training_program_model.dart';
import 'package:neofit_app/data/program_detail_model.dart';

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

  Future<ProgramDetailModel> getProgramDetail(String programId) async {
    final response = await apiClient.dio.get(
      '/api/programs/get_program',
      queryParameters: {'program_id': programId},
    );

    final data = response.data is Map<String, dynamic>
        ? Map<String, dynamic>.from(response.data)
        : <String, dynamic>{};

    return ProgramDetailModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getAvailableTestsForCurrentUser() async {
    final response = await apiClient.dio.get('/api/athletes/snapshots/latest');

    final values =
        response.data['data']?['test_values'] as List<dynamic>? ?? [];

    return values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getProgressData(int attributeTestId) async {
    final response = await apiClient.dio.get(
      '/api/athletes/progress',
      queryParameters: {
        'attribute_test_id': attributeTestId,
      },
    );

    final responseData = response.data;

    if (responseData is! Map) {
      throw Exception('Invalid progress response from server.');
    }

    final map = Map<String, dynamic>.from(responseData);

    final success = map['success'];
    final data = map['data'];

    if (success == false) {
      throw Exception(
        map['error']?.toString() ??
            map['message']?.toString() ??
            'Failed to load progress.',
      );
    }

    if (data == null) {
      throw Exception(
        'Progress data is empty. Make sure a valid attribute_test_id is sent.',
      );
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid progress data format.');
  }

  Future<List<Map<String, dynamic>>> getSportBaselineTests(int sportId) async {
    final response = await apiClient.dio.get(
      '/api/athletes/sports/$sportId/tests',
    );

    final List<dynamic> attributes =
        response.data['data'] as List<dynamic>? ?? [];

    final List<Map<String, dynamic>> flatTests = [];

    for (final rawAttr in attributes) {
      final attr = Map<String, dynamic>.from(rawAttr);
      final tests = attr['attribute_tests'] as List<dynamic>? ?? [];

      for (final rawTest in tests) {
        final test = Map<String, dynamic>.from(rawTest);
        test['attribute_name'] = attr['name'];
        flatTests.add(test);
      }
    }

    return flatTests;
  }

  Future<Map<String, dynamic>> enrollInProgram({
    required String programId,
    List<String> preferredDays = const [],
    String? preferredTime,
    required List<Map<String, dynamic>> baselineTestValues,
  }) async {
    final response = await apiClient.dio.post(
      '/api/programs/enroll_program',
      data: {
        'program_id': programId,
        'preferred_days': preferredDays,
        if (preferredTime != null && preferredTime.isNotEmpty)
          'preferred_time': preferredTime,
        'baseline_test_values': baselineTestValues,
      },
    );

    return Map<String, dynamic>.from(response.data);
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
