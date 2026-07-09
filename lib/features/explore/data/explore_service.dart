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

  Future<List<SuggestedAthleteModel>> getPeople({
    int limit = 12,
    int offset = 0,
    String? query,
  }) async {
    final response = await apiClient.dio.get(
      '/api/social/explore/people',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    final responseData = response.data;
    final List<dynamic> data = responseData is Map<String, dynamic>
        ? responseData['data'] as List<dynamic>? ?? []
        : responseData as List<dynamic>? ?? [];

    return data
        .map(
          (e) => SuggestedAthleteModel.fromExplorePeopleJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<void> followUser(String userId) async {
    await apiClient.dio.post('/api/social/follow/$userId');
  }

  Future<void> unfollowUser(String userId) async {
    await apiClient.dio.delete('/api/social/follow/$userId');
  }

  Future<void> likePost(String postId) async {
    await apiClient.dio.post('/api/social/posts/$postId/like');
  }

  Future<void> unlikePost(String postId) async {
    await apiClient.dio.delete('/api/social/posts/$postId/like');
  }

  Future<List<ExplorePostModel>> getPosts({
    int limit = 6,
    int offset = 0,
  }) async {
    final response = await apiClient.dio.get(
      '/api/social/feed',
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
        .map((e) => ExplorePostModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
