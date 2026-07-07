// lib/features/main_layout/ui/main_layout_screen.dart

import 'package:flutter/material.dart';
// استدعي الشاشات بتاعتك هنا (اتأكد من المسارات)
import '../../home/ui/home_screen.dart';
import '../../profile/ui/profile_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  // دي الشاشات اللي الـ Navbar هيبدل ما بينها
  final List<Widget> _screens = [
    const HomeScreen(), // اندكس 0
    const Center(
      child: Text('Explore / Training', style: TextStyle(color: Colors.white)),
    ), // اندكس 1 (شاشة مؤقتة)
    const ProfileScreen(), // اندكس 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0D),
      // IndexedStack بيحافظ على حالة كل شاشة عشان لما ترجعلها متعملش ريلود من الأول
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E262A), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F1315),
          selectedItemColor: const Color(0xFF00E5C1),
          unselectedItemColor: Colors.white24,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fitness_center_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.fitness_center),
              ),
              label: 'Training',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
