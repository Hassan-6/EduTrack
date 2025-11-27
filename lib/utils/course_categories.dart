import 'package:flutter/material.dart';

class CourseCategory {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final List<Color> gradient;
  final IconData icon;

  const CourseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.gradient,
    required this.icon,
  });
}

class CourseCategories {
  static const computerScience = CourseCategory(
    id: 'computer_science',
    name: 'Computer Science',
    description: 'Software, Hardware, IT, etc',
    primaryColor: Color(0xFF4E9FEC),
    gradient: [Color(0xFF4E9FEC), Color(0xFF2563EB)],
    icon: Icons.computer,
  );

  static const mathematics = CourseCategory(
    id: 'mathematics',
    name: 'Mathematics',
    description: 'Math topics, Stats, etc',
    primaryColor: Color(0xFF5CD6C0),
    gradient: [Color(0xFF5CD6C0), Color(0xFF16A34A)],
    icon: Icons.calculate,
  );

  static const physicalScience = CourseCategory(
    id: 'physical_science',
    name: 'Physical Science',
    description: 'Chemistry, Physics, Biology, etc',
    primaryColor: Color(0xFFC084FC),
    gradient: [Color(0xFFC084FC), Color(0xFF9333EA)],
    icon: Icons.science,
  );

  static const socialScience = CourseCategory(
    id: 'social_science',
    name: 'Social Science',
    description: 'Sociology, Psychology, etc',
    primaryColor: Color(0xFF818CF8),
    gradient: [Color(0xFF818CF8), Color(0xFF4F46E5)],
    icon: Icons.people,
  );

  static const humanities = CourseCategory(
    id: 'humanities',
    name: 'Humanities',
    description: 'History, Languages, etc',
    primaryColor: Color(0xFFF472B6),
    gradient: [Color(0xFFF472B6), Color(0xFFEC4899)],
    icon: Icons.menu_book,
  );

  static List<CourseCategory> get all => [
        computerScience,
        mathematics,
        physicalScience,
        socialScience,
        humanities,
      ];

  static CourseCategory getById(String id) {
    return all.firstWhere(
      (category) => category.id == id,
      orElse: () => computerScience, // Default to Computer Science
    );
  }

  static CourseCategory? tryGetById(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
