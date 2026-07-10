import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neofit_app/features/profile/ui/profile_screen.dart';

import '../../../core/api/api_client.dart';
import '../../../data/training_program_model.dart';
import '../../programs/ui/program_detail_screen.dart';
import '../data/ai_chat_service.dart';

class AiRecommendationInputScreen extends StatefulWidget {
  const AiRecommendationInputScreen({super.key});

  @override
  State<AiRecommendationInputScreen> createState() =>
      _AiRecommendationInputScreenState();
}

class _AiRecommendationInputScreenState
    extends State<AiRecommendationInputScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color cardColor = Color(0xFF141416);
  static const Color accentColor = Color(0xFF2DD4BF);
  static const Color mutedColor = Color(0xFF737373);

  late final AiChatService _service;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedGoal = 'Power';
  double _trainingDays = 4.0;
  double _yearsTraining = 2.5;
  bool _hasInjuryHistory = false;

  double _enduranceScore = 6;
  double _strengthScore = 7;
  double _speedScore = 8;
  double _flexibilityScore = 5;
  double _explosivenessScore = 8;
  double _recoveryScore = 6;

  bool _useSavedData = true;
  bool _isLoading = false;

  Map<String, dynamic>? _recommendation;
  List<TrainingProgramModel> _recommendedPrograms = [];

  final List<String> _goals = const [
    'Weight_Loss',
    'Muscle_Gain',
    'Endurance',
    'Strength',
    'Agility',
    'Speed',
    'Flexibility',
    'Recovery',
    'Power',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _service = AiChatService(apiClient: context.read<ApiClient>());
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildOverrides() {
    return {
      'height_cm': int.tryParse(_heightController.text.trim()) ?? 170,
      'weight_kg': int.tryParse(_weightController.text.trim()) ?? 70,
      'goal': _selectedGoal,
      'training_days_per_week': _trainingDays.toInt(),
      'years_training': _yearsTraining,
      'has_injury_history': _hasInjuryHistory,
      'endurance_score': _enduranceScore.toInt(),
      'strength_score': _strengthScore.toInt(),
      'speed_score': _speedScore.toInt(),
      'flexibility_score': _flexibilityScore.toInt(),
      'explosiveness_score': _explosivenessScore.toInt(),
      'recovery_score': _recoveryScore.toInt(),
    };
  }

  void _showOnboardingRequiredDialog(List<String> missingSteps) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Complete onboarding first',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          missingSteps.isEmpty
              ? 'AI recommendations need your sport profile, metrics, and baseline tests.'
              : 'Missing steps:\n${missingSteps.map((e) => '• $e').join('\n')}',
          style: const TextStyle(
            color: Colors.white70,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Later',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // TODO: navigate to your onboarding/start screen.
              // Example:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Go to onboarding',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRecommendation() async {
    setState(() => _isLoading = true);

    try {
      final onboardingStatus = await _service.getOnboardingStatus();

      final statusData = onboardingStatus['data'] is Map
          ? Map<String, dynamic>.from(onboardingStatus['data'])
          : <String, dynamic>{};

      final isComplete = statusData['is_complete'] == true;

      if (!isComplete) {
        final missingSteps =
            (statusData['missing_steps'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();

        if (!mounted) return;

        _showOnboardingRequiredDialog(missingSteps);
        return;
      }

      final response = await _service.recommendProgram(
        overrides: _useSavedData ? const {} : _buildOverrides(),
      );

      final responseData = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};

      final recommendation = responseData['recommendation'] is Map
          ? Map<String, dynamic>.from(responseData['recommendation'])
          : <String, dynamic>{};

      final rawPrograms =
          responseData['recommended_programs'] as List<dynamic>? ?? [];

      final programs = rawPrograms
          .map(
            (e) => TrainingProgramModel.fromProgramJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _recommendation = recommendation;
        _recommendedPrograms = programs;
      });

      if (programs.isEmpty) {
        _showSnack(
          'AI generated a recommendation but no matching programs were found.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openProgram(TrainingProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(
          programId: program.id,
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : accentColor,
      ),
    );
  }

  String _formatGoal(String goal) {
    return goal.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AI PROGRAM MATCH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.4,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 18),
            _buildModeSwitch(),
            if (!_useSavedData) ...[
              const SizedBox(height: 18),
              _buildInputs(),
            ],
            if (_recommendation != null) ...[
              const SizedBox(height: 26),
              _buildRecommendationSummary(),
            ],
            if (_recommendedPrograms.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildRecommendedPrograms(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: accentColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your best training block',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Use your onboarding data or tune the inputs to get ML-powered program recommendations.',
                  style: TextStyle(
                    color: Colors.white54,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.person_search_outlined, color: accentColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use saved profile data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Recommended default from onboarding metrics.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _useSavedData,
            activeColor: accentColor,
            onChanged: (value) {
              setState(() => _useSavedData = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TUNE INPUTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _heightController,
                label: 'Height',
                hint: '178',
                suffix: 'cm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumberField(
                controller: _weightController,
                label: 'Weight',
                hint: '76',
                suffix: 'kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildDropdown(),
        const SizedBox(height: 14),
        _buildToggleCard(),
        const SizedBox(height: 18),
        _buildMetricSlider(
          'Training days / week',
          _trainingDays,
          1,
          7,
          (v) => setState(() => _trainingDays = v),
        ),
        _buildMetricSlider(
          'Years training',
          _yearsTraining,
          0,
          15,
          (v) => setState(() => _yearsTraining = v),
        ),
        const SizedBox(height: 18),
        const Text(
          'SELF-ASSESSMENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        _buildScoreSlider(
          'Endurance',
          _enduranceScore,
          (v) => setState(() => _enduranceScore = v),
        ),
        _buildScoreSlider(
          'Strength',
          _strengthScore,
          (v) => setState(() => _strengthScore = v),
        ),
        _buildScoreSlider(
          'Speed',
          _speedScore,
          (v) => setState(() => _speedScore = v),
        ),
        _buildScoreSlider(
          'Flexibility',
          _flexibilityScore,
          (v) => setState(() => _flexibilityScore = v),
        ),
        _buildScoreSlider(
          'Explosiveness',
          _explosivenessScore,
          (v) => setState(() => _explosivenessScore = v),
        ),
        _buildScoreSlider(
          'Recovery',
          _recoveryScore,
          (v) => setState(() => _recoveryScore = v),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: const TextStyle(color: mutedColor),
        hintStyle: const TextStyle(color: Colors.white24),
        suffixStyle: const TextStyle(color: mutedColor),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGoal,
      dropdownColor: cardColor,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Primary Goal',
        labelStyle: const TextStyle(color: mutedColor),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: _goals
          .map(
            (goal) => DropdownMenuItem(
              value: goal,
              child: Text(_formatGoal(goal)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedGoal = value);
      },
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: SwitchListTile(
        value: _hasInjuryHistory,
        activeColor: accentColor,
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Recent injury history',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Adapts recommendation intensity.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        onChanged: (value) => setState(() => _hasInjuryHistory = value),
      ),
    );
  }

  Widget _buildMetricSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return _buildSliderShell(
      label: label,
      valueLabel: value.toStringAsFixed(label.contains('Years') ? 1 : 0),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: (max - min).round(),
        activeColor: accentColor,
        inactiveColor: Colors.white10,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildScoreSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return _buildSliderShell(
      label: label,
      valueLabel: value.toInt().toString(),
      child: Slider(
        value: value,
        min: 1,
        max: 10,
        divisions: 9,
        activeColor: accentColor,
        inactiveColor: Colors.white10,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderShell({
    required String label,
    required String valueLabel,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                valueLabel,
                style: const TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildRecommendationSummary() {
    final recommendation = _recommendation ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI MATCH RESULT',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            recommendation['recommended_program']?.toString() ??
                'Recommended Program',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation['reason']?.toString() ??
                'Recommended based on your performance profile.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill(
                recommendation['confidence']?.toString() ?? 'AI',
                Icons.verified,
              ),
              const SizedBox(width: 8),
              _pill(
                recommendation['model_used']?.toString() ?? 'ML Model',
                Icons.memory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPrograms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECOMMENDED PROGRAMS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        ..._recommendedPrograms.map(_buildRecommendedProgramCard),
      ],
    );
  }

  Widget _buildRecommendedProgramCard(TrainingProgramModel program) {
    return InkWell(
      onTap: () => _openProgram(program),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${program.durationWeeks} weeks • ${program.sessionsPerWeek} sessions/week',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: accentColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        program.ratingAvg ?? '0',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        program.sportName ?? program.goal,
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, IconData icon) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateRecommendation,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: accentColor.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    _useSavedData
                        ? 'GENERATE FROM MY PROFILE'
                        : 'GENERATE AI MATCH',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    );
  }
}
