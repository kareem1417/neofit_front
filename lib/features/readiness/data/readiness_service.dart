import '../../../core/api/api_client.dart';
import 'readiness_result.dart';

class ReadinessService {
  final ApiClient apiClient;

  ReadinessService({required this.apiClient});

  Future<ReadinessResult?> getTodayReadiness() async {
    final response = await apiClient.dio.get('/api/readiness/today');

    final data = response.data['data'];

    if (data == null) return null;

    return ReadinessResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<ReadinessResult>> getReadinessHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await apiClient.dio.get(
      '/api/readiness/history',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final list = response.data['data'] as List<dynamic>? ?? [];

    return list
        .map(
          (item) => ReadinessResult.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<ReadinessResult> submitReadiness({
    required double sleepHours,
    required int fatigue,
    required int soreness,
    required int stress,
    String? enrollmentId,
    String? programSessionId,
  }) async {
    final response = await apiClient.dio.post(
      '/api/readiness',
      data: {
        'sleep_hours': sleepHours,
        'fatigue': fatigue,
        'soreness': soreness,
        'stress': stress,
        if (enrollmentId != null && enrollmentId.isNotEmpty)
          'enrollment_id': enrollmentId,
        if (programSessionId != null && programSessionId.isNotEmpty)
          'program_session_id': programSessionId,
      },
    );

    return ReadinessResult.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}
