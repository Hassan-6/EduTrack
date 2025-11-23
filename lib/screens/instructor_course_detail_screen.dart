import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'enrollment_requests_screen.dart';
import 'enrolled_students_screen.dart';
import 'edit_course_screen.dart';
import 'attendance_history_screen.dart';
import '../widgets/course_model.dart';

class InstructorCourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const InstructorCourseDetailScreen({super.key, required this.courseData});

  @override
  State<InstructorCourseDetailScreen> createState() => _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState extends State<InstructorCourseDetailScreen> {
  late Map<String, dynamic> _courseData;
  bool _isLoading = true;
  int _enrolledCount = 0;
  int _pendingRequestsCount = 0;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    _courseData = widget.courseData;
    _loadCourseStats();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      final sessions = await FirebaseService.getCourseAttendanceHistory(_courseData['id']);
      
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
      
      final courseEnrolledCount = await FirebaseService.getCourseEnrolledStudentsCount(_courseData['id']);
      
      List<Map<String, dynamic>> processedRecords = [];
      for (var session in sessions) {
        final verifiedStudents = session['verifiedStudents'] as List<dynamic>? ?? [];
        final studentPhotos = session['studentPhotos'] as Map<String, dynamic>? ?? {};
        
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
      final enrolledStudents = await FirebaseService.getEnrolledStudents(_courseData['id']);
      print('Got ${enrolledStudents.length} enrolled students');
      
      // Get pending requests count
      final requests = await FirebaseService.getEnrollmentRequests(_courseData['id']);
      print('Got ${requests.length} pending requests');
      
      if (mounted) {
        setState(() {
          _enrolledCount = enrolledStudents.length;
          _pendingRequestsCount = requests.length;
          _isLoading = false;
        });
        print('Updated UI: enrolledCount=$_enrolledCount, pendingCount=$_pendingRequestsCount');
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
      final updatedCourse = await FirebaseService.getCourseById(_courseData['id']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Course Details',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF6B7280)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _courseData['description'] ?? 'No description',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // OTP Display
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Course OTP',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _courseData['otp'] ?? 'N/A',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F2937),
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
                    
                    // Action Buttons
                    _buildActionButton(
                      'View Enrollment Requests',
                      Icons.list_alt,
                      _viewEnrollmentRequests,
                      badge: _pendingRequestsCount > 0 ? _pendingRequestsCount : null,
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, {int? badge}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFF1F2937),
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
