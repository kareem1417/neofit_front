import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_service.dart';
import 'auth_state.dart';
import '../../../core/api/api_client.dart';

class TestsLoaded extends AuthState {
  final List<dynamic> tests;
  TestsLoaded({required this.tests});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  ApiClient get apiClient => authService.apiClient;

  // ==========================================
  // Signup & Registration Variables
  // ==========================================
  String? _email;
  String? _password;
  String _role = 'athlete';
  String? _dob;
  String? _selectedLevel;
  String? _selectedPlayerCategory;
  int? _selectedSportId;

  // ==========================================
  // Dashboard & Profile Variables (Public for UI access)
  // ==========================================
  String? username;
  String? fullName;
  String? profilePhoto;
  String? bio;
  String? roleModels;
  int? userAge;
  String? userLevel;
  String? userCategory;
  bool isOnboardingComplete = false;
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? metricsData;
  Map<String, dynamic>? latestSnapshot;

  List<Map<String, dynamic>> dynamicRadarAxes = [];
  int punchPowerScore = 0;
  Map<String, int> punchPowerDetails = {
    'foundation': 0,
    'accel': 0,
    'transfer': 0,
  };

  List<dynamic> availableSports = [];
  dynamic initialSnapshot;

  AuthCubit(this.authService, this.secureStorage) : super(AuthInitial());

  // ==========================================
  // Auth & Onboarding Flow
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

  void saveSignupData({
    required String email,
    required String password,
    required String role,
  }) {
    _email = email;
    _password = password;
    _role = role.toLowerCase();
  }

  void saveProfileData({required String username, required String fullName}) {
    this.username = username;
    this.fullName = fullName;
  }

  void saveDob(String dob) {
    _dob = dob;
  }

