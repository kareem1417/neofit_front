import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../programs/coach_create/ui/coach_program_create_screen.dart';

import '../../auth/logic/auth_cubit.dart';
import '../../home/ui/home_screen.dart';
import '../../explore/ui/tabs/explore_screen.dart';
import '../../profile/ui/profile_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().fetchCoachProfile();
    });
  }

  List<Widget> get _screens => [
        const HomeScreen(),
        const ExploreScreen(),
        const CoachProgramCreateScreen(),
        ProfileScreen(
          isCoach: true,
          onGoHome: () {
            setState(() => _currentIndex = 0);
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 65,
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF070B0D),
          border: Border(
            top: BorderSide(color: Color(0xFF1E262A), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'HOME', 0),
            _buildNavItem(Icons.explore_outlined, 'EXPLORE', 1),
            _buildNavItem(Icons.add_circle_outline, 'CREATE', 2),
            _buildNavItem(Icons.person_outline, 'PROFILE', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF00E5C1) : Colors.white24,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5C1) : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class CoachCreateProgramPlaceholderScreen extends StatelessWidget {
  const CoachCreateProgramPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.9),
              radius: 1.2,
              colors: [Color(0xFF0F1E21), Color(0xFF070B0D)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CREATE PROGRAM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Build training programs for your athletes.',
                style: TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF111619),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1E262A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5C1).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Color(0xFF00E5C1),
                      size: 46,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Program Builder Coming Next',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Next step: create title, sport, level, weeks, sessions, exercises, and publish your own coaching programs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
