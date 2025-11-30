// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  todoReminder,
  calendarReminder,
  qnaResponse,
  questionPresented,
  quizScheduled,
  enrollmentRequest,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? scheduledFor;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.scheduledFor,
  });

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.todoReminder,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      scheduledFor: data['scheduledFor'] != null
          ? (data['scheduledFor'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    DateTime? scheduledFor,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }
}
