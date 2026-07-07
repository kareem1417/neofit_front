import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// 📌 تأكد من استيراد الكيوبت الصح بتاعك (AuthCubit أو UserCubit حسب ما إنت مسميه)
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import 'athlete_details_screen.dart';

class AnotherAthleteDetailsScreen extends StatefulWidget {
  const AnotherAthleteDetailsScreen({super.key});

  @override
  State<AnotherAthleteDetailsScreen> createState() =>
      _AnotherAthleteDetailsScreenState();
}

class _AnotherAthleteDetailsScreenState
    extends State<AnotherAthleteDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _yearsController = TextEditingController();

  // 📌 القيم الافتراضية للـ Dropdowns والـ Switch
  String _selectedGoal = 'General';
  int _selectedDays = 3;
  bool _hasInjuryHistory = false;

  // 📌 القيم المطابقة للـ Enum في الـ Backend
  final List<String> _goals = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Strength',
    'Agility',
    'Speed',
    'Flexibility',
    'Recovery',
    'Power',
    'General',
  ];

  final List<int> _trainingDays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>(); // غيرها لـ UserCubit لو بتستخدمه

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess && state.message.contains('Metrics saved')) {
          // 📌 بعد ما يحفظ الـ Metrics بنجاح، يروح لشاشة الرياضة والاختبارات
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AthleteDetailsScreen(),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
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
                  colors: [Color(0xFF0F1E21), Color(0xFF070B0D)],
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'BODY & TRAINING',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  // Progress Bar (Step 2 of 3 for example)
                  Stack(
                    children: [
                      Container(height: 2, color: const Color(0xFF14191C)),
                      Container(
                        height: 2,
                        width: MediaQuery.of(context).size.width * 0.66,
                        color: const Color(0xFF00E5C1),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            const Text(
                              'Physical Metrics',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Provide your physical metrics and training background to personalize your experience.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 📌 Height & Weight in a Row for better UI
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('HEIGHT'),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _heightController,
                                        hint: '180',
                                        suffixText: 'cm',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('WEIGHT'),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _weightController,
                                        hint: '75',
                                        suffixText: 'kg',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 📌 Goal Dropdown
                            _buildLabel('PRIMARY GOAL'),
                            const SizedBox(height: 8),
                            _buildDynamicDropdown<String>(
                              value: _selectedGoal,
                              items: _goals
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedGoal = val!),
                            ),
                            const SizedBox(height: 24),

                            // 📌 Training Days Dropdown
                            _buildLabel('TRAINING DAYS / WEEK'),
                            const SizedBox(height: 8),
                            _buildDynamicDropdown<int>(
                              value: _selectedDays,
                              items: _trainingDays
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text('$d Days'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedDays = val!),
                            ),
                            const SizedBox(height: 24),

                            // 📌 Years Training (Decimal input)
                            _buildLabel('YEARS TRAINING'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _yearsController,
                              hint: 'e.g., 2.5',
                              suffixText: 'Years',
                              allowDecimal: true,
                            ),
                            const SizedBox(height: 24),

                            // 📌 Injury History Toggle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1315),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1E262A),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Do you have an injury history?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Switch(
                                    value: _hasInjuryHistory,
                                    activeColor: const Color(0xFF00E5C1),
                                    activeTrackColor: const Color(
                                      0xFF00E5C1,
                                    ).withValues(alpha: 0.3),
                                    inactiveThumbColor: Colors.white60,
                                    inactiveTrackColor: Colors.white12,
                                    onChanged: (val) =>
                                        setState(() => _hasInjuryHistory = val),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),

                            // 📌 Submit Button
                            ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        // استدعاء دالة الباك إند
                                        cubit.submitUserMetrics(
                                          height: double.parse(
                                            _heightController.text,
                                          ),
                                          weight: double.parse(
                                            _weightController.text,
                                          ),
                                          goal: _selectedGoal,
                                          trainingDays: _selectedDays,
                                          yearsTraining: double.parse(
                                            _yearsController.text,
                                          ),
                                          hasInjury: _hasInjuryHistory,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5C1),
                                foregroundColor: const Color(0xFF070B0D),
                                shadowColor: const Color(
                                  0xFF00E5C1,
                                ).withValues(alpha: 0.3),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF070B0D),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // === Helper Widgets ===

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white24,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String suffixText,
    bool allowDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Required';
        if (double.tryParse(val) == null) return 'Invalid number';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12, fontSize: 15),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 18.0),
          child: Text(
            suffixText,
            style: const TextStyle(
              color: Colors.white24,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF0F1315),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E262A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E262A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5C1)),
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: const Color(0xFF0F1315),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}
