import 'package:dio/dio.dart';

import 'leaderboard_user_model.dart';

class LeaderboardRepository {
  final Dio dio;

  LeaderboardRepository(this.dio);

  Future<LeaderboardResult> getLeaderboard({
    required String type,
    String? level,
    String? playerCategory,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/api/leaderboards/get_leaderboard',
      queryParameters: {
        'type': type,
        'limit': limit,
        'offset': offset,
        if (level != null && level.isNotEmpty) 'level': level,
        if (playerCategory != null && playerCategory.isNotEmpty)
          'player_category': playerCategory,
      },
    );

    final responseData = response.data;

    if (responseData is! Map) {
      throw Exception('Invalid leaderboard response.');
    }

    final map = Map<String, dynamic>.from(responseData);

    if (map['success'] == false) {
      throw Exception(
        map['error']?.toString() ??
            map['message']?.toString() ??
            'Failed to load leaderboard.',
      );
    }

    final data = map['data'];

    if (data is! Map) {
      throw Exception('Invalid leaderboard data.');
    }

    final dataMap = Map<String, dynamic>.from(data);
    final cohort = dataMap['cohort'] is Map
        ? Map<String, dynamic>.from(dataMap['cohort'])
        : <String, dynamic>{};

    final list = dataMap['leaderboard'] as List<dynamic>? ?? [];

    final athletes = list
        .map(
          (json) => LeaderboardUserModel.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();

    final levelLabel = cohort['level']?.toString().toUpperCase() ?? 'ALL';
    final categoryLabel =
        cohort['player_category']?.toString().toUpperCase() ?? 'ATHLETES';

    final cohortLabel = '$levelLabel $categoryLabel';

    return LeaderboardResult(
      athletes: athletes,
      cohortLabel: cohortLabel,
      athleteCount: int.tryParse(cohort['athlete_count']?.toString() ?? '') ??
          athletes.length,
    );
  }
}

class LeaderboardResult {
  final List<LeaderboardUserModel> athletes;
  final String cohortLabel;
  final int athleteCount;

  const LeaderboardResult({
    required this.athletes,
    required this.cohortLabel,
    required this.athleteCount,
  });
}
