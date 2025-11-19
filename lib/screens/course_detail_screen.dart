import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/course_model.dart';
import 'popup_question_screen.dart';
import 'quiz_screen.dart';
import '../utils/theme_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  // Mock data for notifications
  final List<Map<String, String>> _notifications = [
    {
      'title': 'Lecture 7 has been uploaded.',
      'time': '3/10 11:00 PM',
      'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F95f43002-a4f9-46d0-b34f-6240401cf2a9.png',
    },
    {
      'title': 'Assignment 3 has been uploaded.',
      'time': '5/10 10:00 AM',
      'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fde7fb90a-a5aa-424f-9c3a-7c1ba7596fa1.png',
    },
    {
      'title': 'Quiz 2 has been scheduled',
      'time': '2/10 9:30 AM',
      'icon': 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F676369d5-b87f-44a2-98cd-257f75320b56.png',
    },
  ];

  // Status for activities
  bool _popupQuestionAvailable = false;
  bool _quizAvailable = true;

  @override
  void initState() {
    super.initState();
    // Simulate checking activity status
    _checkActivityStatus();
  }

  void _checkActivityStatus() {
    // Make pop-up question available only for Introduction to Programming
    setState(() {
      _popupQuestionAvailable = widget.course.name == 'Introduction to Programming';
      _quizAvailable = true; // Quiz is ongoing for all courses
    });
  }

  void _joinPopupQuestion() {
    if (_popupQuestionAvailable) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PopupQuestionScreen(courseName: widget.course.name),
        ),
      );
    }
  }

  void _joinQuiz() {
    if (_quizAvailable) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizScreen()),
      );
    }
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
          widget.course.name,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Course Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.course.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course.instructor,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Latest Notifications
            _buildNotificationsSection(),

            const SizedBox(height: 24),

            // Activities Section
            _buildActivitiesSection(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0x0C000000), // THEME: Adaptive shadow
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Notifications',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications from LMS',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _notifications.map((notification) => _buildNotificationItem(notification)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, String> notification) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            notification['icon']!,
            width: 19,
            height: 19,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title']!,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['time']!,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0x0C000000), // THEME: Adaptive shadow
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pop-Up Question Section
          Text(
            'Pop-Up Question',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Status: ',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Text(
                  _popupQuestionAvailable ? 'Ongoing' : 'Unavailable',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
                )
              ],
              gradient: _popupQuestionAvailable
                  ? themeProvider.gradient // THEME: Dynamic gradient
                  : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _popupQuestionAvailable ? _joinPopupQuestion : null,
                child: Center(
                  child: Text(
                    'Answer Question',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quiz Section
          Text(
            'Quiz',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Status: ',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Text(
                  _quizAvailable ? 'Ongoing' : 'Unavailable',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
                )
              ],
              gradient: _quizAvailable
                  ? themeProvider.gradient // THEME: Dynamic gradient
                  : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _quizAvailable ? _joinQuiz : null,
                child: Center(
                  child: Text(
                    'Join Quiz',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}