import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ⚠️ تأكد من مسارات الاستيراد عندك
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import 'edit_initial_tests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().fetchDashboard();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // دالة لتظبيط شكل النصوص (capitalization)
  String _formatText(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF070B0D), // لون الخلفية
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // 🔥 هنا الحل السحري: استخدام BlocBuilder عشان يجبر الشاشة تتحدث لما الداتا توصل
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            // بنقرأ الداتا من الكيوبت في كل مرة الشاشة تتحدث فيها
            final cubit = context.read<AuthCubit>();

            return SafeArea(
              child: Column(
                children: [
                  _buildTopBar(), // البار العلوي (شيلنا اليوزر نيم منه)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileHeader(cubit),
                          const SizedBox(height: 30),
                          _buildTabSwitcher(),
                          const SizedBox(height: 30),
                          _buildAthleticProfileSection(cubit),
                          const SizedBox(height: 24),
                          _buildGoalAnalysisSection(cubit),
                          const SizedBox(height: 24),
                          _buildProgramHistorySection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'NEOFIT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          // 🧹 اليوزر نيم اتشال من هنا عشان نفضي المساحة
          Icon(Icons.settings_outlined, color: Colors.white60, size: 22),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthCubit cubit) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              image: cubit.profilePhoto != null
                  ? DecorationImage(
                      image: NetworkImage(cubit.profilePhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: cubit.profilePhoto == null
                ? const Icon(Icons.person, size: 45, color: Colors.white24)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          cubit.fullName ?? 'Athlete Name',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // 🔥 اليوزر نيم اتنقل هنا وبقى شكله مريح واحترافي
        Text(
          '@${cubit.username ?? 'username'}',
          style: const TextStyle(
            color: Color(0xFF00E5C1), // لون مميز لليوزر نيم
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(
              _formatText(cubit.userLevel ?? 'Amateur'),
              const Color(0xFF00E5C1),
            ),
            const SizedBox(width: 8),
            _buildBadge(
              _formatText(cubit.userCategory ?? 'Middleweight'),
              Colors.white60,
            ),
            const SizedBox(width: 8),
            _buildBadge(cubit.userAge?.toString() ?? '24', Colors.white60),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          cubit.bio ?? 'Relentless pressure. Aiming for the pros.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          'Role Models: ${cubit.roleModels ?? 'Vasyl Lomachenko'}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [_buildTabItem('OVERVIEW', 0), _buildTabItem('POSTS', 1)],
      ),
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
                color: isSelected ? const Color(0xFF00E5C1) : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 2,
              color: isSelected ? const Color(0xFF00E5C1) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleticProfileSection(AuthCubit cubit) {
    final axes = cubit.dynamicRadarAxes;
    const double chartSize = 200;
    const double labelRadius = 140;

    return _buildSectionWrapper(
      title: 'ATHLETIC PROFILE',
      trailing: _buildSmallButton('Update', Icons.edit_outlined, () {
        // Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateSnapshotScreen()));
      }),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1315),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            SizedBox(
              height: 280,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final centerX = constraints.maxWidth / 2;
                  final centerY = 140.0;

                  return Stack(
                    clipBehavior: Clip.none,
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
                              value: (axes[index]['value'] as num)
                                  .toInt()
                                  .toString(),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PERCENTILES BASED ON YOUR COHORT',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalAnalysisSection(AuthCubit cubit) {
    return _buildSectionWrapper(
      title: 'GOAL ANALYSIS',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1315),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF161B1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.change_history,
                color: Color(0xFF00E5C1),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Punch Power',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cubit.punchPowerScore.toString(),
                        style: const TextStyle(
                          color: Color(0xFF00E5C1),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Foundation ${cubit.punchPowerDetails['foundation']} • Accel ${cubit.punchPowerDetails['accel']} • Transfer ${cubit.punchPowerDetails['transfer']}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TAP FOR DETAILS >',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramHistorySection() {
    return _buildSectionWrapper(
      title: 'PROGRAM HISTORY',
      child: Column(
        children: [
          _buildHistoryItem(
            'Fight Shape 6-Week',
            'OCT 14, 2025',
            'Improved ',
            'Aerobic Endurance',
            ' from 42nd to 68th percentile ',
            '(+26 points).',
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            'Foundation Strength',
            'AUG 02, 2025',
            'Improved ',
            'Strength',
            ' from 74th to 86th percentile ',
            '(+12 points).',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String title,
    String date,
    String text1,
    String highlight1,
    String text2,
    String highlight2,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1315),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.check, color: Colors.white60, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF070B0D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: text1),
                  TextSpan(
                    text: highlight1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: text2),
                  TextSpan(
                    text: highlight2,
                    style: const TextStyle(
                      color: Color(0xFF00E5C1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWrapper({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            if (trailing != null) trailing,
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E5C1).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF00E5C1)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00E5C1),
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
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
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

    // رسم شبكة الرادار (المضلعات)
    for (var i = 1; i <= 4; i++) {
      canvas.drawPath(
        _buildPolygonPath(center, radius * (i / 4), count),
        paint,
      );
    }

    // رسم الخطوط المتقاطعة
    for (int i = 0; i < count; i++) {
      double angle = (i * 360 / count - 90) * pi / 180;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        ),
        paint,
      );
    }

    final dataPaint = Paint()
      ..color = const Color(0xFF00E5C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dataPath = Path();

    // إيجاد أعلى قيمة عشان نظبط سكيل الرسمة لو الباك إيند بيبعت قيم فعلية مش Percentiles
    double maxValue = 100.0;
    if (values.isNotEmpty) {
      double maxInList = values.reduce(max);
      if (maxInList > 100)
        maxValue = maxInList; // لو القيم معدية الـ 100 نتعامل معاها ديناميك
    }

    for (int i = 0; i < count; i++) {
      double angle = (i * 360 / count - 90) * pi / 180;
      double r = ((values[i] / maxValue) * radius) * animationValue;

      Offset p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
      canvas.drawCircle(p, 3, Paint()..color = const Color(0xFF00E5C1));
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
  }

  Path _buildPolygonPath(Offset center, double radius, int sides) {
    final path = Path();
    if (sides == 0) return path;
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
