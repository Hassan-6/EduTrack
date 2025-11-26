import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../widgets/course_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';

class QuizResultsScreen extends StatefulWidget {
  final Course course;
  final String quizId;
  final Map<String, dynamic> quizData;

  const QuizResultsScreen({
    super.key,
    required this.course,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  Map<String, dynamic>? _quizResults;
  bool _isLoading = true;
  bool _isActive = true; // Track if quiz is still active
  bool _isInstructor = false; // Track if user is instructor
  String? _currentUserId; // Current user's ID

  @override
  void initState() {
    super.initState();
    // Check if user is instructor
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isInstructor = authProvider.userType == 'instructor';
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await FirebaseService.getQuizResults(
        courseId: widget.course.id,
        quizId: widget.quizId,
      );
      setState(() {
        _quizResults = results;
        _isActive = results['isActive'] == true; // Check if quiz is still active
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quiz results: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markShortQuestionAnswer({
    required String studentId,
    required int questionIndex,
    required bool isCorrect,
  }) async {
    try {
      await FirebaseService.updateQuizShortQuestionGrade(
        courseId: widget.course.id,
        quizId: widget.quizId,
        studentId: studentId,
        questionIndex: questionIndex,
        isCorrect: isCorrect,
      );
      // Reload results to show updated grades
      await _loadResults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCorrect ? 'Marked as correct' : 'Marked as incorrect'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating grade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quizData['questions'] as List<dynamic>? ?? [];
    final allSubmissions = _quizResults?['enrichedSubmissions'] as Map<String, dynamic>? ?? {};
    
    // Filter submissions: show only current student's submission for students, all for instructors
    final enrichedSubmissions = _isInstructor 
        ? allSubmissions 
        : (_currentUserId != null && allSubmissions.containsKey(_currentUserId))
            ? {_currentUserId!: allSubmissions[_currentUserId!]}
            : {};

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quiz Results',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz Header
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
                          widget.quizData['title'] ?? 'Untitled Quiz',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isInstructor
                              ? '${questions.length} Questions • ${enrichedSubmissions.length} Submissions'
                              : '${questions.length} Questions • Your Submission',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student Submissions
                  if (enrichedSubmissions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No submissions yet',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...enrichedSubmissions.entries.map((entry) {
                      return _buildStudentSubmission(
                        studentId: entry.key,
                        submission: entry.value,
                        questions: questions,
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentSubmission({
    required String studentId,
    required Map<String, dynamic> submission,
    required List<dynamic> questions,
  }) {
    final studentName = submission['studentName'] ?? 'Unknown';
    final rollNumber = submission['studentRollNumber'] ?? 'N/A';
    final answers = submission['answers'] as Map<String, dynamic>? ?? {};
    final score = submission['score'] ?? 0;
    final totalQuestions = submission['totalQuestions'] ?? questions.length;
    final percentage = submission['percentage'] ?? 0;
    final shortQuestionGrades = submission['shortQuestionGrades'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
        borderRadius: BorderRadius.circular(12),
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
          // Student Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll Number: $rollNumber',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: percentage >= 70
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade900.withOpacity(0.5)
                          : Colors.green.shade100
                      : percentage >= 50
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.shade900.withOpacity(0.5)
                              : Colors.orange.shade100
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900.withOpacity(0.5)
                              : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score/$totalQuestions ($percentage%)',
                  style: GoogleFonts.inter(
                    color: percentage >= 70
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade300
                            : Colors.green.shade700
                        : percentage >= 50
                            ? Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange.shade300
                                : Colors.orange.shade700
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Answers
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value as Map<String, dynamic>;
            final questionType = question['questionType'] as String? ?? 'MCQ';
            final answer = answers[index.toString()];
            final isShortQuestion = questionType != 'MCQ';

            return _buildQuestionAnswer(
              questionIndex: index,
              question: question,
              answer: answer,
              isShortQuestion: isShortQuestion,
              studentId: studentId,
              shortQuestionGrades: shortQuestionGrades,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswer({
    required int questionIndex,
    required Map<String, dynamic> question,
    required dynamic answer,
    required bool isShortQuestion,
    required String studentId,
    required Map<String, dynamic> shortQuestionGrades,
  }) {
    final questionText = question['question'] ?? 'Question ${questionIndex + 1}';
    final options = question['options'] as List<dynamic>? ?? [];
    final correctAnswerIndex = question['correctAnswerIndex'] as int?;

    // Check if short question is already graded
    final gradeKey = '$questionIndex';
    final isGraded = shortQuestionGrades.containsKey(gradeKey);
    final isCorrect = shortQuestionGrades[gradeKey] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !_isActive
              ? (isShortQuestion
                  ? (isGraded
                      ? (isCorrect ? Colors.green.shade300 : Colors.red.shade300)
                      : Colors.orange.shade300)
                  : (answer == correctAnswerIndex
                      ? Colors.green.shade300
                      : Colors.red.shade300))
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E9FEC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${questionIndex + 1}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isShortQuestion && !_isActive)
                Icon(
                  answer == correctAnswerIndex ? Icons.check_circle : Icons.cancel,
                  color: answer == correctAnswerIndex ? Colors.green : Colors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isShortQuestion)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer:',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    answer?.toString() ?? 'No answer',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!isGraded)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markShortQuestionAnswer(
                            studentId: studentId,
                            questionIndex: questionIndex,
                            isCorrect: true,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Correct'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markShortQuestionAnswer(
                            studentId: studentId,
                            questionIndex: questionIndex,
                            isCorrect: false,
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Incorrect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCorrect 
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.green.shade900.withOpacity(0.5)
                              : Colors.green.shade100
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900.withOpacity(0.5)
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect 
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.shade300
                                  : Colors.green.shade700
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300
                                  : Colors.red.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Marked as Correct' : 'Marked as Incorrect',
                          style: GoogleFonts.inter(
                            color: isCorrect 
                                ? Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...options.asMap().entries.map((optionEntry) {
                  final optIndex = optionEntry.key;
                  final option = optionEntry.value.toString();
                  final isSelected = answer == optIndex;
                  // Only show correct answer if quiz is ended
                  final isCorrectOption = !_isActive && optIndex == correctAnswerIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected && !_isActive
                          ? (isCorrectOption 
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.shade900.withOpacity(0.3)
                                  : Colors.green.shade50
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade900.withOpacity(0.3)
                                  : Colors.red.shade50)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected && !_isActive
                            ? (isCorrectOption ? Colors.green : Colors.red)
                            : Theme.of(context).dividerColor,
                        width: isSelected && !_isActive ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!_isActive)
                          Icon(
                            isSelected
                                ? (isCorrectOption ? Icons.check_circle : Icons.cancel)
                                : (isCorrectOption ? Icons.radio_button_unchecked : null),
                            color: isSelected
                                ? (isCorrectOption ? Colors.green : Colors.red)
                                : (isCorrectOption ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.transparent),
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${String.fromCharCode(65 + optIndex)}. $option',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCorrectOption && !isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.shade900.withOpacity(0.5)
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Correct Answer',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

