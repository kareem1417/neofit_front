import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  // Constructor
  ApiClient()
    : dio = Dio(
        BaseOptions(
          // 1. حطينا اللينك بتاع Render
          baseUrl: 'http://192.168.1.8:3000',
          // 1. استخدم 10.0.2.2 للمحاكي، أو 127.0.0.1 لو بتشغل على ديسكتوب/ويب
          // تأكد إن الباك إند سيرفر شغال الأول!
          // 2. زودنا الوقت لـ 60 ثانية عشان مشكلة الـ Cold Start في السيرفرات المجانية
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),

          headers: {'Content-Type': 'application/json'},
        ),
      ),
      secureStorage = const FlutterSecureStorage() {
    // بننده على الـ Middlewares بتاعتنا أول ما الكلاس يشتغل
    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        // 1. onRequest: ده الـ Middleware اللي بيشتغل قبل ما الريكويست يروح للباك إيند
        onRequest: (options, handler) async {
          // بنقرا التوكن المتسيف في الموبايل
          final token = await secureStorage.read(key: 'jwt_token');

          // لو التوكن موجود، بنحطه في الـ Headers
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 🆕 Add this for debugging
          print('🚀 Request: ${options.method} ${options.path}');
          print('📤 Headers: ${options.headers}');
          if (options.data != null) {
            print('📤 Body: ${options.data}');
          }

          // دي بالظبط زي next() في الـ Express
          return handler.next(options);
        },

        // 2. onResponse: لو عايز تعمل حاجة لما الداتا ترجع بنجاح
        onResponse: (response, handler) {
          // 🆕 Add this for debugging
          print(
            '✅ Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          print('📥 Data: ${response.data}');
          return handler.next(response);
        },

        // 3. onError: الجلوبال إيرور هاندلر بتاعك
        onError: (DioException e, handler) {
          // 🆕 Add better error handling
          print('❌ Error: ${e.message}');
          print('❌ Status Code: ${e.response?.statusCode}');
          print('❌ Response Data: ${e.response?.data}');

          // لو الباك إيند رجع 401 (التوكن خلص أو غلط)
          if (e.response?.statusCode == 401) {
            print('Unauthorized: Token might be expired. Need to logout.');
            // قدام هنحط هنا كود يمسح التوكن ويطرد اليوزر لشاشة اللوجين
          }

          return handler.next(e);
        },
      ),
    );
  }

  // 🆕 Helper method to check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  // 🆕 Helper method to clear auth data (for logout)
  Future<void> clearAuthData() async {
    await secureStorage.delete(key: 'jwt_token');
    // Add any other tokens or user data you want to clear
  }
}
