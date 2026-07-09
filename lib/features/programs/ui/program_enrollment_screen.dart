import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../data/program_detail_model.dart';
import '../../auth/logic/auth_cubit.dart';
import '../data/programs_service.dart';

class ProgramEnrollmentScreen extends StatefulWidget {
  final ProgramDetailModel program;

  const ProgramEnrollmentScreen({
    super.key,
    required this.program,
  });

  @override
  State<ProgramEnrollmentScreen> createState() =>
      _ProgramEnrollmentScreenState();
}

class _ProgramEnrollmentScreenState extends State<ProgramEnrollmentScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color primaryCyan = Color(0xFF2DE1C2);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color cardBg = Color(0xFF141415);

  late final ProgramsService _service;
  late Future<List<Map<String, dynamic>>> _testsFuture;

  final Map<int, TextEditingController> _testControllers = {};
  final Set<String> _selectedDays = {};
  TimeOfDay? _preferredTime;

  bool _isSubmitting = false;

  final List<String> _days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();

    _service = ProgramsService(apiClient: context.read<ApiClient>());

    final sportId = widget.program.sportId ?? _fallbackSportIdFromProfile();

    if (sportId == null) {
      _testsFuture = Future.error(
        'Program sport_id is missing. Add sport_id to getProgramById backend response.',
      );
    } else {
      _testsFuture = _service.getSportBaselineTests(sportId);
    }
  }

  int? _fallbackSportIdFromProfile() {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.userData ?? {};
    final profiles = user['sport_profiles'] as List? ??
        user['user_sport_profiles'] as List? ??
        [];

    if (profiles.isEmpty) return null;

    final profile = Map<String, dynamic>.from(profiles.first);

    return int.tryParse(profile['sport_id']?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final controller in _testControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int testId) {
    _testControllers[testId] ??= TextEditingController();
    return _testControllers[testId]!;
  }

  String? _formatPreferredTime() {
    if (_preferredTime == null) return null;

    final hour = _preferredTime!.hour.toString().padLeft(2, '0');
    final minute = _preferredTime!.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryCyan,
              surface: cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _preferredTime = picked);
    }
  }

  Future<void> _submit(List<Map<String, dynamic>> tests) async {
    if (_selectedDays.isEmpty) {
      _showSnack('Choose at least one training day.');
      return;
    }

    final baselineTestValues = <Map<String, dynamic>>[];

    for (final test in tests) {
      final testId = int.tryParse(test['id']?.toString() ?? '');
      if (testId == null) continue;

      final value = double.tryParse(_controllerFor(testId).text.trim());

      if (value == null) {
        _showSnack('Please enter all baseline test values.');
        return;
      }

      baselineTestValues.add({
        'attribute_test_id': testId,
        'value': value,
      });
    }

    if (baselineTestValues.isEmpty) {
      _showSnack('No baseline tests found.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.enrollInProgram(
        programId: widget.program.id,
        preferredDays: _selectedDays.toList(),
        preferredTime: _formatPreferredTime(),
        baselineTestValues: baselineTestValues,
      );

      if (!mounted) return;

      _showSnack('Enrolled successfully!');

      Navigator.pop(context, true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  String _formatLabel(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _testsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: primaryCyan),
                        )
                      : snapshot.hasError
                          ? _buildError(snapshot.error.toString())
                          : _buildContent(snapshot.data ?? []),
                ),
                if (snapshot.hasData) _buildBottomButton(snapshot.data ?? []),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'PROGRAM ENROLLMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.program.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> tests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgramSummary(),
          const SizedBox(height: 24),
          _buildSectionTitle('TRAINING PREFERENCES'),
          const SizedBox(height: 14),
          _buildDaysPicker(),
          const SizedBox(height: 16),
          _buildTimePicker(),
          const SizedBox(height: 30),
          _buildSectionTitle('BASELINE ASSESSMENT'),
          const SizedBox(height: 8),
          const Text(
            'Enter your current values. These will be saved as your program baseline so we can compare your progress later.',
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (tests.isEmpty)
            const Text(
              'No baseline tests found for this sport.',
              style: TextStyle(color: Colors.white38),
            )
          else
            ...tests.map(_buildTestInput),
        ],
      ),
    );
  }

  Widget _buildProgramSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: primaryCyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.program.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.program.durationWeeks} weeks • ${widget.program.sessionsPerWeek} sessions/week',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _buildDaysPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _days.map((day) {
        final selected = _selectedDays.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? primaryCyan : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? primaryCyan
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Text(
              day.substring(0, 3).toUpperCase(),
              style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePicker() {
    final label = _preferredTime == null
        ? 'Select preferred time'
        : _preferredTime!.format(context);

    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: primaryCyan, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _preferredTime == null ? textGrey : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInput(Map<String, dynamic> test) {
    final testId = int.tryParse(test['id']?.toString() ?? '') ?? 0;
    final name = test['test_name']?.toString() ?? 'Test';
    final unit = test['unit']?.toString() ?? '';
    final attribute = test['attribute_name']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attribute != null && attribute.isNotEmpty)
            Text(
              _formatLabel(attribute),
              style: const TextStyle(
                color: primaryCyan,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controllerFor(testId),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '0.0',
              hintStyle: const TextStyle(color: Colors.white24),
              suffixText: unit,
              suffixStyle: const TextStyle(
                color: textGrey,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(List<Map<String, dynamic>> tests) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor.withValues(alpha: 0.0), bgColor],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submit(tests),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: Colors.black,
            disabledBackgroundColor: primaryCyan.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 10,
            shadowColor: primaryCyan.withValues(alpha: 0.35),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'CONFIRM ENROLLMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
        ),
      ),
    );
  }
}
