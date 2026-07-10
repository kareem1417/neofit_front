import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../main_layout/ui/coach_dashboard_screen.dart';

class CoachDetailsScreen extends StatefulWidget {
  const CoachDetailsScreen({super.key});

  @override
  State<CoachDetailsScreen> createState() => _CoachDetailsScreenState();
}

class _CoachDetailsScreenState extends State<CoachDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSportName;
  String _selectedLevel = 'amateur';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().fetchCoachSports();
    });
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSportName == null || _selectedSportName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose your sport'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await context.read<AuthCubit>().saveCoachDetails(
          sport: _selectedSportName!,
          level: _selectedLevel,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save coach profile'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CoachDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.9),
              radius: 1.2,
              colors: [Color(0xFF0F1E21), Color(0xFF070B0D)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'COACH SETUP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your sport and coaching level',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('SPORT / SPECIALIZATION'),
                        const SizedBox(height: 8),
                        _buildSportDropdown(),
                        const SizedBox(height: 24),
                        _buildLabel('COACHING LEVEL'),
                        const SizedBox(height: 8),
                        _buildLevelDropdown(),
                        const SizedBox(height: 32),
                        _buildInfoCard(),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5C1),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: const Color(0xFF00E5C1)
                                  .withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'ENTER COACH DASHBOARD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  Widget _buildSportDropdown() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final cubit = context.watch<AuthCubit>();
        final sports = cubit.coachSports;

        if (sports.isEmpty && state is AuthLoading) {
          return Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1315),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E262A)),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00E5C1),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1315),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E262A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSportName,
              isExpanded: true,
              dropdownColor: const Color(0xFF111619),
              iconEnabledColor: const Color(0xFF00E5C1),
              hint: const Text(
                'Choose sport',
                style: TextStyle(color: Colors.white24),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              items: sports.map<DropdownMenuItem<String>>((rawSport) {
                final sport = rawSport as Map;
                final name = sport['name']?.toString() ?? 'Unknown';

                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSportName = value);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLevel,
          dropdownColor: const Color(0xFF111619),
          iconEnabledColor: const Color(0xFF00E5C1),
          isExpanded: true,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          items: const [
            DropdownMenuItem(
              value: 'novice',
              child: Text('Novice'),
            ),
            DropdownMenuItem(
              value: 'amateur',
              child: Text('Amateur'),
            ),
            DropdownMenuItem(
              value: 'professional',
              child: Text('Professional'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedLevel = value);
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111619),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Color(0xFF00E5C1),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No athlete goal, metrics, or test entry needed. Coaches can create and manage programs.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}
