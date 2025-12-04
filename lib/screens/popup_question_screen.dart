import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_provider.dart';
import '../widgets/course_model.dart';
import '../services/firebase_service.dart';

class PopupQuestionScreen extends StatefulWidget {
  final Course course;
  final String questionId;
  final Map<String, dynamic> question;

  const PopupQuestionScreen({
    super.key,
    required this.course,
    required this.questionId,
    required this.question,
  });

  @override
  State<PopupQuestionScreen> createState() => _PopupQuestionScreenState();
}

class _PopupQuestionScreenState extends State<PopupQuestionScreen> {
  int? _selectedAnswer;
  String? _textAnswer;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  late final TextEditingController _textAnswerController;

  @override
  void initState() {
    super.initState();
    _textAnswerController = TextEditingController(text: _textAnswer ?? '');
    _checkIfAlreadySubmitted();
  }

  @override
  void dispose() {
    _textAnswerController.dispose();
    super.dispose();
  }

  String _getAnswerText() {
    if (widget.question['questionType'] == 'MCQ') {
      final options = widget.question['options'] as List<dynamic>?;
      if (options != null && _selectedAnswer != null && _selectedAnswer! < options.length) {
        return options[_selectedAnswer!].toString();
      }
      return '';
    } else {
      return _textAnswer ?? '';
    }
  }

  Future<void> _checkIfAlreadySubmitted() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final responses = widget.question['responses'] as Map<String, dynamic>? ?? {};
      if (responses.containsKey(userId)) {
        setState(() {
          _hasSubmitted = true;
          final responseData = responses[userId] as Map<String, dynamic>? ?? {};
          final response = responseData['response'];
          if (widget.question['questionType'] == 'MCQ' && response is int) {
            _selectedAnswer = response;
          } else if (response is String) {
            _textAnswer = response;
            _textAnswerController.text = response;
          }
        });
      }
    } catch (e) {
      print('Error checking submission: $e');
    }
  }

  Future<void> _submitAnswer() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final questionType = widget.question['questionType'] as String? ?? 'MCQ';
    
    if (questionType == 'MCQ') {
      if (_selectedAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an answer')),
        );
        return;
      }
    } else {
      if (_textAnswer == null || _textAnswer!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an answer')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseService.submitPopupQuestionResponse(
        courseId: widget.course.id,
        questionId: widget.questionId,
        studentId: userId,
        response: questionType == 'MCQ' ? _selectedAnswer : _textAnswer,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _hasSubmitted = true;
        });
        _showCompletionDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting answer: $e')),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
            const SizedBox(width: 8),
            Text(
              'Answer Submitted',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your response has been recorded and sent to the instructor.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Question: ${widget.question['question'] ?? ''}',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your answer: ${_getAnswerText()}',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to course details
            },
            child: Text(
              'Return to Course',
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
    final questionType = widget.question['questionType'] as String? ?? 'MCQ';
    final options = widget.question['options'] as List<dynamic>? ?? [];
    final List<String> answers = options.map((o) => o.toString()).toList();
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: themeProvider.gradient, // THEME: Dynamic gradient
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                          'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fe2b369f8-d1f3-4e22-be54-8e13c6df606f.png',
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

              // Question header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pop-Up Question',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Course name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.course.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Instructor and time info
              if (widget.question['createdAt'] != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1), // THEME: Dynamic background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
                      const SizedBox(width: 8),
                      Text(
                        widget.course.instructor,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Question
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.question['question'] ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Answers
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      questionType == 'MCQ' ? 'Select your answer:' : 'Enter your answer:',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    questionType == 'MCQ'
                        ? Column(
                            children: answers.asMap().entries.map<Widget>((entry) {
                                  final index = entry.key;
                                  final answer = entry.value;
                                  return GestureDetector(
                                    onTap: (_isSubmitting || _hasSubmitted) ? null : () {
                                      setState(() {
                                        _selectedAnswer = index;
                                      });
                                    },
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _selectedAnswer == index
                                          ? Theme.of(context).primaryColor.withOpacity(0.1) // THEME: Dynamic selection
                                          : Theme.of(context).cardColor, // THEME: Dynamic card
                                      border: Border.all(
                                        color: _selectedAnswer == index
                                            ? Theme.of(context).primaryColor // THEME: Dynamic border
                                            : Theme.of(context).dividerColor, // THEME: Dynamic border
                                        width: _selectedAnswer == index ? 2 : 1,
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
                                          color: _selectedAnswer == index
                                              ? Theme.of(context).primaryColor // THEME: Dynamic border
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic border
                                        ),
                                        color: _selectedAnswer == index
                                            ? Theme.of(context).primaryColor // THEME: Dynamic selection
                                            : Theme.of(context).cardColor, // THEME: Dynamic background
                                      ),
                                      child: _selectedAnswer == index
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
                          )
                        : TextField(
                            enabled: !_hasSubmitted && !_isSubmitting,
                            controller: _textAnswerController,
                            onChanged: (value) {
                              setState(() {
                                _textAnswer = value;
                              });
                            },
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Type your answer here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                            ),
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 16,
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  gradient: ((questionType == 'MCQ' && _selectedAnswer != null) ||
                          (questionType != 'MCQ' && _textAnswer != null && _textAnswer!.isNotEmpty)) &&
                      !_isSubmitting && !_hasSubmitted
                      ? themeProvider.gradient // THEME: Dynamic gradient
                      : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]),
                ),
                child: Material(
                  color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: ((questionType == 'MCQ' && _selectedAnswer != null) ||
                              (questionType != 'MCQ' && _textAnswer != null && _textAnswer!.isNotEmpty)) &&
                          !_isSubmitting && !_hasSubmitted
                          ? _submitAnswer
                          : null,
                      child: Center(
                        child: _hasSubmitted
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary), // THEME: Dynamic progress
                                    ),
                                  )
                                : Text(
                                    'Submit Answer',
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
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // SafeArea
    ), // Container
    ); // Scaffold
  }
}