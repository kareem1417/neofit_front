import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import 'test_entry.dart'; 

class UserMetricsScreen extends StatefulWidget {
final int sportId; // ضيف ده
  const UserMetricsScreen({super.key, required this.sportId});
  @override
  State<UserMetricsScreen> createState() => _UserMetricsScreenState();
}

class _UserMetricsScreenState extends State<UserMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _yearsTrainingController = TextEditingController();
  
  String _selectedGoal = 'Strength';
  int _trainingDays = 4;
  bool _hasInjuryHistory = false;

  final List<String> _goals = [
    'Weight Loss', 'Muscle Gain', 'Endurance', 'Strength', 'Agility', 'Speed'
  ];

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _yearsTrainingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();

    return BlocConsumer<AuthCubit, AuthState>(
       listener: (context, state) {
        if (state is AuthSuccess) {
          // هنشيل الكومنت ونفعل النقل لشاشة التيستات 🚀
          
          Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => TestEntryScreen(sportId: widget.sportId), // تمرير الـ ID الموروث
  ),
);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.redAccent),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF070B0D),
          body: SafeArea(
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
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'PHYSICAL METRICS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                // Progress Bar (Step 4/5)
                Stack(
                  children: [
                    Container(height: 2, color: const Color(0xFF14191C)),
                    Container(height: 2, width: MediaQuery.of(context).size.width * 0.8, color: const Color(0xFF00E5C1)),
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
                            'Your Starting Point',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'AI uses these metrics to tailor your program and calculate your baseline.',
                            style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.4),
                          ),
                          const SizedBox(height: 32),

                          // Height & Weight
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('HEIGHT (CM)'),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _heightController, hint: '180', isNumber: true),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('WEIGHT (KG)'),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _weightController, hint: '75', isNumber: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Goal
                          _buildLabel('PRIMARY GOAL'),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            value: _selectedGoal,
                            items: _goals,
                            onChanged: (val) => setState(() => _selectedGoal = val!),
                          ),
                          const SizedBox(height: 24),

                          // Training Days & Years
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('DAYS/WEEK'),
                                    const SizedBox(height: 8),
                                    _buildDropdown(
                                      value: _trainingDays.toString(),
                                      items: ['1', '2', '3', '4', '5', '6', '7'],
                                      onChanged: (val) => setState(() => _trainingDays = int.parse(val!)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('YEARS TRAINING'),
                                    const SizedBox(height: 8),
                                    _buildTextField(controller: _yearsTrainingController, hint: '2.5', isNumber: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Injury History Toggle
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1315),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E262A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Injury History', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                    SizedBox(height: 4),
                                    Text('Affects AI program generation', style: TextStyle(color: Colors.white24, fontSize: 12)),
                                  ],
                                ),
                                Switch(
                                  value: _hasInjuryHistory,
                                  activeColor: const Color(0xFF00E5C1),
                                  onChanged: (val) => setState(() => _hasInjuryHistory = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Save Button
                          ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      cubit.submitUserMetrics(
                                        height: double.parse(_heightController.text),
                                        weight: double.parse(_weightController.text),
                                        goal: _selectedGoal.replaceAll(' ', '_'), 
                                        trainingDays: _trainingDays,
                                        yearsTraining: double.parse(_yearsTrainingController.text),
                                        hasInjury: _hasInjuryHistory,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5C1),
                              foregroundColor: const Color(0xFF070B0D),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: state is AuthLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF070B0D), strokeWidth: 2))
                                : const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
        );
      },
    );
  }

  // --- Helper UI Methods ---
  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white24, letterSpacing: 0.8));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF0F1315),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5C1))),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF0F1315), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E262A))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0F1315),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          onChanged: onChanged,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        ),
      ),
    );
  }
}