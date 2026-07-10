import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/leaderboard_repository.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository repository;

  LeaderboardCubit(this.repository) : super(const LeaderboardInitial());

  Future<void> loadLeaderboard({
    String type = 'punch_power',
    String? level,
    String? playerCategory,
    int limit = 50,
    int offset = 0,
  }) async {
    emit(const LeaderboardLoading());

    try {
      final result = await repository.getLeaderboard(
        type: type,
        level: level,
        playerCategory: playerCategory,
        limit: limit,
        offset: offset,
      );

      emit(
        LeaderboardLoaded(
          athletes: result.athletes,
          cohortLabel: result.cohortLabel,
          athleteCount: result.athleteCount,
        ),
      );
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }
}
