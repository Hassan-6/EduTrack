import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// Service to monitor activity and show notifications without creating Firestore docs for other users
/// Uses real-time listeners to detect new items and show local notifications
class ActivityMonitorService {
  static final ActivityMonitorService _instance = ActivityMonitorService._internal();
  factory ActivityMonitorService() => _instance;
  ActivityMonitorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Track last seen timestamps to avoid showing old notifications
  DateTime? _lastSeenQuestions;
  DateTime? _lastSeenQuizzes;
  DateTime? _lastSeenEnrollments;
  DateTime? _lastSeenQnAResponses;

  /// Start monitoring for a student
  void startStudentMonitoring(String userId) {
    print('=== Starting Student Activity Monitoring ===');
    print('User ID: $userId');
    
    _lastSeenQuestions = DateTime.now();
    _lastSeenQuizzes = DateTime.now();
    _lastSeenQnAResponses = DateTime.now();
    
    print('Timestamp baseline set to: ${DateTime.now()}');
    print('Monitoring: Questions, Quizzes, QnA Responses');
    
    _monitorNewQuestions(userId);
    _monitorNewQuizzes(userId);
    _monitorQnAResponses(userId);
    
    print('=== Student Monitoring Active ===');
  }

  /// Start monitoring for an instructor
  void startInstructorMonitoring(String userId) {
    print('=== Starting Instructor Activity Monitoring ===');
    print('User ID: $userId');
    
    _lastSeenEnrollments = DateTime.now();
    _lastSeenQnAResponses = DateTime.now();
    
    print('Timestamp baseline set to: ${DateTime.now()}');
    print('Monitoring: Enrollment Requests, QnA Responses');
    
    _monitorEnrollmentRequests(userId);
    _monitorQnAResponses(userId);
    
    print('=== Instructor Monitoring Active ===');
  }

