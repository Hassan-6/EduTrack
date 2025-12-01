import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  static final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Helper method to get current user's role
  static Future<String?> getCurrentUserRole() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;
      
      final userDoc = await _firebaseFirestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) return null;
      
      final data = userDoc.data();
      return data?['userType'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Helper method to validate user role
  static Future<bool> validateUserRole(String requiredRole) async {
    final userRole = await getCurrentUserRole();
    return userRole == requiredRole;
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
      // Use set with merge:true to create document if it doesn't exist
      await _firebaseFirestore.collection('users').doc(userId).set(
        updates,
        SetOptions(merge: true),
      );
      print('User profile updated successfully');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<void> deleteUserData(String userId) async {
    try {
      // Get user document first to retrieve name and other info
      final userDoc = await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('User document not found');
        return;
      }

      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Deleted User';

      // Mark user as deleted instead of deleting the document
      await _firebaseFirestore.collection('users').doc(userId).update({
        'name': 'Deleted User',
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'originalName': userName,
        // Keep other fields for data integrity but mark as deleted
      });
      
      // Delete user's tasks
      final tasksQuery = await _firebaseFirestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in tasksQuery.docs) {
        await doc.reference.delete();
      }
      
      // Mark user's Q&A posts as from deleted user instead of deleting
      final qnaQuery = await _firebaseFirestore
          .collection('qna')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in qnaQuery.docs) {
        await doc.reference.update({
          'userName': 'Deleted User',
          'userDeleted': true,
        });
      }
      
      // Remove user from course enrollments
      final coursesQuery = await _firebaseFirestore
          .collection('courses')
          .where('enrolledStudents', arrayContains: userId)
          .get();
      
      for (var doc in coursesQuery.docs) {
        await doc.reference.update({
          'enrolledStudents': FieldValue.arrayRemove([userId]),
        });
      }
      
      print('User data marked as deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
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

  // Course Management Methods
  static Future<String> createCourse(Map<String, dynamic> courseData) async {
    try {
      // Validate user is an instructor
      final isInstructor = await validateUserRole('instructor');
      if (!isInstructor) {
        throw Exception('Only instructors can create courses');
      }

      DocumentReference docRef = await _firebaseFirestore.collection('courses').add({
        ...courseData,
        'createdAt': FieldValue.serverTimestamp(),
        'enrolledStudents': [],
        'pendingRequests': [],
        'isActive': true,
        'isArchived': false,
      });
      print('Course created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating course: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getInstructorCourses(String instructorId) async {
    try {
      print('Fetching courses for instructorId: $instructorId');
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .where('instructorId', isEqualTo: instructorId)
          .get();
      
      // Filter out archived courses (treat missing isArchived field as false)
      final courses = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((course) => course['isArchived'] != true)
          .toList();
      
      print('Found ${courses.length} active courses');
      return courses;
    } catch (e) {
      print('Error fetching instructor courses: $e');
      rethrow;
    }
  }

  // Get archived courses for instructor
  static Future<List<Map<String, dynamic>>> getInstructorArchivedCourses(String instructorId) async {
    try {
      print('Fetching archived courses for instructorId: $instructorId');
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .where('instructorId', isEqualTo: instructorId)
          .get();
      
      // Filter for archived courses only
      final archivedCourses = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((course) => course['isArchived'] == true)
          .toList();
      
      print('Found ${archivedCourses.length} archived courses');
      return archivedCourses;
    } catch (e) {
      print('Error fetching instructor archived courses: $e');
      rethrow;
    }
  }

  /// Get all courses where a student is enrolled (checks enrolledStudents array)
  static Future<List<String>> getAllCoursesWhereStudentEnrolled(String studentId) async {
    try {
      print('Searching for courses where student $studentId is enrolled');
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .where('enrolledStudents', arrayContains: studentId)
          .get();
      
      List<String> courseIds = snapshot.docs.map((doc) => doc.id).toList();
      print('Found ${courseIds.length} courses: $courseIds');
      return courseIds;
    } catch (e) {
      print('Error fetching student courses: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getCourseByOTP(String otp) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .where('otp', isEqualTo: otp)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      print('Error fetching course by OTP: $e');
      rethrow;
    }
  }

  static Future<void> requestCourseEnrollment(
    String courseId,
    String studentId,
    Map<String, dynamic> studentData,
  ) async {
    try {
      // Validate user is a student
      final isStudent = await validateUserRole('student');
      if (!isStudent) {
        throw Exception('Only students can request course enrollment');
      }

      final requestRef = _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('enrollmentRequests')
          .doc(studentId);

      // Check if request already exists
      final existingRequest = await requestRef.get();
      
      if (existingRequest.exists) {
        final existingData = existingRequest.data() as Map<String, dynamic>;
        final status = existingData['status'];
        
        // If already approved, don't allow re-request
        if (status == 'approved') {
          throw Exception('You are already enrolled in this course');
        }
        
        // If rejected or removed, update to pending
        if (status == 'rejected' || status == 'removed') {
          await requestRef.update({
            ...studentData,
            'requestedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
          print('Enrollment re-request submitted successfully');
          return;
        }
        
        // If already pending, don't do anything
        if (status == 'pending') {
          throw Exception('You already have a pending enrollment request for this course');
        }
      }
      
      // Create new request if doesn't exist
      await requestRef.set({
        ...studentData,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      print('Enrollment request submitted successfully');
    } catch (e) {
      print('Error requesting enrollment: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getEnrollmentRequests(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('enrollmentRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['studentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching enrollment requests: $e');
      rethrow;
    }
  }

  static Future<void> approveEnrollmentRequest(
    String courseId,
    String studentId,
  ) async {
    try {
      print('Approving enrollment for student: $studentId in course: $courseId');
      
      // Update request status
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('enrollmentRequests')
          .doc(studentId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      print('Updated enrollment request status to approved');

      // Add student to enrolled students in course document
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .update({
        'enrolledStudents': FieldValue.arrayUnion([studentId]),
      });
      print('Added student to enrolledStudents array in course');

      // Add course to student's enrolled courses
      await _firebaseFirestore
          .collection('users')
          .doc(studentId)
          .set({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      }, SetOptions(merge: true));
      print('Added course to student enrolledCourses');

      print('Enrollment request approved successfully');
    } catch (e) {
      print('Error approving enrollment: $e');
      rethrow;
    }
  }

  static Future<void> rejectEnrollmentRequest(
    String courseId,
    String studentId,
  ) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('enrollmentRequests')
          .doc(studentId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      print('Enrollment request rejected successfully');
    } catch (e) {
      print('Error rejecting enrollment: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentEnrolledCourses(String studentId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .where('enrolledStudents', arrayContains: studentId)
          .get();
      
      // Filter out archived courses (treat missing isArchived field as false)
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((course) => course['isArchived'] != true)
          .toList();
    } catch (e) {
      print('Error fetching student courses: $e');
      rethrow;
    }
  }

  // Get archived courses for student
  static Future<List<Map<String, dynamic>>> getStudentArchivedCourses(String studentId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .where('enrolledStudents', arrayContains: studentId)
          .get();
      
      // Filter for archived courses only
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((course) => course['isArchived'] == true)
          .toList();
    } catch (e) {
      print('Error fetching student archived courses: $e');
      rethrow;
    }
  }

  // Update course details
  static Future<void> updateCourse(
    String courseId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      // Validate user is an instructor
      final isInstructor = await validateUserRole('instructor');
      if (!isInstructor) {
        throw Exception('Only instructors can update courses');
      }

      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .update({
        ...updatedData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Course updated successfully');
    } catch (e) {
      print('Error updating course: $e');
      rethrow;
    }
  }

  // Archive course (End Course)
  static Future<void> archiveCourse(String courseId) async {
    try {
      // Validate user is an instructor
      final isInstructor = await validateUserRole('instructor');
      if (!isInstructor) {
        throw Exception('Only instructors can archive courses');
      }

      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
      print('Course archived successfully');
    } catch (e) {
      print('Error archiving course: $e');
      rethrow;
    }
  }

  // Delete course
  static Future<void> deleteCourse(String courseId) async {
    try {
      // Validate user is an instructor
      final isInstructor = await validateUserRole('instructor');
      if (!isInstructor) {
        throw Exception('Only instructors can delete courses');
      }

      // Delete all enrollment requests first
      QuerySnapshot requests = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('enrollmentRequests')
          .get();
      
      for (var doc in requests.docs) {
        await doc.reference.delete();
      }

      // Delete the course
      await _firebaseFirestore.collection('courses').doc(courseId).delete();
      print('Course deleted successfully');
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  // Get enrolled students for a course
  static Future<List<Map<String, dynamic>>> getEnrolledStudents(String courseId) async {
    try {
      print('Getting enrolled students for course: $courseId');
      
      DocumentSnapshot courseDoc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .get();
      
      if (!courseDoc.exists) {
        print('Course document not found');
        return [];
      }

      final courseData = courseDoc.data() as Map<String, dynamic>;
      print('Course data fields: ${courseData.keys.toList()}');
      
      final enrolledStudentIds = List<String>.from(courseData['enrolledStudents'] ?? []);
      print('Found ${enrolledStudentIds.length} enrolled student IDs: $enrolledStudentIds');
      
      if (enrolledStudentIds.isEmpty) {
        print('No enrolled students in course');
        return [];
      }

      List<Map<String, dynamic>> students = [];
      for (String studentId in enrolledStudentIds) {
        try {
          print('Fetching student: $studentId');
          DocumentSnapshot userDoc = await _firebaseFirestore
              .collection('users')
              .doc(studentId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            userData['id'] = studentId;
            
            // Get enrollment date from requests
            DocumentSnapshot requestDoc = await _firebaseFirestore
                .collection('courses')
                .doc(courseId)
                .collection('enrollmentRequests')
                .doc(studentId)
                .get();
            
            if (requestDoc.exists) {
              final requestData = requestDoc.data() as Map<String, dynamic>;
              userData['enrolledAt'] = requestData['approvedAt'];
            }
            
            students.add(userData);
            print('Added student: ${userData['name']}');
          } else {
            print('Warning: User document not found for student: $studentId');
          }
        } catch (e) {
          print('Error fetching student $studentId: $e');
        }
      }
      
      print('Returning ${students.length} enrolled students');
      return students;
    } catch (e) {
      print('Error fetching enrolled students: $e');
      rethrow;
    }
  }

  /// Fallback: query users collection for users who have this course in their `enrolledCourses` field
  static Future<List<Map<String, dynamic>>> getUsersEnrolledInCourse(String courseId) async {
    try {
      print('Fallback: querying users with enrolledCourses arrayContains $courseId');
      QuerySnapshot usersSnapshot = await _firebaseFirestore
          .collection('users')
          .where('enrolledCourses', arrayContains: courseId)
          .get();

      List<Map<String, dynamic>> users = [];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        users.add(data);
      }
      print('Found ${users.length} users via fallback query');
      return users;
    } catch (e) {
      print('Error in fallback getUsersEnrolledInCourse: $e');
      return [];
    }
  }

  // Remove student from course
  static Future<void> removeStudentFromCourse(
    String courseId,
    String studentId,
  ) async {
    try {
      // Remove from enrolledStudents array in course
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .update({
        'enrolledStudents': FieldValue.arrayRemove([studentId]),
      });

      // Remove course from student's enrolled courses
      await _firebaseFirestore
          .collection('users')
          .doc(studentId)
          .update({
        'enrolledCourses': FieldValue.arrayRemove([courseId]),
      });

      // Update enrollment request status
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('enrollmentRequests')
          .doc(studentId)
          .update({
        'status': 'removed',
        'removedAt': FieldValue.serverTimestamp(),
      });

      print('Student removed from course successfully');
    } catch (e) {
      print('Error removing student: $e');
      rethrow;
    }
  }

  // Get course by ID
  static Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('Error fetching course: $e');
      rethrow;
    }
  }

  // Get pop-up questions for a specific course
  static Future<List<Map<String, dynamic>>> getCoursePopupQuestions(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('popupQuestions')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching popup questions: $e');
      return [];
    }
  }

  // Get quizzes for a specific course
  static Future<List<Map<String, dynamic>>> getCourseQuizzes(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }

  // ==================== POPUP QUESTIONS & QUIZZES METHODS ====================

  /// Create a popup question for a course
  static Future<String> createPopupQuestion({
    required String courseId,
    required String instructorId,
    required String question,
    required String questionType, // 'MCQ' or 'Short Question'
    required List<String> options,
    int? correctAnswerIndex, // Optional: null if no correct answer
  }) async {
    try {
      final questionData = {
        'question': question,
        'questionType': questionType,
        'options': options,
        'instructorId': instructorId,
        'courseId': courseId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'responses': {}, // Map of studentId -> response data
      };
      
      // Only add correctAnswerIndex if provided
      if (correctAnswerIndex != null) {
        questionData['correctAnswerIndex'] = correctAnswerIndex;
      }
      
      final docRef = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('popupQuestions')
          .add(questionData);
      
      print('Popup question created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating popup question: $e');
      rethrow;
    }
  }

  /// Submit a student response to a popup question
  static Future<void> submitPopupQuestionResponse({
    required String courseId,
    required String questionId,
    required String studentId,
    required dynamic response, // int for MCQ, String for Short Question
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('popupQuestions')
          .doc(questionId)
          .update({
        'responses.$studentId': {
          'response': response,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });
      
      print('Response submitted for question $questionId by student $studentId');
    } catch (e) {
      print('Error submitting response: $e');
      rethrow;
    }
  }

  /// Deactivate a popup question (end the session)
  static Future<void> deactivatePopupQuestion({
    required String courseId,
    required String questionId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('popupQuestions')
          .doc(questionId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
      
      print('Popup question $questionId deactivated');
    } catch (e) {
      print('Error deactivating question: $e');
      rethrow;
    }
  }

  /// Get popup question results with student responses
  static Future<Map<String, dynamic>> getPopupQuestionResults({
    required String courseId,
    required String questionId,
  }) async {
    try {
      final doc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('popupQuestions')
          .doc(questionId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Question not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Get student profiles for responses
      final responses = data['responses'] as Map<String, dynamic>? ?? {};
      Map<String, dynamic> enrichedResponses = {};
      
      for (var entry in responses.entries) {
        final studentId = entry.key;
        final responseData = entry.value as Map<String, dynamic>;
        final studentProfile = await getUserProfile(studentId);
        
        enrichedResponses[studentId] = {
          ...responseData,
          'studentName': studentProfile?['name'] ?? 'Unknown',
          'studentRollNumber': studentProfile?['rollNumber'] ?? 'N/A',
        };
      }
      
      data['enrichedResponses'] = enrichedResponses;
      
      return data;
    } catch (e) {
      print('Error getting question results: $e');
      rethrow;
    }
  }

  /// Create a quiz for a course
  static Future<String> createQuiz({
    required String courseId,
    required String instructorId,
    required String title,
    required DateTime scheduledDate,
    required int durationMinutes,
    required List<Map<String, dynamic>> questions, // List of question objects
  }) async {
    try {
      final docRef = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .add({
        'title': title,
        'instructorId': instructorId,
        'courseId': courseId,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'durationMinutes': durationMinutes,
        'questions': questions,
        'isActive': false, // Start inactive, will activate at scheduled time
        'createdAt': FieldValue.serverTimestamp(),
        'submissions': {}, // Map of studentId -> submission data
      });
      
      print('Quiz created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating quiz: $e');
      rethrow;
    }
  }

  /// Submit a student quiz submission
  static Future<void> submitQuizResponse({
    required String courseId,
    required String quizId,
    required String studentId,
    required Map<String, dynamic> answers, // Map of questionIndex -> answer
    required int score,
    required int totalQuestions,
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .update({
        'submissions.$studentId': {
          'answers': answers,
          'score': score,
          'totalQuestions': totalQuestions,
          'percentage': (score / totalQuestions * 100).round(),
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });
      
      print('Quiz submission recorded for student $studentId');
    } catch (e) {
      print('Error submitting quiz: $e');
      rethrow;
    }
  }

  /// Deactivate a quiz (end the quiz session)
  static Future<void> deactivateQuiz({
    required String courseId,
    required String quizId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .update({
        'isActive': false,
        'manuallyEnded': true, // Mark as manually ended by instructor
        'endedAt': FieldValue.serverTimestamp(),
      });
      
      print('Quiz $quizId deactivated manually');
    } catch (e) {
      print('Error deactivating quiz: $e');
      rethrow;
    }
  }

  /// Check and update quiz status based on schedule and duration
  static Future<void> updateQuizStatus({
    required String courseId,
    required String quizId,
    required Map<String, dynamic> quizData,
  }) async {
    try {
      final scheduledDate = (quizData['scheduledDate'] as Timestamp?)?.toDate();
      final durationMinutes = quizData['durationMinutes'] as int? ?? 60;
      final isCurrentlyActive = quizData['isActive'] as bool? ?? false;
      final manuallyEnded = quizData['manuallyEnded'] as bool? ?? false;
      
      if (scheduledDate == null) {
        print('Quiz $quizId has no scheduled date');
        return;
      }
      
      // Don't reactivate if quiz was manually ended by instructor
      if (manuallyEnded) {
        print('Quiz $quizId was manually ended - skipping automatic status update');
        return;
      }
      
      final now = DateTime.now();
      final endTime = scheduledDate.add(Duration(minutes: durationMinutes));
      
      // Check if quiz should be active (current time is between start and end)
      final shouldBeActive = now.isAfter(scheduledDate) && now.isBefore(endTime);
      
      // Update status if it differs from what it should be
      if (shouldBeActive && !isCurrentlyActive) {
        // Activate the quiz
        await _firebaseFirestore
            .collection('courses')
            .doc(courseId)
            .collection('quizzes')
            .doc(quizId)
            .update({
          'isActive': true,
          'activatedAt': FieldValue.serverTimestamp(),
        });
        print('Quiz $quizId activated at scheduled time');
      } else if (!shouldBeActive && isCurrentlyActive && now.isAfter(endTime)) {
        // Deactivate the quiz (duration has passed)
        await _firebaseFirestore
            .collection('courses')
            .doc(courseId)
            .collection('quizzes')
            .doc(quizId)
            .update({
          'isActive': false,
          'endedAt': FieldValue.serverTimestamp(),
        });
        print('Quiz $quizId automatically deactivated after duration');
      }
    } catch (e) {
      print('Error updating quiz status: $e');
    }
  }

  /// Get quiz results with all student submissions
  static Future<Map<String, dynamic>> getQuizResults({
    required String courseId,
    required String quizId,
  }) async {
    try {
      final doc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Quiz not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Get student profiles for submissions
      final submissions = data['submissions'] as Map<String, dynamic>? ?? {};
      Map<String, dynamic> enrichedSubmissions = {};
      
      for (var entry in submissions.entries) {
        final studentId = entry.key;
        final submissionData = entry.value as Map<String, dynamic>;
        final studentProfile = await getUserProfile(studentId);
        
        enrichedSubmissions[studentId] = {
          ...submissionData,
          'studentName': studentProfile?['name'] ?? 'Unknown',
          'studentRollNumber': studentProfile?['rollNumber'] ?? 'N/A',
        };
      }
      
      data['enrichedSubmissions'] = enrichedSubmissions;
      
      return data;
    } catch (e) {
      print('Error getting quiz results: $e');
      rethrow;
    }
  }

  /// Update grade for a short answer question in a quiz submission
  static Future<void> updateQuizShortQuestionGrade({
    required String courseId,
    required String quizId,
    required String studentId,
    required int questionIndex,
    required bool isCorrect,
  }) async {
    try {
      // Get current submission
      final quizDoc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .get();
      
      if (!quizDoc.exists) {
        throw Exception('Quiz not found');
      }
      
      final quizData = quizDoc.data() as Map<String, dynamic>;
      final submissions = quizData['submissions'] as Map<String, dynamic>? ?? {};
      final submission = submissions[studentId] as Map<String, dynamic>? ?? {};
      
      // Get current short question grades
      final shortQuestionGrades = Map<String, dynamic>.from(
        submission['shortQuestionGrades'] as Map<String, dynamic>? ?? {},
      );
      
      // Update the grade for this question
      shortQuestionGrades[questionIndex.toString()] = isCorrect;
      
      // Recalculate score
      final questions = quizData['questions'] as List<dynamic>? ?? [];
      final answers = submission['answers'] as Map<String, dynamic>? ?? {};
      int score = 0;
      
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        final questionType = question['questionType'] as String? ?? 'MCQ';
        
        if (questionType == 'MCQ') {
          // Auto-grade MCQ
          final correctIndex = question['correctAnswerIndex'] as int?;
          final answer = answers[i.toString()];
          if (correctIndex != null && answer == correctIndex) {
            score++;
          }
        } else {
          // Check if short question is graded
          final gradeKey = i.toString();
          if (shortQuestionGrades.containsKey(gradeKey) && shortQuestionGrades[gradeKey] == true) {
            score++;
          }
        }
      }
      
      // Update submission with new grade and recalculated score
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .update({
        'submissions.$studentId.shortQuestionGrades': shortQuestionGrades,
        'submissions.$studentId.score': score,
        'submissions.$studentId.percentage': (score / questions.length * 100).round(),
      });
      
      print('Updated short question grade for student $studentId, question $questionIndex');
    } catch (e) {
      print('Error updating short question grade: $e');
      rethrow;
    }
  }

  /// Get all popup questions for a course (including inactive ones for history)
  static Future<List<Map<String, dynamic>>> getPopupQuestionsHistory(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('popupQuestions')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching popup questions history: $e');
      return [];
    }
  }

  /// Get all quizzes for a course (including inactive ones for history)
  static Future<List<Map<String, dynamic>>> getQuizzesHistory(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching quizzes history: $e');
      return [];
    }
  }

  // Attendance Management Methods
  
  /// Create an attendance session for a course with OTP
  static Future<String> createAttendanceSession({
    required String courseId,
    required String otp,
    required int durationMinutes,
  }) async {
    try {
      print('Creating attendance session for course: $courseId');
      final docRef = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .add({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: durationMinutes)),
        ),
        'isActive': true,
        'verifiedStudents': [],
        'studentPhotos': {}, // Initialize empty map for photos
        'studentLocations': {}, // Initialize empty map for locations
      });
      
      print('Attendance session created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating attendance session: $e');
      rethrow;
    }
  }

  /// Verify student attendance with OTP
  static Future<bool> verifyAttendance({
    required String courseId,
    required String studentId,
    required String otp,
    String? photoURL,
  }) async {
    try {
      print('=== VERIFY ATTENDANCE START ===');
      print('Course ID: $courseId');
      print('Student ID: $studentId');
      print('OTP entered: $otp');
      print('Photo URL: $photoURL');
      
      // Find active session with matching OTP
      QuerySnapshot sessions = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .where('otp', isEqualTo: otp)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      print('Found ${sessions.docs.length} sessions');
      
      if (sessions.docs.isEmpty) {
        print('ERROR: No active session found with OTP: $otp');
        return false;
      }

      final sessionDoc = sessions.docs.first;
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      
      print('Session found: ${sessionDoc.id}');
      print('Session OTP: ${sessionData['otp']}');
      print('Session isActive: ${sessionData['isActive']}');
      
      // Check if session has expired
      final expiresAt = (sessionData['expiresAt'] as Timestamp).toDate();
      final now = DateTime.now();
      print('Current time: $now');
      print('Expires at: $expiresAt');
      print('Time remaining: ${expiresAt.difference(now).inSeconds} seconds');
      
      if (now.isAfter(expiresAt)) {
        print('ERROR: Session has expired');
        return false;
      }

      // Add student to verified list with photo URL
      await sessionDoc.reference.update({
        'verifiedStudents': FieldValue.arrayUnion([studentId]),
        'studentPhotos.$studentId': photoURL ?? '', // Store photo URL mapped to student ID
      });
      
      print('SUCCESS: Attendance verified for student: $studentId');
      print('=== VERIFY ATTENDANCE END ===');
      return true;
    } catch (e) {
      print('ERROR in verifyAttendance: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Upload attendance photo to Firebase Storage
  static Future<String?> uploadAttendancePhoto({
    required String studentId,
    required String photoPath,
  }) async {
    try {
      final file = File(photoPath);
      final fileName = 'attendance_${studentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _firebaseStorage.ref().child('attendance_photos/$fileName');
      
      print('Uploading photo to: attendance_photos/$fileName');
      await ref.putFile(file);
      
      final downloadURL = await ref.getDownloadURL();
      print('Photo uploaded successfully: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error uploading attendance photo: $e');
      return null;
    }
  }

  /// Update attendance session with location data only (no photo)
  static Future<void> updateAttendanceLocation({
    required String courseId,
    required String studentId,
    required String otp,
    required Map<String, dynamic> locationData,
  }) async {
    try {
      print('=== UPDATE ATTENDANCE LOCATION START ===');
      print('Course ID: $courseId');
      print('Student ID: $studentId');
      print('OTP: $otp');
      print('Location Data: $locationData');
      
      // Find the session with matching OTP
      QuerySnapshot sessions = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .where('otp', isEqualTo: otp)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      print('Found ${sessions.docs.length} sessions to update');
      
      if (sessions.docs.isEmpty) {
        print('ERROR: No active session found to update location');
        return;
      }

      final sessionDoc = sessions.docs.first;
      print('Updating session: ${sessionDoc.id}');
      
      // Update location data for this student
      Map<String, dynamic> updateData = {
        'studentLocations.$studentId': locationData,
      };
      
      print('Update data to be saved: $updateData');
      
      await sessionDoc.reference.update(updateData);
      
      print('SUCCESS: Attendance location updated for student: $studentId');
      print('=== UPDATE ATTENDANCE LOCATION END ===');
    } catch (e) {
      print('ERROR updating attendance location: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Update attendance session with photo URL and location data
  static Future<void> updateAttendancePhoto({
    required String courseId,
    required String studentId,
    required String otp,
    required String photoURL,
    Map<String, dynamic>? locationData,
  }) async {
    try {
      print('=== UPDATE ATTENDANCE PHOTO START ===');
      print('Course ID: $courseId');
      print('Student ID: $studentId');
      print('OTP: $otp');
      print('Photo URL: $photoURL');
      
      // Find the session with matching OTP
      QuerySnapshot sessions = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .where('otp', isEqualTo: otp)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      print('Found ${sessions.docs.length} sessions to update');
      
      if (sessions.docs.isEmpty) {
        print('ERROR: No active session found to update photo');
        return;
      }

      final sessionDoc = sessions.docs.first;
      print('Updating session: ${sessionDoc.id}');
      
      // Update the photo URL and location data for this student
      Map<String, dynamic> updateData = {
        'studentPhotos.$studentId': photoURL,
      };
      
      // Add location data if provided
      if (locationData != null) {
        print('Adding location data for student: $studentId');
        updateData['studentLocations.$studentId'] = locationData;
      }
      
      await sessionDoc.reference.update(updateData);
      
      print('SUCCESS: Attendance photo and location updated for student: $studentId');
      print('=== UPDATE ATTENDANCE PHOTO END ===');
    } catch (e) {
      print('ERROR updating attendance photo: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Close an attendance session
  static Future<void> closeAttendanceSession({
    required String courseId,
    required String sessionId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .doc(sessionId)
          .update({
        'isActive': false,
        'closedAt': FieldValue.serverTimestamp(),
      });
      
      print('Attendance session closed: $sessionId');
    } catch (e) {
      print('Error closing attendance session: $e');
      rethrow;
    }
  }

  /// Delete an attendance session
  static Future<void> deleteAttendanceSession({
    required String courseId,
    required String sessionId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .doc(sessionId)
          .delete();
      
      print('Attendance session deleted: $sessionId');
    } catch (e) {
      print('Error deleting attendance session: $e');
      rethrow;
    }
  }

  /// Get active attendance session for a course
  static Future<Map<String, dynamic>?> getActiveAttendanceSession(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      print('Error fetching active attendance session: $e');
      return null;
    }
  }

  /// Get attendance history for a course
  static Future<List<Map<String, dynamic>>> getCourseAttendanceHistory(String courseId) async {
    try {
      print('Fetching attendance history for course: $courseId');
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching attendance history: $e');
      return [];
    }
  }

  /// Get real-time attendance session stream
  static Stream<DocumentSnapshot> getAttendanceSessionStream({
    required String courseId,
    required String sessionId,
  }) {
    return _firebaseFirestore
        .collection('courses')
        .doc(courseId)
        .collection('attendance')
        .doc(sessionId)
        .snapshots();
  }

  /// Get total enrolled students count for a course
  static Future<int> getCourseEnrolledStudentsCount(String courseId) async {
    try {
      DocumentSnapshot courseDoc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .get();
      
      if (!courseDoc.exists) {
        return 0;
      }

      final courseData = courseDoc.data() as Map<String, dynamic>;
      final enrolledStudents = courseData['enrolledStudents'] as List<dynamic>?;
      return enrolledStudents?.length ?? 0;
    } catch (e) {
      print('Error getting enrolled students count: $e');
      return 0;
    }
  }

  // ==================== Q&A WALL METHODS ====================

  /// Get all questions from user's enrolled or teaching courses
  static Future<List<Map<String, dynamic>>> getQuestionsForUser(String userId) async {
    try {
      print('Fetching questions for user: $userId');
      
      // Get user profile to determine if student or instructor
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        print('User profile not found');
        return [];
      }

      final userType = userProfile['userType'];
      List<String> courseIds = [];

      if (userType == 'student') {
        // Get student's enrolled courses
        final enrolledCourses = userProfile['enrolledCourses'] as List<dynamic>? ?? [];
        courseIds = enrolledCourses.map((c) => c.toString()).toList();
        print('Student enrolled in ${courseIds.length} courses');
      } else if (userType == 'instructor') {
        // Get instructor's teaching courses
        final instructorCourses = await getInstructorCourses(userId);
        courseIds = instructorCourses.map((c) => c['id'].toString()).toList();
        print('Instructor teaching ${courseIds.length} courses');
      }

      if (courseIds.isEmpty) {
        print('No courses found for user');
        return [];
      }

      // Fetch questions from all courses
      List<Map<String, dynamic>> allQuestions = [];
      for (String courseId in courseIds) {
        try {
          final courseQuestions = await getCourseQuestions(courseId);
          allQuestions.addAll(courseQuestions);
        } catch (e) {
          print('Error fetching questions for course $courseId: $e');
        }
      }

      // Sort by timestamp (newest first)
      allQuestions.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      print('Fetched ${allQuestions.length} total questions');
      return allQuestions;
    } catch (e) {
      print('Error getting questions for user: $e');
      return [];
    }
  }

  /// Get questions for a specific course
  static Future<List<Map<String, dynamic>>> getCourseQuestions(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> questions = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['courseId'] = courseId;
        
        // Get course name
        final courseDoc = await _firebaseFirestore.collection('courses').doc(courseId).get();
        data['courseName'] = courseDoc.data()?['title'] ?? 'Unknown Course';
        
        // Get author profile
        final authorId = data['authorId'];
        final authorProfile = await getUserProfile(authorId);
        data['authorProfile'] = authorProfile;
        
        // Get replies count
        final repliesSnapshot = await doc.reference.collection('replies').get();
        data['repliesCount'] = repliesSnapshot.docs.length;
        
        questions.add(data);
      }

      return questions;
    } catch (e) {
      print('Error getting course questions: $e');
      return [];
    }
  }

  /// Create a new question
  static Future<String?> createQuestion({
    required String courseId,
    required String authorId,
    required String title,
    required String content,
  }) async {
    try {
      print('Creating question in course: $courseId');
      
      final docRef = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .add({
        'authorId': authorId,
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Question created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating question: $e');
      return null;
    }
  }

  /// Get question details with replies
  static Future<Map<String, dynamic>?> getQuestionDetails({
    required String courseId,
    required String questionId,
  }) async {
    try {
      final questionDoc = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .get();

      if (!questionDoc.exists) {
        return null;
      }

      final questionData = questionDoc.data() as Map<String, dynamic>;
      questionData['id'] = questionDoc.id;
      questionData['courseId'] = courseId;

      // Get course name
      final courseDoc = await _firebaseFirestore.collection('courses').doc(courseId).get();
      questionData['courseName'] = courseDoc.data()?['title'] ?? 'Unknown Course';

      // Get author profile
      final authorId = questionData['authorId'];
      final authorProfile = await getUserProfile(authorId);
      questionData['authorProfile'] = authorProfile;

      // Get replies
      final repliesSnapshot = await questionDoc.reference
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .get();

      List<Map<String, dynamic>> replies = [];
      for (var replyDoc in repliesSnapshot.docs) {
        final replyData = replyDoc.data();
        replyData['id'] = replyDoc.id;
        
        // Get reply author profile
        final replyAuthorId = replyData['authorId'];
        final replyAuthorProfile = await getUserProfile(replyAuthorId);
        replyData['authorProfile'] = replyAuthorProfile;
        
        replies.add(replyData);
      }

      questionData['replies'] = replies;
      return questionData;
    } catch (e) {
      print('Error getting question details: $e');
      return null;
    }
  }

  /// Add a reply to a question
  static Future<String?> addReply({
    required String courseId,
    required String questionId,
    required String authorId,
    required String content,
  }) async {
    try {
      print('Adding reply to question: $questionId');
      
      final docRef = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .collection('replies')
          .add({
        'authorId': authorId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update question's updatedAt timestamp
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Reply created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding reply: $e');
      return null;
    }
  }

  /// Delete a question
  static Future<bool> deleteQuestion({
    required String courseId,
    required String questionId,
  }) async {
    try {
      // Delete all replies first
      final repliesSnapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .collection('replies')
          .get();

      for (var doc in repliesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the question
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .delete();

      print('Question deleted: $questionId');
      return true;
    } catch (e) {
      print('Error deleting question: $e');
      return false;
    }
  }

  /// Delete a reply
  static Future<bool> deleteReply({
    required String courseId,
    required String questionId,
    required String replyId,
  }) async {
    try {
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .collection('replies')
          .doc(replyId)
          .delete();

      print('Reply deleted: $replyId');
      return true;
    } catch (e) {
      print('Error deleting reply: $e');
      return false;
    }
  }

  /// Get questions by course (with replies embedded)
  static Future<List<Map<String, dynamic>>> getQuestionsByCourse(String courseId) async {
    try {
      print('Getting questions for course: $courseId');
      
      final questionsSnapshot = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> questions = [];
      
      for (var questionDoc in questionsSnapshot.docs) {
        final questionData = questionDoc.data();
        questionData['id'] = questionDoc.id;
        questionData['courseId'] = courseId;

        // Get replies for this question
        final repliesSnapshot = await questionDoc.reference
            .collection('replies')
            .orderBy('createdAt', descending: false)
            .get();

        List<Map<String, dynamic>> replies = [];
        for (var replyDoc in repliesSnapshot.docs) {
          final replyData = replyDoc.data();
          replyData['id'] = replyDoc.id;
          replies.add(replyData);
        }

        questionData['replies'] = replies;
        questions.add(questionData);
      }

      print('Found ${questions.length} questions for course: $courseId');
      return questions;
    } catch (e) {
      print('Error getting questions by course: $e');
      return [];
    }
  }

  /// Reply to a question
  static Future<String?> replyToQuestion({
    required String questionId,
    required String courseId,
    required String authorId,
    required String content,
  }) async {
    try {
      print('Adding reply to question: $questionId in course: $courseId');
      
      final docRef = await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .collection('replies')
          .add({
        'authorId': authorId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update question's updatedAt timestamp
      await _firebaseFirestore
          .collection('courses')
          .doc(courseId)
          .collection('questions')
          .doc(questionId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Reply created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error replying to question: $e');
      return null;
    }
  }
}
