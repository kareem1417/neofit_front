import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';
import '../../onboarding/ui/create_profile_screen.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Athlete';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14191C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF222B30)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text('JOIN NEOFIT', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                          const SizedBox(height: 12),
                          Text('Create your account to start tracking progress.', style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6), height: 1.4)),
                          const SizedBox(height: 32),
                          
                          // Roles
                          Row(
                            children: [
                              Expanded(child: _buildRoleButton('Athlete', Icons.person_outline, _selectedRole == 'Athlete', () => setState(() => _selectedRole = 'Athlete'))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildRoleButton('Coach', Icons.fitness_center_outlined, _selectedRole == 'Coach', () => setState(() => _selectedRole = 'Coach'))),
                            ],
                          ),
                          const SizedBox(height: 28),
                          
                          // Email
                          Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            decoration: _inputDecoration(hint: 'name@example.com', icon: Icons.mail_outline),
                          ),
                          const SizedBox(height: 24),
                          
                          // Password
                          Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            validator: (val) => val != null && val.length < 6 ? 'Min 6 chars' : null,
                            decoration: _inputDecoration(hint: '••••••••', icon: Icons.lock_outline),
                          ),
                          const SizedBox(height: 24),
                          
                          // Confirm Password
                          Text('CONFIRM PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null,
                            decoration: _inputDecoration(hint: '••••••••', icon: Icons.lock_outline),
                          ),
                          
                          const Spacer(),
                          
                          // Submit Button
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // 1. Save data to cubit
                                  cubit.saveSignupData(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    role: _selectedRole,
                                  );
                                  // 2. Navigate to next screen without API call
Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProfileScreen()));                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5C1),
                                foregroundColor: const Color(0xFF070B0D),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
  }

  Widget _buildRoleButton(String role, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2427) : const Color(0xFF0F1315),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF38454D) : const Color(0xFF1E262A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4), size: 20),
            const SizedBox(width: 8),
            Text(role, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
      filled: true,
      fillColor: const Color(0xFF0F1315),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5C1))),
    );
  }
}