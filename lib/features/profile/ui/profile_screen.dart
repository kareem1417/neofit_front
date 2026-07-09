import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ⚠️ غير المسار ده لمسار ملف AuthCubit بتاعك صح لو مختلف
import '../../auth/logic/auth_cubit.dart';
import '../../onboarding/ui/test_entry.dart';
import '../../../data/post_model.dart';
import '../../auth/logic/auth_state.dart';
import 'edit_profile_screen.dart';
import '../../main_layout/ui/main_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onGoHome;

  const ProfileScreen({super.key, this.onGoHome});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// ضفنا SingleTickerProviderStateMixin عشان الأنيميشن
class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  // متغيرات الأنيميشن
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // تظبيط الأنيميشن (هياخد ثانية ونص)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // شكل الأنيميشن (بيبدأ سريع ويبطأ في الآخر)
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );

    // تشغيل الأنيميشن أول ما الشاشة تفتح
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final cubit = context.read<AuthCubit>();
      cubit.userData == null
          ? cubit.fetchDashboard()
          : cubit.fetchProfileExtras();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (widget.onGoHome != null) {
      widget.onGoHome!();
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // استخدمنا watch عشان لما الداتا تيجي الـ UI يعمل ريفريش لوحده
    final cubit = context.watch<AuthCubit>();

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.9),
          radius: 1.2,
          colors: [Color(0xFF0F1E21), Color(0xFF070B0D)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(cubit), // 👈 باصينا الـ cubit هنا
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(cubit), // 👈 وباصيناه هنا كمان
                      const SizedBox(height: 30),
                      _buildTabSwitcher(),
                      const SizedBox(height: 30),
                      if (_selectedTabIndex == 0) ...[
                        _buildMetricsAndSportSection(cubit),
                        const SizedBox(height: 24),
                        _buildAthleticProfileSection(cubit),
                        const SizedBox(height: 24),
                        _buildGoalAnalysisSection(cubit),
                        const SizedBox(height: 24),
                        _buildInitialOnboardingTestsSection(cubit),
                        const SizedBox(height: 24),
                        _buildProgramHistorySection(),
                      ] else ...[
                        _buildProfilePostsSection(cubit),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthCubit cubit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'NeoFit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            // ✅ اليوزرنيم الديناميك
            '@${cubit.username ?? 'athlete'}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          IconButton(
            onPressed: _goHome,
            icon: const Icon(
              Icons.home_outlined,
              color: Colors.white60,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthCubit cubit) {
    // Helper function عشان نخلي أول حرف كابيتال في المستوى أو الفئة
    String capitalize(String s) =>
        s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

    // تظبيط الداتا اللي هتتعرض
    String level = capitalize(cubit.userLevel ?? 'Amateur');
    String category = capitalize(
      (cubit.userCategory ?? 'Middleweight').replaceAll('_', ' '),
    );
    String age = cubit.userAge?.toString() ?? '--';

    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E262A), width: 1),
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14191C),
                // ✅ عرض الصورة لو موجودة
                image: cubit.profilePhoto != null
                    ? DecorationImage(
                        image: NetworkImage(cubit.profilePhoto!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              // ✅ عرض الأيقونة كبديل لو مفيش صورة
              child: cubit.profilePhoto == null
                  ? const Icon(
                      Icons.person_outline,
                      size: 45,
                      color: Colors.white24,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          // ✅ الاسم الحقيقي
          cubit.fullName ?? 'Athlete Name',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cubit.userLevel != null) ...[
              _buildBadge(level),
              const SizedBox(width: 8),
            ],
            if (cubit.userCategory != null &&
                cubit.userCategory != 'not_applicable') ...[
              _buildBadge(category),
              const SizedBox(width: 8),
            ],
            _buildBadge(age),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          cubit.bio ?? 'Relentless pressure. Aiming for the pros.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        _buildSmallButton(
          'Edit Profile',
          Icons.edit_outlined,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildSocialStats(cubit),
      ],
    );
  }

  Widget _buildSocialStats(AuthCubit cubit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(
          value: cubit.postsCount.toString(),
          label: 'Posts',
          onTap: () async {
            await cubit.fetchProfileExtras();
            if (!mounted) return;
            setState(() => _selectedTabIndex = 1);
          },
        ),
        const SizedBox(width: 28),
        _buildStatItem(
          value: cubit.followersCount.toString(),
          label: 'Followers',
          onTap: () async {
            await cubit.fetchProfileExtras();
            if (!mounted) return;
            _showUsersSheet('Followers', cubit.followers);
          },
        ),
        _buildStatItem(
          value: cubit.followingCount.toString(),
          label: 'Following',
          onTap: () async {
            await cubit.fetchProfileExtras();
            if (!mounted) return;
            _showUsersSheet('Following', cubit.following);
          },
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showUsersSheet(String title, List<Map<String, dynamic>> users) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF09090b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                Expanded(
                  child: users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users yet',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final photo = user['profile_photo']?.toString();
                            final username =
                                user['username']?.toString() ?? 'Unknown';
                            final level = user['level']?.toString() ??
                                user['role']?.toString() ??
                                'Athlete';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2dd4bf)
                                    .withValues(alpha: 0.12),
                                backgroundImage:
                                    photo != null && photo.isNotEmpty
                                        ? NetworkImage(photo)
                                        : null,
                                child: photo == null || photo.isEmpty
                                    ? Text(
                                        username.isNotEmpty
                                            ? username[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          color: Color(0xFF2dd4bf),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                level,
                                style: const TextStyle(color: Colors.white38),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14191C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Row(
      children: [_buildTabItem('OVERVIEW', 0), _buildTabItem('POSTS', 1)],
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              color: isSelected ? const Color(0xFF00E5C1) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsAndSportSection(AuthCubit cubit) {
    final metrics = cubit.metricsData ?? {};
    final user = cubit.userData ?? {};
    final profiles = user['sport_profiles'] as List? ??
        user['user_sport_profiles'] as List? ??
        [];

    final profile = profiles.isNotEmpty
        ? Map<String, dynamic>.from(profiles.first)
        : <String, dynamic>{};

    final sport = profile['sports']?['name']?.toString() ??
        profile['sport_name']?.toString() ??
        'Unknown Sport';

    final goal = metrics['goal']?.toString().replaceAll('_', ' ') ?? 'No goal';

    return _buildCardWrapper(
      title: 'BODY, SPORT & GOAL',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1315),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E262A)),
        ),
        child: Column(
          children: [
            _buildInfoRow('Sport', sport),
            _buildInfoRow('Goal', goal),
            _buildInfoRow(
              'Height',
              metrics['height_cm'] != null
                  ? '${metrics['height_cm']} cm'
                  : '--',
            ),
            _buildInfoRow(
              'Weight',
              metrics['weight_kg'] != null
                  ? '${metrics['weight_kg']} kg'
                  : '--',
            ),
            _buildInfoRow(
              'Training days',
              metrics['training_days_per_week']?.toString() ?? '--',
            ),
            _buildInfoRow(
              'Years training',
              metrics['years_training']?.toString() ?? '--',
            ),
            _buildInfoRow(
              'Injury history',
              metrics['has_injury_history'] == true ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialOnboardingTestsSection(AuthCubit cubit) {
    final tests = cubit.initialOnboardingTests;

    return _buildCardWrapper(
      title: 'INITIAL ONBOARDING TESTS',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1315),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E262A)),
        ),
        child: tests.isEmpty
            ? const Text(
                'No onboarding tests found.',
                style: TextStyle(color: Colors.white38),
              )
            : Column(
                children: tests.map((raw) {
                  final test = Map<String, dynamic>.from(raw);
                  final name = test['test_name']?.toString() ?? 'Test';
                  final value = test['value']?.toString() ?? '--';
                  final unit = test['unit']?.toString() ?? '';

                  return _buildInfoRow(name, '$value $unit');
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildAthleticProfileSection(AuthCubit cubit) {
    final axes = cubit.dynamicRadarAxes;
    const double chartSize = 220;
    const double labelRadius = 145;

    return _buildCardWrapper(
      title: 'ATHLETIC PROFILE',
      trailing: _buildSmallButton('Update', Icons.edit_outlined, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TestEntryScreen(sportId: 1, isEditing: true),
          ),
        );
      }),
      child: SizedBox(
        width: double.infinity,
        height: 340,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerX = constraints.maxWidth / 2;
            final centerY = 160.0;

            return Stack(
              children: [
                Positioned(
                  left: centerX - chartSize / 2,
                  top: centerY - chartSize / 2,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (_, __) {
                      return CustomPaint(
                        size: const Size(chartSize, chartSize),
                        painter: RadarChartPainter(
                          values: axes
                              .map((e) => (e['value'] as num).toDouble())
                              .toList(),
                          animationValue: _animation.value,
                        ),
                      );
                    },
                  ),
                ),
                ...List.generate(axes.length, (index) {
                  final angle = (index * 2 * pi / axes.length) - pi / 2;

                  final x = centerX + cos(angle) * labelRadius;
                  final y = centerY + sin(angle) * labelRadius;

                  return Positioned(
                    left: x - 45,
                    top: y - 20,
                    child: SizedBox(
                      width: 90,
                      child: _RadarLabel(
                        name: axes[index]['name'],
                        value: (axes[index]['value'] as num).toInt().toString(),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoalAnalysisSection(AuthCubit cubit) {
    double getRadarValue(String name) {
      final axis = cubit.dynamicRadarAxes.firstWhere(
        (ax) => (ax['name'] as String).toLowerCase() == name.toLowerCase(),
        orElse: () => {'value': 0.0},
      );
      return axis['value'] as double;
    }

    return _buildCardWrapper(
      title: 'GOAL ANALYSIS',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1315),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E262A)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B0D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Color(0xFF00E5C1)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Punch Power',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  cubit.punchPowerScore.toString(),
                  style: const TextStyle(
                    color: Color(0xFF00E5C1),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetricRow(
              label: 'Foundation',
              value: getRadarValue('Strength'),
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Accel',
              value: getRadarValue('Explosive'),
              color: const Color(0xFF00E5C1),
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Transfer',
              value: getRadarValue('Core'),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePostsSection(AuthCubit cubit) {
    final posts = cubit.profilePosts;

    if (posts.isEmpty) {
      if (cubit.state is AuthLoading) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'No posts yet.',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return Column(
      children: posts.map((post) => _buildProfilePostCard(post)).toList(),
    );
  }

  Widget _buildProfilePostCard(PostModel post) {
    final image = post.imagePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((post.content ?? '').trim().isNotEmpty)
            Text(
              post.content!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          if (image != null && image.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                post.isLikedByMe == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: post.isLikedByMe == true
                    ? Colors.redAccent
                    : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.likesCount ?? 0}',
                style: const TextStyle(color: Colors.white38),
              ),
              const SizedBox(width: 18),
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.commentsCount ?? 0}',
                style: const TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramHistorySection() {
    return _buildCardWrapper(
      title: 'PROGRAM HISTORY',
      child: Column(
        children: [
          _buildHistoryItem('Fight Shape 6-Week', 'OCT 14, 2025', true),
          const SizedBox(height: 12),
          _buildHistoryItem('Foundation Strength', 'AUG 02, 2025', true),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, bool completed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E262A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.white10, size: 20),
            ],
          ),
          Text(
            date,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    final List<Widget> headerChildren = [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ];
    if (trailing != null) headerChildren.add(trailing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: headerChildren,
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildSmallButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF14191C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E262A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF00E5C1)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarLabel extends StatelessWidget {
  final String name;
  final String value;

  const _RadarLabel({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00E5C1),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value.toInt().toString(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final double animationValue;

  RadarChartPainter({required this.values, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final count = values.length;

    for (var i = 1; i <= 4; i++) {
      canvas.drawPath(
        _buildPolygonPath(center, radius * (i / 4), count),
        paint,
      );
    }

    final dataPaint = Paint()
      ..color = const Color(0xFF00E5C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fillPaint = Paint()
      ..color = const Color(0x2200E5C1)
      ..style = PaintingStyle.fill;
    final dataPath = Path();

    for (int i = 0; i < count; i++) {
      double angle = (i * 360 / count - 90) * pi / 180;
      double r = ((values[i] / 100) * radius) * animationValue;

      Offset p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
      canvas.drawCircle(p, 3, Paint()..color = const Color(0xFF00E5C1));
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, dataPaint);
  }

  Path _buildPolygonPath(Offset center, double radius, int sides) {
    final path = Path();
    if (sides == 0) return path; // حماية إضافية لو الـ values جاية فاضية
    for (int i = 0; i < sides; i++) {
      double angle = (i * 360 / sides - 90) * pi / 180;
      Offset point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) => true;
}
