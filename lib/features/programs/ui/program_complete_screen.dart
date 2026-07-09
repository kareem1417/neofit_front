import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../data/program_completion_service.dart';
import '../../profile/ui/progress_tracking_screen.dart';

class ProgramCompleteScreen extends StatefulWidget {
  final String enrollmentId;
  final String programId;
  final List<Map<String, dynamic>> tests;

  const ProgramCompleteScreen({
    super.key,
    required this.enrollmentId,
    required this.programId,
    required this.tests,
  });

  @override
  State<ProgramCompleteScreen> createState() => _ProgramCompleteScreenState();
}

class _ProgramCompleteScreenState extends State<ProgramCompleteScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color primaryCyan = Color(0xFF2DE1C2);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color cardBg = Color(0xFF141415);

  late final ProgramCompletionService _service;

  final Map<int, TextEditingController> _controllers = {};
  final _reviewController = TextEditingController();

  IconData _iconForTest(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('deadlift') ||
        lower.contains('squat') ||
        lower.contains('press') ||
        lower.contains('clean')) {
      return Icons.fitness_center;
    }

    if (lower.contains('jump')) {
      return Icons.square_foot;
    }

    if (lower.contains('ball') || lower.contains('throw')) {
      return Icons.sports_baseball;
    }

    if (lower.contains('run') ||
        lower.contains('mile') ||
        lower.contains('sprint')) {
      return Icons.trending_up;
    }

    if (lower.contains('burpee') || lower.contains('heart')) {
      return Icons.monitor_heart;
    }

    return Icons.speed;
  }

  String _baselineFor(Map<String, dynamic> test) {
    final value = test['value'] ??
        test['baseline'] ??
        test['baseline_value'] ??
        test['raw_value'];

    if (value == null) return '(--)';

    return '($value)';
  }

  Widget _buildMetricInputCard({
    required TextEditingController controller,
    required IconData icon,
    required String title,
    required String baseline,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryCyan, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        cursorColor: primaryCyan,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      baseline,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _rating = 5;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _deltas = [];
  String? _testimonial;
  List<Map<String, dynamic>> _submittedPosttestValues = [];

  @override
  void initState() {
    super.initState();
    _service = ProgramCompletionService(apiClient: context.read<ApiClient>());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _reviewController.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(int testId) {
    _controllers[testId] ??= TextEditingController();
    return _controllers[testId]!;
  }

  Future<void> _submit() async {
    final posttestValues = <Map<String, dynamic>>[];

    for (final test in widget.tests) {
      final testId = int.tryParse(
        test['attribute_test_id']?.toString() ?? test['id']?.toString() ?? '',
      );

      if (testId == null) continue;

      final value = double.tryParse(_controllerFor(testId).text.trim());

      if (value == null) {
        _showSnack('Please enter all final assessment values.', isError: true);
        return;
      }

      posttestValues.add({
        'attribute_test_id': testId,
        'value': value,
      });
    }

    if (posttestValues.isEmpty) {
      _showSnack('No tests found.', isError: true);
      return;
    }

    _submittedPosttestValues = posttestValues;

    setState(() => _isSubmitting = true);

    try {
      final completeResult = await _service.completeProgram(
        enrollmentId: widget.enrollmentId,
        posttestTestValues: posttestValues,
      );

      if (!mounted) return;

      setState(() {
        _deltas = (completeResult['deltas'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _testimonial = completeResult['testimonial']?.toString();
      });

      // Rate program is non-blocking — don't let a rating failure
      // prevent the user from seeing results and navigating.
      try {
        await _service.rateProgram(
          programId: widget.programId,
          rating: _rating,
          review: _reviewController.text,
        );
      } catch (_) {
        // Rating failed silently — user can rate later if needed
      }

      if (!mounted) return;
      _showCelebration(completeResult);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showCelebration(Map<String, dynamic> completeResult) {
    final progressTests =
        (completeResult['progress_tests'] as List<dynamic>? ?? widget.tests)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    final firstTestId = progressTests.isEmpty
        ? null
        : int.tryParse(
            progressTests.first['attribute_test_id']?.toString() ??
                progressTests.first['id']?.toString() ??
                '',
          );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryCyan.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: primaryCyan.withValues(alpha: 0.12),
                blurRadius: 28,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 78,
              ),
              const SizedBox(height: 22),
              const Text(
                'CONGRATULATIONS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _testimonial ??
                    'Your new performance metrics have been recorded successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    if (firstTestId == null) {
                      _showSnack(
                        'Progress cannot be opened because no test ID was found.',
                        isError: true,
                      );
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgressTrackingScreen(
                          initialAttributeTestId: firstTestId,
                          availableTests: progressTests,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'VIEW PROGRESS 📈',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  String _testName(Map<String, dynamic> test) {
    return test['test_name']?.toString() ?? test['name']?.toString() ?? 'Test';
  }

  String _unit(Map<String, dynamic> test) {
    return test['unit']?.toString() ?? '';
  }

  double? _deltaFor(int testId) {
    final delta = _deltas.firstWhere(
      (e) => e['test_id']?.toString() == testId.toString(),
      orElse: () => {},
    );

    return double.tryParse(delta['improvement']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 24),
                    _buildFinalAssessment(),
                    if (_deltas.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildImprovements(),
                    ],
                    const SizedBox(height: 24),
                    _buildRating(),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
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
          const Expanded(
            child: Text(
              'PROGRAM COMPLETE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryCyan.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_run,
              color: primaryCyan,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POST-PROGRAM TESTING REQUIRED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Time to see your gains. Enter your new numbers to calculate your delta improvement and generate your progress snapshot.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'UPDATE PERFORMANCE METRICS',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            Text(
              'BASELINE',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.tests.map((test) {
          final testId = int.tryParse(
            test['attribute_test_id']?.toString() ??
                test['id']?.toString() ??
                '',
          );

          if (testId == null) return const SizedBox.shrink();

          return _buildMetricInputCard(
            controller: _controllerFor(testId),
            icon: _iconForTest(_testName(test)),
            title:
                '${_testName(test).toUpperCase()} ${_unit(test).isEmpty ? '' : '(${_unit(test).toUpperCase()})'}',
            baseline: _baselineFor(test),
          );
        }),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.22)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF87171),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete all tests to finalize your program and see your improvements.',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImprovements() {
    return _section(
      title: 'YOUR IMPROVEMENTS',
      child: Column(
        children: widget.tests.map((test) {
          final testId = int.tryParse(
            test['attribute_test_id']?.toString() ??
                test['id']?.toString() ??
                '',
          );

          if (testId == null) return const SizedBox.shrink();

          final delta = _deltaFor(testId);
          final unit = _unit(test);
          final positive = (delta ?? 0) >= 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _testName(test),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  delta == null
                      ? '--'
                      : '${positive ? '+' : ''}${delta.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    color: positive ? primaryCyan : Colors.redAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(positive ? '🟢' : '🔴'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRating() {
    return _section(
      title: 'RATE THIS PROGRAM',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final selected = index < _rating;

              return IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  selected ? Icons.star : Icons.star_border,
                  color: primaryCyan,
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write your review...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor.withValues(alpha: 0), bgColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryCyan,
            foregroundColor: Colors.black,
            disabledBackgroundColor: primaryCyan.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
                  'Submit & Share 🏆',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
