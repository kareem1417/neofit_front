import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../data/post_model.dart';

class SocialService {
  final ApiClient apiClient;

  SocialService({required this.apiClient});

  Future<PostModel> createPost({
    required String content,
    Uint8List? imageBytes,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (content.trim().isNotEmpty) {
        data['content'] = content.trim();
      }

      if (imageBytes != null) {
        final imageUrl = await _uploadPostImage(imageBytes);
        data['image_path'] = imageUrl;
      }

      final response =
          await apiClient.dio.post('/api/social/posts', data: data);

      if (response.data['success'] == true) {
        return PostModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create post');
      }
    } catch (e) {
      print('❌ Create post error: $e');
      rethrow;
    }
  }

  Future<String> _uploadPostImage(Uint8List imageBytes) async {
    try {
      final MultipartFile multipartFile = MultipartFile.fromBytes(
        imageBytes,
        filename: 'post_image.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      );

      final FormData formData = FormData.fromMap({'image': multipartFile});

      final response = await apiClient.dio.post(
        '/api/social/posts/upload-image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data['success'] == true) {
        return response.data['image_path'] ?? response.data['data']?['path'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      print('❌ Upload post image error: $e');
      rethrow;
    }
  }

  Future<List<PostModel>> getFeed({int limit = 20, int offset = 0}) async {
    try {
      final response = await apiClient.dio.get(
        '/api/social/feed',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PostModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load feed');
      }
    } catch (e) {
      print('❌ Get feed error: $e');
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    await apiClient.dio.post('/api/social/posts/$postId/like');
  }

  Future<void> unlikePost(String postId) async {
    await apiClient.dio.delete('/api/social/posts/$postId/like');
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final response =
        await apiClient.dio.get('/api/social/posts/$postId/comments');
    final List data = response.data['data'];
    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final response = await apiClient.dio.post(
      '/api/social/posts/$postId/comments',
      data: {'content': content},
    );

    return CommentModel.fromJson(response.data['data']);
  }

  // ==========================================
  // Edit & Delete Post
  // ==========================================

  Future<PostModel> editPost(String postId, String content) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/social/posts/$postId',
        data: {'content': content},
      );

      if (response.data['success'] == true) {
        return PostModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to edit post');
      }
    } catch (e) {
      print('❌ Edit post error: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final response = await apiClient.dio.delete(
        '/api/social/posts/$postId',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete post');
      }
    } catch (e) {
      print('❌ Delete post error: $e');
      rethrow;
    }
  }

  // ==========================================
  // Edit & Delete Comment
  // ==========================================

  Future<CommentModel> editComment(
      String postId, String commentId, String content) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/social/posts/$postId/comments/$commentId',
        data: {'content': content},
      );

      if (response.data['success'] == true) {
        return CommentModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to edit comment');
      }
    } catch (e) {
      print('❌ Edit comment error: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final response = await apiClient.dio.delete(
        '/api/social/posts/$postId/comments/$commentId',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      print('❌ Delete comment error: $e');
      rethrow;
    }
  }
}
