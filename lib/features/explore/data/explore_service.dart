import '../../../core/api/api_client.dart';
import '../models/explore_models.dart';

class ExploreService {
  final ApiClient apiClient;

  ExploreService(this.apiClient);

  Future<List<ProgramModel>> getPrograms(
      {int limit = 24, int offset = 0}) async {
    final response = await apiClient.dio.get(
      '/api/programs',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => ProgramModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SuggestedAthleteModel>> getPeople({int limit = 12}) async {
    final response = await apiClient.dio.get(
      '/api/leaderboard/most_improved',
      queryParameters: {
        'limit': limit,
        'offset': 0,
      },
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map(
          (e) => SuggestedAthleteModel.fromMostImprovedJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<List<ExplorePostModel>> getPosts({int limit = 6}) async {
    final response = await apiClient.dio.get(
      '/api/social/feed',
      queryParameters: {
        'limit': limit,
        'offset': 0,
      },
    );

    final responseData = response.data;
    final List<dynamic> data = responseData is Map<String, dynamic>
        ? responseData['data'] as List<dynamic>? ?? []
        : responseData as List<dynamic>? ?? [];

    return data
        .map((e) => ExplorePostModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
