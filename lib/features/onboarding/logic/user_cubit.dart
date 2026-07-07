// lib/features/onboarding/logic/user_cubit.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // ← Add this for Dio classes
import '../../../core/api/api_client.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final ApiClient apiClient;

  UserCubit({required this.apiClient}) : super(UserInitial());

  // Form key
  final GlobalKey<FormState> createProfileFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController bioController = TextEditingController();
  final TextEditingController roleModelsController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  // Profile image
  Uint8List? pickedImageBytes;
  bool hasImage = false;
  String? profileImageUrl;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickProfileImage() async {
    try {
      emit(UserLoading());

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        pickedImageBytes = bytes;
        hasImage = true;

        // Upload the image immediately
        await _uploadProfileImage(bytes);
      } else {
        // User cancelled picking image
        emit(UserInitial());
      }
    } catch (e) {
      emit(UserError(message: 'Failed to pick image: $e'));
    }
  }

  Future<void> _uploadProfileImage(Uint8List bytes) async {
    try {
      // Create multipart file
      final MultipartFile multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: 'profile_photo.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      );

      final FormData formData = FormData.fromMap({'photo': multipartFile});

      final response = await apiClient.dio.post(
        '/api/users/upload-photo',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data['success'] == true) {
        profileImageUrl = response.data['profile_photo_url'];
        emit(UserSuccess(message: 'Profile photo uploaded successfully'));
      }
    } catch (e) {
      print('Upload photo error: $e');
      emit(UserError(message: 'Failed to upload photo: ${e.toString()}'));
    }
  }

  Future<void> createProfile() async {
    // Validate form
    if (!createProfileFormKey.currentState!.validate()) {
      return;
    }

    emit(UserLoading());

    try {
      // 1. Update user profile (bio, social links, role models)
      final socialLinks = <String, String>{};

      if (instagramController.text.trim().isNotEmpty) {
        socialLinks['instagram'] = instagramController.text.trim();
      }

      if (youtubeController.text.trim().isNotEmpty) {
        socialLinks['youtube'] = youtubeController.text.trim();
      }

      // Parse role models - split by comma and trim
      List<String> roleModelsList = [];
      if (roleModelsController.text.isNotEmpty) {
        roleModelsList = roleModelsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final profileData = {
        'bio': bioController.text.trim(),
        'role_models': roleModelsList,
        'social_links': socialLinks,
      };

      print('📤 Sending profile data: $profileData');

      final updateResponse = await apiClient.dio.patch(
        '/api/users/me',
        data: profileData,
      );

      print('📥 Update response: ${updateResponse.data}');

      if (updateResponse.data['success'] != true) {
        throw Exception(
          updateResponse.data['message'] ?? 'Failed to update profile',
        );
      }

      // 2. If there's an image but it wasn't uploaded yet, upload it
      if (pickedImageBytes != null && profileImageUrl == null) {
        await _uploadProfileImage(pickedImageBytes!);
      }

      emit(UserSuccess(message: 'Profile created successfully!'));
    } catch (e) {
      print('❌ Create profile error: $e');
      emit(UserError(message: 'Failed to create profile: ${e.toString()}'));
    }
  }

  // Helper method to check if all required fields are filled
  bool isProfileComplete() {
    return bioController.text.trim().isNotEmpty;
  }

  @override
  Future<void> close() {
    bioController.dispose();
    roleModelsController.dispose();
    instagramController.dispose();
    youtubeController.dispose();
    return super.close();
  }
}
