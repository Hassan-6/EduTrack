// lib/themes/app_themes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class AppThemes {
  static ThemeData lightTheme(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: themeProvider.primaryColor,
      colorScheme: ColorScheme.light(
        primary: themeProvider.primaryColor,
        secondary: themeProvider.secondaryColor,
        background: const Color(0xFFF8FAFC),
        surface: Colors.white,
        onBackground: const Color(0xFF1F2937),
        onSurface: const Color(0xFF1F2937),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E1E1E),
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(color: const Color(0xFF1F2937)),
        displayMedium: GoogleFonts.inter(color: const Color(0xFF1F2937)),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFF1F2937)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF374151)),
        bodySmall: GoogleFonts.inter(color: const Color(0xFF6B7280)),
      ),
      dividerColor: const Color(0xFFF3F4F6),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: themeProvider.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: themeProvider.primaryColor,
        secondary: themeProvider.secondaryColor,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(color: Colors.white),
        displayMedium: GoogleFonts.inter(color: Colors.white),
        bodyLarge: GoogleFonts.inter(color: Colors.white),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFFE5E7EB)),
        bodySmall: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
      ),
      dividerColor: const Color(0xFF374151),
      useMaterial3: true,
    );
  }
}