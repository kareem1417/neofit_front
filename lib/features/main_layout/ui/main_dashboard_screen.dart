import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/logic/auth_cubit.dart';
import '../../home/ui/home_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../../programs/ui/programs_screen.dart';
import '../../explore/ui/tabs/explore_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  bool _hasLoadedProfile = false;

  @override
  void initState() {
    super.initState();
    // Eagerly fetch dashboard data so profile/radar chart is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasLoadedProfile = true;
      context.read<AuthCubit>().fetchDashboard();
    });
  }

  List<Widget> get _screens => [
        const HomeScreen(),
        const ExploreScreen(),
        const ProgramsScreen(),
        const Center(
          child: Text('RANK', style: TextStyle(color: Colors.white)),
        ),
        ProfileScreen(
          onGoHome: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      // الـ IndexedStack بيعرض الشاشة اللي متسجلة في الـ _currentIndex
      body: IndexedStack(index: _currentIndex, children: _screens),
      // الـ Navbar الثابت تحت
      bottomNavigationBar: Container(
        height: 65,
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF070B0D),
          border: Border(top: BorderSide(color: Color(0xFF1E262A), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'HOME', _currentIndex == 0, 0),
            _buildNavItem(
              Icons.explore_outlined,
              'EXPLORE',
              _currentIndex == 1,
              1,
            ),
            _buildNavItem(
              Icons.copy_outlined,
              'PROGRAMS',
              _currentIndex == 2,
              2,
            ),
            _buildNavItem(
              Icons.emoji_events_outlined,
              'RANK',
              _currentIndex == 3,
              3,
            ),
            _buildNavItem(
              Icons.person_outline,
              'PROFILE',
              _currentIndex == 4,
              4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        // Fetch dashboard data when Profile tab is opened for the first time
        if (index == 4 && !_hasLoadedProfile) {
          _hasLoadedProfile = true;
          context.read<AuthCubit>().fetchDashboard();
        }
      },
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
