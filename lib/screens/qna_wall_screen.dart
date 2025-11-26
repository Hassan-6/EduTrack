import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_viewer_screen.dart';
import 'profile_screen.dart';
import '../utils/theme_provider.dart';
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

  void _showReplyDialog(String questionId, String courseId) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
          },
        ),
        title: Text(
          'Q&A Wall',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: isDark ? Colors.white : const Color(0xFF6366F1),
            ),
            onPressed: _showAskQuestionDialog,
          ),
        ],
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF111827) : Colors.white,
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
              : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF6B7280)),
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
              color: isDark ? const Color(0xFF111827) : Colors.white,
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
                                    major: '${profile['userType'] ?? 'User'}',
                                    age: '',
                                    rollNumber: profile['rollNumber'] ?? '',
                                    phoneNumber: profile['phoneNumber'] ?? '',
                                    email: profile['email'] ?? '',
                                    semester: '',
                                    cgpa: '',
                                  ),
                                ),
                              ),
                            );
                          }
                        });
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6366F1),
                            radius: 20,
                            child: Text(
                              authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
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
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                                if (authorRoll.isNotEmpty)
                                  Text(
                                    authorRoll,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
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
                    
                    // Question title
                    Text(
                      question['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    if (question['content'] != null && question['content'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        question['content'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : const Color(0xFF6B7280),
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
                          onPressed: () => _showReplyDialog(question['id'], courseId),
                          icon: const Icon(Icons.reply, size: 16),
                          label: Text('Reply (${replies.length})', style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      ],
                    ),
                    
                    // Replies
                    if (replies.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...replies.map((reply) => _buildReplyItem(reply, isDark)),
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
                              major: '${profile['userType'] ?? 'User'}',
                              age: '',
                              rollNumber: profile['rollNumber'] ?? '',
                              phoneNumber: profile['phoneNumber'] ?? '',
                              email: profile['email'] ?? '',
                              semester: '',
                              cgpa: '',
                            ),
                          ),
                        ),
                      );
                    }
                  });
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF10B981),
                      radius: 14,
                      child: Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authorName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
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
              Text(
                reply['content'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
