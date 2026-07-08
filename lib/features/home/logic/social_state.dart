part of 'social_cubit.dart';

abstract class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {}

class SocialLoading extends SocialState {}

class SocialPostCreated extends SocialState {
  final PostModel post;

  const SocialPostCreated(this.post);

  @override
  List<Object?> get props => [post];
}

class SocialFeedLoaded extends SocialState {
  final List<PostModel> posts;

  const SocialFeedLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class SocialError extends SocialState {
  final String message;

  const SocialError(this.message);

  @override
  List<Object?> get props => [message];
}

class SocialPostUpdated extends SocialState {
  final PostModel post;

  const SocialPostUpdated(this.post);

  @override
  List<Object?> get props => [post];
}

class SocialPostDeleted extends SocialState {
  final String postId;

  const SocialPostDeleted(this.postId);

  @override
  List<Object?> get props => [postId];
}

