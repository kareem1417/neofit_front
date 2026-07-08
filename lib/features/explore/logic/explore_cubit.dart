import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/explore_service.dart';
import 'explore_state.dart';
import '../models/explore_models.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final ExploreService exploreService;

  ExploreCubit(this.exploreService) : super(ExploreInitial());

  Future<void> loadExploreData() async {
    emit(ExploreLoading());

    try {
      final results = await Future.wait([
        exploreService.getPrograms(limit: 8),
        exploreService.getPrograms(limit: 24),
        exploreService.getPeople(limit: 10),
        exploreService.getPosts(limit: 5),
      ]);

      final programs = results[0] as List<ProgramModel>;
      final detailedPrograms = results[1] as List<ProgramModel>;
      final athletes = results[2] as List<SuggestedAthleteModel>;
      final posts = results[3] as List<ExplorePostModel>;

      emit(
        ExploreLoaded(
          programs: programs,
          detailedPrograms: detailedPrograms,
          athletes: athletes,
          people: athletes,
          posts: posts,
        ),
      );
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }
}
