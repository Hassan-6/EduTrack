import 'package:flutter/material.dart';

class Course {
  final String id;
  final String name;
  final String instructor;
  final Color color;
  final List<Color> gradient;
  final IconData icon;
  final String recentActivity;
  final String timeAgo;
  final int assignmentsDue;
  final int unreadMessages;

  const Course({
    required this.id,
    required this.name,
    required this.instructor,
    required this.color,
    required this.gradient,
    required this.icon,
    required this.recentActivity,
    required this.timeAgo,
    required this.assignmentsDue,
    required this.unreadMessages,
  });
}