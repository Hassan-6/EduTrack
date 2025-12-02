import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/profile_avatar.dart';
import 'profile_viewer_screen.dart';
import 'profile_screen.dart';
import '../utils/route_manager.dart';

class QAWallScreen extends StatefulWidget {
  const QAWallScreen({super.key});

  @override
  State<QAWallScreen> createState() => _QAWallScreenState();
}

class _QAWallScreenState extends State<QAWallScreen> {
  int _currentBottomNavIndex = 2; // Q&A is active
  String _selectedFilter = 'All';
  
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _userCourses = [];
  bool _isLoading = true;
  String _userType = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) return;
      
      _userId = authProvider.currentUser!.uid;
      
      // Get user profile to determine user type
      final userProfile = await FirebaseService.getUserProfile(_userId);
      if (userProfile == null) return;
      
      _userType = userProfile['userType'] ?? '';
      
      // Load courses based on user type
      if (_userType == 'student') {
        await _loadStudentData();
      } else if (_userType == 'instructor') {
        await _loadInstructorData();
      }
    } catch (e) {
      print('Error loading Q&A data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudentData() async {
    // Get enrolled courses using the proper method
    final enrolledCourseIds = await FirebaseService.getAllCoursesWhereStudentEnrolled(_userId);
    
    print('=== STUDENT Q&A DATA ===');
    print('Student ID: $_userId');
    print('Enrolled course IDs: $enrolledCourseIds');
    
    // Load course details
    _userCourses.clear();
    for (var courseId in enrolledCourseIds) {
      final course = await FirebaseService.getCourseById(courseId);
      if (course != null) {
        _userCourses.add({
          'id': courseId,
          'title': course['title'] ?? 'Unknown Course',
        });
        print('Added course: ${course['title']}');
      }
    }
    
    print('Total courses loaded: ${_userCourses.length}');
    
    // Load questions from these courses
    await _loadQuestions();
  }

  Future<void> _loadInstructorData() async {
    // Get courses taught by instructor
    final courses = await FirebaseService.getInstructorCourses(_userId);
    
    print('=== INSTRUCTOR Q&A DATA ===');
    print('Instructor ID: $_userId');
    print('Courses taught: ${courses.length}');
    
    _userCourses.clear();
    for (var course in courses) {
      _userCourses.add({
        'id': course['id'],
        'title': course['title'] ?? 'Unknown Course',
      });
      print('Added course: ${course['title']}');
    }
    
    print('Total courses loaded: ${_userCourses.length}');
    
    // Load questions from these courses
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    _questions.clear();
    
    List<String> courseIds = _selectedFilter == 'All' 
        ? _userCourses.map((c) => c['id'] as String).toList()
        : [_userCourses.firstWhere((c) => c['title'] == _selectedFilter)['id']];
    
    for (var courseId in courseIds) {
      final questions = await FirebaseService.getQuestionsByCourse(courseId);
      _questions.addAll(questions);
    }
    
    // Sort by timestamp (newest first)
    _questions.sort((a, b) {
      final aTime = a['createdAt']?.toDate() ?? DateTime(2000);
      final bTime = b['createdAt']?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    
    if (mounted) setState(() {});
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentBottomNavIndex) return;
    
    setState(() => _currentBottomNavIndex = index);
    
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getToDoListRoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
        break;
      case 2:
        // Already on Q&A
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

  void _showAskQuestionDialog() {
    if (_userCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be enrolled in at least one course to ask questions')),
      );
      return;
    }
    
    String? selectedCourse = _userCourses.first['id'];
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Ask a Question',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCourse,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _userCourses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course['id'] as String,
                    child: Text(course['title'] as String, style: GoogleFonts.inter(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) => selectedCourse = value,
              ),
              const SizedBox(height: 16),
              Text('Title', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Enter question title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Details', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  hintText: 'Provide more details about your question',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a question title')),
                );
                return;
              }
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              navigator.pop();
              
              await FirebaseService.createQuestion(
                courseId: selectedCourse!,
                authorId: _userId,
                title: titleController.text.trim(),
                content: contentController.text.trim(),
              );
              
              await _loadQuestions();
              
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Question posted successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text('Post Question', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(String questionId, String courseId, String questionAuthorId, String questionTitle) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Add Reply',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reply')),
                );
                return;
              }
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              navigator.pop();
              
              await FirebaseService.replyToQuestion(
                questionId: questionId,
                courseId: courseId,
                authorId: _userId,
                content: replyController.text.trim(),
              );
              
              // Send notification if not replying to own question
              if (questionAuthorId != _userId) {
                final userProfile = await FirebaseService.getUserProfile(_userId);
                final responderName = userProfile?['name'] ?? 'Someone';
                
                // Create notification for question owner
                await NotificationService().notifyQnaResponse(
                  postOwnerId: questionAuthorId,
                  questionTitle: questionTitle,
                  responderName: responderName,
                  postId: questionId,
                );
              }
              
              await _loadQuestions();
              
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Reply posted successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text('Post Reply', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
          },
        ),
        title: Text(
          'Q&A Wall',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuestions,
              child: Column(
                children: [
                  _buildFilterSection(isDark),
                  Expanded(
                    child: _questions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No questions yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to ask a question!',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              return _buildQuestionCard(_questions[index], isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildQnAFloatingActionButton(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildQnAFloatingActionButton() {
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
          onTap: _showAskQuestionDialog,
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', isDark),
            const SizedBox(width: 8),
            ..._userCourses.map((course) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(course['title'], isDark),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        _loadQuestions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, bool isDark) {
    final authorId = question['authorId'] ?? '';
    final courseId = question['courseId'] ?? '';
    final replies = question['replies'] as List<dynamic>? ?? [];
    final timeAgo = question['createdAt'] != null 
        ? _formatTimeAgo(question['createdAt'].toDate())
        : 'Unknown';

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.getUserProfile(authorId),
      builder: (context, authorSnapshot) {
        final authorName = authorSnapshot.data?['name'] ?? 'Unknown User';
        final authorRoll = authorSnapshot.data?['rollNumber'] ?? '';
        
        return FutureBuilder<Map<String, dynamic>?>(
          future: FirebaseService.getCourseById(courseId),
          builder: (context, courseSnapshot) {
            final courseName = courseSnapshot.data?['title'] ?? 'Unknown Course';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author info
                    GestureDetector(
                      onTap: () {
                        // Load user profile and navigate
                        FirebaseService.getUserProfile(authorId).then((profile) {
                          if (profile != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileViewerScreen(
                                  userProfile: UserProfile(
                                    name: profile['name'] ?? 'Unknown',
                                    username: '@${profile['rollNumber'] ?? 'unknown'}',
                                    major: profile['major'] ?? 'Not specified',
                                    age: '',
                                    rollNumber: profile['rollNumber'] ?? '',
                                    phoneNumber: profile['phoneNumber'] ?? '',
                                    email: profile['email'] ?? '',
                                    semester: profile['semester'] ?? 'Not specified',
                                    cgpa: '',
                                    profileIconIndex: profile['profileIconIndex'] ?? 0,
                                  ),
                                ),
                              ),
                            );
                          }
                        });
                      },
                      child: Row(
                        children: [
                          FutureBuilder(
                            future: FirebaseService.getUserProfile(authorId),
                            builder: (context, snapshot) {
                              final iconIndex = snapshot.hasData && snapshot.data != null
                                  ? (snapshot.data!['profileIconIndex'] ?? 0)
                                  : 0;
                              return ProfileAvatar(
                                iconIndex: iconIndex,
                                radius: 20,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                if (authorRoll.isNotEmpty)
                                  Text(
                                    authorRoll,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              courseName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Question title with edit/delete menu
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            question['title'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (authorId == _userId)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditQuestionDialog(question);
                              } else if (value == 'delete') {
                                _showDeleteQuestionDialog(question);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Edit', style: GoogleFonts.inter()),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (question['content'] != null && question['content'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        question['content'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    
                    // Time and reply button
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showReplyDialog(
                            question['id'],
                            courseId,
                            question['authorId'] ?? '',
                            question['title'] ?? 'Question',
                          ),
                          icon: const Icon(Icons.reply, size: 16),
                          label: Text('Reply (${replies.length})', style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      ],
                    ),
                    
                    // Replies
                    if (replies.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...replies.map((reply) {
                        // Add courseId and questionId to reply for edit/delete
                        reply['courseId'] = courseId;
                        reply['questionId'] = question['id'];
                        return _buildReplyItem(reply, isDark);
                      }),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply, bool isDark) {
    final authorId = reply['authorId'] ?? '';
    final timeAgo = reply['createdAt'] != null 
        ? _formatTimeAgo(reply['createdAt'].toDate())
        : 'Unknown';

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.getUserProfile(authorId),
      builder: (context, snapshot) {
        final authorName = snapshot.data?['name'] ?? 'Unknown User';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  FirebaseService.getUserProfile(authorId).then((profile) {
                    if (profile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileViewerScreen(
                            userProfile: UserProfile(
                              name: profile['name'] ?? 'Unknown',
                              username: '@${profile['rollNumber'] ?? 'unknown'}',
                              major: profile['major'] ?? 'Not specified',
                              age: '',
                              rollNumber: profile['rollNumber'] ?? '',
                              phoneNumber: profile['phoneNumber'] ?? '',
                              email: profile['email'] ?? '',
                              semester: profile['semester'] ?? 'Not specified',
                              cgpa: '',
                              profileIconIndex: profile['profileIconIndex'] ?? 0,
                            ),
                          ),
                        ),
                      );
                    }
                  });
                },
                child: Row(
                  children: [
                    FutureBuilder(
                      future: FirebaseService.getUserProfile(authorId),
                      builder: (context, snapshot) {
                        final iconIndex = snapshot.hasData && snapshot.data != null
                            ? (snapshot.data!['profileIconIndex'] ?? 0)
                            : 0;
                        return ProfileAvatar(
                          iconIndex: iconIndex,
                          radius: 14,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authorName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reply['content'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                  if (authorId == _userId)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditReplyDialog(reply);
                        } else if (value == 'delete') {
                          _showDeleteReplyDialog(reply);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 8),
                              Text('Edit', style: GoogleFonts.inter()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Edit question dialog
  void _showEditQuestionDialog(Map<String, dynamic> question) {
    final titleController = TextEditingController(text: question['title'] ?? '');
    final contentController = TextEditingController(text: question['content'] ?? '');
    final courseId = question['courseId'] ?? '';
    final questionId = question['id'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Question', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Question Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Question Details',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a question title')),
                );
                return;
              }

              final success = await FirebaseService.updateQuestion(
                courseId: courseId,
                questionId: questionId,
                title: title,
                content: content,
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question updated successfully')),
                );
                _loadQuestions();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update question')),
                );
              }
            },
            child: Text('Update', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  // Delete question dialog
  void _showDeleteQuestionDialog(Map<String, dynamic> question) {
    final courseId = question['courseId'] ?? '';
    final questionId = question['id'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Question', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete this question? This will also delete all replies.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await FirebaseService.deleteQuestion(
                courseId: courseId,
                questionId: questionId,
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question deleted successfully')),
                );
                _loadQuestions();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete question')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit reply dialog
  void _showEditReplyDialog(Map<String, dynamic> reply) {
    final contentController = TextEditingController(text: reply['content'] ?? '');
    final courseId = reply['courseId'] ?? '';
    final questionId = reply['questionId'] ?? '';
    final replyId = reply['id'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Reply', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: contentController,
          decoration: InputDecoration(
            labelText: 'Reply Content',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();

              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter reply content')),
                );
                return;
              }

              final success = await FirebaseService.updateReply(
                courseId: courseId,
                questionId: questionId,
                replyId: replyId,
                content: content,
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply updated successfully')),
                );
                _loadQuestions();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update reply')),
                );
              }
            },
            child: Text('Update', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  // Delete reply dialog
  void _showDeleteReplyDialog(Map<String, dynamic> reply) {
    final courseId = reply['courseId'] ?? '';
    final questionId = reply['questionId'] ?? '';
    final replyId = reply['id'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Reply', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete this reply?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await FirebaseService.deleteReply(
                courseId: courseId,
                questionId: questionId,
                replyId: replyId,
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply deleted successfully')),
                );
                _loadQuestions();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete reply')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
