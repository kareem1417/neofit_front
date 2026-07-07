import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/constants.dart';
import '../../../features/auth/logic/auth_cubit.dart';
import '../../../features/home/logic/social_cubit.dart';
import '../../../features/onboarding/logic/user_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  Uint8List? _selectedPostImageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedPostImageBytes = bytes;
      });
    }
  }

  Future<void> _handlePost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedPostImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<SocialCubit>();
      await cubit.createPost(
        content: content,
        imageBytes: _selectedPostImageBytes != null
            ? _selectedPostImageBytes!.toList()
            : null,
      );

      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate post was created
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final userCubit = context.read<UserCubit>();

    // Prefer the dashboard-loaded name from AuthCubit; fall back to onboarding controller
    final displayUsername = authCubit.fullName ??
        authCubit.username ??
        (userCubit.fullNameController.text.trim().isNotEmpty
            ? userCubit.fullNameController.text.trim()
            : 'athlete');

    // Get user avatar from UserCubit or use default
    final userAvatar = userCubit.profileImageUrl != null
        ? NetworkImage('${AppConstants.baseUrl}${userCubit.profileImageUrl}')
        : (userCubit.pickedImageBytes != null
            ? MemoryImage(userCubit.pickedImageBytes!)
            : const AssetImage('assets/default_avatar.png') as ImageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handlePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00E5C1)),
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: Color(0xFF00E5C1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1E262A),
                        backgroundImage: userAvatar,
                        onBackgroundImageError: (_, __) {},
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@$displayUsername',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E262A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.public,
                                    color: Colors.white24, size: 12),
                                const SizedBox(width: 4),
                                const Text(
                                  'Public',
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 11),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.white24, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(color: Colors.white10, fontSize: 18),
                      border: InputBorder.none,
                    ),
                  ),
                  if (_selectedPostImageBytes != null) ...[
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _selectedPostImageBytes!,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPostImageBytes = null),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1315),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: _buildToolbarIcon(Icons.image_outlined),
                ),
                const SizedBox(width: 20),
                _buildToolbarIcon(Icons.person_add_alt_1_outlined),
                const SizedBox(width: 20),
                _buildToolbarIcon(Icons.location_on_outlined),
                const SizedBox(width: 20),
                _buildToolbarIcon(Icons.emoji_emotions_outlined),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Color(0xFF00E5C1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon) {
    return Icon(icon, color: Colors.white60, size: 24);
  }
}
