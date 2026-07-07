import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/post_model.dart';
import '../data/social_service.dart';

part 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  final SocialService socialService;

  SocialCubit({required this.socialService}) : super(SocialInitial());

  Future<void> createPost({
    required String content,
    List<int>? imageBytes,
  }) async {
    emit(SocialLoading());
    try {
      final post = await socialService.createPost(
        content: content,
        imageBytes: imageBytes != null ? Uint8List.fromList(imageBytes) : null,
      );
      emit(SocialPostCreated(post));
    } catch (e) {
      emit(SocialError(e.toString()));
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      return await socialService.getComments(postId);
    } catch (e) {
      throw Exception('Failed to load comments');
    }
  }

  Future<CommentModel> addComment(String postId, String content) async {
    try {
      return await socialService.addComment(postId, content);
    } catch (e) {
      throw Exception('Failed to add comment');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await socialService.likePost(postId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      await socialService.unlikePost(postId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadFeed({int limit = 20, int offset = 0}) async {
    emit(SocialLoading());
    try {
      final posts = await socialService.getFeed(limit: limit, offset: offset);
      emit(SocialFeedLoaded(posts));
    } catch (e) {
      emit(SocialError(e.toString()));
    }
  }
}
