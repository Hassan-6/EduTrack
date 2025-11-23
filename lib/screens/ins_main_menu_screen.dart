import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import '../services/auth_provider.dart';
import '../services/firebase_service.dart';

class InstructorMainMenuScreen extends StatefulWidget {
  const InstructorMainMenuScreen({Key? key}) : super(key: key);

  @override
  State<InstructorMainMenuScreen> createState() => _InstructorMainMenuScreenState();
}

class _InstructorMainMenuScreenState extends State<InstructorMainMenuScreen> {
  int _currentBottomNavIndex = 0; // Home is active
  bool _gradeAssignmentsCompleted = false;
  bool _prepareLectureCompleted = true;
  String _instructorName = 'Instructor';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadInstructorName();
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

  void _toggleGradeAssignments() {
    setState(() {
      _gradeAssignmentsCompleted = !_gradeAssignmentsCompleted;
    });
  }

  void _togglePrepareLecture() {
    setState(() {
      _prepareLectureCompleted = !_prepareLectureCompleted;
    });
  }

  void _navigateToFeature(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    // FIXED: Use RouteManager for navigation
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
        break;
      case 1:
        Navigator.pushReplacementNamed(context, RouteManager.getToDoListRoute());
        break;
      case 2:
        Navigator.pushReplacementNamed(context, RouteManager.getQnARoute());
        break;
      case 3:
        Navigator.pushReplacementNamed(context, RouteManager.getProfileRoute());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Welcome Section
            _buildWelcomeSection(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Features Grid
                    _buildFeaturesGrid(),
                    
                    const SizedBox(height: 25),
                    
                    // Today's Snapshot Section
                    _buildTodaysSnapshot(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar - same as student version
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo and App Name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F94CD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F2a86c877-e3e7-4883-86b9-dac1aa653058.png',
                    width: 23,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'EduTrack - Instructor',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            _isLoadingName ? 'Good Morning! 👋' : 'Good Morning, $_instructorName! 👋',
            style: GoogleFonts.inter(
              color: const Color(0xFF374151),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's your day at a glance",
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'title': 'Notes & Journal',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fa78f3f55-c0e0-4539-991d-09a5001f461c.png',
        'color': const Color(0xFFE6F3FF),
        'route': '/notes', // Same as student
      },
      {
        'title': 'To-Do List',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Feb4185c7-6b7b-4655-a8a4-c18bbf6b2520.png',
        'color': const Color(0xFFF0FFF0),
        'route': '/todo', // Same as student
      },
      {
        'title': 'Courses',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fe357d2f1-c334-46a4-970e-fac1d37fe64b.png',
        'color': const Color(0xFFFEFCE8),
        'route': '/ins_courses', // Different route for instructor
      },
      {
        'title': 'Calendar',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F388c7b56-7041-47f9-bc75-0b9fbf910d91.png',
        'color': const Color(0xFFFFF7ED),
        'route': '/calendar', // Same as student
      },
      {
        'title': 'Q&A Wall',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fb7649f80-53f7-4a54-ba07-fa4c184b6743.png',
        'color': const Color(0xFFFAF5FF),
        'route': '/qna', // Same as student
      },
      {
        'title': 'Attendance',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fc76bcdbc-bd72-40b6-84ef-df4fda96988f.png',
        'color': const Color(0xFFEEF2FF),
        'route': '/ins_attendance', // Changed to instructor attendance
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 156 / 108,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return GestureDetector(
          onTap: () => _navigateToFeature(feature['route'] as String),
          child: _buildFeatureCard(
            title: feature['title'] as String,
            iconUrl: feature['icon'] as String,
            color: feature['color'] as Color,
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String iconUrl,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.network(
                iconUrl,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSnapshot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Snapshot",
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        
        // Next Deadline Card
        _buildNextDeadlineCard(),
        
        const SizedBox(height: 20),
        
        // Today's Tasks Card
        _buildTodaysTasksCard(),
      ],
    );
  }

  Widget _buildNextDeadlineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Classes',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Today',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fe357d2f1-c334-46a4-970e-fac1d37fe64b.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Structures - CS201',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      '10:00 AM - 11:30 AM | Room A-101',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysTasksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
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
            "Today's Tasks",
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Task 1 - Toggleable
          GestureDetector(
            onTap: _toggleGradeAssignments,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _gradeAssignmentsCompleted ? const Color(0xFF0075FF) : Colors.white,
                    border: Border.all(width: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: _gradeAssignmentsCompleted 
                      ? Center(
                          child: Image.network(
                            'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fa1d68ca4-7c8e-4934-9723-cf81ef0358f4.png',
                            width: 13,
                            height: 11,
                            fit: BoxFit.contain,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 11),
                Text(
                  'Grade CS201 Assignments',
                  style: GoogleFonts.inter(
                    color: _gradeAssignmentsCompleted ? const Color(0xFF6B7280) : const Color(0xFF374151),
                    fontSize: 16,
                    height: 1.5,
                    decoration: _gradeAssignmentsCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Task 2 - Toggleable
          GestureDetector(
            onTap: _togglePrepareLecture,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _prepareLectureCompleted ? const Color(0xFF0075FF) : Colors.white,
                    border: Border.all(width: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: _prepareLectureCompleted 
                      ? Center(
                          child: Image.network(
                            'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fa1d68ca4-7c8e-4934-9723-cf81ef0358f4.png',
                            width: 13,
                            height: 11,
                            fit: BoxFit.contain,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 11),
                Text(
                  'Prepare CS301 Lecture',
                  style: GoogleFonts.inter(
                    color: _prepareLectureCompleted ? const Color(0xFF6B7280) : const Color(0xFF374151),
                    fontSize: 16,
                    height: 1.5,
                    decoration: _prepareLectureCompleted ? TextDecoration.lineThrough : null,
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