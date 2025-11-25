import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import '../utils/theme_provider.dart';
import '../services/task_service.dart';
import '../services/firebase_service.dart';
import '../models/task.dart';
import 'new_task_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  int _currentBottomNavIndex = 1;
  List<Task> _pendingTasks = [];
  List<Task> _completedTasks = [];
  List<String> _availableCategories = ['All', 'Personal'];
  bool _isLoading = true;
  bool _showCompletedTasks = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPendingTasks();
    _loadCompletedTasks();
  }

  Future<void> _loadCategories() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final instructorCourses = await FirebaseService.getInstructorCourses(userId);
      final studentCourses = await FirebaseService.getStudentEnrolledCourses(userId);

      final courseNames = <String>{};
      for (var course in instructorCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }
      for (var course in studentCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }

      if (mounted) {
        setState(() {
          _availableCategories = ['All', 'Personal', ...courseNames.toList()];
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadPendingTasks() async {
    try {
      final tasks = await TaskService.getPendingTasks();
      if (mounted) {
        setState(() {
          _pendingTasks = tasks;
        });
      }
    } catch (e) {
      print('Error loading pending tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Future<void> _loadCompletedTasks() async {
    try {
      final tasks = await TaskService.getCompletedTasks();
      if (mounted) {
        setState(() {
          _completedTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading completed tasks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      if (task.isCompleted) {
        await TaskService.uncompleteTask(task.id);
      } else {
        await TaskService.completeTask(task.id);
      }
      _loadPendingTasks();
      _loadCompletedTasks();
    } catch (e) {
      print('Error toggling task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Task',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TaskService.deleteTask(task.id);
                _loadPendingTasks();
                _loadCompletedTasks();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting task: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    String searchCategory = _selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Search Tasks',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                decoration: InputDecoration(
                  hintText: 'Search by title or description...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: searchCategory,
                isExpanded: true,
                items: _availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      searchCategory = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final results = await TaskService.searchTasks(
                    query: searchController.text,
                    category: searchCategory == 'All' ? null : searchCategory,
                  );
                  if (mounted) {
                    setState(() {
                      _pendingTasks = results.where((t) => !t.isCompleted).toList();
                      _completedTasks = results.where((t) => t.isCompleted).toList();
                      _searchQuery = searchController.text;
                      _selectedCategory = searchCategory;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error searching tasks: $e')),
                    );
                  }
                }
              },
              child: Text('Search', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
    });
    _loadPendingTasks();
    _loadCompletedTasks();
  }

  void _addNewTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTaskScreen()),
    );

    if (result != null && result is Task) {
      _loadPendingTasks();
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

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  double get _completionPercentage {
    final totalTasks = _pendingTasks.length + _completedTasks.length;
    return totalTasks > 0 ? _completedTasks.length / totalTasks : 0;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateOnly == today) {
      return 'Today, ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else if (dueDateOnly == tomorrow) {
      return 'Tomorrow, ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else if (dueDateOnly.isBefore(today)) {
      final daysAgo = today.difference(dueDateOnly).inDays;
      return '$daysAgo day${daysAgo == 1 ? '' : 's'} ago';
    } else {
      final daysLeft = dueDateOnly.difference(today).inDays;
      return 'In $daysLeft day${daysLeft == 1 ? '' : 's'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProgressCard(),
                    const SizedBox(height: 24),
                    _buildPendingTasksSection(),
                    if (_completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildCompletedTasksHeader(),
                      const SizedBox(height: 16),
                      if (_showCompletedTasks) _buildCompletedTasksList(),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
      floatingActionButton: _buildFloatingActionButton(themeProvider),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
        onPressed: _onBackPressed,
      ),
      title: Text(
        'To-Do List',
        style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onBackground),
          onPressed: _showSearchDialog,
        ),
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onBackground),
            onPressed: _clearSearch,
          ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _completionPercentage,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              Provider.of<ThemeProvider>(context).primaryColor,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasksSection() {
    if (_pendingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending tasks',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _pendingTasks.map((task) => _buildTaskCard(task)).toList(),
    );
  }

  Widget _buildCompletedTasksHeader() {
    return GestureDetector(
      onTap: () => setState(() => _showCompletedTasks = !_showCompletedTasks),
      child: Row(
        children: [
          Icon(
            _showCompletedTasks ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'Completed Tasks (${_completedTasks.length})',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksList() {
    return Column(
      children: _completedTasks.map((task) => _buildTaskCard(task)).toList(),
    );
  }

  Widget _buildTaskCard(Task task) {
    final categoryColor = _getCategoryColor(task.category);
    final textColor = _getCategoryTextColor(task.category);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTaskCompletion(task),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
                color: task.isCompleted ? Theme.of(context).primaryColor : Colors.transparent,
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
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Due: ${_formatDueDate(task.dueDate)}',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.category,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteTask(task),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  Widget _buildFloatingActionButton(ThemeProvider themeProvider) {
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
        gradient: themeProvider.gradient,
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

  Color _getCategoryColor(String category) {
    if (category == 'Personal') {
      return const Color(0xFFDCFCE7);
    }
    final hash = category.hashCode % 5;
    switch (hash) {
      case 0:
        return const Color(0xFFDBEAFE);
      case 1:
        return const Color(0xFFFEE2E2);
      case 2:
        return const Color(0xFFFEF3C7);
      case 3:
        return const Color(0xFFDCFCE7);
      case 4:
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _getCategoryTextColor(String category) {
    if (category == 'Personal') {
      return const Color(0xFF16A34A);
    }
    final hash = category.hashCode % 5;
    switch (hash) {
      case 0:
        return const Color(0xFF2563EB);
      case 1:
        return const Color(0xFFDC2626);
      case 2:
        return const Color(0xFFD97706);
      case 3:
        return const Color(0xFF16A34A);
      case 4:
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF2563EB);
    }
  }
}
