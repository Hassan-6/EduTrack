import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_provider.dart';
import '../widgets/course_model.dart';
import '../services/firebase_service.dart';

class QuizScreen extends StatefulWidget {
  final Course course;
  final String quizId;
  final Map<String, dynamic> quiz;

  const QuizScreen({
    super.key,
    required this.course,
    required this.quizId,
    required this.quiz,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<dynamic> _selectedAnswers = [];
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  List<Map<String, dynamic>> _questions = [];
  final Map<int, TextEditingController> _textAnswerControllers = {};

  @override
  void initState() {
    super.initState();
    _loadQuizData();
    _checkIfAlreadySubmitted();
  }

  void _loadQuizData() {
    final questions = widget.quiz['questions'] as List<dynamic>? ?? [];
    _questions = questions.map((q) => q as Map<String, dynamic>).toList();
    _selectedAnswers = List.filled(_questions.length, null);

    // Initialize text controllers for short answer questions
    for (int i = 0; i < _questions.length; i++) {
      final questionType = _questions[i]['questionType'] as String? ?? 'MCQ';
      if (questionType != 'MCQ') {
        _textAnswerControllers[i] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    // Dispose text controllers
    for (var controller in _textAnswerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkIfAlreadySubmitted() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final submissions =
          widget.quiz['submissions'] as Map<String, dynamic>? ?? {};
      if (submissions.containsKey(userId)) {
        setState(() {
          _hasSubmitted = true;
          final submissionData =
              submissions[userId] as Map<String, dynamic>? ?? {};
          final answers =
              submissionData['answers'] as Map<String, dynamic>? ?? {};
          for (var entry in answers.entries) {
            final index = int.tryParse(entry.key);
            if (index != null && index < _selectedAnswers.length) {
              _selectedAnswers[index] = entry.value;
              // Also set text controller if it's a short answer question
              if (_textAnswerControllers.containsKey(index)) {
                _textAnswerControllers[index]!.text = entry.value.toString();
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error checking submission: $e');
    }
  }

  void _selectAnswer(int answerIndex) {
    if (_hasSubmitted || _isSubmitting) return;
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _selectTextAnswer(String answer) {
    if (_hasSubmitted || _isSubmitting) return;
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        // Sync controller text with current answer when switching questions
        if (_textAnswerControllers.containsKey(_currentQuestionIndex)) {
          final currentAnswer = _selectedAnswers[_currentQuestionIndex];
          _textAnswerControllers[_currentQuestionIndex]!.text = 
              currentAnswer?.toString() ?? '';
        }
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        // Sync controller text with current answer when switching questions
        if (_textAnswerControllers.containsKey(_currentQuestionIndex)) {
          final currentAnswer = _selectedAnswers[_currentQuestionIndex];
          _textAnswerControllers[_currentQuestionIndex]!.text = 
              currentAnswer?.toString() ?? '';
        }
      });
    }
  }

  Future<void> _finishQuiz() async {
    // Check if all questions are answered
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please answer question ${i + 1}')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate score
      int correctAnswers = 0;
      Map<String, dynamic> answersMap = {};

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final answer = _selectedAnswers[i];
        answersMap[i.toString()] = answer;

        // Check if answer is correct
        if (question['questionType'] == 'MCQ') {
          final correctIndex = question['correctAnswerIndex'] as int?;
          if (correctIndex != null && answer == correctIndex) {
            correctAnswers++;
          }
        }
        // For short questions, we don't auto-grade
      }

      await FirebaseService.submitQuizResponse(
        courseId: widget.course.id,
        quizId: widget.quizId,
        studentId: userId,
        answers: answersMap,
        score: correctAnswers,
        totalQuestions: _questions.length,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _hasSubmitted = true;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(
              context,
            ).cardColor, // THEME: Dynamic background
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Quiz Submitted',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ), // THEME: Dynamic text
                ),
              ],
            ),
            content: Text(
              'Your quiz has been submitted successfully. The instructor will review your answers.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ), // THEME: Dynamic text
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to course details
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ), // THEME: Dynamic button
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting quiz: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No questions available',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final questionType = currentQuestion['questionType'] as String? ?? 'MCQ';
    final options = currentQuestion['options'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: themeProvider.gradient, // THEME: Dynamic gradient
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F33c18e0f-4a2d-4849-8d66-7ae167009cc7.png',
                          width: 11,
                          height: 11,
                          fit: BoxFit.contain,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground, // THEME: Dynamic icon color
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Course name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.course.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Quiz title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.quiz['title'] ?? 'Quiz',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Question number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: GoogleFonts.inriaSerif(
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Question and Answers
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Question Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor, // THEME: Dynamic card
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black.withOpacity(0.3)
                                  : const Color(
                                      0x0C000000,
                                    ), // THEME: Adaptive shadow
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
                              currentQuestion['question'] ?? '',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground, // THEME: Dynamic text
                                fontSize: 14,
                                height: 2,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 16),
                            questionType == 'MCQ'
                                ? Column(
                                    children: options.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final answer = entry.value.toString();
                                      return GestureDetector(
                                        onTap: _hasSubmitted || _isSubmitting
                                            ? null
                                            : () => _selectAnswer(index),
                                        child: Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).cardColor, // THEME: Dynamic card
                                            border: Border.all(
                                              color:
                                                  _selectedAnswers[_currentQuestionIndex] ==
                                                      index
                                                  ? Theme.of(context)
                                                        .primaryColor // THEME: Dynamic border
                                                  : Theme.of(
                                                      context,
                                                    ).dividerColor, // THEME: Dynamic border
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        _selectedAnswers[_currentQuestionIndex] ==
                                                            index
                                                        ? Theme.of(context)
                                                              .primaryColor // THEME: Dynamic border
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(
                                                                0.6,
                                                              ), // THEME: Dynamic border
                                                  ),
                                                  color:
                                                      _selectedAnswers[_currentQuestionIndex] ==
                                                          index
                                                      ? Theme.of(context)
                                                            .primaryColor // THEME: Dynamic selection
                                                      : Theme.of(
                                                          context,
                                                        ).cardColor, // THEME: Dynamic background
                                                ),
                                                child:
                                                    _selectedAnswers[_currentQuestionIndex] ==
                                                        index
                                                    ? Icon(
                                                        Icons.check,
                                                        size: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary, // THEME: Dynamic icon
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  answer,
                                                  style: GoogleFonts.inter(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onBackground, // THEME: Dynamic text
                                                    fontSize: 16,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Builder(
                                    builder: (context) {
                                      // Ensure controller exists and is synced
                                      if (!_textAnswerControllers.containsKey(_currentQuestionIndex)) {
                                        _textAnswerControllers[_currentQuestionIndex] = 
                                            TextEditingController();
                                      }
                                      final controller = _textAnswerControllers[_currentQuestionIndex]!;
                                      // Sync controller text with current answer
                                      final currentAnswer = _selectedAnswers[_currentQuestionIndex]?.toString() ?? '';
                                      if (controller.text != currentAnswer) {
                                        controller.text = currentAnswer;
                                        controller.selection = TextSelection.fromPosition(
                                          TextPosition(offset: currentAnswer.length),
                                        );
                                      }
                                      return TextField(
                                        enabled: !_hasSubmitted && !_isSubmitting,
                                        controller: controller,
                                        onChanged: (value) => _selectTextAnswer(value),
                                        maxLines: 5,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your answer...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Theme.of(context).cardColor,
                                        ),
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onBackground,
                                          fontSize: 16,
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),

                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentQuestionIndex > 0)
                            Expanded(
                              child: Container(
                                height: 56,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                  ), // THEME: Dynamic border
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: (_hasSubmitted || _isSubmitting)
                                        ? null
                                        : _previousQuestion,
                                    child: Center(
                                      child: Text(
                                        'Previous',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor, // THEME: Dynamic text
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_currentQuestionIndex < _questions.length - 1)
                            Expanded(
                              child: Container(
                                height: 56,
                                margin: const EdgeInsets.only(left: 8),
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
                                    ),
                                  ],
                                  gradient: (_hasSubmitted || _isSubmitting)
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade600,
                                            Colors.grey.shade400,
                                          ],
                                        )
                                      : themeProvider
                                            .gradient, // THEME: Dynamic gradient
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: (_hasSubmitted || _isSubmitting)
                                        ? null
                                        : _nextQuestion,
                                    child: Center(
                                      child: Text(
                                        'Next Question',
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
                            ),
                          if (_currentQuestionIndex == _questions.length - 1)
                            Expanded(
                              child: Container(
                                height: 56,
                                margin: const EdgeInsets.only(left: 8),
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
                                    ),
                                  ],
                                  gradient: _hasSubmitted || _isSubmitting
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade600,
                                            Colors.grey.shade400,
                                          ],
                                        )
                                      : themeProvider
                                            .gradient, // THEME: Dynamic gradient
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: (_hasSubmitted || _isSubmitting)
                                        ? null
                                        : _finishQuiz,
                                    child: Center(
                                      child: _hasSubmitted
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Submitted',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : _isSubmitting
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              'Finish Quiz',
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
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
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
