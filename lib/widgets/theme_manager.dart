// lib/utils/theme_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/app_themes.dart';

class ThemeManager extends StatelessWidget {
  final Widget child;

  const ThemeManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: AppThemes.lightTheme(context), // This now returns ThemeData
          darkTheme: AppThemes.darkTheme(context), // This now returns ThemeData
          themeMode: themeProvider.themeMode,
          home: child,
        );
      },
      child: child,
    );
  }
}