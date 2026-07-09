import 'package:flutter/material.dart';
import '../../../../data/training_program_model.dart';
import '../program_detail_screen.dart';
import '../workout_view_screen.dart';

class TrainingProgramCard extends StatelessWidget {
  final TrainingProgramModel program;
  final List<Map<String, dynamic>> tests;

  const TrainingProgramCard({
    super.key,
    required this.program,
    this.tests = const [],
  });

  String _formatGoal(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    // نفس الـ base URL المستخدم في ApiClient عندك
    return 'http://192.168.1.8:3000$path';
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF2DD4BF);
    final imageUrl = _resolveImageUrl(program.coverImage);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        if (program.status == 'active' && program.enrollmentId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutViewScreen(
                enrollmentId: program.enrollmentId!,
                programId: program.programId ?? program.id,
                tests: tests,
              ),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgramDetailScreen(programId: program.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111619),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1E262A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageFallback();
                  },
                ),
              )
            else
              _buildImageFallback(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          program.status.toUpperCase(),
                          style: const TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white38,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${program.durationWeeks} weeks',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    program.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatGoal(program.goal),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (program.status == 'active') ...[
                    const SizedBox(height: 14),
                    _buildProgramProgress(program),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 13,
                        backgroundColor: Color(0xFF1E262A),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white38,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coach ${program.coachName}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramProgress(TrainingProgramModel program) {
    const accentColor = Color(0xFF2DD4BF);

    final progress = (program.progressPercent / 100).clamp(0.0, 1.0);

    final label = program.totalSessionsCount > 0
        ? '${program.completedSessionsCount}/${program.totalSessionsCount} sessions'
        : '${program.progressPercent.toStringAsFixed(0)}% complete';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070B0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'PROGRAM PROGRESS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${program.progressPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E262A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          color: Colors.white24,
          size: 42,
        ),
      ),
    );
  }
}
