import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/course_model.dart';
import 'join_course_screen.dart';
import 'course_detail_screen.dart';
import 'create_course_screen.dart';
import '../utils/theme_provider.dart';
import '../services/auth_provider.dart';
import '../services/firebase_service.dart';
import '../utils/course_categories.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = FirebaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('Loading enrolled courses for student: ${currentUser.uid}');
      final coursesData = await FirebaseService.getStudentEnrolledCourses(currentUser.uid);
      print('Loaded ${coursesData.length} courses from Firebase');
      
      // Load courses with activity status
      final courses = <Course>[];
      for (var courseData in coursesData) {
        // Get category or use default
        final categoryId = courseData['category'] as String?;
        final category = CourseCategories.tryGetById(categoryId) ?? CourseCategories.computerScience;

        // Check for active popup questions and quizzes
        String activityStatus = 'No recent activity';
        try {
          final courseId = courseData['id'] ?? '';
          
          // Check for active popup questions
          final popupQuestions = await FirebaseService.getCoursePopupQuestions(courseId);
          final hasActivePopup = popupQuestions.any((q) => q['isActive'] == true);
          
          // Check for active quizzes
          final quizzes = await FirebaseService.getCourseQuizzes(courseId);
          final hasActiveQuiz = quizzes.any((q) => q['isActive'] == true);
          
          // Set activity status based on what's active
          if (hasActivePopup && hasActiveQuiz) {
            activityStatus = '🔴 Quiz and Pop-up Question Active';
          } else if (hasActiveQuiz) {
            activityStatus = '🔴 Quiz Active';
          } else if (hasActivePopup) {
            activityStatus = '🔴 Pop-up Question Active';
          }
        } catch (e) {
          print('Error checking activity for course ${courseData['id']}: $e');
        }

        courses.add(Course(
          id: courseData['id'] ?? '',
          name: courseData['title'] ?? 'Unnamed Course',
          instructor: courseData['instructorName'] ?? 'Unknown Instructor',
          color: category.primaryColor,
          gradient: category.gradient,
          icon: category.icon,
          recentActivity: activityStatus,
          timeAgo: '',
          assignmentsDue: 0,
          unreadMessages: 0,
        ));
      }
      
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  void _addNewCourse() {
    // Check if user is instructor
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userType = authProvider.userType;

    if (userType == 'instructor') {
      // Navigate to Create Course screen for instructors
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
      );
    } else {
      // Navigate to Join Course screen for students
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const JoinCourseScreen()),
      );
    }
  }

  void _viewCourseDetails(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(course: course),
      ),
    );
  }

  void _searchCourses() {
    // TODO: Implement search functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
        title: Text(
          'Search Courses',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
        ),
        content: Text(
          'Search functionality would go here.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface), // THEME: Dynamic text
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).primaryColor), // THEME: Dynamic button
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Courses',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: _searchCourses,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No enrolled courses yet',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to join a course',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEnrolledCourses,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Courses List Only - No header card
                          ..._courses.map((course) => _buildCourseCard(course)),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: _buildCustomFloatingActionButton(themeProvider),
    );
  }

  Widget _buildCustomFloatingActionButton(ThemeProvider themeProvider) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
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
        gradient: themeProvider.gradient, // THEME: Dynamic gradient
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: _addNewCourse,
          child: Center(
            child: Image.network(
              'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F1acf3707-fc14-48b1-a087-6a99c88d6baa.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: course.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              course.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Course Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course.instructor,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Removed notification badges
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  course.recentActivity,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.timeAgo,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _viewCourseDetails(course),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).primaryColor, // THEME: Dynamic button
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}