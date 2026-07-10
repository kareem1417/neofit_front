import 'package:flutter/material.dart';

import '../models/program_builder_data.dart';

class ExerciseBuilderScreen extends StatefulWidget {
  final ProgramBuilderData programData;
  final int blockIndex;
  final int sessionIndex;

  const ExerciseBuilderScreen({
    super.key,
    required this.programData,
    required this.blockIndex,
    required this.sessionIndex,
  });

  @override
  State<ExerciseBuilderScreen> createState() => _ExerciseBuilderScreenState();
}

class _ExerciseBuilderScreenState extends State<ExerciseBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _intensityController;
  late TextEditingController _restController;
  late TextEditingController _notesController;

  ProgramSessionData get session => widget
      .programData.blocks[widget.blockIndex].sessions[widget.sessionIndex];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _setsController = TextEditingController(text: '3');
    _repsController = TextEditingController(text: '8');
    _intensityController = TextEditingController(text: '');
    _restController = TextEditingController(text: '60');
    _notesController = TextEditingController();

    if (session.exercises.isEmpty) {
      session.exercises = [
        ProgramExerciseData(
          title: 'TRAP BAR DEADLIFT',
          sets: 3,
          reps: '5',
          restSeconds: 120,
          intensityNote: '80% 1RM',
        ),
        ProgramExerciseData(
          title: 'BOX JUMPS',
          icon: 'bolt',
          sets: 4,
          reps: '6',
          restSeconds: 90,
        ),
        ProgramExerciseData(
          title: 'CORE ROTATIONAL WORK',
          icon: 'refresh',
          sets: 3,
          reps: '10/SIDE',
          restSeconds: 60,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _intensityController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _nameController.text.trim();

    if (name.isEmpty) return;

    setState(() {
      session.exercises.add(
        ProgramExerciseData(
          title: name.toUpperCase(),
          sets: int.tryParse(_setsController.text.trim()) ?? 0,
          reps: _repsController.text.trim().isEmpty
              ? '0'
              : _repsController.text.trim(),
          restSeconds: int.tryParse(_restController.text.trim()) ?? 0,
          intensityNote: _intensityController.text.trim(),
          notes: _notesController.text.trim(),
        ),
      );

      _nameController.clear();
      _setsController.text = '3';
      _repsController.text = '8';
      _intensityController.clear();
      _restController.text = '60';
      _notesController.clear();
    });
  }

  void _deleteExercise(int index) {
    setState(() => session.exercises.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B0D);
    const accentTeal = Color(0xFF1CE0BF);
    const surfaceColor = Color(0xFF0F1115);
    const borderColor = Color(0xFF1E2127);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'EXERCISE BUILDER',
                          style: TextStyle(
                            color: accentTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'CURRENT EXERCISES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${session.exercises.length} ADDED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: session.exercises.length,
                      itemBuilder: (context, index) {
                        return _buildExerciseCard(
                          session.exercises[index],
                          index,
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ADD NEW EXERCISE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('EXERCISE NAME'),
                          const SizedBox(height: 12),
                          _buildFormTextField(
                            controller: _nameController,
                            hint: 'e.g., Kettlebell Swings',
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFieldColumn(
                                  'SETS',
                                  _setsController,
                                  '3',
                                  TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFieldColumn(
                                  'REPS',
                                  _repsController,
                                  '8',
                                  TextInputType.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFieldColumn(
                                  'INTENSITY',
                                  _intensityController,
                                  '80% 1RM',
                                  TextInputType.text,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFieldColumn(
                                  'REST SEC',
                                  _restController,
                                  '60',
                                  TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('NOTES / CUES'),
                          const SizedBox(height: 12),
                          _buildFormTextField(
                            controller: _notesController,
                            hint: 'Focus on hip hinge...',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _addExercise,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: accentTeal.withValues(alpha: 0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: accentTeal, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'ADD EXERCISE TO SESSION',
                                    style: TextStyle(
                                      color: accentTeal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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
                        'SAVE & RETURN TO SESSION',
                        style: TextStyle(
                          color: Color(0xFF070B0D),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.check,
                        color: Color(0xFF070B0D),
                        size: 20,
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

  Widget _buildFieldColumn(
    String label,
    TextEditingController controller,
    String hint,
    TextInputType type,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 12),
        _buildFormTextField(
          controller: controller,
          hint: hint,
          keyboardType: type,
        ),
      ],
    );
  }

  Widget _buildExerciseCard(ProgramExerciseData exercise, int index) {
    const surfaceColor = Color(0xFF0F1115);
    const borderColor = Color(0xFF1E2127);
    const accentTeal = Color(0xFF1CE0BF);

    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'bolt':
          return Icons.bolt;
        case 'refresh':
          return Icons.autorenew;
        default:
          return Icons.fitness_center;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(
              getIcon(exercise.icon),
              color: accentTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.details,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteExercise(index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white24,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
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
          color: Colors.white.withValues(alpha: 0.1),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF070B0D),
        contentPadding: const EdgeInsets.all(18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E2127)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1CE0BF), width: 1),
        ),
      ),
    );
  }
}
