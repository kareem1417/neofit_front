import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/explore_cubit.dart';
import '../../logic/explore_state.dart';
import '../widgets/people_card.dart';

class ExplorePeopleTab extends StatelessWidget {
  const ExplorePeopleTab({super.key});

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PEOPLE TO FOLLOW',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'FILTER',
                        style: TextStyle(
                          color: Color(0xFF2dd4bf),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.people.length,
                  itemBuilder: (context, index) {
                    return PeopleCard(
                      athlete: state.people[index],
                      onToggleFollow: () {
                        context
                            .read<ExploreCubit>()
                            .toggleFollow(state.people[index]);
                      },
                    );
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
