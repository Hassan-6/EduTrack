import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/course_model.dart';
import '../services/firebase_service.dart';

class PresentQuestionScreen extends StatefulWidget {
  final Course course;

  const PresentQuestionScreen({super.key, required this.course});

  @override
  State<PresentQuestionScreen> createState() => _PresentQuestionScreenState();
}

class _PresentQuestionScreenState extends State<PresentQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  String _selectedQuestionType = 'MCQ';
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;
  bool _hasCorrectAnswer = true; // Toggle for whether there is a correct answer

  Future<void> _sendQuestion() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    if (_selectedQuestionType == 'MCQ') {
      for (int i = 0; i < _optionControllers.length; i++) {
        if (_optionControllers[i].text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all options')),
          );
          return;
        }
      }
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final instructorId = FirebaseAuth.instance.currentUser?.uid;
      if (instructorId == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final options = _selectedQuestionType == 'MCQ'
          ? _optionControllers.map((c) => c.text).toList()
          : _optionControllers[0].text.isNotEmpty
              ? [_optionControllers[0].text]
              : <String>[]; // For short answer, store expected answer if provided

      // Create popup question in backend
      await FirebaseService.createPopupQuestion(
        courseId: widget.course.id,
        instructorId: instructorId,
        question: _questionController.text,
        questionType: _selectedQuestionType,
        options: options,
        correctAnswerIndex: _hasCorrectAnswer ? _correctAnswerIndex : null,
      );

      Navigator.pop(context); // Close loading

      // Show success alert
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Question Presented',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'The question has been successfully presented to your students.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to Course Details Screen
              },
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: const Color(0xFF4E9FEC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating question: $e')),
      );
    }
  }

  Widget _buildMCQOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Options:',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Radio(
                  value: index,
                  groupValue: _correctAnswerIndex,
                  onChanged: (value) {
                    setState(() {
                      _correctAnswerIndex = value!;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Option ${String.fromCharCode(65 + index)}',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShortAnswerOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Correct Answer:',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _optionControllers[0], // Use first controller for short answer
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter the correct answer...',
              border: InputBorder.none,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
              ),
            ),
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _onBackPressed() {
    Navigator.pop(context);
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
          'Present Question',
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
                    'Present a question to your students',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question Input
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter your question here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4E9FEC)),
                      ),
                    ),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Question Type Selection
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
                    'Question Type:',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuestionTypeButton('MCQ'),
                      const SizedBox(width: 12),
                      _buildQuestionTypeButton('Short Question'),
                    ],
                  ),
                ],
              ),
            ),

            // Options based on question type
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
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
              child: _selectedQuestionType == 'MCQ' 
                  ? _buildMCQOptions() 
                  : _buildShortAnswerOptions(),
            ),
            const SizedBox(height: 16),
            
            // Toggle for correct answer
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Has Correct Answer',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toggle if this question has a correct answer',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _hasCorrectAnswer,
                    onChanged: (value) {
                      setState(() {
                        _hasCorrectAnswer = value;
                      });
                    },
                    activeColor: const Color(0xFF4E9FEC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Send Button
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
                  onTap: _sendQuestion,
                  child: Center(
                    child: Text(
                      'Send Question',
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeButton(String type) {
    bool isSelected = _selectedQuestionType == type;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedQuestionType = type;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4E9FEC) : Colors.transparent,
              border: Border.all(
                color: isSelected ? const Color(0xFF4E9FEC) : const Color(0xFFD1D5DB),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                type,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}