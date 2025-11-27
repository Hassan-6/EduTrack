import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/course_model.dart';
import 'popup_question_screen.dart';
import 'quiz_screen.dart';
import 'question_results_screen.dart';
import 'quiz_results_screen.dart';
import '../utils/theme_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/profile_avatar.dart';
import 'profile_screen.dart';
import 'profile_viewer_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  // Course info data
  Map<String, dynamic>? _courseData;
  List<Map<String, dynamic>> _enrolledStudents = [];
  bool _isLoadingCourseInfo = true;

  // Status for activities
  bool _popupQuestionAvailable = false;
  bool _quizAvailable = false;
  Map<String, dynamic>? _activePopupQuestion;
  Map<String, dynamic>? _activeQuiz;
  bool _isLoadingActivities = true;
  bool _hasSubmittedPopupQuestion = false;
  bool _hasSubmittedQuiz = false;
  
  // History
  List<Map<String, dynamic>> _popupQuestionsHistory = [];
  List<Map<String, dynamic>> _quizzesHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _checkActivityStatus();
    _loadHistory();
    _loadCourseInfo();
  }

  Future<void> _loadCourseInfo() async {
    setState(() => _isLoadingCourseInfo = true);
    try {
      // Load course data
      final courseData = await FirebaseService.getCourseById(widget.course.id);
      setState(() => _courseData = courseData);
      
      // Load enrolled students
      List<Map<String, dynamic>> students =
          await FirebaseService.getEnrolledStudents(widget.course.id);

      // If the course document's enrolledStudents array is empty or returned
      // results look incomplete (for example only the current user), try a
      // fallback that queries the `users` collection for users who list the
      // course in their `enrolledCourses` field.
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (students.isEmpty || (students.length == 1 && currentUserId != null && students.any((s) => s['id'] == currentUserId))) {
        final fallback = await FirebaseService.getUsersEnrolledInCourse(widget.course.id);
        if (fallback.isNotEmpty) {
          students = fallback;
        }
      }

      setState(() => _enrolledStudents = students);
    } catch (e) {
      print('Error loading course info: $e');
    } finally {
      setState(() => _isLoadingCourseInfo = false);
    }
  }

  Future<void> _checkActivityStatus() async {
    setState(() => _isLoadingActivities = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoadingActivities = false);
      return;
    }
    
    // Check if there are active pop-up questions and quizzes for this course
    try {
      // Check for active pop-up questions
      final popupQuestions = await FirebaseService.getCoursePopupQuestions(widget.course.id);
      final activePopups = popupQuestions.where((q) => q['isActive'] == true).toList();
      
      // Check if student has already submitted to active popup question
      bool hasSubmittedPopup = false;
      if (activePopups.isNotEmpty) {
        final activePopup = activePopups.first;
        final responses = activePopup['responses'] as Map<String, dynamic>? ?? {};
        hasSubmittedPopup = responses.containsKey(userId);
      }
      
      // Check for active quizzes
      final quizzes = await FirebaseService.getCourseQuizzes(widget.course.id);
      
      // Update quiz statuses based on schedule before checking
      for (var quiz in quizzes) {
        await FirebaseService.updateQuizStatus(
          courseId: widget.course.id,
          quizId: quiz['id'],
          quizData: quiz,
        );
      }
      
      // Fetch updated quiz list after status updates
      final updatedQuizzes = await FirebaseService.getCourseQuizzes(widget.course.id);
      final activeQuizzes = updatedQuizzes.where((q) => q['isActive'] == true).toList();
      
      // Check if student has already submitted to active quiz
      bool hasSubmittedQuiz = false;
      if (activeQuizzes.isNotEmpty) {
        final activeQuiz = activeQuizzes.first;
        final submissions = activeQuiz['submissions'] as Map<String, dynamic>? ?? {};
        hasSubmittedQuiz = submissions.containsKey(userId);
      }
      
      setState(() {
        _popupQuestionAvailable = activePopups.isNotEmpty && !hasSubmittedPopup;
        _quizAvailable = activeQuizzes.isNotEmpty && !hasSubmittedQuiz;
        _activePopupQuestion = activePopups.isNotEmpty ? activePopups.first : null;
        _activeQuiz = activeQuizzes.isNotEmpty ? activeQuizzes.first : null;
        _hasSubmittedPopupQuestion = hasSubmittedPopup;
        _hasSubmittedQuiz = hasSubmittedQuiz;
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error checking activity status: $e');
      setState(() {
        _popupQuestionAvailable = false;
        _quizAvailable = false;
        _activePopupQuestion = null;
        _activeQuiz = null;
        _isLoadingActivities = false;
      });
    }
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final questions = await FirebaseService.getCoursePopupQuestions(widget.course.id);
      final quizzes = await FirebaseService.getCourseQuizzes(widget.course.id);
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      // Filter to only show questions/quizzes the student has submitted to
      final studentQuestions = questions.where((q) {
        final responses = q['responses'] as Map<String, dynamic>? ?? {};
        return userId != null && responses.containsKey(userId);
      }).toList();
      
      final studentQuizzes = quizzes.where((q) {
        final submissions = q['submissions'] as Map<String, dynamic>? ?? {};
        return userId != null && submissions.containsKey(userId);
      }).toList();
      
      setState(() {
        _popupQuestionsHistory = studentQuestions;
        _quizzesHistory = studentQuizzes;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  void _joinPopupQuestion() {
    if (_popupQuestionAvailable && _activePopupQuestion != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PopupQuestionScreen(
            course: widget.course,
            questionId: _activePopupQuestion!['id'],
            question: _activePopupQuestion!,
          ),
        ),
      ).then((_) {
        // Refresh activity status and history after returning
        _checkActivityStatus();
        _loadHistory();
      });
    }
  }

  void _joinQuiz() {
    if (_quizAvailable && _activeQuiz != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            course: widget.course,
            quizId: _activeQuiz!['id'],
            quiz: _activeQuiz!,
          ),
        ),
      ).then((_) {
        // Refresh activity status and history after returning
        _checkActivityStatus();
        _loadHistory();
      });
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
                  GestureDetector(
                    onTap: () async {
                      if (_courseData != null && _courseData!['instructorId'] != null) {
                        try {
                          final instructorProfile = await FirebaseService.getUserProfile(_courseData!['instructorId']);
                          if (instructorProfile != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileViewerScreen(
                                  userProfile: UserProfile(
                                    name: instructorProfile['name'] ?? widget.course.instructor,
                                    username: '@${(instructorProfile['name'] ?? '').replaceAll(' ', '.').toLowerCase()}',
                                    major: instructorProfile['major'] ?? 'Not specified',
                                    age: instructorProfile['age'] ?? '',
                                    rollNumber: instructorProfile['rollNumber'] ?? '',
                                    phoneNumber: instructorProfile['phoneNumber'] ?? '',
                                    email: instructorProfile['email'] ?? '',
                                    semester: instructorProfile['semester'] ?? 'Not specified',
                                    cgpa: instructorProfile['cgpa'] ?? 'N/A',
                                    profileIconIndex: instructorProfile['profileIconIndex'] ?? 0,
                                  ),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error loading instructor profile: $e');
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.course.instructor,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Course Info Section
            _buildCourseInfoSection(),

            const SizedBox(height: 24),

            // Activities Section
            _buildActivitiesSection(themeProvider),
            
            const SizedBox(height: 24),
            
            // History Section
            _buildHistorySection(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfoSection() {
    if (_isLoadingCourseInfo) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.3) 
                    : const Color(0x0C000000),
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
                'Course Description',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _courseData?['description'] ?? 'No description available',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Enrolled Students
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.3) 
                    : const Color(0x0C000000),
                spreadRadius: 0,
                offset: const Offset(0, 1),
                blurRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrolled Students',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_enrolledStudents.length}',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_enrolledStudents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No students enrolled yet',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...(_enrolledStudents.take(10).map((student) => _buildStudentListItem(student)).toList()),
              if (_enrolledStudents.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'And ${_enrolledStudents.length - 10} more...',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentListItem(Map<String, dynamic> student) {
    final name = student['name'] ?? 'Unknown';
    final rollNumber = student['rollNumber'] ?? 'N/A';
    final profileIconIndex = student['profileIconIndex'] ?? 0;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileViewerScreen(
              userProfile: UserProfile(
                name: name,
                username: '@${rollNumber.toLowerCase()}',
                major: student['major'] ?? 'Not specified',
                age: student['age'] ?? '',
                rollNumber: rollNumber,
                phoneNumber: student['phoneNumber'] ?? '',
                email: student['email'] ?? '',
                semester: student['semester'] ?? 'Not specified',
                cgpa: student['cgpa'] ?? 'N/A',
                profileIconIndex: profileIconIndex,
              ),
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            iconIndex: profileIconIndex ?? 0,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rollNumber,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  _hasSubmittedPopupQuestion 
                      ? 'Already Answered' 
                      : _popupQuestionAvailable 
                          ? 'Ongoing' 
                          : 'Unavailable',
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
          if (_isLoadingActivities)
            const Center(child: CircularProgressIndicator())
          else
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
                gradient: _popupQuestionAvailable && !_hasSubmittedPopupQuestion
                    ? themeProvider.gradient // THEME: Dynamic gradient
                    : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _popupQuestionAvailable && !_hasSubmittedPopupQuestion ? _joinPopupQuestion : null,
                  child: Center(
                    child: Text(
                      _hasSubmittedPopupQuestion ? 'Already Answered' : 'Answer Question',
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
                  _hasSubmittedQuiz 
                      ? 'Already Taken' 
                      : _quizAvailable 
                          ? 'Ongoing' 
                          : 'Unavailable',
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
          if (_isLoadingActivities)
            const Center(child: CircularProgressIndicator())
          else
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
                gradient: _quizAvailable && !_hasSubmittedQuiz
                    ? themeProvider.gradient // THEME: Dynamic gradient
                    : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _quizAvailable && !_hasSubmittedQuiz ? _joinQuiz : null,
                  child: Center(
                    child: Text(
                      _hasSubmittedQuiz ? 'Already Taken' : 'Join Quiz',
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
  
  Widget _buildHistorySection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0x0C000000),
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
            'My History',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingHistory)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (_popupQuestionsHistory.isEmpty && _quizzesHistory.isEmpty)
            Text(
              'No history yet',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            )
          else ...[
            // Popup Questions History
            if (_popupQuestionsHistory.isNotEmpty) ...[
              Text(
                'Pop-Up Questions',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ..._popupQuestionsHistory.map((question) => _buildHistoryItem(
                title: question['question'] ?? 'Question',
                type: 'Question',
                isActive: question['isActive'] == true,
                onTap: () {
                  final course = Course(
                    id: widget.course.id,
                    name: widget.course.name,
                    instructor: widget.course.instructor,
                    color: widget.course.color,
                    gradient: widget.course.gradient,
                    icon: widget.course.icon,
                    recentActivity: '',
                    timeAgo: '',
                    assignmentsDue: 0,
                    unreadMessages: 0,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionResultsScreen(
                        course: course,
                        questionId: question['id'],
                        question: question['question'] ?? '',
                        questionType: question['questionType'] ?? 'MCQ',
                        options: (question['options'] as List<dynamic>? ?? []).map((o) => o.toString()).toList(),
                        correctAnswerIndex: question['correctAnswerIndex'] ?? -1,
                      ),
                    ),
                  );
                },
              )),
              const SizedBox(height: 16),
            ],
            
            // Quizzes History
            if (_quizzesHistory.isNotEmpty) ...[
              Text(
                'Quizzes',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ..._quizzesHistory.map((quiz) => _buildHistoryItem(
                title: quiz['title'] ?? 'Quiz',
                type: 'Quiz',
                isActive: quiz['isActive'] == true,
                onTap: () {
                  final course = Course(
                    id: widget.course.id,
                    name: widget.course.name,
                    instructor: widget.course.instructor,
                    color: widget.course.color,
                    gradient: widget.course.gradient,
                    icon: widget.course.icon,
                    recentActivity: '',
                    timeAgo: '',
                    assignmentsDue: 0,
                    unreadMessages: 0,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizResultsScreen(
                        course: course,
                        quizId: quiz['id'],
                        quizData: quiz,
                      ),
                    ),
                  );
                },
              )),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildHistoryItem({
    required String title,
    required String type,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                type == 'Question' ? Icons.quiz : Icons.assignment,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade900.withOpacity(0.5)
                          : Colors.green.shade100
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Ended',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade300
                            : Colors.green.shade700
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}