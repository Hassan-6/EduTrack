import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new task
  static Future<String> createTask({
    required String title,
    required String description,
    required String category,
    required DateTime dueDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('Creating task for user: $userId');
      print('Task details - Title: $title, Category: $category, DueDate: $dueDate');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add({
        'title': title,
        'description': description,
        'category': category,
        'dueDate': dueDate,
        'isCompleted': false,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Task created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating task: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  /// Get all pending tasks sorted by due date
  static Future<List<Task>> getPendingTasks() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('isCompleted', isEqualTo: false)
          .get();

      final tasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort by dueDate ascending
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    } catch (e) {
      print('Error getting pending tasks: $e');
      rethrow;
    }
  }

  /// Get completed tasks from last 7 days
  static Future<List<Task>> getCompletedTasks() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Fetch all completed tasks (no orderBy to avoid composite index requirement)
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('isCompleted', isEqualTo: true)
          .get();

      // Filter and sort in code
      final tasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc.data(), doc.id))
          .where((task) => task.completedAt.isAfter(sevenDaysAgo))
          .toList();
      
      // Sort by completedAt descending
      tasks.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return tasks;
    } catch (e) {
      print('Error getting completed tasks: $e');
      rethrow;
    }
  }

  /// Search tasks by title or description
  static Future<List<Task>> searchTasks({
    required String query,
    String? category,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      QuerySnapshot snapshot;

      if (category != null && category != 'All') {
        snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .where('category', isEqualTo: category)
            .get();
      } else {
        snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .get();
      }

      final allTasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // If query is empty, return all tasks (possibly filtered by category)
      if (query.isEmpty) {
        return allTasks;
      }

      // Otherwise filter by search query
      return allTasks
          .where((task) =>
              task.title.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching tasks: $e');
      rethrow;
    }
  }

  /// Mark task as completed
  static Future<void> completeTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing task: $e');
      rethrow;
    }
  }

  /// Mark task as incomplete (re-enter to pending list)
  static Future<void> uncompleteTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'isCompleted': false,
        'completedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error uncompleting task: $e');
      rethrow;
    }
  }

  /// Update task details
  static Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String category,
    required DateTime dueDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'title': title,
        'description': description,
        'category': category,
        'dueDate': dueDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  /// Delete task
  static Future<void> deleteTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  /// Get upcoming tasks for main menu (next 3 tasks)
  static Future<List<Task>> getUpcomingTasks({int limit = 3}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('isCompleted', isEqualTo: false)
          .get();

      final tasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort by dueDate ascending and take top limit
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks.take(limit).toList();
    } catch (e) {
      print('Error getting upcoming tasks: $e');
      rethrow;
    }
  }
}
