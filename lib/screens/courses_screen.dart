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
import 'archived_courses_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name'; // name, category, date

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
        _filteredCourses = courses;
        _isLoading = false;
      });
      _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    setState(() {
      // Filter by search query and category
      _filteredCourses = _courses.where((course) {
        final courseName = course.name.toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        // Get category name from the course's gradient/icon
        String categoryName = '';
        for (var category in CourseCategories.all) {
          if (category.primaryColor == course.color) {
            categoryName = category.name;
            break;
          }
        }
        
        // If search query is empty, only filter by category
        final titleMatch = query.isEmpty || courseName.contains(query);
        final categoryMatch = _selectedCategory == 'All' || categoryName == _selectedCategory;
        
        return titleMatch && categoryMatch;
      }).toList();
      
      // Sort courses
      _filteredCourses.sort((a, b) {
        switch (_sortBy) {
          case 'name':
            return a.name.compareTo(b.name);
          case 'category':
            // Compare by color as a proxy for category
            return a.color.value.compareTo(b.color.value);
          case 'date':
            // For students, this would be join date - using reverse order (most recent first)
            // Since we don't have join date in Course model, we'll maintain current order
            return _courses.indexOf(b).compareTo(_courses.indexOf(a));
          default:
            return 0;
        }
      });
    });
  }
  
  void _showSearchDialog() {
    final searchController = TextEditingController(text: _searchQuery);
    String searchCategory = _selectedCategory;
    
    // Get list of categories from existing courses
    final categoriesInUse = <String>{'All'};
    for (var course in _courses) {
      for (var category in CourseCategories.all) {
        if (category.primaryColor == course.color) {
          categoriesInUse.add(category.name);
          break;
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Search Courses',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by title...',
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: searchCategory,
                isExpanded: true,
                items: categoriesInUse.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      searchCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = searchController.text;
                  _selectedCategory = searchCategory;
                });
                _applyFiltersAndSort();
              },
              child: Text(
                'Search',
                style: GoogleFonts.inter(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Sort Courses',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Name', 'name'),
            _buildSortOption('Category', 'category'),
            _buildSortOption('Joined Date', 'date'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      value: value,
      groupValue: _sortBy,
      onChanged: (newValue) {
        setState(() {
          _sortBy = newValue!;
        });
        _applyFiltersAndSort();
        Navigator.pop(context);
      },
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
            icon: Icon(Icons.archive, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
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
            icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: _showSearchDialog,
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
              ? _buildEmptyState()
              : _filteredCourses.isEmpty
                  ? _buildNoResultsState()
                  : RefreshIndicator(
                      onRefresh: _loadEnrolledCourses,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Search info banner
                              if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Showing ${_filteredCourses.length} of ${_courses.length} courses',
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              // Courses List
                              ..._filteredCourses.map((course) => _buildCourseCard(course)),
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
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
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
    );
  }
  
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Courses Found',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
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