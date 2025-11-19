import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  final List<int?> _selectedAnswers = [null, null];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      'answers': ['Lorem', 'Ipsum', 'Dolor', 'Sit amet'],
    },
    {
      'question': 'Mitochondria is the ___ of the cell',
      'answers': ['Powerhouse', 'Battery', 'Voltage', 'Flower house'],
    },
  ];

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _finishQuiz() {
    int correctAnswers = 0;
    // Check answers (in real app, this would be done by server)
    if (_selectedAnswers[0] == 0) correctAnswers++;
    if (_selectedAnswers[1] == 0) correctAnswers++;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
        title: Text(
          'Quiz Completed',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
        ),
        content: Text(
          'You got $correctAnswers out of ${_questions.length} questions correct!',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface), // THEME: Dynamic text
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to course details
            },
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).primaryColor), // THEME: Dynamic button
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentQuestion = _questions[_currentQuestionIndex];
    
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
                          color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic icon color
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
                  'Introduction to Programming',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                  'Quiz 3:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                          color: Theme.of(context).cardColor, // THEME: Dynamic card
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
                              currentQuestion['question'],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                                fontSize: 14,
                                height: 2,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: (currentQuestion['answers'] as List<String>)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final answer = entry.value;
                                return GestureDetector(
                                  onTap: () => _selectAnswer(index),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor, // THEME: Dynamic card
                                      border: Border.all(
                                        color: _selectedAnswers[_currentQuestionIndex] == index
                                            ? Theme.of(context).primaryColor // THEME: Dynamic border
                                            : Theme.of(context).dividerColor, // THEME: Dynamic border
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _selectedAnswers[_currentQuestionIndex] == index
                                                  ? Theme.of(context).primaryColor // THEME: Dynamic border
                                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic border
                                            ),
                                            color: _selectedAnswers[_currentQuestionIndex] == index
                                                ? Theme.of(context).primaryColor // THEME: Dynamic selection
                                                : Theme.of(context).cardColor, // THEME: Dynamic background
                                          ),
                                          child: _selectedAnswers[_currentQuestionIndex] == index
                                              ? Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Theme.of(context).colorScheme.onPrimary, // THEME: Dynamic icon
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            answer,
                                            style: GoogleFonts.inter(
                                              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                                  border: Border.all(color: Theme.of(context).primaryColor), // THEME: Dynamic border
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _previousQuestion,
                                    child: Center(
                                      child: Text(
                                        'Previous',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(context).primaryColor, // THEME: Dynamic text
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
                                    )
                                  ],
                                  gradient: themeProvider.gradient, // THEME: Dynamic gradient
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _nextQuestion,
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
                                    )
                                  ],
                                  gradient: themeProvider.gradient, // THEME: Dynamic gradient
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _finishQuiz,
                                    child: Center(
                                      child: Text(
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