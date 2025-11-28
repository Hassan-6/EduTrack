import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import '../utils/theme_provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/firebase_service.dart';
import 'new_task_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  int _currentBottomNavIndex = 1;
  bool _isLoadingPending = true;
  bool _isLoadingCompleted = true;
  bool _isCompletedTasksExpanded = true;
  
  List<Task> _pendingTasks = [];
  List<Task> _completedTasks = [];
  List<String> _categories = ['Personal'];
  List<Task> _filteredPendingTasks = [];
  List<Task> _filteredCompletedTasks = [];
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadPendingTasks(),
      _loadCompletedTasks(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _errorMessage = null;
      });
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      final instructorCourses = await FirebaseService.getInstructorCourses(userId);
      final studentCourses = await FirebaseService.getStudentEnrolledCourses(userId);
      
      final courseNames = <String>{'Personal'};
      for (var course in instructorCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }
      for (var course in studentCourses) {
        courseNames.add(course['title'] ?? 'Unknown Course');
      }
      
      setState(() {
        _categories = courseNames.toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _loadPendingTasks() async {
    try {
      setState(() {
        _isLoadingPending = true;
        _errorMessage = null;
      });
      
      final tasks = await TaskService.getPendingTasks();
      
      setState(() {
        _pendingTasks = tasks;
        _filteredPendingTasks = tasks;
        _isLoadingPending = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pending tasks: $e';
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _loadCompletedTasks() async {
    try {
      setState(() {
        _isLoadingCompleted = true;
        _errorMessage = null;
      });
      
      final tasks = await TaskService.getCompletedTasks();
      
      setState(() {
        _completedTasks = tasks;
        _filteredCompletedTasks = tasks;
        _isLoadingCompleted = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load completed tasks: $e';
        _isLoadingCompleted = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      if (task.isCompleted) {
        await TaskService.uncompleteTask(task.id);
      } else {
        await TaskService.completeTask(task.id);
      }
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(task.isCompleted ? 'Task marked as pending' : 'Task completed!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await TaskService.deleteTask(taskId);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showSearchDialog() async {
    final TextEditingController searchController = TextEditingController();
    String? selectedCategory = _selectedCategory;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Search Tasks',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title or description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    // Optional: Real-time search as user types
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  items: ['All', ..._categories]
                      .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value ?? 'All';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final query = searchController.text.trim();
                final category = selectedCategory == 'All' ? null : selectedCategory;
                
                try {
                  final results = await TaskService.searchTasks(
                    query: query,
                    category: category,
                  );
                  
                  if (mounted) {
                    setState(() {
                      _searchQuery = query;
                      _selectedCategory = selectedCategory ?? 'All';
                      _filteredPendingTasks = results.where((t) => !t.isCompleted).toList();
                      _filteredCompletedTasks = results.where((t) => t.isCompleted).toList();
                    });
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Search error: $e')),
                    );
                  }
                }
              },
              child: Text(
                'Search',
                style: GoogleFonts.inter(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Due Today';
    } else if (dateOnly.isBefore(today)) {
      return 'Overdue';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Due Tomorrow';
    } else if (dateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return 'Due ${DateFormat('EEEE').format(date)}';
    } else {
      return 'Due ${DateFormat('MMM d').format(date)}';
    }
  }

  String _formatTimestamp(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Personal': const Color(0xFFDCFCE7),
      'Math': const Color(0xFFDBEAFE),
      'English': const Color(0xFFFEE2E2),
      'History': const Color(0xFFFCE7F3),
      'Science': const Color(0xFFFEF08A),
    };
    return colors[category] ?? const Color(0xFFDBEAFE);
  }

  Color _getCategoryTextColor(String category) {
    final colors = {
      'Personal': const Color(0xFF16A34A),
      'Math': const Color(0xFF2563EB),
      'English': const Color(0xFFDC2626),
      'History': const Color(0xFFBE185D),
      'Science': const Color(0xFFEAB308),
    };
    return colors[category] ?? const Color(0xFF2563EB);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
        onPressed: () => Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute()),
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
      ],
    );
  }

  Widget _buildProgressCard() {
    final totalTasks = _pendingTasks.length + _completedTasks.length;
    final completionPercentage = totalTasks > 0 ? _completedTasks.length / totalTasks : 0;
    final themeProvider = Provider.of<ThemeProvider>(context);

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
            '${_completedTasks.length} of $totalTasks tasks completed',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completionPercentage.toDouble(),
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                themeProvider.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasksSection() {
    if (_isLoadingPending) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    if (_filteredPendingTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No pending tasks!',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _filteredPendingTasks.map((task) => _buildTaskCard(task)).toList(),
    );
  }

  Widget _buildCompletedTasksHeader() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCompletedTasksExpanded = !_isCompletedTasksExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _isCompletedTasksExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
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
              'Completed Tasks (${_filteredCompletedTasks.length})',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTasksList() {
    if (_isLoadingCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    if (!_isCompletedTasksExpanded || _filteredCompletedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _filteredCompletedTasks.map((task) => _buildTaskCard(task, isCompleted: true)).toList(),
    );
  }

  Widget _buildTaskCard(Task task, {bool isCompleted = false}) {
    final categoryColor = _getCategoryColor(task.category);
    final categoryTextColor = _getCategoryTextColor(task.category);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleTaskCompletion(task),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.description,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteTask(task.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.category,
                  style: GoogleFonts.inter(
                    color: categoryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _formatDueDate(task.dueDate).contains('Overdue')
                      ? Colors.red.withOpacity(0.1)
                      : _formatDueDate(task.dueDate).contains('Today')
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _formatDueDate(task.dueDate).contains('Overdue')
                        ? Colors.red
                        : _formatDueDate(task.dueDate).contains('Today')
                            ? Colors.orange
                            : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: _formatDueDate(task.dueDate).contains('Overdue')
                          ? Colors.red
                          : _formatDueDate(task.dueDate).contains('Today')
                              ? Colors.orange
                              : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(task.dueDate),
                      style: GoogleFonts.inter(
                        color: _formatDueDate(task.dueDate).contains('Overdue')
                            ? Colors.red
                            : _formatDueDate(task.dueDate).contains('Today')
                                ? Colors.orange
                                : Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatTimestamp(task.createdAt)}',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (task.isCompleted) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.green.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Completed: ${_formatTimestamp(task.completedAt)}',
                      style: GoogleFonts.inter(
                        color: Colors.green.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewTaskScreen()),
            );
            if (result != null) {
              await _loadPendingTasks();
            }
          },
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

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;
    
    setState(() {
      _currentBottomNavIndex = index;
    });

    // Navigate based on index - clear stack and only keep main menu
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getMainMenuRoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
        break;
      case 1:
        // Already on Tasks
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getQnARoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getProfileRoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressCard(),
                    const SizedBox(height: 24),
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Text(
                              'Results for "$_searchQuery"',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                  _filteredPendingTasks = _pendingTasks;
                                  _filteredCompletedTasks = _completedTasks;
                                });
                              },
                              child: Text(
                                'Clear',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildPendingTasksSection(),
                    if (_searchQuery.isNotEmpty 
                        ? _filteredCompletedTasks.isNotEmpty 
                        : _completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildCompletedTasksHeader(),
                      const SizedBox(height: 16),
                      _buildCompletedTasksList(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}