import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/course_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class ScheduleQuizScreen extends StatefulWidget {
  final Course course;

  const ScheduleQuizScreen({super.key, required this.course});

  @override
  State<ScheduleQuizScreen> createState() => _ScheduleQuizScreenState();
}

class _ScheduleQuizScreenState extends State<ScheduleQuizScreen> {
  final TextEditingController _quizTitleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 1;
  int _durationMinutes = 0;
  final List<QuizQuestion> _questions = [];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _scheduleQuiz() async {
    if (_quizTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quiz title')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    // Validate all questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} is empty')),
        );
        return;
      }
      
      if (q.type == 'MCQ') {
        for (int j = 0; j < q.optionControllers.length; j++) {
          if (q.optionControllers[j].text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Question ${i + 1} option ${String.fromCharCode(65 + j)} is empty')),
            );
            return;
          }
        }
        // Validate that a correct answer is selected for MCQ
        if (q.correctAnswerIndex < 0 || q.correctAnswerIndex >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Question ${i + 1} requires a correct answer selection')),
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

      // Prepare questions data
      List<Map<String, dynamic>> questionsData = [];
      for (var q in _questions) {
        final questionData = <String, dynamic>{
          'question': q.questionController.text,
          'questionType': q.type,
        };
        
        if (q.type == 'MCQ') {
          questionData['options'] = q.optionControllers.map((c) => c.text).toList();
          questionData['correctAnswerIndex'] = q.correctAnswerIndex;
        } else {
          // For Short Question, store the expected answer if provided
          if (q.optionControllers[0].text.isNotEmpty) {
            questionData['options'] = [q.optionControllers[0].text];
          }
        }
        
        questionsData.add(questionData);
      }

      // Combine date and time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final durationMinutes = (_durationHours * 60) + _durationMinutes;

      // Create quiz in backend
      final quizId = await FirebaseService.createQuiz(
        courseId: widget.course.id,
        instructorId: instructorId,
        title: _quizTitleController.text,
        scheduledDate: scheduledDateTime,
        durationMinutes: durationMinutes,
        questions: questionsData,
      );
      
      print('Quiz created with ID: $quizId');

      // Get enrolled students and notify them
      final courseDoc = await FirebaseService.getCourseById(widget.course.id);
      final List<String> enrolledStudents = 
          List<String>.from(courseDoc?['enrolledStudents'] ?? []);

      // Notify all enrolled students (excluding the instructor if they're in the list)
      final studentsToNotify = enrolledStudents.where((id) => id != instructorId).toList();
      
      if (studentsToNotify.isNotEmpty) {
        await NotificationService().notifyQuizScheduled(
          studentIds: studentsToNotify,
          courseName: widget.course.name,
          quizTitle: _quizTitleController.text,
          quizDate: scheduledDateTime,
        );
      }

      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz scheduled successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling quiz: $e')),
      );
    }
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
          'Schedule Quiz',
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
                    'Schedule a quiz for your students',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quiz Title
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
                    'Quiz Title:',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quizTitleController,
                      decoration: InputDecoration(
                        hintText: 'Enter quiz title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Section
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
                    'Schedule',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Picker
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Time',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Text(
                    'Duration:',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDurationField(_durationHours, 'Hours', (value) {
                        setState(() => _durationHours = int.tryParse(value) ?? 0);
                      }),
                      const SizedBox(width: 16),
                      _buildDurationField(_durationMinutes, 'Minutes', (value) {
                        setState(() => _durationMinutes = int.tryParse(value) ?? 0);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Questions Section
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions (${_questions.length})',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _addQuestion,
                            child: Center(
                              child: Text(
                                'Add Question',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return _buildQuestionCard(question, index);
                  }),
                  if (_questions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No questions added yet',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Schedule Button
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
                  onTap: _scheduleQuiz,
                  child: Center(
                    child: Text(
                      'Schedule Quiz',
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

  Widget _buildDurationField(int value, String label, Function(String) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: TextEditingController(text: value.toString()),
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1}',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeQuestion(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Question Type Selection
          Text(
            'Question Type:',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuestionTypeButton(
                  'MCQ',
                  question.type == 'MCQ',
                  () {
                    setState(() {
                      question.type = 'MCQ';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuestionTypeButton(
                  'Short Question',
                  question.type == 'Short Question',
                  () {
                    setState(() {
                      question.type = 'Short Question';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: question.questionController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Enter question...',
              border: OutlineInputBorder(),
            ),
          ),
          // Show options for MCQ
          if (question.type == 'MCQ') ...[
            const SizedBox(height: 12),
            Text(
              'Options:',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio(
                      value: optionIndex,
                      groupValue: question.correctAnswerIndex,
                      onChanged: (value) {
                        setState(() {
                          question.correctAnswerIndex = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: question.optionControllers[optionIndex],
                        decoration: InputDecoration(
                          hintText: 'Option ${String.fromCharCode(65 + optionIndex)}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // Show text field for Short Question
            const SizedBox(height: 12),
            Text(
              'Expected Answer (optional):',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: question.optionControllers[0],
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter expected answer...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionTypeButton(
    String type,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4E9FEC) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4E9FEC)
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              type,
              style: GoogleFonts.inter(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final TextEditingController questionController = TextEditingController();
  String type = 'MCQ';
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int correctAnswerIndex = 0;
}