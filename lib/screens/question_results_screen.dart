import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/course_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';

class QuestionResultsScreen extends StatefulWidget {
  final Course course;
  final String? questionId; // Optional for backward compatibility
  final String question;
  final String questionType;
  final List<String> options;
  final int correctAnswerIndex;

  const QuestionResultsScreen({
    super.key,
    required this.course,
    this.questionId,
    required this.question,
    required this.questionType,
    required this.options,
    required this.correctAnswerIndex,
  });

  @override
  State<QuestionResultsScreen> createState() => _QuestionResultsScreenState();
}

class _QuestionResultsScreenState extends State<QuestionResultsScreen> {
  Map<int, double> _results = {};
  bool _isLoading = false;
  int _totalResponses = 0;
  bool _isActive = true; // Track if question is still active
  Map<String, dynamic>? _questionData; // Store full question data
  bool _isInstructor = false; // Track if user is instructor

  @override
  void initState() {
    super.initState();
    // Check if user is instructor
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isInstructor = authProvider.userType == 'instructor';
    
    if (widget.questionId != null) {
      _loadResults();
    } else {
      // Use mock data for backward compatibility
      _results = {
        0: 25.0,
        1: 60.0,
        2: 10.0,
        3: 5.0,
      };
      _totalResponses = 100;
    }
  }

  Future<void> _loadResults() async {
    if (widget.questionId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final data = await FirebaseService.getPopupQuestionResults(
        courseId: widget.course.id,
        questionId: widget.questionId!,
      );
      
      setState(() {
        _calculateResults(data);
      });
    } catch (e) {
      print('Error loading results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading results: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateResults(Map<String, dynamic> data) {
    _questionData = data; // Store full question data
    final responses = data['enrichedResponses'] as Map<String, dynamic>? ?? {};
    _totalResponses = responses.length;
    _isActive = data['isActive'] == true; // Check if question is still active
    
    if (widget.questionType == 'MCQ') {
      // Count responses for each option
      Map<int, int> optionCounts = {};
      for (int i = 0; i < widget.options.length; i++) {
        optionCounts[i] = 0;
      }
      
      for (var response in responses.values) {
        final answer = response['response'];
        if (answer is int && answer >= 0 && answer < widget.options.length) {
          optionCounts[answer] = (optionCounts[answer] ?? 0) + 1;
        }
      }
      
      // Calculate percentages
      _results = {};
      for (var entry in optionCounts.entries) {
        _results[entry.key] = _totalResponses > 0
            ? (entry.value / _totalResponses * 100)
            : 0.0;
      }
    }
  }

  Future<void> _endQuestion() async {
    if (widget.questionId == null) {
      Navigator.pop(context);
      return;
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await FirebaseService.deactivatePopupQuestion(
        courseId: widget.course.id,
        questionId: widget.questionId!,
      );
      
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close results screen
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question session ended')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending question: $e')),
      );
    }
  }

  void _done() {
    Navigator.pop(context);
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  List<Widget> _buildStudentAnswersSection() {
    if (_questionData == null) return [];
    
    final enrichedResponses = _questionData!['enrichedResponses'] as Map<String, dynamic>? ?? {};
    if (enrichedResponses.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'No student responses yet',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    List<Widget> widgets = [
      Text(
        'Student Answers',
        style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
    ];

    enrichedResponses.forEach((studentId, responseData) {
      final studentName = responseData['studentName'] ?? 'Unknown';
      final studentRollNumber = responseData['studentRollNumber'] ?? 'N/A';
      final answer = responseData['response'];
      
      String answerText;
      if (widget.questionType == 'MCQ') {
        if (answer is int && answer >= 0 && answer < widget.options.length) {
          answerText = widget.options[answer];
        } else {
          answerText = 'No answer selected';
        }
      } else {
        answerText = answer?.toString() ?? 'No answer provided';
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      studentName,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    studentRollNumber,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                answerText,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar color
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: _onBackPressed, // FIXED: Use the new handler
        ),
        title: Text(
          'Question Results',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Question Results',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // THEME: Dynamic card color
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
                    'Question:',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (widget.questionType == 'MCQ') ...[
              // Options with Results
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card color
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
                      'Student Responses:',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final percentage = _results[index] ?? 0.0;
                      // Only show correct answer if question is ended
                      final isCorrect = !_isActive && index == widget.correctAnswerIndex;
                      final count = _totalResponses > 0 
                          ? ((percentage / 100) * _totalResponses).round()
                          : 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFDCFCE7) : Theme.of(context).cardColor,
                          border: Border.all(
                            color: isCorrect ? const Color(0xFF16A34A) : Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCorrect ? const Color(0xFF16A34A) : Theme.of(context).cardColor,
                                border: Border.all(
                                  color: isCorrect 
                                      ? const Color(0xFF16A34A) 
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: GoogleFonts.inter(
                                    color: isCorrect 
                                        ? Colors.white 
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onBackground,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    color: isCorrect 
                                        ? const Color(0xFF16A34A) 
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.questionId != null)
                                  Text(
                                    '($count)',
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else ...[
              // Short Answer Results
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card color
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
                      'Correct Answer:',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        border: Border.all(color: const Color(0xFF16A34A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.options.isNotEmpty ? widget.options[0] : 'No answer provided',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF166534),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total Responses: $_totalResponses',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.questionId != null && _isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ))
            else ...[
              // Response count
              if (widget.questionId != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade700
                          : Colors.blue.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total Responses: $_totalResponses',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade200
                          : Colors.blue.shade900,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),

              // Individual Student Answers Section (for instructors)
              if (_isInstructor && _questionData != null)
                ..._buildStudentAnswersSection(),

              const SizedBox(height: 24),

              // End Question / Done Button (only for instructors)
              if (_isInstructor && widget.questionId != null && _isActive)
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _endQuestion,
                      child: Center(
                        child: Text(
                          'End Question Session',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (!_isInstructor)
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _done,
                      child: Center(
                        child: Text(
                          'Done',
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}