import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/course_model.dart';
import 'course_enrollment_screen.dart';
import 'course_detail_screen.dart';
import '../utils/theme_provider.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final List<Course> _courses = [
    Course(
      id: '1',
      name: 'Introduction to Programming',
      instructor: 'Dr. Sarah Mitchell',
      color: const Color(0xFF4E9FEC),
      gradient: const [Color(0xFF4E9FEC), Color(0xFF2563EB)],
      icon: Icons.code,
      recentActivity: 'New Quiz available: Week 3 Assessment',
      timeAgo: '2 hours ago',
      assignmentsDue: 2,
      unreadMessages: 3,
    ),
    Course(
      id: '2',
      name: 'Calculus I',
      instructor: 'Prof. James Wilson',
      color: const Color(0xFF5CD6C0),
      gradient: const [Color(0xFF5CD6C0), Color(0xFF16A34A)],
      icon: Icons.calculate,
      recentActivity: 'Assignment 4 feedback posted',
      timeAgo: '1 day ago',
      assignmentsDue: 1,
      unreadMessages: 0,
    ),
    Course(
      id: '3',
      name: 'Physics II',
      instructor: 'Dr. Emily Chen',
      color: const Color(0xFFC084FC),
      gradient: const [Color(0xFFC084FC), Color(0xFF9333EA)],
      icon: Icons.science,
      recentActivity: 'Lab report due tomorrow',
      timeAgo: '3 hours ago',
      assignmentsDue: 1,
      unreadMessages: 5,
    ),
    Course(
      id: '4',
      name: 'Spanish Literature',
      instructor: 'Prof. Maria Rodriguez',
      color: const Color(0xFF818CF8),
      gradient: const [Color(0xFF818CF8), Color(0xFF4F46E5)],
      icon: Icons.menu_book,
      recentActivity: 'Discussion forum: Cervantes analysis',
      timeAgo: '2 days ago',
      assignmentsDue: 0,
      unreadMessages: 2,
    ),
  ];

  void _addNewCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CourseEnrollmentScreen()),
    );
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
      body: SingleChildScrollView(
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