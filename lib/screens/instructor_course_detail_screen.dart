import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'enrollment_requests_screen.dart';
import 'enrolled_students_screen.dart';
import 'edit_course_screen.dart';
import 'attendance_history_screen.dart';
import 'present_question_screen.dart';
import 'question_results_screen.dart';
import 'quiz_results_screen.dart';
import '../widgets/course_model.dart';
import '../utils/route_manager.dart';

class InstructorCourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const InstructorCourseDetailScreen({super.key, required this.courseData});

  @override
  State<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends State<InstructorCourseDetailScreen> {
  late Map<String, dynamic> _courseData;
  bool _isLoading = true;
  int _enrolledCount = 0;
  int _pendingRequestsCount = 0;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoadingAttendance = true;
  List<Map<String, dynamic>> _popupQuestionsHistory = [];
  List<Map<String, dynamic>> _quizzesHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _courseData = widget.courseData;
    _loadCourseStats();
    _loadAttendanceHistory();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final questions = await FirebaseService.getPopupQuestionsHistory(
        _courseData['id'],
      );
      final quizzes = await FirebaseService.getQuizzesHistory(
        _courseData['id'],
      );

      if (mounted) {
        setState(() {
          _popupQuestionsHistory = questions;
          _quizzesHistory = quizzes;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      final sessions = await FirebaseService.getCourseAttendanceHistory(
        _courseData['id'],
      );

      print('=== LOADING ATTENDANCE HISTORY ===');
      print('Found ${sessions.length} sessions');

      Set<String> allStudentIds = {};
      for (var session in sessions) {
        final verified = session['verifiedStudents'] as List<dynamic>? ?? [];
        allStudentIds.addAll(verified.map((id) => id.toString()));
      }

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

      final courseEnrolledCount =
          await FirebaseService.getCourseEnrolledStudentsCount(
            _courseData['id'],
          );

      List<Map<String, dynamic>> processedRecords = [];
      for (var session in sessions) {
        final verifiedStudents =
            session['verifiedStudents'] as List<dynamic>? ?? [];
        final studentPhotos =
            session['studentPhotos'] as Map<String, dynamic>? ?? {};

        print('Session ${session['id']}: studentPhotos = $studentPhotos');

        List<Map<String, dynamic>> studentDetails = [];

        for (var studentId in verifiedStudents) {
          final profile = studentProfiles[studentId.toString()];
          final photoURL = studentPhotos[studentId.toString()] ?? '';

          print('Student $studentId: photoURL = $photoURL');

          if (profile != null) {
            studentDetails.add({
              'name': profile['name'] ?? 'Unknown',
              'rollNumber': profile['rollNumber'] ?? 'N/A',
              'photoURL': photoURL,
              'studentId': studentId.toString(),
            });
          } else {
            studentDetails.add({
              'name': 'Unknown',
              'rollNumber': 'N/A',
              'photoURL': photoURL,
              'studentId': studentId.toString(),
            });
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

      print('=== PROCESSED ${processedRecords.length} RECORDS ===');

      if (mounted) {
        setState(() {
          _attendanceRecords = processedRecords;
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      print('Error loading attendance history: $e');
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

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

  Future<void> _loadCourseStats() async {
    try {
      print('Loading course stats for course: ${_courseData['id']}');

      // Get enrolled students count
      final enrolledStudents = await FirebaseService.getEnrolledStudents(
        _courseData['id'],
      );
      print('Got ${enrolledStudents.length} enrolled students');

      // Get pending requests count
      final requests = await FirebaseService.getEnrollmentRequests(
        _courseData['id'],
      );
      print('Got ${requests.length} pending requests');

      if (mounted) {
        setState(() {
          _enrolledCount = enrolledStudents.length;
          _pendingRequestsCount = requests.length;
          _isLoading = false;
        });
        print(
          'Updated UI: enrolledCount=$_enrolledCount, pendingCount=$_pendingRequestsCount',
        );
      }
    } catch (e) {
      print('Error loading course stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshCourse() async {
    try {
      final updatedCourse = await FirebaseService.getCourseById(
        _courseData['id'],
      );
      if (updatedCourse != null && mounted) {
        setState(() {
          _courseData = updatedCourse;
        });
      }
      await _loadCourseStats();
    } catch (e) {
      print('Error refreshing course: $e');
    }
  }

  void _copyOTP() {
    Clipboard.setData(ClipboardData(text: _courseData['otp'] ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteCourse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${_courseData['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.deleteCourse(_courseData['id']);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting course: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editCourse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCourseScreen(courseData: _courseData),
      ),
    );

    if (result == true) {
      await _refreshCourse();
    }
  }

  void _viewEnrollmentRequests() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnrollmentRequestsScreen(
          courseId: _courseData['id'],
          courseTitle: _courseData['title'] ?? 'Course',
        ),
      ),
    );

    if (result == true) {
      await _refreshCourse();
    }
  }

  void _viewEnrolledStudents() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnrolledStudentsScreen(
          courseId: _courseData['id'],
          courseTitle: _courseData['title'] ?? 'Course',
        ),
      ),
    );

    if (result == true) {
      await _refreshCourse();
    }
  }

  void _viewAttendanceHistory() {
    // Create a Course object for the attendance history screen
    final course = Course(
      id: _courseData['id'],
      name: _courseData['title'] ?? 'Course',
      instructor: _courseData['instructorName'] ?? 'Instructor',
      color: const Color(0xFF2563EB),
      gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
      icon: Icons.book,
      recentActivity: '',
      timeAgo: '',
      assignmentsDue: 0,
      unreadMessages: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceHistoryScreen(
          course: course,
          attendanceRecords: _attendanceRecords,
        ),
      ),
    );
  }

  void _presentQuestion() {
    // Create a Course object for the present question screen
    final course = Course(
      id: _courseData['id'],
      name: _courseData['title'] ?? 'Course',
      instructor: _courseData['instructorName'] ?? 'Instructor',
      color: const Color(0xFF2563EB),
      gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
      icon: Icons.book,
      recentActivity: '',
      timeAgo: '',
      assignmentsDue: 0,
      unreadMessages: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresentQuestionScreen(course: course),
      ),
    );
  }

  void _scheduleQuiz() {
    // Create a Course object for the schedule quiz screen
    final course = Course(
      id: _courseData['id'],
      name: _courseData['title'] ?? 'Course',
      instructor: _courseData['instructorName'] ?? 'Instructor',
      color: const Color(0xFF2563EB),
      gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
      icon: Icons.book,
      recentActivity: '',
      timeAgo: '',
      assignmentsDue: 0,
      unreadMessages: 0,
    );

    Navigator.pushNamed(
      context,
      RouteManager.getScheduleQuizRoute(),
      arguments: course,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Course Details',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            onPressed: _editCourse,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteCourse,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCourse,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // THEME: Dynamic card color
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _courseData['title'] ?? 'Untitled Course',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _courseData['description'] ?? 'No description',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // OTP Display
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.surface
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.vpn_key,
                                  color: const Color(0xFF2563EB),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Course OTP',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _courseData['otp'] ?? 'N/A',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onBackground,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  color: const Color(0xFF2563EB),
                                  onPressed: _copyOTP,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Enrolled Students',
                            _enrolledCount.toString(),
                            Icons.people,
                            const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending Requests',
                            _pendingRequestsCount.toString(),
                            Icons.pending,
                            const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions Section (Present Question & Schedule Quiz)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // THEME: Dynamic card color
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Present questions or schedule quizzes for your students',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Present Question Button
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.quiz,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Present Question',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
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

                          // Schedule Quiz Button
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.assignment,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Schedule Quiz',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
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
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    _buildActionButton(
                      'View Enrollment Requests',
                      Icons.list_alt,
                      _viewEnrollmentRequests,
                      badge: _pendingRequestsCount > 0
                          ? _pendingRequestsCount
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'View Enrolled Students',
                      Icons.school,
                      _viewEnrolledStudents,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'View Attendance History',
                      Icons.history,
                      _viewAttendanceHistory,
                    ),
                    const SizedBox(height: 20),

                    // History Section
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 16),

        // Pop-up Questions History
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // THEME: Dynamic card color
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz, color: Color(0xFF4E9FEC), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Pop-up Questions History',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_popupQuestionsHistory.isEmpty)
                Text(
                  'No pop-up questions yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              else
                ..._popupQuestionsHistory.map((question) {
                  return _buildQuestionHistoryItem(question);
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quizzes History
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // THEME: Dynamic card color
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment,
                    color: Color(0xFF4E9FEC),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quizzes History',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_quizzesHistory.isEmpty)
                Text(
                  'No quizzes yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              else
                ..._quizzesHistory.map((quiz) {
                  return _buildQuizHistoryItem(quiz);
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionHistoryItem(Map<String, dynamic> question) {
    final responses = question['responses'] as Map<String, dynamic>? ?? {};
    final totalResponses = responses.length;
    final options = question['options'] as List<dynamic>? ?? [];
    final questionType = question['questionType'] as String? ?? 'MCQ';

    // Calculate percentages for each option
    Map<int, int> optionCounts = {};
    for (var response in responses.values) {
      final responseData = response as Map<String, dynamic>? ?? {};
      final answer = responseData['response'];
      if (questionType == 'MCQ' && answer is int) {
        optionCounts[answer] = (optionCounts[answer] ?? 0) + 1;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  question['question'] ?? 'No question text',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (question['isActive'] == true)
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade900.withOpacity(0.5)
                          : Colors.green.shade100
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question['isActive'] == true ? 'Active' : 'Ended',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: (question['isActive'] == true)
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade300
                            : Colors.green.shade700
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total Responses: $totalResponses',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (questionType == 'MCQ' && options.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value.toString();
              final count = optionCounts[index] ?? 0;
              final percentage = totalResponses > 0
                  ? (count / totalResponses * 100).toStringAsFixed(1)
                  : '0.0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + index)}. $option',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                    Text(
                      '$count ($percentage%)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4E9FEC),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  final course = Course(
                    id: _courseData['id'],
                    name: _courseData['title'] ?? 'Course',
                    instructor: _courseData['instructorName'] ?? 'Instructor',
                    color: const Color(0xFF2563EB),
                    gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    icon: Icons.book,
                    recentActivity: '',
                    timeAgo: '',
                    assignmentsDue: 0,
                    unreadMessages: 0,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionResultsScreen(
                        course: course,
                        questionId: question['id'],
                        question: question['question'] ?? '',
                        questionType: questionType,
                        options: options.map((o) => o.toString()).toList(),
                        correctAnswerIndex: question['correctAnswerIndex'] ?? -1,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4E9FEC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (question['isActive'] == true)
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('End Question'),
                        content: const Text('Are you sure you want to end this question? Students will no longer be able to submit answers.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('End', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      try {
                        await FirebaseService.deactivatePopupQuestion(
                          courseId: _courseData['id'],
                          questionId: question['id'],
                        );
                        _loadHistory();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Question ended successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error ending question: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    'End Question',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistoryItem(Map<String, dynamic> quiz) {
    final submissions = quiz['submissions'] as Map<String, dynamic>? ?? {};
    final totalSubmissions = submissions.length;
    final questions = quiz['questions'] as List<dynamic>? ?? [];
    final scheduledDate = quiz['scheduledDate'];
    DateTime? date;
    if (scheduledDate != null) {
      if (scheduledDate is Timestamp) {
        date = scheduledDate.toDate();
      } else if (scheduledDate is DateTime) {
        date = scheduledDate;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quiz['title'] ?? 'Untitled Quiz',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (quiz['isActive'] == true)
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade900.withOpacity(0.5)
                          : Colors.green.shade100
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quiz['isActive'] == true ? 'Active' : 'Ended',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: (quiz['isActive'] == true)
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade300
                            : Colors.green.shade700
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Questions: ${questions.length} | Submissions: $totalSubmissions',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  final course = Course(
                    id: _courseData['id'],
                    name: _courseData['title'] ?? 'Course',
                    instructor: _courseData['instructorName'] ?? 'Instructor',
                    color: const Color(0xFF2563EB),
                    gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    icon: Icons.book,
                    recentActivity: '',
                    timeAgo: '',
                    assignmentsDue: 0,
                    unreadMessages: 0,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizResultsScreen(
                        course: course,
                        quizId: quiz['id'] ?? '',
                        quizData: quiz,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View Results',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4E9FEC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (quiz['isActive'] == true)
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('End Quiz'),
                        content: const Text('Are you sure you want to end this quiz? Students will no longer be able to submit answers.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('End', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      try {
                        await FirebaseService.deactivateQuiz(
                          courseId: _courseData['id'],
                          quizId: quiz['id'] ?? '',
                        );
                        _loadHistory();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quiz ended successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error ending quiz: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    'End Quiz',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    int? badge,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // THEME: Dynamic card color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
