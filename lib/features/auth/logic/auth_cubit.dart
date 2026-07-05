import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_service.dart';
import 'auth_state.dart';

/// State for when baseline tests are loaded successfully.
class TestsLoaded extends AuthState {
  final List<dynamic> tests;
  TestsLoaded({required this.tests});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;

  // متغيرات (حصالة) عشان نحفظ الداتا المؤقتة بين الشاشات
  String? _email;
  String? _password;
  String _role = 'athlete'; 
  String? _username;

  // متغير يشيل الرياضات المتاحة
  List<dynamic> availableSports = [];

  AuthCubit(this.authService, this.secureStorage) : super(AuthInitial());

  // ==========================================
  // Login Flow
  // ==========================================
  Future<void> loginUser(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await authService.login(email, password);
      final token = response['token']; 
      await secureStorage.write(key: 'jwt_token', value: token);
      emit(AuthSuccess(message: 'Logged in successfully'));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

  // ==========================================
  // Registration Flow (Multi-step)
  // ==========================================

  void saveSignupData({required String email, required String password, required String role}) {
    _email = email;
    _password = password;
    _role = role.toLowerCase();
  }

  void saveProfileData({required String username}) {
    _username = username;
  }
  
  Future<void> submitRegistration({required String dateOfBirth}) async {
    print('--- REGISTRATION ATTEMPT ---');
    print('Email: $_email');
    print('Username: $_username');
    print('Role: $_role');
    print('DOB: $dateOfBirth');

    if (_email == null || _password == null || _username == null) {
      print('❌ ERROR: Missing data in Cubit memory!');
      emit(AuthError(error: 'Missing required registration data.'));
      return;
    }

    emit(AuthLoading());
    
    try {
      print('⏳ Sending request to Render Server...');
      final response = await authService.register(
        username: _username!,
        email: _email!,
        password: _password!,
        dateOfBirth: dateOfBirth,
        role: _role,
      );
      
      print('✅ SUCCESS! Server responded: $response');
      final token = response['data']['tokens']['accessToken'];
      await secureStorage.write(key: 'jwt_token', value: token);
      
      emit(AuthSuccess(message: 'Account created successfully!'));
    } catch (e) {
      print('❌ API CATCH ERROR: $e'); 
      emit(AuthError(error: e.toString()));
    }
  }

  // ==========================================
  // User Metrics Flow
  // ==========================================
  Future<void> submitUserMetrics({
    required double height,
    required double weight,
    required String goal,
    required int trainingDays,
    required double yearsTraining,
    required bool hasInjury,
  }) async {
    emit(AuthLoading());
    try {
      await authService.apiClient.dio.post(
        '/api/athletes/metrics',
        data: {
          'height_cm': height,
          'weight_kg': weight,
          'goal': goal,
          'training_days_per_week': trainingDays,
          'years_training': yearsTraining,
          'has_injury_history': hasInjury,
        },
      );
      
      emit(AuthSuccess(message: 'Metrics saved successfully!'));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

  // ==========================================
  // Dynamic Sports & Baseline Tests Flow
  // ==========================================
  
  // 1. جلب الرياضات
  // 1. جلب الرياضات
  Future<void> fetchSports() async {
    try {
      // 🚀 ضفنا /athletes/ هنا
      final response = await authService.apiClient.dio.get('/api/athletes/sports'); 
      availableSports = response.data['data'];
      emit(SportsLoaded(sports: availableSports));
    } catch (e) {
      print('❌ Fetch Sports Error: $e');
      emit(AuthError(error: e.toString()));
    }
  }

  // 2. جلب التيستات وفك التداخل (Flattening)
  Future<void> fetchBaselineTests(int sportId) async {
    emit(AuthLoading());
    try {
      // 🚀 ضفنا /athletes/ هنا
      final response = await authService.apiClient.dio.get('/api/athletes/baseline-tests/$sportId');
      final List<dynamic> attributes = response.data['data'];
      
      List<dynamic> flatTests = [];
      for (var attr in attributes) {
        if (attr['attribute_tests'] != null) {
          for (var test in attr['attribute_tests']) {
            test['attribute_name'] = attr['name']; 
            flatTests.add(test);
          }
        }
      }
      
      emit(TestsLoaded(tests: flatTests));
    } catch (e) {
      print('❌ Fetch Tests Error: $e');
      emit(AuthError(error: e.toString()));
    }
  }

  // 3. إرسال بيانات الرياضي والتيستات مع بعض
  Future<void> submitAthleteDetails(int sportId, Map<int, TextEditingController> controllers) async {
    emit(AuthLoading());
    
    try {
      List<Map<String, dynamic>> testValues = [];
      
      controllers.forEach((testId, controller) {
        if (controller.text.isNotEmpty) {
          testValues.add({
            "attribute_test_id": testId,
            "value": double.tryParse(controller.text) ?? 0.0,
          });
        }
      });

      // 🚀 ضفنا /athletes/ هنا
      await authService.apiClient.dio.post('/api/athletes/snapshots', data: {
        "sport_id": sportId,
        "snapshot_type": "manual_update", 
        "test_values": testValues,
      });

      emit(AuthSuccess(message: 'Athlete details submitted successfully'));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }
}