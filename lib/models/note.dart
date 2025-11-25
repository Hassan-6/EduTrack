import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Color? categoryColor;
  final Color? textColor;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.categoryColor,
    this.textColor,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'Personal',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    Color? categoryColor,
    Color? textColor,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryColor: categoryColor ?? this.categoryColor,
      textColor: textColor ?? this.textColor,
    );
  }
}