  /// Monitor for new questions in enrolled courses
  void _monitorNewQuestions(String userId) {
    print('[Monitor] Setting up question monitoring for user: $userId');
    
    // Get user's enrolled courses
    _firestore.collection('users').doc(userId).snapshots().listen((userDoc) {
      if (!userDoc.exists) {
        print('[Monitor] User document not found: $userId');
        return;
      }
      
      final enrolledCourses = List<String>.from(userDoc.data()?['enrolledCourses'] ?? []);
      print('[Monitor] User enrolled in ${enrolledCourses.length} courses');
      
      // Monitor each enrolled course for new questions
      for (final courseId in enrolledCourses) {
        print('[Monitor] Monitoring questions in course: $courseId');
        _firestore
            .collection('courses')
            .doc(courseId)
            .collection('popupQuestions')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isEmpty) {
            print('[Monitor] No questions found in course: $courseId');
            return;
          }
          
          final doc = snapshot.docs.first;
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          
          print('[Monitor] Question detected in $courseId:');
          print('  Question ID: ${doc.id}');
          print('  Created at: $createdAt');
          print('  Instructor: ${data['instructorId']}');
          print('  Current user: $userId');
          print('  Baseline time: $_lastSeenQuestions');
          
          // Only show notification for questions created after monitoring started
          if (createdAt != null && 
              _lastSeenQuestions != null && 
              createdAt.isAfter(_lastSeenQuestions!) &&
              data['instructorId'] != userId) {
            
            print('[Monitor] ✅ Showing question notification!');
            
            // Show local notification
            _notificationService.showLocalNotification(
              id: doc.id.hashCode,
              title: 'New Question',
              body: 'Instructor has presented a question in your course',
              payload: 'question:$courseId',
            );
          } else {
            print('[Monitor] ❌ Skipped notification (old question or self-created)');
          }
        });
      }
    });
  }

  /// Monitor for new quizzes in enrolled courses
  void _monitorNewQuizzes(String userId) {
    // Get user's enrolled courses
    _firestore.collection('users').doc(userId).snapshots().listen((userDoc) {
      if (!userDoc.exists) return;
      
      final enrolledCourses = List<String>.from(userDoc.data()?['enrolledCourses'] ?? []);
      
      // Monitor each enrolled course for new quizzes
      for (final courseId in enrolledCourses) {
        _firestore
            .collection('courses')
            .doc(courseId)
            .collection('quizzes')
            .orderBy('scheduledDate', descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isEmpty) return;
          
          final doc = snapshot.docs.first;
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final scheduledDate = (data['scheduledDate'] as Timestamp?)?.toDate();
          
          // Only show notification for quizzes created after monitoring started
          if (createdAt != null && 
              _lastSeenQuizzes != null && 
              createdAt.isAfter(_lastSeenQuizzes!) &&
              data['instructorId'] != userId) {
            
            final quizTitle = data['title'] ?? 'Quiz';
            final dateStr = scheduledDate != null 
                ? scheduledDate.toString().split(' ')[0] 
                : 'soon';
            
            // Show local notification
            _notificationService.showLocalNotification(
              id: doc.id.hashCode,
              title: 'Quiz Scheduled',
              body: '$quizTitle on $dateStr',
              payload: 'quiz:$courseId',
            );
            
            // Schedule reminder 1 hour before quiz if applicable
            if (scheduledDate != null && scheduledDate.isAfter(DateTime.now())) {
              final reminderTime = scheduledDate.subtract(const Duration(hours: 1));
              if (reminderTime.isAfter(DateTime.now())) {
                _notificationService.scheduleNotification(
                  id: '${doc.id}_reminder'.hashCode,
                  title: 'Quiz Starting Soon',
                  body: '$quizTitle starts in 1 hour',
                  scheduledDate: reminderTime,
                  payload: 'quiz:$courseId',
                );
              }
            }
          }
        });
      }
    });
  }

  /// Monitor for enrollment requests (instructor only)
  void _monitorEnrollmentRequests(String instructorId) {
    // Get instructor's courses
    _firestore
        .collection('courses')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .listen((coursesSnapshot) {
      
      for (final courseDoc in coursesSnapshot.docs) {
        final courseId = courseDoc.id;
        final courseName = courseDoc.data()['title'] ?? 'Course';
        
        // Monitor enrollment requests for this course
        _firestore
            .collection('courses')
            .doc(courseId)
            .collection('enrollmentRequests')
            .where('status', isEqualTo: 'pending')
            .orderBy('requestedAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isEmpty) return;
          
          final doc = snapshot.docs.first;
          final data = doc.data();
          final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();
          
          // Only show notification for requests created after monitoring started
          if (requestedAt != null && 
              _lastSeenEnrollments != null && 
              requestedAt.isAfter(_lastSeenEnrollments!)) {
            
            final studentName = data['studentName'] ?? 'A student';
            
            // Show local notification
            _notificationService.showLocalNotification(
              id: doc.id.hashCode,
              title: 'New Enrollment Request',
              body: '$studentName wants to enroll in $courseName',
              payload: 'enrollment:$courseId',
            );
          }
        });
      }
    });
  }

  /// Monitor for QnA responses (both students and instructors)
  void _monitorQnAResponses(String userId) {
    print('[Monitor] Setting up QnA response monitoring for user: $userId');
    
    // Monitor all questions where user is the author using collectionGroup
    _firestore
        .collectionGroup('questions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((questionsSnapshot) {
      
      print('[Monitor] Found ${questionsSnapshot.docs.length} questions by user');
      
      for (final questionDoc in questionsSnapshot.docs) {
        final questionId = questionDoc.id;
        final questionData = questionDoc.data();
        final questionTitle = questionData['questionTitle'] ?? 'your question';
        
        print('[Monitor] Monitoring replies to question: $questionId ("$questionTitle")');
        
        // Monitor replies to this question
        questionDoc.reference
            .collection('replies')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((repliesSnapshot) async {
          if (repliesSnapshot.docs.isEmpty) {
            print('[Monitor] No replies yet for question: $questionId');
            return;
          }
          
          final replyDoc = repliesSnapshot.docs.first;
          final replyData = replyDoc.data();
          final createdAt = (replyData['createdAt'] as Timestamp?)?.toDate();
          final replyAuthorId = replyData['authorId'];
          
          print('[Monitor] Reply detected for question "$questionTitle":');
          print('  Reply ID: ${replyDoc.id}');
          print('  Created at: $createdAt');
          print('  Reply author: $replyAuthorId');
          print('  Question author: $userId');
          print('  Baseline time: $_lastSeenQnAResponses');
          
          // Only show notification for replies from others, created after monitoring started
          if (createdAt != null && 
              _lastSeenQnAResponses != null && 
              createdAt.isAfter(_lastSeenQnAResponses!) &&
              replyAuthorId != userId) {
            
            print('[Monitor] ✅ Showing QnA response notification!');
            
            // Get responder's name from their profile
            String responderName = 'Someone';
            try {
              final responderDoc = await _firestore
                  .collection('users')
                  .doc(replyAuthorId)
                  .get();
              if (responderDoc.exists) {
                responderName = responderDoc.data()?['name'] ?? 'Someone';
              }
            } catch (e) {
              print('Error getting responder name: $e');
            }
            
            // Show local notification
            _notificationService.showLocalNotification(
              id: replyDoc.id.hashCode,
              title: 'New Response to Your Question',
              body: '$responderName responded to "$questionTitle"',
              payload: 'qna:$questionId',
            );
          } else {
            print('[Monitor] ❌ Skipped notification (old reply or self-reply)');
          }
        });
      }
    });
  }

  /// Stop all monitoring (call when user logs out)
  void stopMonitoring() {
    _lastSeenQuestions = null;
    _lastSeenQuizzes = null;
    _lastSeenEnrollments = null;
    _lastSeenQnAResponses = null;
  }
}
