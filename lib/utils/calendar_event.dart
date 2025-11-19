import 'package:flutter/material.dart';

enum EventType {
  assignment,
  event,
  exam,
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final EventType type;
  final Color color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.color,
  });
}