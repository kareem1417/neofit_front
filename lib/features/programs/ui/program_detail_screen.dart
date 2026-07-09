import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../data/program_detail_model.dart';
import '../data/programs_service.dart';
import 'program_enrollment_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  final String programId;
  final ProgramDetailModel? initialProgram;

  const ProgramDetailScreen({
    super.key,
    required this.programId,
    this.initialProgram,
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color primaryCyan = Color(0xFF2DE1C2);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color cardBg = Color(0xFF141415);

  late final ProgramsService _service;
  late Future<ProgramDetailModel> _future;

  @override
  void initState() {
    super.initState();
    _service = ProgramsService(apiClient: context.read<ApiClient>());
    _future = widget.initialProgram != null
        ? Future.value(widget.initialProgram)
        : _service.getProgramDetail(widget.programId);
  }

  String _formatLabel(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return 'http://192.168.1.8:3000$path';
  }

  Future<void> _handleEnroll(ProgramDetailModel program) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramEnrollmentScreen(program: program),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program enrollment completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<ProgramDetailModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryCyan),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final program = snapshot.data!;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context, program),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildCoachAndRatingRow(program),
                          const SizedBox(height: 32),
                          _buildWhyThisProgram(program),
                          const SizedBox(height: 32),
                          _buildProgramStats(program),
                          const SizedBox(height: 32),
                          _buildCurriculumStructure(program),
                          if (program.recentRatings.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildRecentReviews(program),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildFloatingEnrollButton(program),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white24, size: 42),
              const SizedBox(height: 16),
              const Text(
                'Failed to load program',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _future = _service.getProgramDetail(widget.programId);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryCyan,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, ProgramDetailModel program) {
    final imageUrl = _resolveImageUrl(program.coverImage);

    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          color: cardBg,
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildHeaderFallback(),
                )
              : _buildHeaderFallback(),
        ),
        Container(
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgColor.withValues(alpha: 0.65),
                bgColor.withValues(alpha: 0.05),
                bgColor.withValues(alpha: 0.82),
                bgColor,
              ],
              stops: const [0.0, 0.3, 0.8, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(_formatLabel(program.goalPrimary), isPrimary: true),
                  _buildTag('${program.durationWeeks} WEEKS', isPrimary: false),
                  if (program.levelTarget != null)
                    _buildTag(
                      _formatLabel(program.levelTarget!),
                      isPrimary: false,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                program.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'PROGRAM DETAILS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderFallback() {
    return const Center(
      child: Icon(
        Icons.fitness_center,
        color: Colors.white24,
        size: 58,
      ),
    );
  }

  Widget _buildCoachAndRatingRow(ProgramDetailModel program) {
    final coachPhoto = _resolveImageUrl(program.coach.photo);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1E1E1E),
              backgroundImage:
                  coachPhoto != null ? NetworkImage(coachPhoto) : null,
              child: coachPhoto == null
                  ? const Icon(Icons.person_outline, color: textGrey)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LEAD COACH',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  program.coach.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: primaryCyan, size: 16),
                const SizedBox(width: 4),
                Text(
                  program.ratingAvg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Text(
              '${program.ratingCount} REVIEWS',
              style: const TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWhyThisProgram(ProgramDetailModel program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WHY THIS PROGRAM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          program.description.isNotEmpty
              ? program.description
              : 'A focused training plan designed to improve performance through structured sessions and progressive workload.',
          style: const TextStyle(
            color: textGrey,
            fontSize: 14,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramStats(ProgramDetailModel program) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_outlined,
            value: '${program.durationWeeks}',
            label: 'WEEKS',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            value: '${program.sessionsPerWeek}',
            label: 'SESSIONS/WEEK',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.group_outlined,
            value: '${program.enrollmentCount}',
            label: 'ATHLETES',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryCyan, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumStructure(ProgramDetailModel program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CURRICULUM STRUCTURE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        if (program.blocks.isEmpty)
          const Text(
            'No curriculum blocks available yet.',
            style: TextStyle(color: textGrey),
          )
        else
          ...program.blocks.asMap().entries.map((entry) {
            final index = entry.key;
            final block = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPhaseCard(
                number: (index + 1).toString().padLeft(2, '0'),
                title: block.name.toUpperCase(),
                subtitle:
                    'WEEKS ${block.weekStart} - ${block.weekEnd} • ${block.sessions.length} SESSIONS',
                description: block.description,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPhaseCard({
    required String number,
    required String title,
    required String subtitle,
    String? description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews(ProgramDetailModel program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT REVIEWS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        ...program.recentRatings.map(
          (rating) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rating.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, color: primaryCyan, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      rating.rating.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                if (rating.review.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    rating.review,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? primaryCyan : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary ? Colors.black : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFloatingEnrollButton(ProgramDetailModel program) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          top: 24,
          bottom: 32,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor.withValues(alpha: 0.0), bgColor],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: primaryCyan,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryCyan.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _handleEnroll(program),
              child: const Center(
                child: Text(
                  'ENROLL IN PROGRAM',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
