// lib/theme/design_system.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF4E9FEC);
  static const Color secondary = Color(0xFF5CD6C0);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0x0D000000);
  // Add all colors from your Figma design
}

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle body1 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  // Add all text styles from Figma
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  // Add spacing values from Figma
}