import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../models/journal_entry.dart';

class NotesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== NOTES METHODS ====================

  /// Create a new note
  static Future<String> createNote({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add({
        'title': title,
        'content': content,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Note created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating note: $e');
      rethrow;
    }
  }

  /// Update an existing note
  static Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .update({
        'title': title,
        'content': content,
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Note updated: $noteId');
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  /// Delete a note
  static Future<void> deleteNote(String noteId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();

      print('Note deleted: $noteId');
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }

  /// Get all notes for current user
  static Future<List<Note>> getNotes() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching notes: $e');
      return [];
    }
  }

  /// Stream of all notes for current user
  static Stream<List<Note>> getNotesStream() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error setting up notes stream: $e');
      return Stream.value([]);
    }
  }

  /// Search notes by title and/or category
  static Future<List<Note>> searchNotes({
    required String query,
    String? category,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      var queryRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes') as Query;

      // If category is specified, filter by category
      if (category != null && category.isNotEmpty && category != 'All') {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      final snapshot = await queryRef.orderBy('updatedAt', descending: true).get();

      // Filter by title search (case-insensitive)
      final results = snapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  /// Get a single note by ID
  static Future<Note?> getNote(String noteId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .get();

      if (!doc.exists) return null;
      return Note.fromFirestore(doc);
    } catch (e) {
      print('Error fetching note: $e');
      return null;
    }
  }

  // ==================== JOURNAL METHODS ====================

  /// Create a new journal entry
  static Future<String> createJournalEntry({
    required String title,
    required String content,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .add({
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isFavorited': false,
      });

      print('Journal entry created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating journal entry: $e');
      rethrow;
    }
  }

  /// Update an existing journal entry
  static Future<void> updateJournalEntry({
    required String entryId,
    required String title,
    required String content,
    bool? isFavorited,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = {
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isFavorited != null) {
        updateData['isFavorited'] = isFavorited;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .update(updateData);

      print('Journal entry updated: $entryId');
    } catch (e) {
      print('Error updating journal entry: $e');
      rethrow;
    }
  }

  /// Delete a journal entry
  static Future<void> deleteJournalEntry(String entryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .delete();

      print('Journal entry deleted: $entryId');
    } catch (e) {
      print('Error deleting journal entry: $e');
      rethrow;
    }
  }

  /// Get all journal entries for current user (sorted by creation date, oldest first)
  static Future<List<JournalEntry>> getJournalEntries() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching journal entries: $e');
      return [];
    }
  }

  /// Stream of journal entries (sorted by creation date, oldest first)
  static Stream<List<JournalEntry>> getJournalEntriesStream() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error setting up journal stream: $e');
      return Stream.value([]);
    }
  }

  /// Toggle favorite status of a journal entry
  static Future<void> toggleJournalFavorite(String entryId, bool currentStatus) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .update({'isFavorited': !currentStatus});

      print('Journal entry favorite status toggled: $entryId');
    } catch (e) {
      print('Error toggling favorite status: $e');
      rethrow;
    }
  }

  /// Get a single journal entry by ID
  static Future<JournalEntry?> getJournalEntry(String entryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .get();

      if (!doc.exists) return null;
      return JournalEntry.fromFirestore(doc);
    } catch (e) {
      print('Error fetching journal entry: $e');
      return null;
    }
  }
}