  void saveCohortData(int sportId, String level, String playerCategory) {
    _selectedSportId = sportId;
    _selectedLevel = level.toLowerCase();
    _selectedPlayerCategory = playerCategory.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> submitRegistration({required String dateOfBirth}) async {
    if (_email == null ||
        _password == null ||
        username == null ||
        fullName == null) {
      emit(AuthError(error: 'Missing required registration data.'));
      return;
    }

    emit(AuthLoading());

    try {
      final response = await authService.register(
        fullName: fullName!,
        username: username!,
        email: _email!,
        password: _password!,
        dateOfBirth: dateOfBirth,
        role: _role,
      );
      print("REGISTER RESPONSE:");

      final token = response['data']['tokens']['accessToken'];
      await secureStorage.write(key: 'jwt_token', value: token);
      print("EMITTING SUCCESS");
      emit(AuthSuccess(message: 'Account created successfully!'));
    } catch (e) {
      print("REGISTER ERROR: $e");
      emit(AuthError(error: e.toString()));
    }
  }

  Future<void> submitAthleteDetails(
    Map<int, TextEditingController> controllers,
  ) async {
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

      await authService.apiClient.dio.post(
        '/api/athletes/onboarding',
        data: {
          "sport_id": _selectedSportId,
          "level": _selectedLevel,
          "player_category": _selectedPlayerCategory,
          "test_values": testValues,
        },
      );
      isOnboardingComplete = true;
      emit(AuthSuccess(message: 'Onboarding completed successfully'));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

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

      emit(AuthSuccess(message: 'Metrics saved!'));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

  // ==========================================
  // Profile & Dashboard Flow
  // ==========================================

  Future<void> fetchDashboard() async {
    emit(AuthLoading());

    try {
      final response = await authService.apiClient.dio.get(
        '/api/athletes/dashboard',
      );
      final data = response.data['data'];

      dashboardData = data;
      userData = data['user'];
      metricsData = data['metrics'];
      latestSnapshot = data['latest_snapshot'];

      // 📌 1. استخراج بيانات اليوزر الأساسية
      if (userData != null) {
        username = userData!['username'];
        fullName = userData!['full_name'] ?? 'Athlete Name';
        profilePhoto = userData!['profile_photo'];
        bio = userData!['bio'] ?? 'Relentless pressure. Aiming for the pros.';

        final models = userData!['role_models'] as List?;
        roleModels = (models != null && models.isNotEmpty)
            ? models.join(', ')
            : 'Vasyl Lomachenko';
        // حساب العمر من تاريخ الميلاد
        if (userData!['date_of_birth'] != null) {
          DateTime dob = DateTime.parse(userData!['date_of_birth']);
          userAge = DateTime.now().year - dob.year;
        }

        // استخراج الـ Level والـ Category من الـ Profile الرياضي
        final profiles = userData!['sport_profiles'] as List?;
        if (profiles != null && profiles.isNotEmpty) {
          userLevel = profiles[0]['level'];
          userCategory = profiles[0]['player_category'];
        }
      }

      // 📌 2. استخراج بيانات الرادار
      final radar = data['radar'] as List? ?? [];
      dynamicRadarAxes = radar.map<Map<String, dynamic>>((axis) {
        return {
          'name': axis['attribute_name'].toString().toUpperCase(),
          'value': (axis['value'] as num).toDouble(),
        };
      }).toList();

      // Punch Power
      if (data['punch_power'] != null) {
        punchPowerScore = (data['punch_power']['score'] as num).toInt();
        punchPowerDetails = {
          'foundation': (data['punch_power']['foundation'] as num).toInt(),
          'accel': (data['punch_power']['accelerator'] as num).toInt(),
          'transfer': (data['punch_power']['transfer'] as num).toInt(),
        };
      }

      print("========== DASHBOARD LOADED ==========");
      print("User: $username | Age: $userAge | Category: $userCategory");
      print("Radar: $dynamicRadarAxes");
      print("Punch Power: $punchPowerScore $punchPowerDetails");

      emit(AuthSuccess(message: 'Dashboard Loaded'));
    } catch (e) {
      print("Dashboard Error: $e");
      emit(AuthError(error: e.toString()));
    }
  }

  // ==========================================
  // Snapshots & Tests Flow
  // ==========================================

  Future<void> fetchLatestSnapshot(int sportId) async {
    emit(AuthLoading());

    try {
      final testsResponse = await authService.apiClient.dio.get(
        '/api/athletes/sports/$sportId/tests',
      );

      final snapshotResponse = await authService.apiClient.dio.get(
        '/api/athletes/snapshots/latest',
      );

      final List<dynamic> attributes = testsResponse.data['data'];
      final List<dynamic> snapshotValues =
          snapshotResponse.data['data']['test_values'];

      List<dynamic> flatTests = [];

      for (var attr in attributes) {
        if (attr['attribute_tests'] != null) {
          for (var test in attr['attribute_tests']) {
            test['attribute_name'] = attr['name'];

            final value = snapshotValues
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (e) => e?['attribute_test_id'] == test['id'],
                  orElse: () => null,
                );

            test['current_value'] = value?['value'];

            flatTests.add(test);
          }
        }
      }

      emit(TestsLoaded(tests: flatTests));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

  Future<void> createManualSnapshot(
    Map<int, TextEditingController> controllers,
  ) async {
    emit(AuthLoading());

    try {
      List<Map<String, dynamic>> testValues = [];

      controllers.forEach((id, controller) {
        if (controller.text.isNotEmpty) {
          testValues.add({
            "attribute_test_id": id,
            "value": double.parse(controller.text),
          });
        }
      });

      await authService.apiClient.dio.post(
        "/api/athletes/snapshots",
        data: {"snapshot_type": "manual_update", "test_values": testValues},
      );

      emit(AuthSuccess(message: "Snapshot created"));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

  Future<void> fetchBaselineTests(int sportId) async {
    emit(AuthLoading());

    try {
      final response = await authService.apiClient.dio.get(
        '/api/athletes/sports/$sportId/tests',
      );

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

  Future<void> fetchSports() async {
    try {
      final response = await authService.apiClient.dio.get(
        '/api/athletes/sports',
      );

      availableSports = response.data['data'];
      emit(SportsLoaded(sports: availableSports));
    } catch (e) {
      print('❌ Fetch Sports Error: $e');
      emit(AuthError(error: e.toString()));
    }
  }
}
