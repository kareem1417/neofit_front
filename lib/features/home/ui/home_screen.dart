import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// ✅ Correct imports
import '../../onboarding/logic/user_cubit.dart';
import '../../onboarding/logic/user_state.dart';
import '../logic/social_cubit.dart';
import '../../../data/post_model.dart';
import 'comments_bottom_sheet.dart';
import 'create_post_screen.dart';

// import '../../widgets/comments_bottom_sheet.dart'; // Will implement later
// import '../explore/ai_advisor_chat_screen.dart'; // Will implement later

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load feed when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialCubit>().loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NEOFIT',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          _navigateToCreatePost();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Posts feed with state management
            Expanded(
              child: BlocConsumer<SocialCubit, SocialState>(
                listener: (context, state) {
                  if (state is SocialError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  if (state is SocialPostCreated) {
                    // Refresh feed after creating a post
                    context.read<SocialCubit>().loadFeed();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post created successfully!'),
                        backgroundColor: Color(0xFF00E5C1),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is SocialLoading && state is! SocialFeedLoaded) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00E5C1),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _getPostsCount(state) + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildWhatsOnYourMindBox(context);
                      }

                      final posts = _getPosts(state);
                      if (index - 1 >= posts.length) {
                        return const SizedBox.shrink();
                      }

                      final post = posts[index - 1];
                      return InteractivePostCard(post: post);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // AI Advisor - will implement later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI Advisor Screen coming soon!')),
          );
        },
        backgroundColor: const Color(0xFF18181b),
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome, color: Color(0xFF2DD4BF)),
      ),
    );
  }

  int _getPostsCount(SocialState state) {
    if (state is SocialFeedLoaded) {
      return state.posts.length;
    }
    return 0;
  }

  List<PostModel> _getPosts(SocialState state) {
    if (state is SocialFeedLoaded) {
      return state.posts;
    }
    return [];
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(),
      ),
    );

    if (result == true) {
      // Post was created, refresh feed
      context.read<SocialCubit>().loadFeed();
    }
  }

  // Create Post Box
  Widget _buildWhatsOnYourMindBox(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        final userCubit = context.read<UserCubit>();

        // Get user avatar
        Widget buildAvatar() {
          if (userCubit.profileImageUrl != null) {
            return CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E262A),
              backgroundImage: NetworkImage(
                'http://192.168.1.8:3000${userCubit.profileImageUrl}',
              ),
            );
          } else if (userCubit.pickedImageBytes != null) {
            return CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E262A),
              backgroundImage: MemoryImage(userCubit.pickedImageBytes!),
            );
          } else {
            return const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF1E262A),
              child: Icon(Icons.person, color: Colors.white24),
            );
          }
        }

        return InkWell(
          onTap: _navigateToCreatePost,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1315),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF1E262A)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "What's on your mind?",
                          style: TextStyle(color: Colors.white24, fontSize: 14),
                        ),
                        Icon(
                          Icons.image_outlined,
                          color: Colors.white24,
                          size: 20,
                        ),
                      ],
                    ),
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

// ==========================================
// POST CARD WIDGET
// ==========================================
class InteractivePostCard extends StatefulWidget {
  final PostModel post;
  const InteractivePostCard({super.key, required this.post});

  @override
  State<InteractivePostCard> createState() => _InteractivePostCardState();
}

class _InteractivePostCardState extends State<InteractivePostCard> {
  bool _isLiking = false;

  void toggleLike() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);

    try {
      final cubit = context.read<SocialCubit>();

      // Optimistic update
      final previousLiked = widget.post.isLikedByMe ?? false;
      final previousCount = widget.post.likesCount ?? 0;

      setState(() {
        widget.post.isLikedByMe = !previousLiked;
        widget.post.likesCount =
            previousLiked ? previousCount - 1 : previousCount + 1;
      });

      // Actually call the API
      if (previousLiked) {
        await cubit.unlikePost(widget.post.id!);
      } else {
        await cubit.likePost(widget.post.id!);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        widget.post.isLikedByMe = !(widget.post.isLikedByMe ?? false);
        widget.post.likesCount = (widget.post.likesCount ?? 0) +
            ((widget.post.isLikedByMe ?? false) ? 1 : -1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to ${widget.post.isLikedByMe == true ? "like" : "unlike"} post')),
      );
    } finally {
      setState(() => _isLiking = false);
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: widget.post),
    ).then((_) {
      // تحديث الشاشة بعد ما تقفل الـ BottomSheet عشان لو عدد الكومنتات زاد يظهر
      setState(() {});
    });
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isLiked = post.isLikedByMe ?? false;
    final likesCount = post.likesCount ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111619).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E262A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: post.author?.profilePhoto != null
                    ? NetworkImage(
                        'http://192.168.1.8:3000${post.author!.profilePhoto}',
                      )
                    : const NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
                      ) as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author?.username ?? 'Unknown User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white24),
            ],
          ),

          // Content
          if (post.content != null && post.content!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              post.content!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          // Image
          if (post.imagePath != null && post.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'http://192.168.1.8:3000${post.imagePath}',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: const Color(0xFF1E262A),
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.white24),
                    ),
                  );
                },
              ),
            ),
          ],

          // Actions
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: toggleLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white24,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        color: isLiked ? Colors.red : Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: _showComments,
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white24,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.commentsCount?.toString() ?? '0',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
