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
baseUrl: 'http://127.0.0.1:3000',            
            // 2. زودنا الوقت لـ 60 ثانية عشان مشكلة الـ Cold Start في السيرفرات المجانية
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            
            headers: {
              'Content-Type': 'application/json',
            },
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

          // دي بالظبط زي next() في الـ Express
          return handler.next(options);
        },

        // 2. onResponse: لو عايز تعمل حاجة لما الداتا ترجع بنجاح
        onResponse: (response, handler) {
          return handler.next(response);
        },

        // 3. onError: الجلوبال إيرور هاندلر بتاعك
        onError: (DioException e, handler) {
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
}