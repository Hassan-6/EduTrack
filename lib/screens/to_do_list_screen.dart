import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import 'new_task_screen.dart';
import '../utils/theme_provider.dart'; // ADD THIS IMPORT

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  int _currentBottomNavIndex = 1;

  final List<TodoItem> _pendingTasks = [
    TodoItem(
      id: '1',
      title: 'Finish English Essay',
      dueDate: 'Today, 11:59 PM',
      category: 'Academic',
      categoryColor: const Color(0xFFFEE2E2),
      textColor: const Color(0xFFDC2626),
      isCompleted: false,
    ),
    TodoItem(
      id: '2',
      title: 'Math Homework - Algebra',
      dueDate: 'Tomorrow, 2:30 PM',
      category: 'Academic',
      categoryColor: const Color(0xFFDBEAFE),
      textColor: const Color(0xFF2563EB),
      isCompleted: false,
    ),
    TodoItem(
      id: '3',
      title: 'Call Mom',
      dueDate: 'This Weekend',
      category: 'Personal',
      categoryColor: const Color(0xFFDCFCE7),
      textColor: const Color(0xFF16A34A),
      isCompleted: false,
    ),
    TodoItem(
      id: '4',
      title: 'Prepare for History Quiz',
      dueDate: 'Friday, 9:00 AM',
      category: 'Academic',
      categoryColor: const Color(0xFFDBEAFE),
      textColor: const Color(0xFF2563EB),
      isCompleted: false,
    ),
  ];

  final List<TodoItem> _completedTasks = [
    TodoItem(
      id: '5',
      title: 'Read Chapter 5 - Biology',
      dueDate: 'Yesterday, 6:00 PM',
      category: 'Academic',
      categoryColor: const Color(0xFFDBEAFE),
      textColor: const Color(0xFF2563EB),
      isCompleted: true,
    ),
    TodoItem(
      id: '6',
      title: 'Submit Lab Report',
      dueDate: 'Completed 2 days ago',
      category: 'Academic',
      categoryColor: const Color(0xFFDBEAFE),
      textColor: const Color(0xFF2563EB),
      isCompleted: true,
    ),
    TodoItem(
      id: '7',
      title: 'Buy Textbooks',
      dueDate: 'Completed 1 week ago',
      category: 'Academic',
      categoryColor: const Color(0xFFDBEAFE),
      textColor: const Color(0xFF2563EB),
      isCompleted: true,
    ),
  ];

  void _toggleTaskCompletion(String taskId) {
    setState(() {
      final pendingIndex = _pendingTasks.indexWhere((task) => task.id == taskId);
      if (pendingIndex != -1) {
        final task = _pendingTasks[pendingIndex];
        _pendingTasks.removeAt(pendingIndex);
        _completedTasks.insert(0, task.copyWith(isCompleted: true));
        return;
      }

      final completedIndex = _completedTasks.indexWhere((task) => task.id == taskId);
      if (completedIndex != -1) {
        final task = _completedTasks[completedIndex];
        _completedTasks.removeAt(completedIndex);
        _pendingTasks.add(task.copyWith(isCompleted: false));
      }
    });
  }

  void _addNewTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTaskScreen()),
    );

    if (result != null && result is TodoItem) {
      setState(() {
        _pendingTasks.insert(0, result);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/main_menu');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/qna');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  double get _completionPercentage {
    final totalTasks = _pendingTasks.length + _completedTasks.length;
    return totalTasks > 0 ? _completedTasks.length / totalTasks : 0;
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
          onPressed: _onBackPressed,
        ),
        title: Text(
          'To-Do List',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // THEME: Dynamic card
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${_completedTasks.length} of ${_pendingTasks.length + _completedTasks.length} tasks completed',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _completionPercentage,
                      backgroundColor: Theme.of(context).dividerColor, // THEME: Dynamic background
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeProvider.primaryColor, // THEME: Dynamic progress color
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ..._pendingTasks.map((task) => _buildTaskItem(task)),

              if (_completedTasks.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), // THEME: Dynamic icon
                    const SizedBox(width: 8),
                    Text(
                      'Completed Tasks (${_completedTasks.length})',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._completedTasks.map((task) => _buildCompletedTaskItem(task)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
      floatingActionButton: _buildTodoFloatingActionButton(themeProvider),
    );
  }

  Widget _buildTodoFloatingActionButton(ThemeProvider themeProvider) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
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
        gradient: themeProvider.gradient, // THEME: Dynamic gradient
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: _addNewTask,
          child: const Center(
            child: Icon(
              Icons.add,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(TodoItem task) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTaskCompletion(task.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? Theme.of(context).primaryColor : Theme.of(context).dividerColor, // THEME: Dynamic border
                  width: 2,
                ),
                color: task.isCompleted ? Theme.of(context).primaryColor : Colors.transparent, // THEME: Dynamic fill
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Due: ${task.dueDate}',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                        fontSize: 14,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.categoryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.category,
                        style: GoogleFonts.inter(
                          color: task.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskItem(TodoItem task) {
    return Opacity(
      opacity: 0.8,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black.withOpacity(0.2) 
              : const Color(0xFFF9FAFB), // THEME: Adaptive background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5CD6C0), // Keep completion color
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic text
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    task.dueDate,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic text
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodoItem {
  final String id;
  final String title;
  final String dueDate;
  final String category;
  final Color categoryColor;
  final Color textColor;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.category,
    required this.categoryColor,
    required this.textColor,
    required this.isCompleted,
  });

  TodoItem copyWith({
    bool? isCompleted,
  }) {
    return TodoItem(
      id: id,
      title: title,
      dueDate: dueDate,
      category: category,
      categoryColor: categoryColor,
      textColor: textColor,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}