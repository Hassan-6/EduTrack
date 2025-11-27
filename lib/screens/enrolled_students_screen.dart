import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../widgets/profile_avatar.dart';
import 'profile_screen.dart';
import 'profile_viewer_screen.dart';

class EnrolledStudentsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const EnrolledStudentsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<EnrolledStudentsScreen> createState() => _EnrolledStudentsScreenState();
}

class _EnrolledStudentsScreenState extends State<EnrolledStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledStudents();
  }

  Future<void> _loadEnrolledStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await FirebaseService.getEnrolledStudents(widget.courseId);
      print('Loaded ${students.length} enrolled students');
      if (students.isNotEmpty) {
        print('First student data: ${students[0]}');
      }
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading enrolled students: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeStudent(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Student'),
        content: Text(
          'Are you sure you want to remove ${student['name'] ?? 'this student'} from this course?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.removeStudentFromCourse(widget.courseId, student['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadEnrolledStudents();
          Navigator.pop(context, true); // Return true to refresh parent
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing student: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrolled Students',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.courseTitle,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEnrolledStudents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return _buildStudentCard(student);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Students Enrolled',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Students will appear here once they enroll in your course',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    print('=== Building card for student ===');
    print('Full student data: $student');
    print('Keys in student data: ${student.keys.toList()}');
    print('Name field value: ${student['name']}');
    print('Email field value: ${student['email']}');
    
    final name = student['name'] ?? 'Unknown Student';
    final email = student['email'] ?? '';
    final rollNumber = student['rollNumber'] ?? 'N/A';
    final enrolledDate = _formatDate(student['enrolledAt']);
    final profileIconIndex = student['profileIconIndex'] ?? 0;
    
    print('After extraction: name=$name, email=$email, rollNumber=$rollNumber');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileViewerScreen(
              userProfile: UserProfile(
                name: name,
                username: '@${rollNumber.toLowerCase()}',
                major: student['major'] ?? 'Not specified',
                age: student['age'] ?? '',
                rollNumber: rollNumber,
                phoneNumber: student['phoneNumber'] ?? '',
                email: email,
                semester: student['semester'] ?? 'Not specified',
                cgpa: student['cgpa'] ?? 'N/A',
                profileIconIndex: profileIconIndex,
              ),
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          // Avatar
          ProfileAvatar(
            iconIndex: profileIconIndex ?? 0,
            radius: 24,
          ),
          const SizedBox(width: 12),
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Roll: $rollNumber',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enrolled: $enrolledDate',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          // Remove Button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.red,
            onPressed: () => _removeStudent(student),
            tooltip: 'Remove student',
          ),
        ],
      ),
      ),
    );
  }
}
