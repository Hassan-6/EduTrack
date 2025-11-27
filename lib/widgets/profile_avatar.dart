import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/profile_screen.dart';
import '../utils/theme_provider.dart';

/// Reusable profile avatar widget that displays user's selected profile icon
class ProfileAvatar extends StatelessWidget {
  final int iconIndex;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfileAvatar({
    Key? key,
    required this.iconIndex,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? themeProvider.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (backgroundColor ?? themeProvider.primaryColor).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        ProfileIcons.getIcon(iconIndex),
        size: radius * 0.9,
        color: iconColor ?? themeProvider.primaryColor,
      ),
    );
  }
}
