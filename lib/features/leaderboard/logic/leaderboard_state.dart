import '../data/leaderboard_user_model.dart';

abstract class LeaderboardState {
  const LeaderboardState();
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardUserModel> athletes;
  final String cohortLabel;
  final int athleteCount;

  const LeaderboardLoaded({
    required this.athletes,
    required this.cohortLabel,
    required this.athleteCount,
  });
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError(this.message);
}
