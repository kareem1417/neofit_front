import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../data/training_program_model.dart';
import '../data/programs_service.dart';
import '../explore/ai_advisor_chat_screen.dart';
import 'widgets/training_program_card.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  late final ProgramsService _programsService;
  late Future<_ProgramsScreenData> _programsFuture;

  // Fallback tests from latest snapshot (used for available programs only)
  List<Map<String, dynamic>> _fallbackTests = [];

  @override
  void initState() {
    super.initState();
    _programsService = ProgramsService(
      apiClient: context.read<ApiClient>(),
    );
    _programsFuture = _loadPrograms();
    _loadFallbackTests();
  }

  Future<void> _loadFallbackTests() async {
    try {
      final tests = await _programsService.getAvailableTestsForCurrentUser();
      if (mounted) {
        setState(() {
          _fallbackTests = tests;
        });
      }
    } catch (e) {
      // Fallback only — primary tests come from enrollment baseline_tests
    }
  }

  Future<_ProgramsScreenData> _loadPrograms() async {
    final results = await Future.wait([
      _programsService.getActivePrograms(),
      _programsService.getAvailablePrograms(limit: 5),
    ]);

    return _ProgramsScreenData(
      activePrograms: results[0],
      availablePrograms: results[1],
    );
  }

  Future<void> _refreshPrograms() async {
    setState(() {
      _programsFuture = _loadPrograms();
    });

    await _programsFuture;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B0D);
    const accentColor = Color(0xFF2DD4BF);
    const fabBgColor = Color(0xFF18181b);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'MY PROGRAMS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<_ProgramsScreenData>(
        future: _programsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              color: accentColor,
              backgroundColor: fabBgColor,
              onRefresh: _refreshPrograms,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white24,
                    size: 42,
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Failed to load programs',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final activePrograms = snapshot.data?.activePrograms ?? [];
          final availablePrograms = snapshot.data?.availablePrograms ?? [];

          return RefreshIndicator(
            color: accentColor,
            backgroundColor: fabBgColor,
            onRefresh: _refreshPrograms,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    'ACTIVE PROGRAMS (${activePrograms.length})',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (activePrograms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          color: Colors.white24,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No active programs yet',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Enroll in a program to see it here.',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...activePrograms.map(
                    (program) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: TrainingProgramCard(
                        program: program,
                        tests: program.baselineTests.isNotEmpty
                            ? program.baselineTests
                            : _fallbackTests,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    activePrograms.isEmpty ? 16 : 12,
                    20,
                    12,
                  ),
                  child: Text(
                    'AVAILABLE PROGRAMS (${availablePrograms.length})',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (availablePrograms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          color: Colors.white24,
                          size: 42,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No available programs found',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...availablePrograms.map(
                    (program) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: TrainingProgramCard(
                        program: program,
                        tests: _fallbackTests,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiAdvisorChatScreen(),
            ),
          );
        },
        backgroundColor: fabBgColor,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.auto_awesome,
          color: accentColor,
        ),
      ),
    );
  }
}

class _ProgramsScreenData {
  final List<TrainingProgramModel> activePrograms;
  final List<TrainingProgramModel> availablePrograms;

  const _ProgramsScreenData({
    required this.activePrograms,
    required this.availablePrograms,
  });
}
