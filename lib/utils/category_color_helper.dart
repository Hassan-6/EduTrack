import 'package:flutter/material.dart';

class CategoryColorHelper {
  static const Map<String, Map<String, Color>> categoryColors = {
    'Personal': {
      'background': Color(0xFFF3E8FF),
      'text': Color(0xFF9333EA),
    },
    'Math': {
      'background': Color(0xFFDBEAFE),
      'text': Color(0xFF2563EB),
    },
    'Physics': {
      'background': Color(0xFFDCFCE7),
      'text': Color(0xFF16A34A),
    },
    'Chemistry': {
      'background': Color(0xFFFEF08A),
      'text': Color(0xFFCA8A04),
    },
    'Biology': {
      'background': Color(0xFFDDD6FE),
      'text': Color(0xFF6366F1),
    },
    'History': {
      'background': Color(0xFFFECDD3),
      'text': Color(0xFFC2185B),
    },
    'Literature': {
      'background': Color(0xFFC7D2FE),
      'text': Color(0xFF4F46E5),
    },
    'Art': {
      'background': Color(0xFFE0E7FF),
      'text': Color(0xFF3B82F6),
    },
    'Music': {
      'background': Color(0xFFE9D5FF),
      'text': Color(0xFFA855F7),
    },
    'Computer Science': {
      'background': Color(0xFFDEF7FF),
      'text': Color(0xFF0EA5E9),
    },
  };

  static Color getCategoryBackgroundColor(String category) {
    return categoryColors[category]?['background'] ?? categoryColors['Personal']!['background']!;
  }

  static Color getCategoryTextColor(String category) {
    return categoryColors[category]?['text'] ?? categoryColors['Personal']!['text']!;
  }

  static List<String> getDefaultCategories() {
    return categoryColors.keys.toList();
  }
}
