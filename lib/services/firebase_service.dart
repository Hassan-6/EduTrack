import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Authentication Methods
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User signed up successfully: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User signed in successfully: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  static User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  static Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  // Password Reset
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('Password reset email sent successfully to $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Firestore Methods for Course Enrollment
  static Future<void> enrollInCourse(String userId, Map<String, dynamic> courseData) async {
    try {
      await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .add({
        ...courseData,
        'enrolledAt': FieldValue.serverTimestamp(),
      });
      print('Enrollment request sent successfully');
    } catch (e) {
      print('Error enrolling in course: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserEnrollments(String userId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('enrollments')
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching enrollments: $e');
      rethrow;
    }
  }

  static Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User profile created successfully');
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firebaseFirestore.collection('users').doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).update(updates);
      print('User profile updated successfully');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<void> verifyOTP(String userId, String otp, Map<String, dynamic> courseData) async {
    try {
      // Store OTP verification in Firestore
      await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('otpVerifications')
          .add({
        'otp': otp,
        'courseData': courseData,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      print('OTP verified and stored successfully');
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    }
  }
}
