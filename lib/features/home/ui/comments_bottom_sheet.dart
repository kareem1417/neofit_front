import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/post_model.dart';
import '../logic/social_cubit.dart';
import '../../auth/logic/auth_cubit.dart'; // مسار الـ AuthCubit بتاعك

class CommentsBottomSheet extends StatefulWidget {
  final PostModel post;
  const CommentsBottomSheet({super.key, required this.post});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final cubit = context.read<SocialCubit>();
      final comments = await cubit.getComments(widget.post.id!);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final cubit = context.read<SocialCubit>();
      final newComment = await cubit.addComment(
          widget.post.id!, _commentController.text.trim());

      setState(() {
        _comments.add(newComment); // إضافة الكومنت في اللستة
        widget.post.commentsCount = (widget.post.commentsCount ?? 0) + 1;
        _commentController.clear();
      });

      // ننزل لآخر كومنت
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final myAvatar = authCubit.profilePhoto != null
        ? NetworkImage('http://192.168.1.8:3000${authCubit.profilePhoto}')
        : const AssetImage('assets/default_avatar.png') as ImageProvider;

    return DraggableScrollableSheet(
      initialChildSize:
          0.9, // يفتح واخد مساحة كبيرة عشان يشيل البوست والكومنتات
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF070B0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header Indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Post Content Header (زي فيسبوك)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      widget.post.author?.profilePhoto != null
                                          ? NetworkImage(
                                              'http://192.168.1.8:3000${widget.post.author!.profilePhoto}')
                                          : const AssetImage(
                                                  'assets/default_avatar.png')
                                              as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.post.author?.username ?? 'Unknown',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (widget.post.content != null &&
                                widget.post.content!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.post.content!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                            if (widget.post.imagePath != null &&
                                widget.post.imagePath!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'http://192.168.1.8:3000${widget.post.imagePath}',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Divider(color: Colors.white10, thickness: 1),

                      // 2. Comments List
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00E5C1))),
                        )
                      else if (_comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text("No comments yet. Be the first!",
                                style: TextStyle(color: Colors.white24)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: comment.profilePhoto !=
                                            null
                                        ? NetworkImage(
                                            'http://192.168.1.8:3000${comment.profilePhoto}')
                                        : const AssetImage(
                                                'assets/default_avatar.png')
                                            as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E262A),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.username ?? 'User',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.content ?? '',
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12),
                                          child: Text(
                                            _formatTimeAgo(comment.createdAt),
                                            style: const TextStyle(
                                                color: Colors.white24,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Comment Input Area
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  left: 16,
                  right: 16,
                  top: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F1315),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: myAvatar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E262A),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle:
                                TextStyle(color: Colors.white24, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isPosting
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF00E5C1))),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: Color(0xFF00E5C1)),
                            onPressed: _addComment,
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
