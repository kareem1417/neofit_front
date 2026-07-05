import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/user/user_cubit.dart';
import '../../../logic/user/user_state.dart';
import 'signup1_screen.dart';
import '../profile/main_dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserCubit>();
    final double screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainDashboardScreen(),
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
                  colors: [
                    Color(0xFF0F1E21),
                    Color(0xFF070B0D),
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: cubit.loginFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: screenHeight * 0.12),
                              Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14191C),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF222B30),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: CustomPaint(
                                      size: const Size(28, 28),
                                      painter: HexagonPainter(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'NeoFit',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Know your power.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Find your edge.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.08),
                              const Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white24,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: cubit.signInEmail,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'name@example.com',
                                  hintStyle: const TextStyle(
                                    color: Colors.white12,
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline,
                                    color: Colors.white24,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F1315),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E262A),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E262A),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00E5C1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'PASSWORD',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white24,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'FORGOT?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00E5C1),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: cubit.signInPassword,
                                obscureText: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(
                                    color: Colors.white12,
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.white24,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F1315),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E262A),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E262A),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00E5C1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: state is UserLoading
                                    ? null
                                    : () {
                                        if (cubit.loginFormKey.currentState!.validate()) {
                                          cubit.signIn();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00E5C1),
                                  foregroundColor: const Color(0xFF070B0D),
                                  shadowColor: const Color(0xFF00E5C1).withValues(alpha: 0.3),
                                  elevation: 8,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Log In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24.0, top: 24.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white60,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SignupScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF00E5C1),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}