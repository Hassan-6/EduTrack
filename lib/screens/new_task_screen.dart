import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'to_do_list_screen.dart';
import '../utils/theme_provider.dart';

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
  TaskCategory _selectedCategory = TaskCategory.academic;
  
  bool _isTimeAM = false;
  int _hour = 5;
  int _minute = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    _isTimeAM = now.hour < 12;
    _dueTime = TimeOfDay.fromDateTime(now);
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
        _hour = picked.hourOfPeriod;
        _isTimeAM = picked.period == DayPeriod.am;
      });
    }
  }

  void _createTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final task = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      dueDate: _formatDueDate(),
      category: _getCategoryName(_selectedCategory),
      categoryColor: _getCategoryColor(_selectedCategory),
      textColor: _getCategoryTextColor(_selectedCategory),
      isCompleted: false,
    );

    Navigator.pop(context, task);
  }

  String _formatDueDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selected == today) {
      return 'Today, ${_dueTime.format(context)}';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${_dueTime.format(context)}';
    } else {
      final dateFormat = DateFormat('MMM d');
      return '${dateFormat.format(_selectedDate)}, ${_dueTime.format(context)}';
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.academic:
        return const Color(0xFFDBEAFE);
      case TaskCategory.personal:
        return const Color(0xFFDCFCE7);
      case TaskCategory.work:
        return const Color(0xFFFEF3C7);
      case TaskCategory.other:
        return const Color(0xFFF3E8FF);
    }
  }

  Color _getCategoryTextColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.academic:
        return const Color(0xFF2563EB);
      case TaskCategory.personal:
        return const Color(0xFF16A34A);
      case TaskCategory.work:
        return const Color(0xFFD97706);
      case TaskCategory.other:
        return const Color(0xFF9333EA);
    }
  }

  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.academic:
        return 'Academic';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // THEME: Dynamic header
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 86,
                      height: 32,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 11,
                            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic icon
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
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
                    // Task Details Card
                    _buildTaskDetailsCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Due Date Card
                    _buildDueDateCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Due Time Card
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
                gradient: themeProvider.gradient, // THEME: Dynamic gradient
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
                  onTap: _createTask,
                  child: Center(
                    child: Text(
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
          // Task Title
          _buildFormField(
            label: 'Task',
            hintText: 'Enter title...',
            controller: _titleController,
          ),
          
          const SizedBox(height: 24),
          
          // Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
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
                      : const Color(0x7FFFFFFF), // THEME: Adaptive background
                  border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TaskCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
                    ),
                    items: TaskCategory.values.map((TaskCategory category) {
                      return DropdownMenuItem<TaskCategory>(
                        value: category,
                        child: Text(
                          _getCategoryName(category),
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (TaskCategory? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
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
          Text(
            'Select date',
            style: GoogleFonts.roboto(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
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
                border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MM/dd/yyyy').format(_selectedDate),
                      style: GoogleFonts.roboto(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 16,
                        letterSpacing: 1,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
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
          Text(
            'Due Time',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Compact Time Picker
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.2) 
                    : const Color(0xFFF8FAFC), // THEME: Adaptive background
                border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dueTime.format(context),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label
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
                : const Color(0x7FFFFFFF), // THEME: Adaptive background
            border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic hint
                fontSize: 16,
                height: 1.5,
              ),
            ),
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

enum TaskCategory {
  academic,
  personal,
  work,
  other,
}