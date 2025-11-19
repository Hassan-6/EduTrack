import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_menu_screen.dart';
import 'to_do_list_screen.dart';
import 'qna_wall_screen.dart';
import 'profile_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  // Define all your main screens here
  final List<Widget> _screens = [
    const MainMenuScreen(), // Home
    const TodoListScreen(), // Tasks
    const QAWallScreen(),   // Q&A
    const ProfileScreen(),  // Profile
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final navItems = [
      {
        'label': 'Home',
        'icon': Icons.home_outlined,
        'route': '/main_menu',
      },
      {
        'label': 'Tasks',
        'icon': Icons.checklist,
        'route': '/todo',
      },
      {
        'label': 'Q&A',
        'icon': Icons.question_answer,
        'route': '/qna',
      },
      {
        'label': 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
      },
    ];

    return Container(
      height: 77,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = _currentIndex == index;
          
          return GestureDetector(
            onTap: () => _onTabTapped(index),
            child: _buildNavItem(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              isActive: isActive,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4F94CD) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? const Color(0xFF4F94CD) : const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}