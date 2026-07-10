import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../programs/explore/ai_advisor_chat_screen.dart';
import '../data/leaderboard_repository.dart';
import '../data/leaderboard_user_model.dart';
import '../logic/leaderboard_cubit.dart';
import '../logic/leaderboard_state.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const Color bgColor = Color(0xFF070B0D);
  static const Color cardColor = Color(0xFF111619);
  static const Color chipColor = Color(0xFF14191C);
  static const Color borderColor = Color(0xFF1E262A);
  static const Color accentColor = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeaderboardCubit(
        LeaderboardRepository(
          context.read<ApiClient>().dio,
        ),
      )..loadLeaderboard(type: 'punch_power'),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildPodiumPreview(),
              _buildFilterRow(),
              _buildCohortInfo(),
              Expanded(
                child: _buildLeaderboardList(),
              ),
              _buildStickyUserTile(),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'rank_ai_advisor_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiAdvisorChatScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF18181B),
            shape: const CircleBorder(),
            child: const Icon(
              Icons.auto_awesome,
              color: accentColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'LEADERBOARDS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPreview() {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        if (state is! LeaderboardLoaded || state.athletes.length < 3) {
          return const SizedBox.shrink();
        }

        final topThree = state.athletes.take(3).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPodiumUser(topThree[1], 2, 44),
              _buildPodiumUser(topThree[0], 1, 58),
              _buildPodiumUser(topThree[2], 3, 44),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodiumUser(
    LeaderboardUserModel athlete,
    int place,
    double radius,
  ) {
    final isWinner = place == 1;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildAvatar(athlete.avatarUrl, radius: radius),
            Positioned(
              top: -8,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isWinner ? accentColor : chipColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  place == 1 ? Icons.emoji_events : Icons.military_tech,
                  color: isWinner ? Colors.black : Colors.white70,
                  size: isWinner ? 18 : 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: 86,
          child: Text(
            athlete.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isWinner ? Colors.white : Colors.white70,
              fontSize: isWinner ? 13 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${athlete.percentileScore}%ile',
          style: const TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            'PUNCH POWER',
            isActive: true,
            onTap: (context) {
              context.read<LeaderboardCubit>().loadLeaderboard(
                    type: 'punch_power',
                  );
            },
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'STRENGTH',
            isActive: false,
            onTap: (context) {
              context.read<LeaderboardCubit>().loadLeaderboard(
                    type: 'strength',
                  );
            },
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'ENDURANCE',
            isActive: false,
            onTap: (context) {
              context.read<LeaderboardCubit>().loadLeaderboard(
                    type: 'endurance',
                  );
            },
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'AMATEUR',
            isActive: false,
            onTap: (context) {
              context.read<LeaderboardCubit>().loadLeaderboard(
                    type: 'punch_power',
                    level: 'amateur',
                  );
            },
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            'MIDDLEWEIGHT',
            isActive: false,
            onTap: (context) {
              context.read<LeaderboardCubit>().loadLeaderboard(
                    type: 'punch_power',
                    playerCategory: 'middleweight',
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    required bool isActive,
    required void Function(BuildContext context) onTap,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => onTap(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? accentColor : chipColor,
              borderRadius: BorderRadius.circular(20),
              border: isActive ? null : Border.all(color: borderColor),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCohortInfo() {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        final cohortLabel = state is LeaderboardLoaded
            ? state.cohortLabel
            : 'AMATEUR MIDDLEWEIGHTS';
        final count = state is LeaderboardLoaded ? state.athleteCount : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'TARGET COHORT: $cohortLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$count ATHLETES',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardList() {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return const Center(
            child: CircularProgressIndicator(color: accentColor),
          );
        }

        if (state is LeaderboardError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        if (state is LeaderboardLoaded) {
          final athletes =
              state.athletes.where((a) => !a.isCurrentUser).toList();

          if (athletes.isEmpty) {
            return const Center(
              child: Text(
                'No leaderboard data yet.',
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: athletes.length,
            itemBuilder: (context, index) {
              return _buildAthleteCard(athletes[index]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAthleteCard(LeaderboardUserModel athlete) {
    final bool isTop = athlete.rank == 1;
    final bool isUp = athlete.trendStatus == 'up';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop ? accentColor.withValues(alpha: 0.35) : borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${athlete.rank}',
              style: TextStyle(
                color: isTop ? accentColor : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildAvatar(athlete.avatarUrl, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              athlete.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${athlete.percentileScore}%ile',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isUp ? Colors.greenAccent : Colors.redAccent,
                    size: 17,
                  ),
                  Text(
                    athlete.deltaTrend,
                    style: TextStyle(
                      color: isUp ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyUserTile() {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        if (state is! LeaderboardLoaded) {
          return const SizedBox.shrink();
        }

        final matches = state.athletes.where((a) => a.isCurrentUser);
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }

        final me = matches.first;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1315),
            border: Border(
              top: BorderSide(
                color: accentColor.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '#${me.rank}',
                style: const TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  _buildAvatar(me.avatarUrl, radius: 20),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ME',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      me.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${me.deltaTrend} PTS THIS MONTH',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${me.percentileScore}%ile',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? url, {required double radius}) {
    final hasUrl = url != null && url.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: borderColor,
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      child: hasUrl
          ? null
          : Icon(
              Icons.person,
              color: Colors.white38,
              size: radius,
            ),
    );
  }
}
