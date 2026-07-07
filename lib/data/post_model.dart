class PostAuthor {
  final String? id;
  final String? username;
  final String? profilePhoto;

  PostAuthor({this.id, this.username, this.profilePhoto});

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] ?? json['_id'],
      username: json['username'],
      profilePhoto: json['profilePhoto'] ?? json['profile_photo'],
    );
  }
}

class PostModel {
  final String? id;
  final String? content;
  final String? imagePath;
  int? likesCount;
  int? commentsCount;
  bool? isLikedByMe;
  final DateTime? createdAt;
  final PostAuthor? author;

  PostModel({
    this.id,
    this.content,
    this.imagePath,
    this.likesCount,
    this.commentsCount,
    this.isLikedByMe,
    this.createdAt,
    this.author,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? json['_id'],
      content: json['content'],
      imagePath: json['imagePath'] ?? json['image_path'],
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      commentsCount: json['commentsCount'] ?? json['comments_count'] ?? 0,
      isLikedByMe: json['isLikedByMe'] ?? json['is_liked_by_me'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      author:
          json['author'] != null ? PostAuthor.fromJson(json['author']) : null,
    );
  }
}

class CommentModel {
  final String? id;
  final String? content;
  final DateTime? createdAt;
  final String? authorId;
  final String? username;
  final String? profilePhoto;

  CommentModel({
    this.id,
    this.content,
    this.createdAt,
    this.authorId,
    this.username,
    this.profilePhoto,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? json['_id'],
      content: json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      authorId: json['author_id'] ?? json['authorId'],
      username: json['username'],
      profilePhoto: json['profile_photo'] ?? json['profilePhoto'],
    );
  }
}
