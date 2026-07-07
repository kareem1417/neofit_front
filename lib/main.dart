import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/api/api_client.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/ui/login_screen.dart';

// ✅ ضفنا مسار الـ UserCubit هنا
import 'features/onboarding/logic/user_cubit.dart';
import 'features/home/data/social_service.dart';
import 'features/home/logic/social_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authService = AuthService(apiClient: apiClient);
  const secureStorage = FlutterSecureStorage();

  runApp(
    RepositoryProvider<ApiClient>.value(
      value: apiClient,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(authService, secureStorage)),
          BlocProvider(create: (_) => UserCubit(apiClient: apiClient)),
          BlocProvider<SocialCubit>(
            create: (_) => SocialCubit(
              socialService: SocialService(apiClient: apiClient),
            ),
          ),
        ],
        child: const NeoFitApp(),
      ),
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
      home: const LoginScreen(),
    );
  }
}
