import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../services/task_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _dueTime = const TimeOfDay(hour: 17, minute: 0);
  String _selectedCategory = 'Personal';
  List<String> _availableCategories = ['Personal'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final instructorCourses = await FirebaseService.getInstructorCourses(userId);
      final studentCourses = await FirebaseService.getStudentEnrolledCourses(userId);

      final courseNames = <String>{'Personal'};
      for (var course in instructorCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }
      for (var course in studentCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }

      if (mounted) {
        setState(() {
          _availableCategories = courseNames.toList();
          if (!_availableCategories.contains(_selectedCategory)) {
            _selectedCategory = _availableCategories.first;
          }
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final taskId = await TaskService.createTask(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        dueDate: dueDateTime,
      );

      // Schedule notification reminder
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await NotificationService().scheduleTaskReminder(
            taskId: taskId,
            taskTitle: _titleController.text,
            taskDescription: _descriptionController.text,
            dueDate: dueDateTime,
            userId: user.uid,
          );
        } catch (e) {
          print('Warning: Failed to schedule notification: $e');
          // Don't block task creation if notification fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating task: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 86,
                      height: 32,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 11,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 16,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    'New Task',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Placeholder for alignment
                  const SizedBox(width: 86),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildTaskDetailsCard(),
                    const SizedBox(height: 24),
                    _buildDueDateCard(),
                    const SizedBox(height: 24),
                    _buildDueTimeCard(),
                  ],
                ),
              ),
            ),

            // Create Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(24),
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: themeProvider.gradient,
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
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading ? null : _createTask,
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Task',
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
      ),
    );
  }

  Widget _buildTaskDetailsCard() {
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
          _buildFormField(
            label: 'Task',
            hintText: 'Enter title...',
            controller: _titleController,
          ),
          
          const SizedBox(height: 24),
          
          _buildFormField(
            label: 'Description',
            hintText: 'Enter description...',
            controller: _descriptionController,
          ),
          
          const SizedBox(height: 24),
          
          // Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.black.withOpacity(0.2) 
                      : const Color(0x7FFFFFFF),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    items: _availableCategories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateCard() {
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
            'Select date',
            style: GoogleFonts.roboto(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MM/dd/yyyy').format(_selectedDate),
                      style: GoogleFonts.roboto(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 16,
                        letterSpacing: 1,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    height: 40,
                    child: Center(
                      child: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueTimeCard() {
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
            'Due Time',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.2) 
                    : const Color(0xFFF8FAFC),
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dueTime.format(context),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2) 
                : const Color(0x7FFFFFFF),
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

