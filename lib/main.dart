import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/api/api_client.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/ui/signup_screen.dart'; // هنبدأ من شاشة التسجيل للتيست

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تجهيز الـ Dependencies (زي الـ Dependency Injection)
  final apiClient = ApiClient();
  final authService = AuthService(apiClient: apiClient);
  const secureStorage = FlutterSecureStorage();

  runApp(
    // 2. بنغلف الابلكيشن بالـ Provider عشان الـ Cubit يبقى متشاف في كل الشاشات
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authService, secureStorage),
        ),
      ],
      child: const NeoFitApp(),
    ),
  );
}

class NeoFitApp extends StatelessWidget {
  const NeoFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B0D),
      ),
      // هنخلي أول شاشة تفتح هي الـ Signup عشان نمشي في الـ Flow بتاعنا
      home: const SignupScreen(), 
    );
  }
}