import '../models/explore_models.dart';

abstract class ExploreState {}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final List<ProgramModel> programs;
  final List<ProgramModel> detailedPrograms;
  final List<SuggestedAthleteModel> athletes;
  final List<SuggestedAthleteModel> people;
  final List<ExplorePostModel> posts;

  ExploreLoaded({
    required this.programs,
    required this.detailedPrograms,
    required this.athletes,
    required this.people,
    required this.posts,
  });
}

class ExploreError extends ExploreState {
  final String message;

  ExploreError(this.message);
}
