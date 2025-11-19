import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      height: 77,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context, // PASS CONTEXT HERE
            themeProvider: themeProvider,
            icon: Icons.home,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context: context, // PASS CONTEXT HERE
            themeProvider: themeProvider,
            icon: Icons.checklist,
            activeIcon: Icons.checklist,
            label: 'Tasks',
            index: 1,
            isActive: currentIndex == 1,
          ),
          _buildNavItem(
            context: context, // PASS CONTEXT HERE
            themeProvider: themeProvider,
            icon: Icons.question_answer,
            activeIcon: Icons.question_answer,
            label: 'Q&A',
            index: 2,
            isActive: currentIndex == 2,
          ),
          _buildNavItem(
            context: context, // PASS CONTEXT HERE
            themeProvider: themeProvider,
            icon: Icons.person,
            activeIcon: Icons.person,
            label: 'Profile',
            index: 3,
            isActive: currentIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context, // ADD THIS PARAMETER
    required ThemeProvider themeProvider,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? themeProvider.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? themeProvider.primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}