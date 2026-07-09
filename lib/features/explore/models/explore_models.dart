class ProgramModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String duration;
  final double rating;
  final int enrollmentCount;
  final String goal;
  final String level;
  final String coachName;
  final String sportName;

  const ProgramModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.rating,
    required this.enrollmentCount,
    required this.goal,
    required this.level,
    required this.coachName,
    required this.sportName,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_image']?.toString() ?? '';
    final imageUrl =
        cover.startsWith('http') ? cover : 'http://192.168.1.8:3000$cover';

    return ProgramModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Program',
      description: json['description']?.toString() ?? '',
      imageUrl: cover.isEmpty ? '' : imageUrl,
      duration: '${json['duration_weeks'] ?? 0} WEEKS',
      rating: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0,
      enrollmentCount:
          int.tryParse(json['enrollment_count']?.toString() ?? '0') ?? 0,
      goal: json['goal_primary']?.toString() ?? 'general',
      level: json['level_target']?.toString() ?? 'beginner',
      coachName: json['coach_name']?.toString() ?? 'Unknown Coach',
      sportName: json['sport_name']?.toString() ?? 'General',
    );
  }
}

class SuggestedAthleteModel {
  final String userId;
  final String username;
  final String? fullName;
  final String? profilePhoto;
  final String level;
  final bool isCurrentUser;
  final double? score;
  final double? delta;
  final String? bio;
  final String? role;
  final bool isFollowedByMe;

  const SuggestedAthleteModel({
    required this.userId,
    required this.username,
    this.fullName,
    this.profilePhoto,
    required this.level,
    required this.isCurrentUser,
    this.score,
    this.delta,
    this.bio,
    this.role,
    this.isFollowedByMe = false,
  });

  String get initials {
    final clean = username.trim();
    if (clean.isEmpty) return 'A';
    return clean.substring(0, 1).toUpperCase();
  }

  SuggestedAthleteModel copyWith({
    String? userId,
    String? username,
    String? fullName,
    String? profilePhoto,
    String? level,
    bool? isCurrentUser,
    double? score,
    double? delta,
    String? bio,
    String? role,
    bool? isFollowedByMe,
  }) {
    return SuggestedAthleteModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      level: level ?? this.level,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      score: score ?? this.score,
      delta: delta ?? this.delta,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
    );
  }

  factory SuggestedAthleteModel.fromMostImprovedJson(
    Map<String, dynamic> json,
  ) {
    final photo = json['profile_photo']?.toString();
    final photoUrl = (photo != null && photo.isNotEmpty)
        ? (photo.startsWith('http') ? photo : 'http://192.168.1.8:3000$photo')
        : null;

    return SuggestedAthleteModel(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      profilePhoto: photoUrl,
      level: 'Most Improved',
      isCurrentUser: json['is_current_user'] == true,
      delta: double.tryParse(json['punch_power_delta']?.toString() ?? '0'),
    );
  }

  factory SuggestedAthleteModel.fromExplorePeopleJson(
    Map<String, dynamic> json,
  ) {
    final photo = json['profile_photo']?.toString();
    final photoUrl = (photo != null && photo.isNotEmpty)
        ? (photo.startsWith('http') ? photo : 'http://192.168.1.8:3000$photo')
        : null;

    final username = json['username']?.toString() ?? 'Unknown';
    final fullName = json['full_name']?.toString();

    return SuggestedAthleteModel(
      userId: json['id']?.toString() ?? '',
      username: (fullName != null && fullName.trim().isNotEmpty)
          ? fullName
          : username,
      fullName: fullName,
      profilePhoto: photoUrl,
      level: json['role']?.toString() ?? 'Athlete',
      role: json['role']?.toString(),
      bio: json['bio']?.toString(),
      isCurrentUser: false,
      isFollowedByMe: json['is_followed_by_me'] == true,
    );
  }
}

class ExplorePostModel {
  final String id;
  final String username;
  final String? profilePhoto;
  final String content;
  final String? imagePath;
  final int likes;
  final int comments;
  final bool isLikedByMe;
  final String timeAgo;
  final String? authorId;

  const ExplorePostModel({
    required this.id,
    required this.username,
    this.profilePhoto,
    required this.content,
    this.imagePath,
    required this.likes,
    required this.comments,
    required this.isLikedByMe,
    required this.timeAgo,
    this.authorId,
  });

  factory ExplorePostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ??
        json['users'] as Map<String, dynamic>? ??
        {};

    final photo = author['profile_photo']?.toString() ??
        author['profilePhoto']?.toString();

    final photoUrl = (photo != null && photo.isNotEmpty)
        ? (photo.startsWith('http') ? photo : 'http://192.168.1.8:3000$photo')
        : null;

    final image =
        json['image_path']?.toString() ?? json['imagePath']?.toString();

    final imageUrl = (image != null && image.isNotEmpty)
        ? (image.startsWith('http') ? image : 'http://192.168.1.8:3000$image')
        : null;

    final createdAtRaw =
        json['created_at']?.toString() ?? json['createdAt']?.toString();

    return ExplorePostModel(
      id: json['id']?.toString() ?? '',
      username: author['username']?.toString() ?? 'Unknown',
      profilePhoto: photoUrl,
      content: json['content']?.toString() ?? '',
      imagePath: imageUrl,
      authorId: author['id']?.toString() ??
          author['user_id']?.toString() ??
          json['user_id']?.toString() ??
          json['author_id']?.toString(),
      likes: int.tryParse(
            (json['like_count'] ??
                    json['likes_count'] ??
                    json['likesCount'] ??
                    0)
                .toString(),
          ) ??
          0,
      comments: int.tryParse(
            (json['comment_count'] ??
                    json['comments_count'] ??
                    json['commentsCount'] ??
                    0)
                .toString(),
          ) ??
          0,
      isLikedByMe:
          json['is_liked_by_me'] == true || json['isLikedByMe'] == true,
      timeAgo: _formatTimeAgo(createdAtRaw),
    );
  }

  ExplorePostModel copyWith({
    String? id,
    String? username,
    String? profilePhoto,
    String? content,
    String? imagePath,
    int? likes,
    int? comments,
    bool? isLikedByMe,
    String? authorId,
    String? timeAgo,
  }) {
    return ExplorePostModel(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      authorId: authorId ?? this.authorId,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }

  static String _formatTimeAgo(String? raw) {
    if (raw == null) return 'Just now';
    final date = DateTime.tryParse(raw);
    if (date == null) return 'Just now';

    final diff = DateTime.now().difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
