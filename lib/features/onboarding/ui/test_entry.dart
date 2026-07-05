import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';

class TestEntryScreen extends StatefulWidget {
  final int sportId;
  const TestEntryScreen({super.key, required this.sportId});

  @override
  State<TestEntryScreen> createState() => _TestEntryScreenState();
}

class _TestEntryScreenState extends State<TestEntryScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().fetchBaselineTests(widget.sportId);
  }

  TextEditingController _getController(int testId) {
    _controllers[testId] ??= TextEditingController();
    return _controllers[testId]!;
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
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Saved!")));
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  // Header (اللي إنت عايزه)
                  Container(
                    height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
                        const Text('BASELINE TESTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0)),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: (state is TestsLoaded && state.tests.isNotEmpty)
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            itemCount: state.tests.length,
                            itemBuilder: (context, index) {
                              final testData = state.tests[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                // هنا استخدمنا التصميم الرهيب بتاعك
                                child: _buildTestCard(
                                  icon: Icons.fitness_center,
                                  title: testData['test_name'].toString().toUpperCase(),
                                  child: _buildInputField(
                                    controller: _getController(testData['id']),
                                    hint: '0',
                                    unit: testData['unit'].toString().toUpperCase(),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: CircularProgressIndicator(color: Color(0xFF00E5C1))),
                  ),
                  
                  // الزرار الأخير
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ElevatedButton(
                      onPressed: () => cubit.submitAthleteDetails(widget.sportId, _controllers),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5C1), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Calculate My Scores', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- حط الدوال دي تحت هنا (نفس اللي بعتهولي في الكود بتاعك) ---
  Widget _buildTestCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF111619).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E262A))),
      child: Column(children: [
        Row(children: [Icon(icon, color: const Color(0xFF00E5C1), size: 18), const SizedBox(width: 12), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        child
      ]),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, required String unit}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Padding(padding: const EdgeInsets.all(16), child: Text(unit, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold))),
        filled: true, fillColor: const Color(0xFF070B0D),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5C1))),
      ),
    );
  }
}