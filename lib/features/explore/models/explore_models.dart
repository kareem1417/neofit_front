/// Models used by the Explore feature.

class ProgramModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String duration;
  final String goal;
  final double rating;
  final int enrollmentCount;
  final String coachName;

  const ProgramModel({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.duration = '',
    this.goal = 'general',
    this.rating = 0.0,
    this.enrollmentCount = 0,
    this.coachName = 'Unknown Coach',
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Program',
      description: json['description']?.toString() ?? '',
      imageUrl: json['cover_image']?.toString() ?? '',
      duration: _formatDuration(json['duration_weeks']),
      goal: json['goal_primary']?.toString() ?? 'general',
      rating: double.tryParse(json['rating_avg']?.toString() ?? '') ?? 0.0,
      enrollmentCount:
          int.tryParse(json['enrollment_count']?.toString() ?? '') ?? 0,
      coachName: json['coach_name']?.toString() ?? 'Unknown Coach',
    );
  }

  static String _formatDuration(dynamic weeks) {
    final w = int.tryParse(weeks?.toString() ?? '') ?? 0;
    if (w <= 0) return 'Flexible';
    return '$w ${w == 1 ? 'week' : 'weeks'}';
  }
}

class SuggestedAthleteModel {
  final String id;
  final String username;
  final String? profilePhoto;
  final String level;

  const SuggestedAthleteModel({
    required this.id,
    required this.username,
    this.profilePhoto,
    this.level = '',
  });

  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username[0].toUpperCase();
  }

  factory SuggestedAthleteModel.fromMostImprovedJson(
      Map<String, dynamic> json) {
    return SuggestedAthleteModel(
      id: json['athlete_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Athlete',
      profilePhoto: json['profile_photo']?.toString(),
      level: json['level']?.toString() ?? '',
    );
  }
}

class ExplorePostModel {
  final String id;
  final String username;
  final String? profilePhoto;
  final String content;
  final String timeAgo;
  final int likes;
  final int comments;

  const ExplorePostModel({
    required this.id,
    required this.username,
    this.profilePhoto,
    this.content = '',
    this.timeAgo = '',
    this.likes = 0,
    this.comments = 0,
  });

  factory ExplorePostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return ExplorePostModel(
      id: json['id']?.toString() ?? '',
      username: author?['username']?.toString() ??
          json['username']?.toString() ??
          'User',
      profilePhoto: author?['profile_photo']?.toString() ??
          author?['profilePhoto']?.toString() ??
          json['profile_photo']?.toString(),
      content: json['content']?.toString() ?? '',
      timeAgo: _formatTimeAgo(json['created_at'] ?? json['createdAt']),
      likes: int.tryParse(json['likes_count']?.toString() ??
              json['likesCount']?.toString() ??
              '') ??
          0,
      comments: int.tryParse(json['comments_count']?.toString() ??
              json['commentsCount']?.toString() ??
              '') ??
          0,
    );
  }

  static String _formatTimeAgo(dynamic dateStr) {
    if (dateStr == null) return 'Just now';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return 'Just now';

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}
