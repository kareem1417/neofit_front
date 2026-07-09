import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/explore_service.dart';
import 'explore_state.dart';
import '../models/explore_models.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final ExploreService exploreService;

  ExploreCubit(this.exploreService) : super(ExploreInitial());
  Future<void> toggleFollow(SuggestedAthleteModel athlete) async {
    final currentState = state;
    if (currentState is! ExploreLoaded) return;

    final optimisticValue = !athlete.isFollowedByMe;

    List<SuggestedAthleteModel> updateList(
      List<SuggestedAthleteModel> list,
      bool value,
    ) {
      return list.map((item) {
        if (item.userId == athlete.userId) {
          return item.copyWith(isFollowedByMe: value);
        }
        return item;
      }).toList();
    }

    emit(
      currentState.copyWith(
        people: updateList(currentState.people, optimisticValue),
        athletes: updateList(currentState.athletes, optimisticValue),
      ),
    );

    try {
      if (optimisticValue) {
        await exploreService.followUser(athlete.userId);
      } else {
        await exploreService.unfollowUser(athlete.userId);
      }

      final refreshedPosts = await exploreService.getPosts(limit: 20);
      final latestState = state;
      if (latestState is ExploreLoaded) {
        emit(latestState.copyWith(posts: refreshedPosts));
      }
    } catch (e) {
      final latestState = state;
      if (latestState is ExploreLoaded) {
        emit(
          latestState.copyWith(
            people: updateList(latestState.people, athlete.isFollowedByMe),
            athletes: updateList(latestState.athletes, athlete.isFollowedByMe),
          ),
        );
      }
    }
  }

  Future<void> togglePostLike(ExplorePostModel post) async {
    final currentState = state;
    if (currentState is! ExploreLoaded) return;

    final wasLiked = post.isLikedByMe;
    final nextLiked = !wasLiked;
    final nextLikes = nextLiked ? post.likes + 1 : post.likes - 1;

    List<ExplorePostModel> updatePosts(bool liked, int likes) {
      return currentState.posts.map((item) {
        if (item.id == post.id) {
          return item.copyWith(
            isLikedByMe: liked,
            likes: likes < 0 ? 0 : likes,
          );
        }
        return item;
      }).toList();
    }

    emit(
      currentState.copyWith(
        posts: updatePosts(nextLiked, nextLikes),
      ),
    );

    try {
      if (nextLiked) {
        await exploreService.likePost(post.id);
      } else {
        await exploreService.unlikePost(post.id);
      }
    } catch (e) {
      final latestState = state;
      if (latestState is ExploreLoaded) {
        emit(
          latestState.copyWith(
            posts: latestState.posts.map((item) {
              if (item.id == post.id) {
                return post;
              }
              return item;
            }).toList(),
          ),
        );
      }
    }
  }

  Future<void> loadExploreData() async {
    emit(ExploreLoading());

    try {
      final programs = await exploreService.getPrograms(limit: 8);
      final detailedPrograms = await exploreService.getPrograms(limit: 24);
      final people = await exploreService.getPeople(limit: 10);
      final posts = await exploreService.getPosts(limit: 5);

      emit(
        ExploreLoaded(
          programs: programs,
          detailedPrograms: detailedPrograms,
          athletes: people,
          people: people,
          posts: posts,
        ),
      );
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }
}
