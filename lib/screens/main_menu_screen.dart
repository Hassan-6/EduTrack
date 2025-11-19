import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import '../services/auth_provider.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentBottomNavIndex = 0;
  bool _mathTaskCompleted = false;
  bool _physicsTaskCompleted = true;

  void _toggleMathTask() {
    setState(() {
      _mathTaskCompleted = !_mathTaskCompleted;
    });
  }

  void _togglePhysicsTask() {
    setState(() {
      _physicsTaskCompleted = !_physicsTaskCompleted;
    });
  }

  void _navigateToFeature(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

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
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildWelcomeSection(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildFeaturesGrid(),
                    const SizedBox(height: 25),
                    _buildTodaysSnapshot(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        color: Theme.of(context).cardColor, // THEME: Dynamic app bar color
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0xFF000000).withOpacity(0.05), // THEME: Adaptive shadow
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F94CD), // Keep brand color
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
                'EduTrack',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
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
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Text(
                'Hi, ${authProvider.userName}! 👋',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            "Here's your day at a glance",
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic secondary text
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
        'color': const Color(0xFFE6F3FF), // Keep feature colors
        'route': '/notes',
      },
      {
        'title': 'To-Do List',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Feb4185c7-6b7b-4655-a8a4-c18bbf6b2520.png',
        'color': const Color(0xFFF0FFF0),
        'route': '/todo',
      },
      {
        'title': 'Courses',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fe357d2f1-c334-46a4-970e-fac1d37fe64b.png',
        'color': const Color(0xFFFEFCE8),
        'route': '/courses',
      },
      {
        'title': 'Calendar',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F388c7b56-7041-47f9-bc75-0b9fbf910d91.png',
        'color': const Color(0xFFFFF7ED),
        'route': '/calendar',
      },
      {
        'title': 'Q&A Wall',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fb7649f80-53f7-4a54-ba07-fa4c184b6743.png',
        'color': const Color(0xFFFAF5FF),
        'route': '/qna',
      },
      {
        'title': 'Attendance',
        'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fc76bcdbc-bd72-40b6-84ef-df4fda96988f.png',
        'color': const Color(0xFFEEF2FF),
        'route': '/attendance',
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
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0xFF000000).withOpacity(0.05), // THEME: Adaptive shadow
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
              color: color, // Keep feature-specific colors
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
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
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
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        _buildNextDeadlineCard(),
        const SizedBox(height: 20),
        _buildTodaysTasksCard(),
      ],
    );
  }

  Widget _buildNextDeadlineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0xFF000000).withOpacity(0.05), // THEME: Adaptive shadow
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
                'Next Deadline',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00), // Keep urgency color
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Due Tomorrow',
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
                  color: const Color(0xFFFEE2E2), // Keep icon background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fe4e92e22-3e54-4bc9-a24d-dd98d94daeb4.png',
                    width: 14,
                    height: 16,
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
                      'Chemistry Lab Report',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      'Due: Oct 2, 11:59 PM',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic secondary text
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
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0xFF000000).withOpacity(0.05), // THEME: Adaptive shadow
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
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          GestureDetector(
            onTap: _toggleMathTask,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _mathTaskCompleted ? const Color(0xFF0075FF) : Theme.of(context).cardColor, // THEME: Adaptive checkbox
                    border: Border.all(
                      color: _mathTaskCompleted ? const Color(0xFF0075FF) : Theme.of(context).dividerColor, // THEME: Adaptive border
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: _mathTaskCompleted 
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
                  'Review Math Chapter 5',
                  style: GoogleFonts.inter(
                    color: _mathTaskCompleted 
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) // THEME: Dynamic completed text
                        : Theme.of(context).colorScheme.onBackground, // THEME: Dynamic active text
                    fontSize: 16,
                    height: 1.5,
                    decoration: _mathTaskCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _togglePhysicsTask,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _physicsTaskCompleted ? const Color(0xFF0075FF) : Theme.of(context).cardColor, // THEME: Adaptive checkbox
                    border: Border.all(
                      color: _physicsTaskCompleted ? const Color(0xFF0075FF) : Theme.of(context).dividerColor, // THEME: Adaptive border
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: _physicsTaskCompleted 
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
                  'Submit Physics homework',
                  style: GoogleFonts.inter(
                    color: _physicsTaskCompleted 
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) // THEME: Dynamic completed text
                        : Theme.of(context).colorScheme.onBackground, // THEME: Dynamic active text
                    fontSize: 16,
                    height: 1.5,
                    decoration: _physicsTaskCompleted ? TextDecoration.lineThrough : null,
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