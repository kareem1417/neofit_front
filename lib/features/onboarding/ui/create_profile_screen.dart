// lib/features/onboarding/ui/create_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/user_cubit.dart';
import '../logic/user_state.dart';
import '../../auth/logic/auth_cubit.dart';
import 'AnotherAthleteDetailsScreen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  int _bioLength = 0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<UserCubit>();
    _bioLength = cubit.bioController.text.length;
    cubit.bioController.addListener(_updateBioLength);
  }

  void _updateBioLength() {
    if (mounted) {
      setState(() {
        _bioLength = context.read<UserCubit>().bioController.text.length;
      });
    }
  }

  @override
  void dispose() {
    context.read<UserCubit>().bioController.removeListener(_updateBioLength);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserCubit>();

    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) async {
        if (state is UserSuccess) {
          await context.read<AuthCubit>().fetchDashboard();

          if (!context.mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AnotherAthleteDetailsScreen(),
            ),
          );
        } else if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.9),
                  radius: 1.2,
                  colors: [Color(0xFF0F1E21), Color(0xFF070B0D)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'COMPLETE PROFILE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),

                  // Progress Bar
                  Stack(
                    children: [
                      Container(height: 2, color: const Color(0xFF14191C)),
                      Container(
                        height: 2,
                        width: MediaQuery.of(context).size.width * 0.50,
                        color: const Color(0xFF00E5C1),
                      ),
                    ],
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: cubit.createProfileFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),

                            // Profile Picture
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 132,
                                    height: 132,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0F1315),
                                      border: Border.all(
                                        color: cubit.hasImage
                                            ? const Color(0xFF00E5C1)
                                            : const Color(0xFF1E262A),
                                        width: 2,
                                      ),
                                    ),
                                    child: cubit.pickedImageBytes != null
                                        ? ClipOval(
                                            child: Image.memory(
                                              cubit.pickedImageBytes!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_outline,
                                            size: 54,
                                            color: Colors.white24,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => cubit.pickProfileImage(),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF00E5C1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x4000E5C1),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: state is UserLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF070B0D),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt_outlined,
                                                color: Color(0xFF070B0D),
                                                size: 18,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (cubit.hasImage)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '✓ Photo uploaded successfully',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF00E5C1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 48),
                            _buildLabel('FULL NAME *'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: cubit.fullNameController,
                              hint: 'John Doe',
                              prefixIcon: Icons.person_outline,
                              // ضيف الـ validator ده هنا
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabel('BIO *'),
                                Text(
                                  '$_bioLength / 150',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white24,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: cubit.bioController,
                              maxLines: 5,
                              maxLength: 150,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Bio is required';
                                }
                                return null;
                              },
                              buildCounter: (
                                context, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) =>
                                  null,
                              decoration: _inputDecoration(
                                hint:
                                    'Tell the community a little about yourself...',
                              ).copyWith(
                                  contentPadding: const EdgeInsets.all(16)),
                            ),
                            const SizedBox(height: 32),

                            // Role Models
                            _buildLabel('ROLE MODELS (Optional)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: cubit.roleModelsController,
                              hint:
                                  'e.g., Mike Tyson, Vasyl Lomachenko (comma separated)',
                              prefixIcon: Icons.star_outline,
                            ),
                            const SizedBox(height: 32),

                            // Social Links
                            _buildLabel('SOCIAL LINKS (Optional)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: cubit.instagramController,
                              hint: 'Instagram username (e.g. neo_fit)',
                              prefixIcon: Icons.camera_alt_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: cubit.youtubeController,
                              hint: 'YouTube channel URL',
                              prefixIcon: Icons.play_circle_outline,
                            ),
                            const SizedBox(height: 48),

                            // Next Button
                            ElevatedButton(
                              onPressed: state is UserLoading
                                  ? null
                                  : () {
                                      if (cubit
                                          .createProfileFormKey.currentState!
                                          .validate()) {
                                        cubit.createProfile();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5C1),
                                foregroundColor: const Color(0xFF070B0D),
                                shadowColor: const Color(
                                  0xFF00E5C1,
                                ).withValues(alpha: 0.3),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: state is UserLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF070B0D),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Complete Profile',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white24,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    String? Function(String?)? validator, // ضفنا السطر ده
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator, // وضفنا السطر ده
      decoration: _inputDecoration(hint: hint, prefixIcon: prefixIcon),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white12, fontSize: 15),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.white24, size: 20)
          : null,
      filled: true,
      fillColor: const Color(0xFF0F1315),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E262A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E262A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00E5C1)),
      ),
    );
  }
}
