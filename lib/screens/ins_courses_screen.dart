import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/route_manager.dart';
import '../utils/theme_provider.dart';
import '../widgets/role_guard.dart';
import 'create_course_screen.dart';
import '../services/auth_provider.dart';
import '../services/firebase_service.dart';
import 'instructor_course_detail_screen.dart';
import '../utils/course_categories.dart';
import 'archived_courses_screen.dart';

class InstructorCoursesScreen extends StatefulWidget {
  const InstructorCoursesScreen({super.key});

  @override
  State<InstructorCoursesScreen> createState() => _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  String _instructorName = 'Instructor';
  bool _isLoadingName = true;
  List<Map<String, dynamic>> _firebaseCourses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadInstructorName();
    _loadInstructorCourses();
  }

  Future<void> _loadInstructorName() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final userProfile = await FirebaseService.getUserProfile(authProvider.currentUser!.uid);
        if (userProfile != null && mounted) {
          setState(() {
            _instructorName = userProfile['name'] ?? 'Instructor';
            _isLoadingName = false;
          });
        }
      }
    } catch (e) {
      print('Error loading instructor name: $e');
      if (mounted) {
        setState(() {
          _instructorName = 'Instructor';
          _isLoadingName = false;
        });
      }
    }
  }

  Future<void> _loadInstructorCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        print('Loading courses for instructor: ${authProvider.currentUser!.uid}');
        final courses = await FirebaseService.getInstructorCourses(authProvider.currentUser!.uid);
        print('Courses loaded: ${courses.length}');
        if (mounted) {
          setState(() {
            _firebaseCourses = courses;
            _isLoadingCourses = false;
          });
        }
      }
    } catch (e) {
      print('Error loading courses: $e');
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    }
  }

  void _addNewCourse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
    );
    
    // Reload courses if a new course was created
    if (result == true) {
      _loadInstructorCourses();
    }
  }

  void _searchCourses() {
    // TODO: Implement search functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Courses'),
        content: const Text('Search functionality would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'instructor',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
        appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: _onBackPressed, // FIXED: Use the new handler
        ),
        title: Text(
          'My Courses',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.archive, color: Theme.of(context).colorScheme.onBackground),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArchivedCoursesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground),
            onPressed: _searchCourses,
          ),
        ],
      ),
      body: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInstructorCourses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Welcome Card for Instructor
                      _buildWelcomeCard(),
                      const SizedBox(height: 16),
                      // Courses List
                      if (_firebaseCourses.isEmpty)
                        _buildEmptyState()
                      else
                        ..._firebaseCourses.map((course) => _buildFirebaseCourseCard(course)),
                    ],
                  ),
                ),
              ),
            ),
        floatingActionButton: _buildCustomFloatingActionButton(),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
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
            _isLoadingName ? 'Welcome back! 👋' : 'Welcome back, $_instructorName! 👋',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are teaching ${_firebaseCourses.length} course${_firebaseCourses.length == 1 ? '' : 's'} this semester',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFloatingActionButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Courses Yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first course',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseCourseCard(Map<String, dynamic> courseData) {
    // Get category or use default
    final categoryId = courseData['category'] as String?;
    final category = CourseCategories.tryGetById(categoryId) ?? CourseCategories.computerScience;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstructorCourseDetailScreen(courseData: courseData),
          ),
        );
        if (result == true) {
          _loadInstructorCourses();
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
                      courseData['title'] ?? 'Untitled Course',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${courseData['otp'] ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
