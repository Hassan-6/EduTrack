import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/firebase_service.dart';
import '../utils/course_categories.dart';
import 'instructor_course_detail_screen.dart';
import 'course_detail_screen.dart';
import '../widgets/course_model.dart';

class ArchivedCoursesScreen extends StatefulWidget {
  const ArchivedCoursesScreen({super.key});

  @override
  State<ArchivedCoursesScreen> createState() => _ArchivedCoursesScreenState();
}

class _ArchivedCoursesScreenState extends State<ArchivedCoursesScreen> {
  List<Map<String, dynamic>> _archivedCourses = [];
  bool _isLoading = true;
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    _loadArchivedCourses();
  }

  Future<void> _loadArchivedCourses() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      _isInstructor = authProvider.userType == 'instructor';

      List<Map<String, dynamic>> courses;
      if (_isInstructor) {
        courses = await FirebaseService.getInstructorArchivedCourses(currentUser.uid);
      } else {
        courses = await FirebaseService.getStudentArchivedCourses(currentUser.uid);
      }

      if (mounted) {
        setState(() {
          _archivedCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading archived courses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading archived courses: $e')),
        );
      }
    }
  }

  void _viewCourseDetails(Map<String, dynamic> courseData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (_isInstructor) {
            return InstructorCourseDetailScreen(courseData: courseData);
          } else {
            // Create Course object for student view
            final categoryId = courseData['category'] as String?;
            final category = CourseCategories.tryGetById(categoryId) ?? CourseCategories.computerScience;
            
            final course = Course(
              id: courseData['id'] ?? '',
              name: courseData['title'] ?? 'Unnamed Course',
              instructor: courseData['instructorName'] ?? 'Unknown Instructor',
              color: category.primaryColor,
              gradient: category.gradient,
              icon: category.icon,
              recentActivity: 'Archived',
              timeAgo: '',
              assignmentsDue: 0,
              unreadMessages: 0,
            );
            return CourseDetailScreen(course: course);
          }
        },
      ),
    );

    // Reload if course was modified
    if (result == true) {
      _loadArchivedCourses();
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
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Archived Courses',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : _archivedCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No archived courses',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadArchivedCourses,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ..._archivedCourses.map((course) => _buildCourseCard(course)),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> courseData) {
    final categoryId = courseData['category'] as String?;
    final category = CourseCategories.tryGetById(categoryId) ?? CourseCategories.computerScience;

    return GestureDetector(
      onTap: () => _viewCourseDetails(courseData),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: category.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['title'] ?? 'Unnamed Course',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseData['instructorName'] ?? 'Unknown Instructor',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.archive, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Archived',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              courseData['description'] ?? 'No description',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
