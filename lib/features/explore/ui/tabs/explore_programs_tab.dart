import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/explore_cubit.dart';
import '../../logic/explore_state.dart';
import '../widgets/explore_program_card.dart';

class ExploreProgramsTab extends StatelessWidget {
  const ExploreProgramsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      'BOXING',
      'GOAL',
      'LEVEL',
      'DURATION',
      'RATING',
    ];

    return BlocBuilder<ExploreCubit, ExploreState>(
      builder: (context, state) {
        if (state is ExploreLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2dd4bf)),
          );
        }
        if (state is ExploreLoaded) {
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: categories.map((cat) {
                    final isActive = cat == 'BOXING';
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2dd4bf)
                            : const Color(0xFF18181b),
                        borderRadius: BorderRadius.circular(20),
                        border: isActive
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FEATURED PROGRAMS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      '${state.detailedPrograms.length} AVAILABLE',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.detailedPrograms.length,
                  itemBuilder: (context, index) {
                    return ExploreProgramCard(
                        program: state.detailedPrograms[index]);
                  },
                ),
              ),
            ],
          );
        }
        if (state is ExploreError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
