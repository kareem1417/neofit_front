import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/explore_cubit.dart';
import '../../logic/explore_state.dart';
import '../../models/explore_models.dart';

class ExploreTopTab extends StatelessWidget {
  const ExploreTopTab({super.key});

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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Popular Programs', () {}),
              const SizedBox(height: 12),
              _buildProgramsList(state.programs),
              const SizedBox(height: 24),
              _buildSectionHeader('Suggested Athletes', () {}),
              const SizedBox(height: 12),
              _buildAthletesList(state.athletes),
              const SizedBox(height: 24),
              _buildSectionHeader('Trending Posts', () {}),
              const SizedBox(height: 12),
              _buildPostsList(state.posts),
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

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(color: Color(0xFF2dd4bf)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgramsList(List<ProgramModel> programs) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: program.imageUrl.isNotEmpty
                      ? Image.network(
                          program.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _programFallback(),
                        )
                      : _programFallback(),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8)
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2dd4bf),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          program.duration,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        program.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${program.rating} • ${program.enrollmentCount} enrolled',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAthletesList(List<SuggestedAthleteModel> athletes) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: athletes.length,
        itemBuilder: (context, index) {
          final athlete = athletes[index];
          return Container(
            width: 130,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181b),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      const Color(0xFF2dd4bf).withValues(alpha: 0.1),
                  backgroundImage: athlete.profilePhoto != null
                      ? NetworkImage(athlete.profilePhoto!)
                      : null,
                  child: athlete.profilePhoto == null
                      ? Text(
                          athlete.initials,
                          style: const TextStyle(
                            color: Color(0xFF2dd4bf),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  athlete.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  athlete.level,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2dd4bf),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Follow',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList(List<ExplorePostModel> posts) {
    return Column(
      children: posts
          .map(
            (post) => Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181b),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF2dd4bf),
                        backgroundImage: post.profilePhoto != null
                            ? NetworkImage(post.profilePhoto!)
                            : null,
                        child: post.profilePhoto == null
                            ? const Icon(Icons.person,
                                size: 12, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.content,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border,
                          color: Colors.white38, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.likes}',
                          style: const TextStyle(color: Colors.white38)),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline,
                          color: Colors.white38, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.comments}',
                          style: const TextStyle(color: Colors.white38)),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _programFallback() {
    return Container(
      color: const Color(0xFF18181b),
      child: const Center(
        child: Icon(Icons.fitness_center, color: Colors.white24, size: 36),
      ),
    );
  }
}
