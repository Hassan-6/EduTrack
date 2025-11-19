import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class PopupQuestionScreen extends StatefulWidget {
  final String courseName;

  const PopupQuestionScreen({super.key, required this.courseName});

  @override
  State<PopupQuestionScreen> createState() => _PopupQuestionScreenState();
}

class _PopupQuestionScreenState extends State<PopupQuestionScreen> {
  int? _selectedAnswer;
  bool _isSubmitting = false;

  // Single question sent by instructor
  final Map<String, dynamic> _question = {
    'question': 'What is the time complexity of accessing an element in an array by index?',
    'answers': [
      'O(1) - Constant Time',
      'O(n) - Linear Time', 
      'O(log n) - Logarithmic Time',
      'O(n²) - Quadratic Time'
    ],
    'questionId': 'popup_001', // For tracking with instructor
    'sentBy': 'Dr. Sarah Mitchell',
    'sentTime': '2 minutes ago'
  };

  void _submitAnswer() {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call to submit answer to instructor
    Future.delayed(const Duration(seconds: 2), () {
      _showCompletionDialog();
    });
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
              'Your response has been recorded and sent to ${_question['sentBy']}.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Question: ${_question['question']}',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your answer: ${_question['answers'][_selectedAnswer!]}',
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
    // Cast the answers to List<String> to avoid type issues
    final List<String> answers = (_question['answers'] as List<dynamic>).cast<String>();
    
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
                  widget.courseName,
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
                      _question['sentBy'],
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
                    const SizedBox(width: 8),
                    Text(
                      _question['sentTime'],
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 14,
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
                  _question['question'],
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
              Expanded(
                child: Container(
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
                    children: [
                      Text(
                        'Select your answer:',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: answers.asMap().entries.map<Widget>((entry) {
                            final index = entry.key;
                            final answer = entry.value;
                            return GestureDetector(
                              onTap: _isSubmitting ? null : () {
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
                        ),
                      ),
                    ],
                  ),
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
                  gradient: _selectedAnswer != null && !_isSubmitting
                      ? themeProvider.gradient // THEME: Dynamic gradient
                      : LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade400]),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _selectedAnswer != null && !_isSubmitting ? _submitAnswer : null,
                    child: Center(
                      child: _isSubmitting
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
          ),
        ),
      ),
    );
  }
}