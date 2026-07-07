import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
// 📌 المسار ده بتاع شاشة البروفايل اللي اليوزر هيروحها بعد ما يخلص خالص
import '../../profile/ui/profile_screen.dart';

class AthleteDetailsScreen extends StatefulWidget {
  const AthleteDetailsScreen({super.key});

  @override
  State<AthleteDetailsScreen> createState() => _AthleteDetailsScreenState();
}

class _AthleteDetailsScreenState extends State<AthleteDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSportId;
  String _selectedLevel = 'Amateur';
  String? _selectedCategory;

  bool _hasCategories = false;
  String _categoryLabel = 'CATEGORY';
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = false;

  // 📌 حصالة عشان نشيل فيها الـ Controllers بتاعت الـ Tests اللي هتيجي من السيرفر
  final Map<int, TextEditingController> _testControllers = {};

  final List<String> levels = ['Novice', 'Amateur', 'Professional'];

  @override
  void initState() {
    super.initState();
    // 1. اول ما الشاشة تفتح نجيب الرياضات
    context.read<AuthCubit>().fetchSports();
  }

  @override
  void dispose() {
    for (var controller in _testControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 📌 اللوجيك بتاع تغيير الرياضة
  Future<void> _onSportChanged(int? sportId, AuthCubit cubit) async {
    if (sportId == null) return;

    // تصفير الداتا القديمة
    setState(() {
      _selectedSportId = sportId;
      _selectedCategory = null;
      _categories = [];
      _testControllers.clear();
    });

    final sport = cubit.availableSports.firstWhere((s) => s['id'] == sportId);

    setState(() {
      _hasCategories = sport['has_categories'] ?? false;
      String cType = sport['category_type'] ?? 'category';
      _categoryLabel = cType.replaceAll('_', ' ').toUpperCase();
    });

    // 2. لو الرياضة ليها تصنيفات (أوزان أو مراكز)، نجيبها من الـ API
    if (_hasCategories) {
      setState(() => _isLoadingCategories = true);
      try {
        final res = await cubit.authService.apiClient.dio.get(
          '/api/athletes/sports/$sportId/categories',
        );
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            res.data['data']['categories'],
          );
        });
      } catch (e) {
        debugPrint('Failed to load categories: $e');
      } finally {
        setState(() => _isLoadingCategories = false);
      }
    } else {
      _selectedCategory = 'not_applicable'; // للرياضات اللي ملهاش زي الجري
    }

    // 3. نجيب الاختبارات الخاصة بالرياضة دي
    cubit.fetchBaselineTests(sportId);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess &&
            state.message.contains('Onboarding completed')) {
          // لما يخلص Onboarding نوديه على شاشة البروفايل الرئيسية
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
            (route) => false,
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
          backgroundColor: const Color(0xFF070B0D),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'Define your cohort',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We use this data to compare your performance fairly against similar athletes on the leaderboards.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1. PRIMARY SPORT
                    _buildLabel('PRIMARY SPORT'),
                    const SizedBox(height: 8),
                    _buildDynamicDropdown<int>(
                      value: _selectedSportId,
                      hint: 'Select your sport',
                      items: cubit.availableSports
                          .map<DropdownMenuItem<int>>(
                            (sport) => DropdownMenuItem<int>(
                              value: sport['id'],
                              child: Text(
                                "${sport['icon'] ?? ''} ${sport['name']}",
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => _onSportChanged(val, cubit),
                    ),
                    const SizedBox(height: 24),

                    // 2. COMPETITIVE LEVEL
                    _buildLabel('COMPETITIVE LEVEL'),
                    const SizedBox(height: 12),
                    _buildSegmentedControl(levels, _selectedLevel),
                    const SizedBox(height: 24),

                    // 3. CATEGORY / WEIGHT CLASS (Dynamic)
                    if (_hasCategories) ...[
                      _buildLabel(_categoryLabel),
                      const SizedBox(height: 8),
                      if (_isLoadingCategories)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5C1),
                          ),
                        )
                      else
                        _buildDynamicDropdown<String>(
                          value: _selectedCategory,
                          hint: 'Select $_categoryLabel',
                          items: _categories
                              .map<DropdownMenuItem<String>>(
                                (cat) => DropdownMenuItem<String>(
                                  value: cat['value'],
                                  child: Text(cat['label']),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val),
                        ),
                      const SizedBox(height: 32),
                    ],

                    // 4. BASELINE TESTS (Dynamic)
                    if (state is TestsLoaded) ...[
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Baseline Assessment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Log your current stats to establish your baseline.',
                        style: TextStyle(fontSize: 13, color: Colors.white60),
                      ),
                      const SizedBox(height: 24),

                      ...state.tests.map((test) {
                        final id = test['id'];
                        // بنجهز كنترولر لكل تيست لو مش موجود
                        if (!_testControllers.containsKey(id)) {
                          _testControllers[id] = TextEditingController();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                test['test_name'].toString().toUpperCase(),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _testControllers[id],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Required'
                                    : null,
                                decoration: _inputDecoration(hint: '0.0')
                                    .copyWith(
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          test['unit'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 32),

                    // 5. SUBMIT BUTTON
                    ElevatedButton(
                      onPressed: (state is AuthLoading)
                          ? null
                          : () {
                              if (_formKey.currentState!.validate() &&
                                  _selectedSportId != null &&
                                  _selectedCategory != null) {
                                // 1. حفظ بيانات الكوهورت
                                cubit.saveCohortData(
                                  _selectedSportId!,
                                  _selectedLevel,
                                  _selectedCategory!,
                                );
                                // 2. إرسال الاختبارات لإنشاء الحساب والبروفايل
                                cubit.submitAthleteDetails(_testControllers);
                              } else if (_selectedCategory == null &&
                                  _hasCategories) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select your category/position',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5C1),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is AuthLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Complete Onboarding',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // === Helper Widgets ===

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white24,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildDynamicDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String hint,
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
          hint: Text(hint, style: const TextStyle(color: Colors.white24)),
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

  Widget _buildSegmentedControl(List<String> levels, String selectedLevel) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Row(
        children: levels.map((level) {
          final isSelected = selectedLevel == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedLevel = level),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E2427)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white24,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white12, fontSize: 15),
      filled: true,
      fillColor: const Color(0xFF0F1315),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
    );
  }
}
