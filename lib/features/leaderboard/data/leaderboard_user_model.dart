class LeaderboardUserModel {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int percentileScore;
  final String deltaTrend;
  final String trendStatus;
  final bool isCurrentUser;

  const LeaderboardUserModel({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.rank,
    required this.percentileScore,
    required this.deltaTrend,
    required this.trendStatus,
    this.isCurrentUser = false,
  });

  factory LeaderboardUserModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserModel(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['profile_photo']?.toString(),
      rank: int.tryParse(json['rank']?.toString() ?? '') ?? 0,
      percentileScore:
          int.tryParse(json['percentile_score']?.toString() ?? '') ?? 0,
      deltaTrend: json['delta_trend']?.toString() ?? '+0',
      trendStatus: json['trend_status']?.toString() ?? 'up',
      isCurrentUser: json['is_current_user'] == true,
    );
  }
}
