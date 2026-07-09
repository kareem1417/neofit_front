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

  ExploreLoaded copyWith({
    List<ProgramModel>? programs,
    List<ProgramModel>? detailedPrograms,
    List<SuggestedAthleteModel>? athletes,
    List<SuggestedAthleteModel>? people,
    List<ExplorePostModel>? posts,
  }) {
    return ExploreLoaded(
      programs: programs ?? this.programs,
      detailedPrograms: detailedPrograms ?? this.detailedPrograms,
      athletes: athletes ?? this.athletes,
      people: people ?? this.people,
      posts: posts ?? this.posts,
    );
  }
}

class ExploreError extends ExploreState {
  final String message;

  ExploreError(this.message);
}
