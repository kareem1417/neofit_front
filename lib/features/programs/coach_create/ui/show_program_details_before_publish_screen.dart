import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../../main_layout/ui/coach_dashboard_screen.dart';
import '../data/coach_program_service.dart';
import '../models/program_builder_data.dart';

class ShowProgramDetailsBeforePublishScreen extends StatefulWidget {
  final ProgramBuilderData programData;

  const ShowProgramDetailsBeforePublishScreen({
    super.key,
    required this.programData,
  });

  @override
  State<ShowProgramDetailsBeforePublishScreen> createState() =>
      _ShowProgramDetailsBeforePublishScreenState();
}

class _ShowProgramDetailsBeforePublishScreenState
    extends State<ShowProgramDetailsBeforePublishScreen> {
  bool _isPublishing = false;

  Future<void> _publish() async {
    if (_isPublishing) return;

    if (widget.programData.blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one block before publishing'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final service = CoachProgramService(
        apiClient: context.read<ApiClient>(),
      );

      await service.publishProgram(widget.programData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program published successfully'),
          backgroundColor: Color(0xFF1CE0BF),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CoachDashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish program: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B0D);
    const accentTeal = Color(0xFF1CE0BF);

    final programData = widget.programData;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(programData),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoachRow(programData),
                      const SizedBox(height: 40),
                      const Text(
                        'WHY THIS PROGRAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        programData.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'CURRICULUM STRUCTURE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...programData.blocks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final block = entry.value;

                        return _buildStructureCard(
                          (index + 1).toString().padLeft(2, '0'),
                          block.title,
                          '${block.weeks} • ${block.sessions.length} SESSIONS',
                          accentTeal,
                        );
                      }),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: _isPublishing ? null : _publish,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: accentTeal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentTeal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPublishing)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF070B0D),
                        ),
                      )
                    else ...[
                      const Text(
                        'PUBLISH PROGRAM',
                        style: TextStyle(
                          color: Color(0xFF070B0D),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.public,
                        color: Color(0xFF070B0D),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ProgramBuilderData programData) {
    const bgColor = Color(0xFF070B0D);
    const accentTeal = Color(0xFF1CE0BF);

    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white10,
            image: programData.coverImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(programData.coverImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: programData.coverImageUrl == null
              ? const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.white10,
                    size: 100,
                  ),
                )
              : null,
        ),
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                bgColor.withValues(alpha: 0.8),
                bgColor,
              ],
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 16,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Text(
            'PROGRAM DETAILS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
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
              Row(
                children: [
                  _buildBadge(programData.sportName.toUpperCase(), accentTeal),
                  const SizedBox(width: 8),
                  _buildBadge('${programData.duration} WEEKS', Colors.white12),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                programData.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachRow(ProgramBuilderData programData) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF1CE0BF),
              width: 1.5,
            ),
          ),
          child: const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white24, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LEAD COACH',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              (programData.coachName ?? 'YOUR COACH PROFILE').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color == Colors.white12 ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border:
            color == Colors.white12 ? null : Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == Colors.white12 ? Colors.white60 : color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStructureCard(
    String id,
    String title,
    String subtitle,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                id,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white10,
            size: 14,
          ),
        ],
      ),
    );
  }
}
