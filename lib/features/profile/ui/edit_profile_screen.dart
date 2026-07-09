import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../onboarding/ui/test_entry.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _basicFormKey = GlobalKey<FormState>();
  final _metricsFormKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _bioController;
  late final TextEditingController _roleModelsController;
  late final TextEditingController _instagramController;
  late final TextEditingController _youtubeController;

  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _yearsTrainingController;

  String _selectedGoal = 'general';
  int _trainingDays = 3;
  bool _hasInjury = false;

  String _selectedLevel = 'amateur';
  String _selectedCategory = 'not_applicable';

  final List<String> _goals = const [
    'weight_loss',
    'muscle_gain',
    'endurance',
    'strength',
    'agility',
    'speed',
    'flexibility',
    'recovery',
    'power',
    'general',
  ];

  final List<String> _levels = const [
    'novice',
    'amateur',
    'professional',
  ];

  @override
  void initState() {
    super.initState();

    final cubit = context.read<AuthCubit>();
    final user = cubit.userData ?? {};
    final metrics = cubit.metricsData ?? {};
    final profiles = user['sport_profiles'] as List? ??
        user['user_sport_profiles'] as List? ??
        [];

    final profile = profiles.isNotEmpty
        ? Map<String, dynamic>.from(profiles.first)
        : <String, dynamic>{};

    _usernameController = TextEditingController(
      text: cubit.username ?? user['username']?.toString() ?? '',
    );
    _fullNameController = TextEditingController(
      text: cubit.fullName ?? user['full_name']?.toString() ?? '',
    );
    _birthdayController = TextEditingController(
      text: user['date_of_birth']?.toString().split('T').first ?? '',
    );
    _bioController = TextEditingController(
      text: cubit.bio ?? user['bio']?.toString() ?? '',
    );
    String _normalizeValue(String? value, String fallback) {
      final normalized = value?.trim().toLowerCase().replaceAll(' ', '_');

      if (normalized == null || normalized.isEmpty) {
        return fallback;
      }

      return normalized;
    }

    String _safeDropdownValue(
      String? value,
      List<String> allowed,
      String fallback,
    ) {
      final normalized = _normalizeValue(value, fallback);
      return allowed.contains(normalized) ? normalized : fallback;
    }

    final roleModels = user['role_models'];
    _roleModelsController = TextEditingController(
      text: roleModels is List ? roleModels.join(', ') : '',
    );

    final socialLinks = user['social_links'];
    _instagramController = TextEditingController(
      text:
          socialLinks is Map ? socialLinks['instagram']?.toString() ?? '' : '',
    );
    _youtubeController = TextEditingController(
      text: socialLinks is Map ? socialLinks['youtube']?.toString() ?? '' : '',
    );

    _heightController = TextEditingController(
      text: metrics['height_cm']?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: metrics['weight_kg']?.toString() ?? '',
    );
    _yearsTrainingController = TextEditingController(
      text: metrics['years_training']?.toString() ?? '',
    );

    _selectedGoal = _safeDropdownValue(
      metrics['goal']?.toString(),
      _goals,
      'general',
    );
    _trainingDays = int.tryParse(
          metrics['training_days_per_week']?.toString() ?? '',
        ) ??
        3;
    _hasInjury = metrics['has_injury_history'] == true;

    _selectedLevel = _safeDropdownValue(
      profile['level']?.toString(),
      _levels,
      'amateur',
    );
    _selectedCategory = _normalizeValue(
      profile['player_category']?.toString() ??
          profile['weight_class']?.toString(),
      'not_applicable',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _birthdayController.dispose();
    _bioController.dispose();
    _roleModelsController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _yearsTrainingController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_birthdayController.text) ??
          DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _birthdayController.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _saveBasicInfo() async {
    if (!_basicFormKey.currentState!.validate()) return;

    final roleModels = _roleModelsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final socialLinks = <String, String>{};
    if (_instagramController.text.trim().isNotEmpty) {
      socialLinks['instagram'] = _instagramController.text.trim();
    }
    if (_youtubeController.text.trim().isNotEmpty) {
      socialLinks['youtube'] = _youtubeController.text.trim();
    }

    await context.read<AuthCubit>().updateBasicProfile(
          username: _usernameController.text,
          fullName: _fullNameController.text,
          dateOfBirth: _birthdayController.text,
          bio: _bioController.text,
          roleModels: roleModels,
          socialLinks: socialLinks,
        );
  }

  Future<void> _saveMetrics() async {
    if (!_metricsFormKey.currentState!.validate()) return;

    await context.read<AuthCubit>().updateMetrics(
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
          goal: _selectedGoal,
          trainingDays: _trainingDays,
          yearsTraining: double.parse(_yearsTrainingController.text),
          hasInjury: _hasInjury,
        );
  }

  Future<void> _saveSportProfile() async {
    await context.read<AuthCubit>().updateSportProfile(
          level: _selectedLevel,
          playerCategory: _selectedCategory,
        );
  }

  void _openTestsEditor() {
    final cubit = context.read<AuthCubit>();
    final user = cubit.userData ?? {};
    final profiles = user['sport_profiles'] as List? ??
        user['user_sport_profiles'] as List? ??
        [];

    final profile = profiles.isNotEmpty
        ? Map<String, dynamic>.from(profiles.first)
        : <String, dynamic>{};

    final sportId = int.tryParse(profile['sport_id']?.toString() ?? '') ?? 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestEntryScreen(
          sportId: sportId,
          isEditing: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF070B0D),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildBasicInfoCard(isLoading),
                        const SizedBox(height: 18),
                        _buildMetricsCard(isLoading),
                        const SizedBox(height: 18),
                        _buildSportProfileCard(isLoading),
                        const SizedBox(height: 18),
                        _buildTestsCard(),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'EDIT PROFILE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(bool isLoading) {
    return _card(
      title: 'BASIC INFORMATION',
      child: Form(
        key: _basicFormKey,
        child: Column(
          children: [
            _field(
              label: 'USERNAME',
              controller: _usernameController,
              validator: (v) =>
                  v == null || v.trim().length < 3 ? 'Min 3 chars' : null,
            ),
            _field(
              label: 'FULL NAME',
              controller: _fullNameController,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            _field(
              label: 'BIRTHDAY',
              controller: _birthdayController,
              readOnly: true,
              onTap: _pickBirthday,
            ),
            _field(
              label: 'BIO',
              controller: _bioController,
              maxLines: 4,
            ),
            _field(
              label: 'ROLE MODELS',
              controller: _roleModelsController,
              hint: 'Ali, Tyson, Lomachenko',
            ),
            _field(
              label: 'INSTAGRAM',
              controller: _instagramController,
            ),
            _field(
              label: 'YOUTUBE',
              controller: _youtubeController,
            ),
            _button(
              label: 'Save Basic Info',
              loading: isLoading,
              onTap: _saveBasicInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(bool isLoading) {
    return _card(
      title: 'BODY & TRAINING',
      child: Form(
        key: _metricsFormKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'HEIGHT',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    suffix: 'cm',
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    label: 'WEIGHT',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    suffix: 'kg',
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
            _dropdown<String>(
              label: 'GOAL',
              value: _selectedGoal,
              items: _goals,
              onChanged: (v) => setState(() => _selectedGoal = v!),
            ),
            _dropdown<int>(
              label: 'TRAINING DAYS / WEEK',
              value: _trainingDays,
              items: const [1, 2, 3, 4, 5, 6, 7],
              onChanged: (v) => setState(() => _trainingDays = v!),
            ),
            _field(
              label: 'YEARS TRAINING',
              controller: _yearsTrainingController,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Invalid' : null,
            ),
            SwitchListTile(
              value: _hasInjury,
              onChanged: (v) => setState(() => _hasInjury = v),
              activeColor: const Color(0xFF00E5C1),
              title: const Text(
                'Injury history',
                style: TextStyle(color: Colors.white),
              ),
            ),
            _button(
              label: 'Save Metrics',
              loading: isLoading,
              onTap: _saveMetrics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportProfileCard(bool isLoading) {
    return _card(
      title: 'ATHLETE DETAILS',
      child: Column(
        children: [
          _dropdown<String>(
            label: 'LEVEL',
            value: _selectedLevel,
            items: _levels,
            onChanged: (v) => setState(() => _selectedLevel = v!),
          ),
          _field(
            label: 'CATEGORY',
            controller: TextEditingController(text: _selectedCategory),
            onChanged: (v) => _selectedCategory = v,
          ),
          _button(
            label: 'Save Athlete Details',
            loading: isLoading,
            onTap: _saveSportProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildTestsCard() {
    return _card(
      title: 'INITIAL / ATHLETIC TESTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Update your test values and create a new snapshot.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          _button(
            label: 'Edit Tests',
            loading: false,
            onTap: _openTestsEditor,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? suffix,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          labelStyle: const TextStyle(color: Colors.white38),
          hintStyle: const TextStyle(color: Colors.white24),
          suffixStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF070B0D),
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
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: const Color(0xFF0F1315),
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF070B0D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString().replaceAll('_', ' ')),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _button({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5C1),
          foregroundColor: const Color(0xFF070B0D),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
