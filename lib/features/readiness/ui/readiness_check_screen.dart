import 'package:flutter/material.dart';

import '../data/readiness_result.dart';
import '../data/readiness_service.dart';

class ReadinessCheckScreen extends StatefulWidget {
  final ReadinessService service;
  final String? enrollmentId;
  final String? programSessionId;
  final ValueChanged<ReadinessResult> onSubmitted;

  const ReadinessCheckScreen({
    super.key,
    required this.service,
    required this.onSubmitted,
    this.enrollmentId,
    this.programSessionId,
  });

  @override
  State<ReadinessCheckScreen> createState() => _ReadinessCheckScreenState();
}

class _ReadinessCheckScreenState extends State<ReadinessCheckScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color primaryCyan = Color(0xFF2DE1C2);
  static const Color cardBg = Color(0xFF141415);

  double _sleepHours = 7;
  int _fatigue = 2;
  int _soreness = 2;
  int _stress = 2;

  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await widget.service.submitReadiness(
        sleepHours: _sleepHours,
        fatigue: _fatigue,
        soreness: _soreness,
        stress: _stress,
        enrollmentId: widget.enrollmentId,
        programSessionId: widget.programSessionId,
      );

      if (!mounted) return;

      widget.onSubmitted(result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'READINESS CHECK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Answer 4 quick questions before starting today’s workout.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSleepQuestion(),
                    const SizedBox(height: 18),
                    _buildScaleQuestion(
                      title: 'Fatigue',
                      subtitle: 'How tired do you feel?',
                      value: _fatigue,
                      lowLabel: 'Fresh',
                      highLabel: 'Exhausted',
                      onChanged: (value) => setState(() => _fatigue = value),
                    ),
                    const SizedBox(height: 18),
                    _buildScaleQuestion(
                      title: 'Soreness',
                      subtitle: 'How sore are your muscles?',
                      value: _soreness,
                      lowLabel: 'None',
                      highLabel: 'Very sore',
                      onChanged: (value) => setState(() => _soreness = value),
                    ),
                    const SizedBox(height: 18),
                    _buildScaleQuestion(
                      title: 'Stress',
                      subtitle: 'How stressed do you feel?',
                      value: _stress,
                      lowLabel: 'Calm',
                      highLabel: 'Stressed',
                      onChanged: (value) => setState(() => _stress = value),
                    ),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
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
              'PRE-WORKOUT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSleepQuestion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionTitle(
            title: 'Sleep',
            subtitle: 'How many hours did you sleep?',
            value: '${_sleepHours.toStringAsFixed(1)} h',
          ),
          Slider(
            value: _sleepHours,
            min: 0,
            max: 14,
            divisions: 28,
            activeColor: primaryCyan,
            inactiveColor: Colors.white12,
            label: _sleepHours.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _sleepHours = value);
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0h', style: TextStyle(color: Colors.white30, fontSize: 11)),
              Text('14h',
                  style: TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaleQuestion({
    required String title,
    required String subtitle,
    required int value,
    required String lowLabel,
    required String highLabel,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionTitle(
            title: title,
            subtitle: subtitle,
            value: '$value/5',
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = rating == value;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 48,
                    margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryCyan : const Color(0xFF09090B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? primaryCyan : Colors.white10,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        rating.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lowLabel,
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
              Text(
                highLabel,
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _questionTitle({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: primaryCyan,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
            disabledBackgroundColor: primaryCyan.withValues(alpha: 0.35),
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
                  'CALCULATE READINESS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}
