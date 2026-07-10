import '../../../core/api/api_client.dart';

class AiChatService {
  final ApiClient apiClient;

  AiChatService({required this.apiClient});

  Future<Map<String, dynamic>> askQuestion({
    required String question,
    String? sessionId,
  }) async {
    final response = await apiClient.dio.post(
      '/api/ai/ask',
      data: {
        'question': question,
        if (sessionId != null) 'session_id': sessionId,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await apiClient.dio.get('/api/ai/sessions');

    final data = response.data is Map<String, dynamic>
        ? response.data['data'] as List<dynamic>? ?? []
        : response.data as List<dynamic>? ?? [];

    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getOnboardingStatus() async {
    final response = await apiClient.dio.get('/api/athletes/onboarding/status');

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid onboarding status response.');
  }

  Future<Map<String, dynamic>> recommendProgram({
    Map<String, dynamic> overrides = const {},
  }) async {
    final response = await apiClient.dio.post(
      '/api/ai/recommend',
      data: overrides,
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid recommendation response.');
  }

  Future<List<Map<String, dynamic>>> getSessionMessages(
      String sessionId) async {
    final response = await apiClient.dio.get(
      '/api/ai/sessions/$sessionId/messages',
    );

    final data = response.data is Map<String, dynamic>
        ? response.data['data'] as List<dynamic>? ?? []
        : response.data as List<dynamic>? ?? [];

    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
