import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:neofit_app/features/auth/logic/auth_cubit.dart';
import 'package:neofit_app/features/auth/logic/auth_state.dart';
import '../models/program_builder_data.dart';
import 'block_builder_screen.dart';

class CoachProgramCreateScreen extends StatefulWidget {
  const CoachProgramCreateScreen({super.key});

  @override
  State<CoachProgramCreateScreen> createState() =>
      _CoachProgramCreateScreenState();
}

class _CoachProgramCreateScreenState extends State<CoachProgramCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '6');
  final _frequencyController = TextEditingController(text: '3');
  final _coverUrlController = TextEditingController();

  int? _selectedSportId;
  String? _selectedSportName;

  String _selectedGoal = 'strength';
  String _selectedLevel = 'amateur';

  final List<String> _goals = const [
    'strength',
    'explosiveness',
    'endurance',
    'power',
    'general',
    'speed',
  ];

  final List<String> _levels = const [
    'novice',
    'amateur',
    'professional',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().fetchCoachSports();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _frequencyController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a sport'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final data = ProgramBuilderData()
      ..title = _titleController.text.trim()
      ..description = _descriptionController.text.trim()
      ..sportId = _selectedSportId
      ..sportName = _selectedSportName ?? 'Sport'
      ..goal = _selectedGoal
      ..level = _selectedLevel
      ..duration = _durationController.text.trim()
      ..frequency = _frequencyController.text.trim()
      ..coverImageUrl = _coverUrlController.text.trim().isEmpty
          ? null
          : _coverUrlController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockBuilderScreen(programData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B0D);
    const accentTeal = Color(0xFF1CE0BF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(0.33),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),
                      const Text(
                        'PROGRAM BASICS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set the foundation for your program. You can add blocks, sessions, and exercises next.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLabel('TITLE'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'Explosive Power Program',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('DESCRIPTION'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'Describe the outcome and structure...',
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('SPORT'),
                      const SizedBox(height: 8),
                      _buildSportDropdown(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'GOAL',
                              value: _selectedGoal,
                              values: _goals,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedGoal = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdown(
                              label: 'LEVEL',
                              value: _selectedLevel,
                              values: _levels,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedLevel = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('DURATION WEEKS'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _durationController,
                                  hint: '6',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final parsed = int.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('SESSIONS / WEEK'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _frequencyController,
                                  hint: '3',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final parsed = int.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('COVER IMAGE URL OPTIONAL'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _coverUrlController,
                        hint: 'https://images.unsplash.com/...',
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _goNext,
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: accentTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE TO BLOCKS',
                        style: TextStyle(
                          color: Color(0xFF070B0D),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF070B0D),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'CREATE PROGRAM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            'STEP 1/3',
            style: TextStyle(
              color: Color(0xFF1CE0BF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Stack(
      children: [
        Container(
          height: 2,
          width: double.infinity,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 2,
            color: const Color(0xFF1CE0BF),
          ),
        ),
      ],
    );
  }

  Widget _buildSportDropdown() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final sports = context.watch<AuthCubit>().coachSports;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E2127)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSportId,
              isExpanded: true,
              dropdownColor: const Color(0xFF111619),
              iconEnabledColor: const Color(0xFF1CE0BF),
              hint: Text(
                sports.isEmpty ? 'Loading sports...' : 'Choose sport',
                style: const TextStyle(color: Colors.white24),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              items: sports.map<DropdownMenuItem<int>>((raw) {
                final sport = Map<String, dynamic>.from(raw as Map);
                final id = int.tryParse(sport['id'].toString()) ?? 0;
                final name = sport['name']?.toString() ?? 'Unknown';

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(name),
                  onTap: () => _selectedSportName = name,
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSportId = value);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E2127)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF111619),
              iconEnabledColor: const Color(0xFF1CE0BF),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              items: values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        filled: true,
        fillColor: const Color(0xFF0F1115),
        contentPadding: const EdgeInsets.all(18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E2127)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CE0BF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}
