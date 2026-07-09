import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/logic/auth_cubit.dart';
import '../../../data/post_model.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<PostModel> _posts = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final dio = context.read<AuthCubit>().authService.apiClient.dio;

      final results = await Future.wait([
        dio.get(
          '/api/users/public',
          queryParameters: {'user_id': widget.userId},
        ),
        dio.get(
          '/api/social/users/${widget.userId}/posts',
          queryParameters: {'limit': 30, 'offset': 0},
        ),
        dio.get(
          '/api/social/users/${widget.userId}/followers',
          queryParameters: {'limit': 50, 'offset': 0},
        ),
        dio.get(
          '/api/social/users/${widget.userId}/following',
          queryParameters: {'limit': 50, 'offset': 0},
        ),
      ]);

      _profile = Map<String, dynamic>.from(results[0].data['data']);

      final postsData = results[1].data['data'] as List<dynamic>? ?? [];
      _posts = postsData
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final followersData = results[2].data['data'] as List<dynamic>? ?? [];
      _followers =
          followersData.map((e) => Map<String, dynamic>.from(e)).toList();

      final followingData = results[3].data['data'] as List<dynamic>? ?? [];
      _following =
          followingData.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Public profile error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070B0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5C1)),
        ),
      );
    }

    final profile = _profile ?? {};
    final username = profile['username']?.toString() ?? 'Unknown';
    final fullName = profile['full_name']?.toString() ?? username;
    final bio = profile['bio']?.toString() ?? '';
    final photo = profile['profile_photo']?.toString();

    final followersCount = profile['followers_count'] ?? _followers.length;
    final followingCount = profile['following_count'] ?? _following.length;

    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(username),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFF14191C),
                      backgroundImage: photo != null && photo.isNotEmpty
                          ? NetworkImage(photo)
                          : null,
                      child: photo == null || photo.isEmpty
                          ? const Icon(
                              Icons.person_outline,
                              color: Colors.white24,
                              size: 42,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@$username',
                      style: const TextStyle(color: Colors.white38),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stat(
                          value: _posts.length.toString(),
                          label: 'Posts',
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                        const SizedBox(width: 28),
                        _stat(
                          value: followersCount.toString(),
                          label: 'Followers',
                          onTap: () => _showUsersSheet('Followers', _followers),
                        ),
                        const SizedBox(width: 28),
                        _stat(
                          value: followingCount.toString(),
                          label: 'Following',
                          onTap: () => _showUsersSheet('Following', _following),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _tabs(),
                    const SizedBox(height: 24),
                    if (_selectedTab == 0)
                      _overview(profile)
                    else
                      _postsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(String username) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              '@$username',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      children: [
        _tab('OVERVIEW', 0),
        _tab('POSTS', 1),
      ],
    );
  }

  Widget _tab(String title, int index) {
    final selected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              color: selected ? const Color(0xFF00E5C1) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _overview(Map<String, dynamic> profile) {
    final profiles = profile['user_sport_profiles'] as List? ??
        profile['sport_profiles'] as List? ??
        [];

    final sportProfile = profiles.isNotEmpty
        ? Map<String, dynamic>.from(profiles.first)
        : <String, dynamic>{};

    final sport = sportProfile['sports']?['name']?.toString() ??
        sportProfile['sport_name']?.toString() ??
        'Unknown Sport';

    final level = sportProfile['level']?.toString() ?? '--';
    final category = sportProfile['player_category']?.toString() ??
        sportProfile['weight_class']?.toString() ??
        '--';

    return _card(
      title: 'ATHLETE INFO',
      child: Column(
        children: [
          _infoRow('Sport', sport),
          _infoRow('Level', level),
          _infoRow('Category', category),
        ],
      ),
    );
  }

  Widget _postsSection() {
    if (_posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text(
          'No posts yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return Column(
      children: _posts.map(_postCard).toList(),
    );
  }

  Widget _postCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((post.content ?? '').trim().isNotEmpty)
            Text(
              post.content!,
              style: const TextStyle(color: Colors.white70),
            ),
          if (post.imagePath != null && post.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imagePath!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1315),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E262A)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showUsersSheet(String title, List<Map<String, dynamic>> users) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF09090b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users yet',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final id = user['id']?.toString();
                            final username =
                                user['username']?.toString() ?? 'Unknown';
                            final photo = user['profile_photo']?.toString();

                            return ListTile(
                              onTap: id == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PublicProfileScreen(userId: id),
                                        ),
                                      );
                                    },
                              leading: CircleAvatar(
                                backgroundImage:
                                    photo != null && photo.isNotEmpty
                                        ? NetworkImage(photo)
                                        : null,
                                child: photo == null || photo.isEmpty
                                    ? Text(username[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(
                                username,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
