import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../data/workout_model.dart';
import '../data/workouts_service.dart';
import 'program_complete_screen.dart';

class WorkoutViewScreen extends StatefulWidget {
  final String enrollmentId;
  final String programId;
  final List<Map<String, dynamic>> tests;

  const WorkoutViewScreen({
    super.key,
    required this.enrollmentId,
    required this.programId,
    required this.tests,
  });

  @override
  State<WorkoutViewScreen> createState() => _WorkoutViewScreenState();
}

class _WorkoutViewScreenState extends State<WorkoutViewScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color primaryCyan = Color(0xFF2DE1C2);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color cardBg = Color(0xFF141415);

  late final WorkoutsService _service;
  late Future<NextWorkoutModel> _future;

  int _currentExerciseIndex = 0;
  int _rpe = 8;
  bool _isSubmitting = false;

  final _notesController = TextEditingController();
  final Map<int, List<_SetEntryControllers>> _exerciseSetControllers = {};

  @override
  void initState() {
    super.initState();
    _service = WorkoutsService(apiClient: context.read<ApiClient>());
    _future = _service.getNextWorkout(enrollmentId: widget.enrollmentId);
  }

  @override
  void dispose() {
    _notesController.dispose();

    for (final sets in _exerciseSetControllers.values) {
      for (final set in sets) {
        set.dispose();
      }
    }

    super.dispose();
  }

  void _ensureControllersForExercise(
    int exerciseIndex,
    WorkoutExerciseModel exercise,
  ) {
    if (_exerciseSetControllers.containsKey(exerciseIndex)) return;

    final setCount = exercise.sets > 0 ? exercise.sets : 1;

    _exerciseSetControllers[exerciseIndex] = List.generate(
      setCount,
      (_) => _SetEntryControllers(),
    );
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      _exerciseSetControllers[exerciseIndex] ??= [];
      _exerciseSetControllers[exerciseIndex]!.add(_SetEntryControllers());
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    final sets = _exerciseSetControllers[exerciseIndex];
    if (sets == null || sets.length <= 1) return;

    setState(() {
      sets[setIndex].dispose();
      sets.removeAt(setIndex);
    });
  }

  Future<void> _completeWorkout(NextWorkoutModel workout) async {
    if (workout.sessionId == null) return;

    final payloadExercises = <Map<String, dynamic>>[];

    for (int i = 0; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      final setControllers = _exerciseSetControllers[i] ?? [];

      final setsData = <Map<String, dynamic>>[];

      for (final set in setControllers) {
        final weight = double.tryParse(set.weightController.text.trim());
        final reps = int.tryParse(set.repsController.text.trim());

        if (weight == null || reps == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill weight and reps for all sets.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        setsData.add({
          'weight': weight,
          'reps': reps,
        });
      }

      payloadExercises.add({
        'session_exercise_id': exercise.id,
        'sets_data': setsData,
      });
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.logWorkout(
        enrollmentId: widget.enrollmentId,
        sessionId: workout.sessionId!,
        rpe: _rpe,
        notes: _notesController.text,
        exercises: payloadExercises,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout completed successfully ✅')),
      );

      Navigator.pop(context, true);
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

  void _goNext(NextWorkoutModel workout) {
    if (_currentExerciseIndex < workout.exercises.length - 1) {
      setState(() => _currentExerciseIndex++);
    }
  }

  void _goPrevious() {
    if (_currentExerciseIndex > 0) {
      setState(() => _currentExerciseIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<NextWorkoutModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryCyan),
              );
            }

            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }

            final workout = snapshot.data!;

            if (workout.isProgramComplete) {
              return _buildProgramComplete(workout);
            }

            if (workout.exercises.isEmpty) {
              return _buildError('No exercises found for this workout.');
            }

            final exercise = workout.exercises[_currentExerciseIndex];
            _ensureControllersForExercise(_currentExerciseIndex, exercise);

            return Column(
              children: [
                _buildHeader(workout),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExerciseCard(workout, exercise),
                        const SizedBox(height: 18),
                        _buildNavigation(workout),
                        const SizedBox(height: 24),
                        _buildSessionFeedback(),
                        const SizedBox(height: 24),
                        _buildCompleteButton(workout),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(NextWorkoutModel workout) {
    final dayNumber = workout.dayOffset + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
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
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $dayNumber - ${workout.sessionName ?? 'Workout'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workout.scheduledDate != null
                      ? 'Scheduled: ${workout.scheduledDate!.toIso8601String().split('T').first}'
                      : 'Next workout',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (workout.estimatedDurationMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${workout.estimatedDurationMinutes} MIN',
                style: const TextStyle(
                  color: primaryCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    NextWorkoutModel workout,
    WorkoutExerciseModel exercise,
  ) {
    final setControllers = _exerciseSetControllers[_currentExerciseIndex] ?? [];

    return Container(
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
            'Exercise ${_currentExerciseIndex + 1}/${workout.exercises.length}',
            style: const TextStyle(
              color: primaryCyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _buildExerciseInfoRow(
            Icons.fitness_center,
            '${exercise.sets} sets × ${exercise.reps} reps',
          ),
          const SizedBox(height: 8),
          _buildExerciseInfoRow(
            Icons.timer_outlined,
            'Rest: ${exercise.restSeconds} seconds',
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          ...List.generate(setControllers.length, (index) {
            return _buildSetRow(index, setControllers[index]);
          }),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _addSet(_currentExerciseIndex),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Set'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryCyan,
              side: BorderSide(color: primaryCyan.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: textGrey, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: textGrey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSetRow(int index, _SetEntryControllers controllers) {
    final canRemove =
        (_exerciseSetControllers[_currentExerciseIndex]?.length ?? 0) > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              'Set ${index + 1}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _smallInput(
              controller: controllers.weightController,
              hint: '80',
              suffix: 'kg',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _smallInput(
              controller: controllers.repsController,
              hint: '5',
              suffix: 'reps',
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _removeSet(_currentExerciseIndex, index),
              icon: const Icon(
                Icons.close,
                color: Colors.white30,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallInput({
    required TextEditingController controller,
    required String hint,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        hintStyle: const TextStyle(color: Colors.white24),
        suffixStyle: const TextStyle(color: textGrey, fontSize: 11),
        filled: true,
        fillColor: bgColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan),
        ),
      ),
    );
  }

  Widget _buildNavigation(NextWorkoutModel workout) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentExerciseIndex == 0 ? null : _goPrevious,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white24,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentExerciseIndex == workout.exercises.length - 1
                ? null
                : () => _goNext(workout),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryCyan,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionFeedback() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSION FEEDBACK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Session RPE',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$_rpe/10',
                style: const TextStyle(
                  color: primaryCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: _rpe.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: primaryCyan,
            inactiveColor: Colors.white12,
            label: '$_rpe',
            onChanged: (v) => setState(() => _rpe = v.round()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Notes...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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

  Widget _buildCompleteButton(NextWorkoutModel workout) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _completeWorkout(workout),
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
                'Complete Workout ✅',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
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

  Widget _buildProgramComplete(NextWorkoutModel workout) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: primaryCyan,
              size: 54,
            ),
            const SizedBox(height: 18),
            const Text(
              'All Sessions Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              workout.message ?? 'Ready to finish the program.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgramCompleteScreen(
                      enrollmentId: widget.enrollmentId,
                      programId: widget.programId,
                      tests: widget.tests,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Start Final Assessment',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetEntryControllers {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}
