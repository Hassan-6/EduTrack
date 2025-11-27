import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;
  String? _userType; // 'student' or 'instructor'
  String _userName = 'User'; // Cache user's name

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get userType => _userType;
  String get userName => _userName;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication state on app startup
  void _initializeAuth() {
    // Listen to authentication state changes
    FirebaseService.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _loadUserType();
      } else {
        _userType = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Load user type (student or instructor) from Firestore
  Future<void> _loadUserType() async {
    if (_currentUser == null) return;

    try {
      final profile = await FirebaseService.getUserProfile(_currentUser!.uid);
      _userType = profile?['userType'] as String? ?? 'student';
      _userName = profile?['name'] as String? ?? 'User';
      notifyListeners();
    } catch (e) {
      print('Error loading user type: $e');
      _userType = 'student'; // Default to student
      _userName = 'User';
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password, bool isInstructor) async {
    try {
      final userCredential = await FirebaseService.signInWithEmail(email, password);
      
      if (userCredential?.user != null) {
        // Load user profile to check stored role
        await _loadUserType();
        
        final attemptedRole = isInstructor ? 'instructor' : 'student';
        
        // Validate that stored role matches login attempt
        if (_userType != attemptedRole) {
          // Sign out immediately if role doesn't match
          await FirebaseService.signOut();
          return {
            'success': false,
            'error': 'This account is registered as a ${_userType}. Please select the correct account type.'
          };
        }
        
        return {'success': true};
      }
      
      return {'success': false, 'error': 'Login failed'};
    } catch (e) {
      print('Sign in error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(
    String email,
    String password,
    String name,
    bool isInstructor, {
    String? rollNumber,
  }) async {
    try {
      final userCredential = await FirebaseService.signUpWithEmail(email, password);

      if (userCredential?.user != null) {
        // Create user profile in Firestore
        final profileData = {
          'name': name,
          'email': email,
          'userType': isInstructor ? 'instructor' : 'student',
          'isInstructor': isInstructor,
          'profileIconIndex': 0, // Default profile icon
        };
        
        // Add roll number for students if provided
        if (!isInstructor && rollNumber != null && rollNumber.isNotEmpty) {
          profileData['rollNumber'] = rollNumber;
        }
        
        await FirebaseService.createUserProfile(
          userCredential!.user!.uid,
          profileData,
        );
        _userName = name; // Cache the name
      }

      _userType = isInstructor ? 'instructor' : 'student';
      notifyListeners();
      return true;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await FirebaseService.signOut();
      _currentUser = null;
      _userType = null;
      _userName = 'User';
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}
