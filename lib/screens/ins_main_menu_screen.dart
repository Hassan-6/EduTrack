import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import '../services/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../utils/calendar_event.dart';

class InstructorMainMenuScreen extends StatefulWidget {
  const InstructorMainMenuScreen({Key? key}) : super(key: key);

  @override
  State<InstructorMainMenuScreen> createState() => _InstructorMainMenuScreenState();
}

class _InstructorMainMenuScreenState extends State<InstructorMainMenuScreen> {
  int _currentBottomNavIndex = 0; // Home is active
  String _instructorName = 'Instructor';
  bool _isLoadingName = true;
  List<Task> _todaysTasks = [];
  CalendarEvent? _nextDeadline;
  bool _isLoadingTasks = true;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadInstructorName();
    _loadTodaysTasks();
    _loadUpcomingEvents();
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

  Future<void> _loadTodaysTasks() async {
    try {
      final today = DateTime.now();

      // Get both pending and completed tasks
      final allPendingTasks = await TaskService.getPendingTasks();
      final allCompletedTasks = await TaskService.getCompletedTasks();

      // Filter pending tasks for today
      final todaysPendingTasks = allPendingTasks
          .where(
            (task) =>
                task.dueDate.year == today.year &&
                task.dueDate.month == today.month &&
                task.dueDate.day == today.day,
          )
          .toList();

      // Filter completed tasks for today
      final todaysCompletedTasks = allCompletedTasks
          .where(
            (task) =>
                task.dueDate.year == today.year &&
                task.dueDate.month == today.month &&
                task.dueDate.day == today.day,
          )
          .toList();

      // Combine both lists
      final allTodaysTasks = [...todaysPendingTasks, ...todaysCompletedTasks];

      // Sort by due date (completed tasks will appear after pending ones if same time)
      allTodaysTasks.sort((a, b) {
        final dateCompare = a.dueDate.compareTo(b.dueDate);
        if (dateCompare != 0) return dateCompare;
        // If same date, pending tasks come first
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return 0;
      });

      setState(() {
        _todaysTasks = allTodaysTasks.take(3).toList();
        _isLoadingTasks = false;
      });
    } catch (e) {
      print('Error loading today\'s tasks: $e');
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoadingEvents = false);
        return;
      }

      // Get start of today to include all events from today onwards
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calendar_events')
          .where('date', isGreaterThanOrEqualTo: startOfToday)
          .orderBy('date', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        _nextDeadline = CalendarEvent(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          startTime: data['startTime'] ?? '',
          endTime: data['endTime'] ?? '',
          type: _parseEventType(data['type'] ?? 'event'),
          color: _getColorForType(_parseEventType(data['type'] ?? 'event')),
        );
      }

      setState(() => _isLoadingEvents = false);
    } catch (e) {
      print('Error loading upcoming events: $e');
      setState(() => _isLoadingEvents = false);
    }
  }

  EventType _parseEventType(String type) {
    switch (type) {
      case 'assignment':
        return EventType.assignment;
      case 'exam':
        return EventType.exam;
      case 'event':
      default:
        return EventType.event;
    }
  }

  Color _getColorForType(EventType type) {
    switch (type) {
      case EventType.assignment:
        return const Color(0xFF4E9FEC);
      case EventType.event:
        return const Color(0xFF5CD6C0);
      case EventType.exam:
        return const Color(0xFFFB923C);
    }
  }

  void _toggleTaskCompletion(Task task) async {
    try {
      if (task.isCompleted) {
        await TaskService.uncompleteTask(task.id);
      } else {
        await TaskService.completeTask(task.id);
      }
      await _loadTodaysTasks();
    } catch (e) {
      print('Error toggling task: $e');
    }
  }

  void _navigateToFeature(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;
    
    setState(() {
      _currentBottomNavIndex = index;
    });

    // Navigate based on index - clear stack and only keep main menu
    switch (index) {
      case 0:
        // Already on Main Menu
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getToDoListRoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getQnARoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getProfileRoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
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
        color: Theme.of(context).cardColor, // THEME: Dynamic app bar color
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.05),
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
                  color: Theme.of(context).colorScheme.onBackground,
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
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's your day at a glance",
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.05),
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
              color: Theme.of(context).colorScheme.onBackground,
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
            color: Theme.of(context).colorScheme.onBackground,
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
    if (_isLoadingEvents) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_nextDeadline == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF000000).withOpacity(0.05),
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
              'Next Deadline',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming events',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.05),
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
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _nextDeadline!.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  _nextDeadline!.type.toString().split('.').last.toUpperCase(),
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
                  color: _nextDeadline!.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getEventIcon(_nextDeadline!.type),
                    color: _nextDeadline!.color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nextDeadline!.title,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      'Due: ${_formatEventDate(_nextDeadline!.date)}',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.assignment:
        return Icons.assignment;
      case EventType.event:
        return Icons.event;
      case EventType.exam:
        return Icons.quiz;
    }
  }

  String _formatEventDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  Widget _buildTodaysTasksCard() {
    if (_isLoadingTasks) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.05),
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
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          if (_todaysTasks.isEmpty)
            Text(
              'No tasks for today',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            )
          else
            ..._todaysTasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _toggleTaskCompletion(task),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? const Color(0xFF0075FF)
                              : Colors.white,
                          border: Border.all(
                            color: task.isCompleted
                                ? const Color(0xFF0075FF)
                                : Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: task.isCompleted
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          task.title,
                          style: GoogleFonts.inter(
                            color: task.isCompleted
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : Theme.of(context).colorScheme.onBackground,
                            fontSize: 16,
                            height: 1.5,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}