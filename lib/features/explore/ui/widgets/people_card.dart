import 'package:flutter/material.dart';
import '../../models/explore_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../profile/ui/profile_screen.dart';
import '../../../profile/ui/public_profile_screen.dart';

class PeopleCard extends StatelessWidget {
  final SuggestedAthleteModel athlete;
  final VoidCallback? onToggleFollow;

  const PeopleCard({
    super.key,
    required this.athlete,
    this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2dd4bf).withValues(alpha: 0.12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  athlete.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  athlete.level,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onToggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: athlete.isFollowedByMe
                    ? const Color(0xFF18181b)
                    : const Color(0xFF2dd4bf),
                foregroundColor:
                    athlete.isFollowedByMe ? Colors.white : Colors.black,
                side: athlete.isFollowedByMe
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.15))
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                athlete.isFollowedByMe ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
