import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/course_model.dart';
import '../utils/route_manager.dart';
import '../services/firebase_service.dart';
import 'present_question_screen.dart';
import 'question_results_screen.dart';
import 'attendance_history_screen.dart';

class InstructorCourseDetailScreen extends StatefulWidget {
  final Course course;

  const InstructorCourseDetailScreen({super.key, required this.course});

  @override
  State<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends State<InstructorCourseDetailScreen> {
  // Mock data for notifications
  final List<Map<String, String>> _notifications = [
    {
      'title': 'Lecture 7 has been uploaded.',
      'time': '3/10 11:00 PM',
      'icon':
          'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F95f43002-a4f9-46d0-b34f-6240401cf2a9.png',
    },
    {
      'title': 'Assignment 3 has been uploaded.',
      'time': '5/10 10:00 AM',
      'icon':
          'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fde7fb90a-a5aa-424f-9c3a-7c1ba7596fa1.png',
    },
    {
      'title': 'Quiz 2 has been scheduled',
      'time': '2/10 9:30 AM',
      'icon':
          'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F676369d5-b87f-44a2-98cd-257f75320b56.png',
    },
  ];

  // Real attendance data from Firebase
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoadingAttendance = true;

  // Questions and quizzes history
  List<Map<String, dynamic>> _popupQuestionsHistory = [];
  List<Map<String, dynamic>> _quizzesHistory = [];
  bool _isLoadingHistory = true;

  // Mock data for enrollment requests
  final List<Map<String, String>> _enrollmentRequests = [
    {'name': 'Ahmed Raza', 'rollNumber': '241631448'},
    {'name': 'Fatima Noor', 'rollNumber': '241631449'},
    {'name': 'Bilal Shah', 'rollNumber': '241631450'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
    _loadQuestionsAndQuizzesHistory();
  }

  // Fetch attendance history from Firebase
  Future<void> _loadAttendanceHistory() async {
    try {
      // Get all attendance sessions for this course
      final sessions = await FirebaseService.getCourseAttendanceHistory(
        widget.course.id,
      );

      // Collect all unique student IDs to batch fetch profiles
      Set<String> allStudentIds = {};
      for (var session in sessions) {
        final verified = session['verifiedStudents'] as List<dynamic>? ?? [];
        allStudentIds.addAll(verified.map((id) => id.toString()));
      }

      // Batch fetch all student profiles
      Map<String, Map<String, dynamic>> studentProfiles = {};
      for (String studentId in allStudentIds) {
        try {
          final profile = await FirebaseService.getUserProfile(studentId);
          if (profile != null) {
            studentProfiles[studentId] = profile;
          }
        } catch (e) {
          print('Error fetching profile for student $studentId: $e');
        }
      }

      // Get total enrolled students count for the course
      final courseEnrolledCount =
          await FirebaseService.getCourseEnrolledStudentsCount(
            widget.course.id,
          );

      // Process each session
      List<Map<String, dynamic>> processedRecords = [];
      for (var session in sessions) {
        final verifiedStudents =
            session['verifiedStudents'] as List<dynamic>? ?? [];
        List<Map<String, String>> studentDetails = [];

        // Build student details list using cached profiles
        for (var studentId in verifiedStudents) {
          final profile = studentProfiles[studentId.toString()];
          if (profile != null) {
            studentDetails.add({
              'name': profile['name'] ?? 'Unknown',
              'rollNumber': profile['rollNumber'] ?? 'N/A',
            });
          } else {
            studentDetails.add({'name': 'Unknown', 'rollNumber': 'N/A'});
          }
        }

        processedRecords.add({
          'date': _formatDate(session['createdAt']),
          'present': verifiedStudents.length,
          'total': courseEnrolledCount,
          'students': studentDetails,
          'sessionId': session['id'],
        });
      }

      setState(() {
        _attendanceRecords = processedRecords;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      print('Error loading attendance history: $e');
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  // Format Firestore Timestamp to readable date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _presentQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresentQuestionScreen(course: widget.course),
      ),
    );
  }

  void _scheduleQuiz() {
    Navigator.pushNamed(
      context,
      RouteManager.getScheduleQuizRoute(),
      arguments: widget.course,
    );
  }

  void _viewAttendanceRecord(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AttendanceRecordScreen(course: widget.course, record: record),
      ),
    );
  }

  void _viewAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceHistoryScreen(
          course: widget.course,
          attendanceRecords: _attendanceRecords,
        ),
      ),
    );
  }

  void _viewEnrollmentRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnrollmentRequestsScreen(
          course: widget.course,
          requests: _enrollmentRequests,
          onUpdate: () {
            setState(() {}); // Refresh when returning
          },
        ),
      ),
    );
  }

  Future<void> _loadQuestionsAndQuizzesHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final questions = await FirebaseService.getPopupQuestionsHistory(
        widget.course.id,
      );
      final quizzes = await FirebaseService.getQuizzesHistory(widget.course.id);

      setState(() {
        _popupQuestionsHistory = questions;
        _quizzesHistory = quizzes;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  void _viewQuestionResults({
    String? questionId,
    Map<String, dynamic>? questionData,
  }) {
    if (questionId != null && questionData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionResultsScreen(
            course: widget.course,
            questionId: questionId,
            question: questionData['question'] ?? '',
            questionType: questionData['questionType'] ?? 'MCQ',
            options: List<String>.from(questionData['options'] ?? []),
            correctAnswerIndex: questionData['correctAnswerIndex'] ?? 0,
          ),
        ),
      );
    } else {
      // Fallback for backward compatibility
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionResultsScreen(
            course: widget.course,
            question: "Sample question from previous session",
            questionType: "MCQ",
            options: ["Option A", "Option B", "Option C", "Option D"],
            correctAnswerIndex: 1,
          ),
        ),
      );
    }
  }

  void _viewQuizResults(String quizId, Map<String, dynamic> quizData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          course: widget.course,
          quizId: quizId,
          quizData: quizData,
        ),
      ),
    );
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getCoursesRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: _onBackPressed,
        ),
        title: Text(
          widget.course.name,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Course Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.course.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course.instructor,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Latest Notifications
            _buildNotificationsSection(),

            const SizedBox(height: 24),

            // Attendance Records Section
            _buildAttendanceSection(),

            const SizedBox(height: 24),

            // Instructor Tools Section
            _buildInstructorToolsSection(),

            const SizedBox(height: 24),

            // History Section
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  // In your course_detail_screen.dart - just replace colors
  Widget _buildNotificationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Automatically adapts
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ), // Automatically adapts
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : const Color(0x0C000000),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Notifications',
            style: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).colorScheme.onBackground, // Automatically adapts
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications from LMS',
            style: GoogleFonts.inter(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7), // Automatically adapts
              fontSize: 14,
            ),
          ),
          // ... rest of your existing code
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, String> notification) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            notification['icon']!,
            width: 19,
            height: 19,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title']!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1E1E1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['time']!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1E1E1E),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            spreadRadius: 0,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Records',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View attendance records for your course',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Show loading indicator while fetching
          if (_isLoadingAttendance)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          // Show message if no records
          else if (_attendanceRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance records yet',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance sessions will appear here once you generate OTPs',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Show attendance records
          else
            Column(
              children: _attendanceRecords
                  .map((record) => _buildAttendanceItem(record))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> record) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _viewAttendanceRecord(record),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${record['date']}',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance: ${record['present']}/${record['total']} students',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorToolsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            spreadRadius: 0,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructor Tools',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your course activities',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Present Question Section
          Text(
            'Present Question',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a real-time question to your students',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x19000000),
                  spreadRadius: 0,
                  offset: Offset(0, 10),
                  blurRadius: 15,
                ),
                BoxShadow(
                  color: Color(0x19000000),
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _presentQuestion,
                child: Center(
                  child: Text(
                    'Present Question',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Schedule Quiz Section
          Text(
            'Schedule Quiz',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create and schedule assessments for your students',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x19000000),
                  spreadRadius: 0,
                  offset: Offset(0, 10),
                  blurRadius: 15,
                ),
                BoxShadow(
                  color: Color(0x19000000),
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _scheduleQuiz,
                child: Center(
                  child: Text(
                    'Schedule Quiz',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Enrollment Requests Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _viewEnrollmentRequests,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: widget.course.color),
                    const SizedBox(width: 8),
                    Text(
                      'View Enrollment Requests',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // View Attendance History Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _viewAttendanceHistory,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: widget.course.color),
                    const SizedBox(width: 8),
                    Text(
                      'View Attendance History',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Review Question Results Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _viewQuestionResults,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, color: widget.course.color),
                    const SizedBox(width: 8),
                    Text(
                      'Review Question Results',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            spreadRadius: 0,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questions & Quizzes History',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View past questions and quizzes with student results',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Popup Questions History
            if (_popupQuestionsHistory.isNotEmpty) ...[
              Text(
                'Popup Questions',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ..._popupQuestionsHistory.map(
                (question) => _buildHistoryItem(
                  title: question['question'] ?? 'Untitled Question',
                  type: 'Question',
                  date: _formatDate(question['createdAt']),
                  isActive: question['isActive'] ?? false,
                  onTap: () => _viewQuestionResults(
                    questionId: question['id'],
                    questionData: question,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quizzes History
            if (_quizzesHistory.isNotEmpty) ...[
              Text(
                'Quizzes',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ..._quizzesHistory.map(
                (quiz) => _buildHistoryItem(
                  title: quiz['title'] ?? 'Untitled Quiz',
                  type: 'Quiz',
                  date: _formatDate(quiz['createdAt']),
                  isActive: quiz['isActive'] ?? false,
                  onTap: () => _viewQuizResults(quiz['id'], quiz),
                ),
              ),
            ],

            if (_popupQuestionsHistory.isEmpty && _quizzesHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No history yet',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Questions and quizzes will appear here once created',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String type,
    required String date,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Ended',
                              style: GoogleFonts.inter(
                                color: isActive
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            type,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quiz Results Screen
class QuizResultsScreen extends StatefulWidget {
  final Course course;
  final String quizId;
  final Map<String, dynamic> quizData;

  const QuizResultsScreen({
    super.key,
    required this.course,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  Map<String, dynamic>? _quizResults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await FirebaseService.getQuizResults(
        courseId: widget.course.id,
        quizId: widget.quizId,
      );
      setState(() {
        _quizResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quiz results: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quiz Results',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.course.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.quizData['title'] ?? 'Untitled Quiz',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quiz Results',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student Submissions
                  if (_quizResults != null) ...[
                    Text(
                      'Student Submissions',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_quizResults!['enrichedSubmissions']
                                as Map<String, dynamic>? ??
                            {})
                        .entries
                        .map((entry) => _buildStudentSubmission(entry.value)),
                  ],

                  if (_quizResults == null ||
                      (_quizResults!['enrichedSubmissions'] as Map? ?? {})
                          .isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No submissions yet',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentSubmission(Map<String, dynamic> submission) {
    final score = submission['score'] ?? 0;
    final total = submission['totalQuestions'] ?? 1;
    final percentage = submission['percentage'] ?? 0;
    final studentName = submission['studentName'] ?? 'Unknown';
    final rollNumber = submission['studentRollNumber'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                rollNumber,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score/$total',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  color: percentage >= 70
                      ? Colors.green.shade700
                      : percentage >= 50
                      ? Colors.orange.shade700
                      : Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Attendance Record Screen
class AttendanceRecordScreen extends StatelessWidget {
  final Course course;
  final Map<String, dynamic> record;

  const AttendanceRecordScreen({
    super.key,
    required this.course,
    required this.record,
  });

  void _onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => _onBackPressed(context),
        ),
        title: Text(
          'Attendance Record - ${record['date']}',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: course.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Attendance Summary',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${record['present']}/${record['total']} students present',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Students List
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    spreadRadius: 0,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Students Present',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    record['students'].length,
                    (index) => _buildStudentItem(context, record['students'][index]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(BuildContext context, Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: course.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: course.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  student['rollNumber'],
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enrollment Requests Screen
class EnrollmentRequestsScreen extends StatefulWidget {
  final Course course;
  final List<Map<String, String>> requests;
  final VoidCallback onUpdate;

  const EnrollmentRequestsScreen({
    super.key,
    required this.course,
    required this.requests,
    required this.onUpdate,
  });

  @override
  State<EnrollmentRequestsScreen> createState() =>
      _EnrollmentRequestsScreenState();
}

class _EnrollmentRequestsScreenState extends State<EnrollmentRequestsScreen> {
  void _onBackPressed() {
    Navigator.pop(context);
  }

  void _handleRequest(int index, bool accepted) {
    setState(() {
      widget.requests.removeAt(index);
    });
    widget.onUpdate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request ${accepted ? 'accepted' : 'rejected'}'),
        backgroundColor: accepted ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: _onBackPressed,
        ),
        title: Text(
          'Enrollment Requests',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: widget.requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.course.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Pending Enrollment Requests',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.requests.length} request(s) pending',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Requests List
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          spreadRadius: 0,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(
                        widget.requests.length,
                        (index) =>
                            _buildRequestItem(widget.requests[index], index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestItem(Map<String, String> request, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.course.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: widget.course.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name']!,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      request['rollNumber']!,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _handleRequest(index, false),
                      child: Center(
                        child: Text(
                          'Reject',
                          style: GoogleFonts.inter(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _handleRequest(index, true),
                      child: Center(
                        child: Text(
                          'Accept',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
