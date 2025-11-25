class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Personal',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as dynamic).toDate()
          : DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as dynamic).toDate()
          : DateTime(1970),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? completedAt : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
