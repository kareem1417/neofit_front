import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/explore_cubit.dart';
import '../../logic/explore_state.dart';
import '../../models/explore_models.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../profile/ui/profile_screen.dart';
import '../../../profile/ui/public_profile_screen.dart';

class ExplorePostsTab extends StatelessWidget {
  const ExplorePostsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreCubit, ExploreState>(
      builder: (context, state) {
        if (state is ExploreLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2dd4bf)),
          );
        }

        if (state is ExploreError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        if (state is ExploreLoaded) {
          if (state.posts.isEmpty) {
            return const Center(
              child: Text(
                'No posts yet. Follow athletes to see their posts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2dd4bf),
            backgroundColor: const Color(0xFF18181b),
            onRefresh: () => context.read<ExploreCubit>().loadExploreData(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                return _ExplorePostCard(post: state.posts[index]);
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

class _ExplorePostCard extends StatelessWidget {
  final ExplorePostModel post;

  const _ExplorePostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Wrap CircleAvatar with GestureDetector for navigation
                GestureDetector(
                  onTap: () {
                    final authorId = post.authorId;
                    final myId =
                        context.read<AuthCubit>().userData?['id']?.toString();

                    if (authorId == null || authorId.isEmpty) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => authorId == myId
                            ? const ProfileScreen()
                            : PublicProfileScreen(userId: authorId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        const Color(0xFF2dd4bf).withValues(alpha: 0.12),
                    backgroundImage: post.profilePhoto != null
                        ? NetworkImage(post.profilePhoto!)
                        : null,
                    child: post.profilePhoto == null
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFF2dd4bf),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  post.timeAgo,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (post.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                post.content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          if (post.imagePath != null && post.imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imagePath!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    context.read<ExploreCubit>().togglePostLike(post);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLikedByMe
                            ? Colors.redAccent
                            : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likes}',
                        style: const TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.comments}',
                  style: const TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
