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
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoadingCourses = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name'; // name, category, date

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
            _filteredCourses = courses;
            _isLoadingCourses = false;
          });
          _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    setState(() {
      // Filter by search query and category
      _filteredCourses = _firebaseCourses.where((course) {
        final title = (course['title'] ?? '').toLowerCase();
        final categoryId = course['category'] as String?;
        final category = CourseCategories.tryGetById(categoryId) ?? CourseCategories.computerScience;
        final query = _searchQuery.toLowerCase();
        
        // If search query is empty, only filter by category
        final titleMatch = query.isEmpty || title.contains(query);
        final categoryMatch = _selectedCategory == 'All' || category.name == _selectedCategory;
        
        return titleMatch && categoryMatch;
      }).toList();
      
      // Sort courses
      _filteredCourses.sort((a, b) {
        switch (_sortBy) {
          case 'name':
            return (a['title'] ?? '').compareTo(b['title'] ?? '');
          case 'category':
            final catA = CourseCategories.tryGetById(a['category'])?.name ?? '';
            final catB = CourseCategories.tryGetById(b['category'])?.name ?? '';
            return catA.compareTo(catB);
          case 'date':
            final dateA = a['createdAt'] as int? ?? 0;
            final dateB = b['createdAt'] as int? ?? 0;
            return dateB.compareTo(dateA); // Most recent first
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
    for (var course in _firebaseCourses) {
      final categoryId = course['category'] as String?;
      if (categoryId != null) {
        final category = CourseCategories.tryGetById(categoryId);
        if (category != null) {
          categoriesInUse.add(category.name);
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
            _buildSortOption('Created Date', 'date'),
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
            icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.onBackground),
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground),
            onPressed: _showSearchDialog,
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
                      else if (_filteredCourses.isEmpty)
                        _buildNoResultsState()
                      else
                        ..._filteredCourses.map((course) => _buildFirebaseCourseCard(course)),
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
            _searchQuery.isEmpty && _selectedCategory == 'All'
                ? 'You are teaching ${_firebaseCourses.length} course${_firebaseCourses.length == 1 ? '' : 's'} this semester'
                : 'Showing ${_filteredCourses.length} of ${_firebaseCourses.length} courses',
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
  
  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Courses Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
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
