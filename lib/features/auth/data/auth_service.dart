import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AuthService {
  final ApiClient apiClient;

  // بنعمل Dependency Injection للـ ApiClient اللي لسه كاتبينه
  AuthService({required this.apiClient});

  // 1. Login Method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      // بنرجع الداتا اللي جاية من الباك إيند
      return response.data;
    } on DioException catch (e) {
      // السطر ده هيطبعلك الرد بتاع الباك إيند بالكامل في التيرمينال
      print('🔥 DIO ERROR RESPONSE: ${e.response?.data}');

      // هنا بنحاول نقرأ الـ message أو الـ error اللي جاية من النود جي إس
      final errorMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to register';
      throw Exception(errorMessage);
    }
  }

  // 2. Register Method
  Future<Map<String, dynamic>> register({
    required String username,
    // required String fullName,
    required String email,
    required String password,
    required String dateOfBirth,
    required String role,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/register',
        data: {
          'username': username,
          //'full_name': fullName,
          'email': email,
          'password': password,
          'date_of_birth': dateOfBirth,
          'role': role,
        },
      );
      return response.data;
    } on DioException catch (e) {
      // السطر ده هو اللي هيطلع لنا السبب الحقيقي في التيرمينال
      print('🚨 ERROR RESPONSE FROM SERVER: ${e.response?.data}');

      // محاولة ذكية لاستخراج الرسالة الفعلية من السيرفر
      final serverMessage =
          e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Failed to register';
      throw Exception(serverMessage);
    }
  }
}
